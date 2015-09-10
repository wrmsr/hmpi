HMPI is a relatively small codebase, consisting of the following files:

| File Name | Purpose |
|:----------|:--------|
| [error.h](https://code.google.com/p/hmpi/source/browse/hmpi/error.h) | Macros for warning and error reporting. |
| [lock.h](https://code.google.com/p/hmpi/source/browse/hmpi/lock.h) | Platform-specific primitives for locking and related atomic operations. |
| [hmpi.h](https://code.google.com/p/hmpi/source/browse/hmpi/hmpi.h) | User-visible header file defining (H)MPI interface. |
| [hmpi.c](https://code.google.com/p/hmpi/source/browse/hmpi/hmpi.c) | Initialization, shutdown, and communicator management. |
| [hmpi\_p2p.c](https://code.google.com/p/hmpi/source/browse/hmpi/hmpi_p2p.c) | Point-to-point message matching, message passing, and ownership passing (give/take). |
| [hmpi\_opi.c](https://code.google.com/p/hmpi/source/browse/hmpi/hmpi_opi.c) | Ownership Passing initialization and memory pools (alloc/free). |

Related but non-HMPI-specific files:

profile.h        Profiling tools, see [PerformanceProfiling](PerformanceProfiling.md).

sm\_malloc.c  Shared memory heap allocator, see [SharedHeapAllocator](SharedHeapAllocator.md).

malloc.c        dlmalloc, see [SharedHeapAllocator](SharedHeapAllocator.md).


# [error.h](https://code.google.com/p/hmpi/source/browse/hmpi/error.h) #

Contains two macros, `ERROR` and `WARNING`, used throughout the HMPI code.  `WARNING` prints a message prefixed with the file and line number from where it is called.  `ERROR` does the same, but then immediately aborts the program.


# [lock.h](https://code.google.com/p/hmpi/source/browse/hmpi/lock.h) #

Contains platform-specific implementation of an atomic lock (mutex), and some other atomic primitives:

| Function | Purpose |
|:---------|:--------|
| STORE\_FENCE | Ensure all prior memory writes are complete. |
| LOAD\_FENCE  | Ensure all prior memory reads are complete. |
| FENCE            | Ensure all prior memory reads and writes are complete. |
| CAS\_PTR\_BOOL | Compare-and-swap on a pointer value, evaluating to a boolean expression. |
| CAS\_PTR\_VAL | Compare-and-swap evaluating to the previous value of the pointer. |
| CAS\_T\_BOOL | Compare-and-swap an arbitrary type, evaluating to a boolean expression. |
| FETCH\_ADD32 | Fetch-and-add 32-bit integer value. |
| FETCH\_ADD64 | Fetch-and-add 64-but integer value. |
| FETCH\_STORE | Fetch-and-store a pointer value. |
| LOCK\_INIT | Initialize a lock (mutex). |
| LOCK\_ACQUIRE | Spin (block without yield) until a lock is acquired. |
| LOCK\_RELEASE | Release a lock. |

Many of these routines are modeled after (and often implemented by) the [Intel/GCC built-in atomic primtives](http://gcc.gnu.org/onlinedocs/gcc-4.3.5/gcc/Atomic-Builtins.html).  In addition to ICC and GCC, they are also supported by XLC on Blue Gene/Q.

On x86, the lock routines are implemented using the well-known [MCS lock algorithms](http://www.cs.rochester.edu/research/synchronization/pseudocode/ss.html).  These have slightly better scalability (i.e., better performance when many cores are spinning to acquire the lock) than a simple spin-lock, and provide a FIFO ordering guarantee.  That is, if process A gets in line to acquire the lock before process B, process A will always acquire the lock first.  Without FIFO ordering, we found that HMPI performance varied widely due to long delays occasionally caused by lock starvation.

On Blue Gene/Q we found no benefit to using the MCS lock algorithms, so instead we use the PowerPC A2-specific L2 lock primitives, which are faster than the standard PowerPC `lwarx`/`stwcx` instructions.


# [hmpi.h](https://code.google.com/p/hmpi/source/browse/hmpi/hmpi.h) #

This is the main HMPI header file.  Applications should include `hmpi.h` instead of the standard `mpi.h` when compiling to use HMPI.  All of the standard MPI routines, types, and constants implemented by HMPI are designated with an `HMPI_` prefix.  For each of the MPI routines HMPI implements, a corresponding macro renaming the MPI call to the HMPI call.

Collectives are currently handled differently, as we do not implement any of them directly.  Instead, there is one macro for each MPI collective which passes the call down to the underlying MPI, dereferencing the HMPI communicator object properly along the way.

HMPI defines its own versions of user-visible MPI objects:  `HMPI_Comm`, `HMPI_COMM_WORLD`, `HMPI_Request`, `HMPI_Status`, etc.

Several internal data structures are also defined here, as they are referenced by the public-facing MPI objects.  `HMPI_Item` is a simple base type for using objects as linked list elements.  For any structure that will be used as a linked list, its first member variable will be an instance of `HMPI_Item`.  This allows type casting back and forth between `HMPI_Item` and the appropriate structure type.  `HMPI_Request_list` implements a linked list of `HMPI_Item` objects/elements.  Elements are single-linked while both a head and tail are kept track of.

Again for internal use, a number of macros are defined.  The most interesting is `IS_SM_BUF()`, which takes a pointer as an argument and evaluates to a boolean indicating whether the specified memory is part of the shared memory heap or not.  Each `HMPI_Request` has a type associated with it, defined by macros to indicate send/recv, HMPI (local) / MPI (remote), and receives with `MPI_ANY_SOURCE`.  In addition, each request has a state, either `ACTIVE` (message is in transit) or `COMPLETE` (message completed).  Finally, each request has a flag (`do_free`) for tracking what should be done with its associated message buffer when completed.  `DO_NOT_FREE` indicates a user buffer that should not be touched, while `DO_FREE` indicates a regular buffer that should be `free`'d.  `OPI_FREE` indicates the buffer should be returned to the memory pool via `OPI_Free`.


# [hmpi.c](https://code.google.com/p/hmpi/source/browse/hmpi/hmpi.c) #

Contains HMPI initialization and communicator management code.  `HMPI_Init` calls `MPI_Init`, then sets up `HMPI_COMM_WORLD`.  Next, it allocates data structures representing incoming local messages and local receives.  Rank 0 on a node does the initialization, then shares the address of the data structures using node-local MPI broadcast.  A final world-wide barrier ensures all ranks have finished initializing before returning to the application.

`HMPI_Finalize` has little work to do other than print any profiling variables and call `MPI_Finalize`.

`init_communicator` does the work of creating an `HMPI_Comm`, given an `MPI_Comm`.  This routine fills in the HMPI-specific data structure elements.  Most importantly, for each communicator, we internally split it into sub-communicators, one for each node.  Various fields in the `HMPI_Comm` object are filled in based on this node-local communicator and are used for quick access to rank/size information throughout the HMPI codebase.

HMPI implements the MPI communicator management routines using `init_communicator` and calling the equivalent MPI routines.

# [hmpi\_p2p.c](https://code.google.com/p/hmpi/source/browse/hmpi/hmpi_p2p.c) #

Point-to-point messaging code, the bulk of HMPI, is located in this file.


## Front-end Routines ##

All forms of HMPI Send and Receive (e.g., `HMPI_Send`, `HMPI_Irecv` are located in this file.  In any of these routines, a check is first performed to determine whether the message source (receive) or destination (send) is within the same node (local) or not (remote).    Depending on whether the message is local or remote, and whether it is non-blocking, several things can happen (`MPI_ANY_SOURCE` receives have additional special handling, see below):

**Remote, blocking:**  In this case, a non-blocking form of the respective send or receive is posted to the MPI layer.  Even in the blocking case, non-blocking MPI calls are need to alternately make message progress (see next section) in both the HMPI and MPI layers.  However, since the HMPI-level call is expected to wait for message completion, creation of an `HMPI_Request` object is not necessary when the message is also remote.

**Remote, non-blocking:**  A send or receive is posted to the MPI layer, and an `HMPI_Request` object is created and returned to the user so that the message can be completed later.  For performance reasons, the first element of `HMPI_Request` is a union between `HMPI_Item` and `MPI_Request`.  We know that the `HMPI_Request` will never be placed on a linked list in this case, and that better performance is achieved if the associated `MPI_Request` is the first element of `HMPI_Request`.

**Local**: Both send and receive, regardless of whether they are blocking or non-blocking, have an auxiliary function for handling local messages (`HMPI_Local_isend` and `HMPI_Local_irecv`.  Local messages are always handled as if they were non-blocking, and always create an `HMPI_Request` object that gets added to an appropriate message queue.  Receives go to the local receive list, while sends are added to the incoming message queue of the destination rank.  Blocking forms of local send/receive poll progress until the message is completed.

The various non-blocking completion routines (`MPI_Test*`, `MPI_Wait*`) behave similarly, polling `HMPI_Progress` (see next section) and testing for message completion.

## Message Progress and Matching ##

Like most MPI implementations, HMPI has a polling progress architecture.  That is, there is a single function `HMPI_Progress`, that attempts to match incoming sends to local receives and then transfer the message data.  Each rank has a queue of local receives, and a queue of incoming sends.  The receive queue is private, while the incoming send queue is shared and protected by a lock.  Any local rank may append a send message to any other local rank's send queue.  `HMPI_Progres` iterates over the requests in the receive queue, attempting to find a matching (same rank, tag, communicator) message in its incoming send queue.  When a matching send is found, the send and receive requests are removed from their corresponding queues, the data is transferred, and both messages are marked as completed.

To meet MPI's match ordering rules, there are actually two incoming send queues per rank.  One is private, and one is shared.  Other ranks add their send requests to the lock-protected shared queue.  When `HMPI_Progress` is called, it uses the `update_send_reqs` routine to drain the shared send queue into the private send queue.  The matching loop only attempts to match against requests in the private send queue.

Too see why, consider the case where a rank posts local receive A, then another local receive B.  Also assume that there is only the one shared send queue.  Now, `HMPI_Progress` is called and the matching loop first looks for an incoming send that matches receive A.  No sends are in the queue, so no match is made.  After this, but before the loop can check for matches for receive B, a sender inserts send request X with a (rank, tag, communicator) that matches both receive A and B.  MPI matching rules require that this send be matched with A, but now receive B will be checked and successfully matched with send X.  The private queue ensures that this cannot happen; the loop that checks all receives for matches against a list of incoming sends that cannot be changed.

See the section Data Transfer section below for the protocols use to copy data from the send to the receive.

## `MPI_ANY_SOURCE` ##

Receives specified with MPI\_ANY\_SOURCE require all sorts of special handling, as they may be matched with either a local (HMPI-level) or remote (MPI-level) message.  In fact, `MPI_ANY_SOURCE` receives are treated as being both local and remote at the same time -- the `HMPI_Request` object is added to the local receive list, while a receive is posted to the underlying MPI.  Completion functions test the receive as if it were a remote receive, completing the message there if possible.  If the progress routine makes a local match, it attempts to cancel the receive posted to the MPI layer.  If the cancel succeeds, data transfer proceeds as usual with the normal match.  Otherwise, the cancel failed, meaning MPI has already matched a message -- we complete the MPI\_ANY\_SOURCE receive using the MPI layer and ignore the local match.


## Data Transfer Protocols ##

Once a message is matched, the data needs to be transferred from the send buffer to the receive buffer.  HMPI has three different protocols for transferring data depending on the message size.  More detail on these protocols can be found in the [Hybrid MPI: Efficient Message Passing for Multi-core Systems](http://htor.inf.ethz.ch/publications/index.php?pub=173) paper.

**Immediate:** If the message is less than 256 bytes (may change depending on platform), the sender copies the message data into an inline buffer located in the `HMPI_Request` object.  The receiver copies the data using the same control flow path as the **Single Copy** protocol.

**Synergistic:** If the send buffer is located in shared memory (i.e., the heap) and is larger than a platform-specific threshold (8kb on x86, 16kb on BG/Q), the receive enters the synergistic protocol and sets a flag on the matching send request indicating so.  Next, the receiver enters a loop copying one block of the message at a time using `memcpy` until the entire message has been transferred.  If the sender polls its send request and sees that the receiver has set the synergistic protocol flag, it also enters a similar block copy loop until the message transfer is completed.

**Single Copy:** If the other protocols are not suitable to use, data is transferred by the receiver using a single `memcpy` call.


## Ownership Passing ##

OPI Give and Take messages are matched in the same manner and using the same queues as MPI messages, but no data transfer occurs--only the pointer address itself is copied over.  In fact, `OPI_Give` and `OPI_Take` are just syntactic sugar that encourage the producer-consumer, single-owner ownership passing semantics.  Ownership passing is possible just by transferring pointers using HMPI Send and Receive.  With a shared heap in place, ownership mostly works by default.

# [hmpi\_opi.c](https://code.google.com/p/hmpi/source/browse/hmpi/hmpi_opi.c) #

This file contains the implementations of `OPI_Alloc` and `OPI_Free`, which represent the memory pool functionality detailed in our paper, [Ownership Passing: Efficient Distributed Memory Programming on Multi-core Systems](http://htor.inf.ethz.ch/publications/index.php?pub=161).  Additionally, an `OPI_Init}} routine is located here for doing OPI-specific initialization, and is called only from {{{HMPI_Init` -- users should not call this routine.

`OPI_Alloc` allocates memory, but first searches a linked list (the memory pool) in first-fit fashion for a to reuse, avoiding an expensive `malloc`/`memalign` call.  Each rank gets its own memory pool, and always searches its own pool for a buffer.

When buffers are freed by calling `OPI_Free`, they are added back into a memory pool instead of releasing the memory back to the OS.  Which memory pool depends on how this code is configured:  macros near the top of the file select receiver-side pools (`RECVER_POOL`, the default) or sender-side pools (`SENDER_POOL`).  When receiver pools are enabled, `OPI_Free` _prepends_ its buffer to the local memory pool list.  For sender pools, the buffer is returned to the pool of the rank that originally allocated the memory.

If sender-side pools are enabled, locks are enabled in both `OPI_Alloc` and `OPI_Free` to synchronize access.  Each memory pool (one per rank) gets its own lock.