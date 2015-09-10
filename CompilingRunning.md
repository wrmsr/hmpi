## Obtain the source code ##

First, grab the source code, either one of the tarballs or doing an SVN checkout (see the Source page for the project).  Tarballs are occasionally made available here:

https://code.google.com/p/hmpi/source/browse/#svn%2Frelease

Latest direct link:

https://hmpi.googlecode.com/svn/release/hmpi-072913.tar.gz

To download, select the desired file and use the 'View raw file' link under File Info on the right.


## Compile ##

Compile on an x86 system with just 'make', or on Blue Gene/Q with 'make bgq'.  This will produce libhmpi.a and libhmpi-bgq.a, respectively.

To compile an application to use HMPI, first you need to replace all #includes of mpi.h with hmpi.h.

Compile applications with these extra flags on x86 (they can be split up for separate compile/link commands appropriately):
```
-I$(HMPI_DIR) -L$(HMPI_DIR) -lhmpi
```

Compile applications with these extra flags on Blue Gene/Q:
```
-I$(HMPI_DIR) -L$(HMPI_DIR) -lhmpi-bgq -Wl,--allow-multiple-definition
```

The extra linker flag above is required to make weak symbols actually be weak on Blue Gene/Q.  Without it, the linker will emit multiple definition errors for malloc/free/etc.


## Shared Heap Allocator Issues ##

Our shared heap allocator based on [dlmalloc](http://g.oswego.edu/dl/html/malloc.html) is linked in and used by default (BG\_MAP\_COMMONHEAP is no longer used by HMPI on Blue Gene/Q).  It will use POSIX SHM to try to mmap as much memory as possible.  On Blue Gene/Q, two environment variables need to be set: SM\_SIZE and BG\_SHAREDMEMSIZE.  BG\_SHAREDMEMSIZE configures the amount of shared memory the system reserves when running on the compute nodes.  SM\_SIZE configures how much shared memory the shared heap allocator will consume.  Below are reasonable defaults:

```
export SM_SIZE=12288
export BG_SHAREDMEMSIZE=`expr $SM_SIZE + 65`
export SM_RANKS=64
```

Numbers are in units of megabytes for both variables.  The default value for BG\_SHAREDMEMSIZE is 64 megabytes, which is used by the system and underlying MPI.  When configuring for HMPI, it is necessary to account for that plus the space the shared heap allocator will consume (ideally all the rest of memory).  Note that the application's heap area will be located in this shared memory region, so it is not necessary to leave regular memory aside for that purpose (only the program data segments, global variables, and stack remain in regular/private memory).

There's one more variable of interest: SM\_RANKS is used to specify the expected number of ranks.  The default is 64 on Blue Gene/Q and 16 everywhere else.  This affects how much memory is available to each rank: SM\_SIZE / SM\_RANKS.  So if you're running less than 64 ranks on Blue Gene/Q, you may want to change it so there's more memory available.

The SM\_SIZE and SM\_RANKS environment variables work on all platforms.  On non-BGQ systems, HMPI currently defaults to SM\_SIZE=524288 and SM\_RANKS=16 (creating a heap of size SM\_SIZE/SM\_RANKS=32gb).  These variables may need to be adjusted accordingly for your system.  SM\_RANKS should be set to the number of cores (or less, if running fewer MPI ranks).  SM\_SIZE should be set as large as possible, ideally large enough that each rank has a heap region equal to the size of physical memory.

When running an application, the shared heap allocator creates a file /dev/shm/hmpismfile on each node (/dev/shm is normally a tmpfs mount).  Upon normal termination, this file gets cleaned up automatically.  However, if the application segfaults or is killed using CTRL+C, that file will likely be left behind.  On slurm-based systems (i.e., LC) this can be cleaned up using the following command when running either in a batch script or interactively:

```
srun -N $SLURM_NNODES --tasks-per-node=1 rm /dev/shm/hmpismfile
```

Yet again, Blue Gene/Q is different.  First off, the above command probably won't work.  However it doesn't seem necessary, as the OS on the compute nodes appears to clean up the shared memory file regardless of how the application terminates.  In other words, the above issue doesn't apply to Blue Gene/Q, at least on the LC systems.

### Systems that randomize addresses returned by mmap() ###

Some Linux distributions default to returning randomizing addresses from mmap(), apparently for security purposes.  This causes the shared heap allocator to abort during initialization, with the following error:

```
ERROR sm_malloc.c:293 sm_region limit 7f45ef6xxxxx doesn't match computed limit  7f45exxxxxxx
```

Note that this error can also be caused by a stale shared memory file (see above).  By default HMPI relies on a quirk where mmap() will return the same address on each MPI rank, since they are all the exact same program.  Randomizing the addresses returned by mmap() breaks this.  The fix is to add this macro to the compile line:

```
-DUSE_PROC_MAPS=1
```

This enables code that will parse /proc/`<pid>`/maps to find a hole big enough for the desired mmap region, then specify the address of that hole to mmap.  So far it appears that this is sufficient for discovering the same address to map the shared memory region to on all MPI ranks in a node.


## Impact of using a Shared Heap Allocator ##

The shared heap allocator returns shared memory from malloc() and friends.  That is, a pointer returned by malloc() on one process (MPI rank) is valid on all participating processes on the same node.  The implication here is that it is perfectly valid to malloc() some memory, do something with it, and pass a pointer to that memory via MPI Send/Recv, and another rank can access that same memory directly, without any copying or translation (see Ownership Passing with HMPI).  Existing shared memory synchronization primitives such as POSIX-threads mutexes/semaphores and [GCC built-in atomics](http://gcc.gnu.org/onlinedocs/gcc-4.1.1/gcc/Atomic-Builtins.html) work just as they do among threads.  On processors with relaxed memory consistency models (i.e. PowerPC), memory fences are necessary when sharing data.  The shared heap is the basis for all of HMPI's optimizations.


## Missing Features ##

Being a research project, HMPI doesn't fully implement MPI, although support is growing over time.  If it appears that some functionality is missing, contact the authors and we'll try to get it added.  Most notably, HMPI currently does not support non-contiguous user-defined MPI datatypes, or alternate send forms like MPI\_Bsend and MPI\_Ssend.  The one-sided interface is not implemented, nor the new features of MPI-3.


## Running HMPI ##

Once compiled and linked into a normal MPI application, nothing special needs to be done to run using MPI.  Just run the application as it is normally intended.  HMPI should be completely transparent, though hopefully providing speedups.