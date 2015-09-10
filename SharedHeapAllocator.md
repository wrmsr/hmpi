HMPI is built on what we call the shared memory heap allocator.  Normally, memory allocation routines like `malloc`, `memalign`, etc. return memory that is private to the calling process.  When these functions are overridden by the shared memory heap allocator (SM heap), the memory returned is actually shared by all participating processes in a system (compute node).  An address (pointer) returned by `malloc` is safe for that process to use as it normally would; other processes will not allocate the same memory.  The difference is that now the address can be shared with another participating processes, and that process can access the same memory at the same address without any extra work.

_Footnote:  Using a shared heap does expose programs to bugs/exploits due to the fact that one process can write to any memory in the heap, including portions allocated and/or used by other processes._

In HMPI, we use the SM heap to implement single-copy data transfer (and other novel protocols) for message passing.  Normally this requires non-standard kernel extensions; the SM heap makes it possible to do so entirely in user space.

Although part of the HMPI codebase, the SM allocator is not HMPI or MPI specific in any way.  To use it, compile [hmpi/malloc.c](https://code.google.com/p/hmpi/source/browse/hmpi/malloc.c) and [hmpi/sm\_malloc.c](https://code.google.com/p/hmpi/source/browse/hmpi/hmpi.c), then link them your code.

The SM heap takes advantage of the fact that on many Linux systems, `malloc` and friends are defined as [weak symbols](https://en.wikipedia.org/wiki/Weak_symbol), allowing them to be transparently overridden just by linking with the SM heap code.  On Blue Gene/Q, the following XLC compiler linker argument is required:

```
-Wl,--allow-multiple-definition
```


# Implementation Details #

Rather than implementing an entirely new memory allocator, we repurposed Doug Lea's [dlmalloc](http://g.oswego.edu/dl/html/malloc.html).  The default memory allocator used in Linux is ptmalloc, which is also based on dlmalloc.  Other allocators can be modified to work as a shared memory heap, for example we have also modified Google's tcmalloc.

In the HMPI code base, [hmpi/malloc.c](https://code.google.com/p/hmpi/source/browse/hmpi/malloc.c) is dlmalloc with some macros defined at the top to adjust its behavior for SM heap purposes.  Specifically, we only use the memory pool interface (not the default `malloc`/etc functions), and disable all use of `sbrk` and `mmap`.  Instead, each process will create a statically sized memory pool from which to allocate memory.

_We chose the static mpool approach with dlmalloc to minimize cross-process fragmentation and synchronization.  An alternative solution, that works more portably with other memory allocators, is to provide our own implementation of `sbrk`.  Then, the memory allocator code is configured to use only our version of `sbrk` rather than the operating system's.  Emulating `mmap` effectively requires writing another set of memory allocator algorithms behind it, so we disable `mmap` support in the memory allocator---the point is to avoid writing a new memory allocator!  In addition, the memory allocator must not assume that sequential calls to sbrk will return contiguous memory._

[hmpi/sm\_malloc.c](https://code.google.com/p/hmpi/source/browse/hmpi/hmpi.c) implements all the magic of the SM heap.  On the first call to any memory allocation routine, `__sm_init` is invoked.  Here, we create a large shared memory region (many gigabytes) to use as the heap for all participating processes.  The current approach uses `shm_open` and `mmap`.  The `SM_SIZE` environment variables controls how many megabytes are allocated for the shared memory region.  The `SM_RANKS` environment variable determines how much of that shared region each process will reserve: `SM_SIZE / SM_RANKS` megabytes.

We must ensure that this shared memory region is allocated at the same address on every process.  Some Linux systems return addresses deterministically from `mmap`.  Since `__sm_init` executes extremely early in the application's life, we can be fairly confident that each process will return the same address from `mmap`.  However, apparently some Linux systems randomize the addresses returned by `mmap` for security purposes.  We work around this by parsing `/proc/<pid>/maps` to find the first hole in the virtual memory space large enough for the shared memory region.  `find_map_address()` implements this work around, and we now use it by default.  Coincidentally, we tend to occupy the exact same virtual space that a private heap normally would.

The `/proc/<pid>/maps` work around is sufficient for SPMD (single-program-multiple-data), which is the norm for MPI.  Each process will have the same virtual memory layout, since they are all executing the same program.  When sharing the heap across different binaries, this code will probably need some adjusting to account for different binary sizes -- rounding up the first base address found should be enough to account for this, or perhaps the first hole should be skipped altogether.

Some trickery is needed to coordinate the initialization among multiple processes.  Each process first attempts to open the file backing the shared memory region using the create-exclusive (`O_CREAT|O_EXCL` flags.  If the file already exists, `shm_open` returns an error indicating so.  Exactly one process will succeed at creating the file, and it will take the responsibility for initializing the shared memory region and a small data structure located at the beginning of the region.  If a process fails to open and create the file, it tries again without the create-exclusive flags, which is expected to succeed.  These processes then spin on a value in the data structure, waiting for the go-ahead from the creating/initializing process.

Once the region is in place, each rank uses an atomic fetch-add operation to reserve a portion of the shared memory region to allocate memory for itself.  Next, a dlmalloc memory pool is created using the local portion of the shared region.  All calls to `malloc` et.al. on this process will return memory only from this memory pool.

Still in [hmpi/sm\_malloc.c](https://code.google.com/p/hmpi/source/browse/hmpi/hmpi.c) are wrappers that implement `malloc`, `memalign`, `free`, etc. that check for initialization and then call dlmalloc using the local shared memory pool.
