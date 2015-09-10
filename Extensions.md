## Additional Communicators ##

HMPI provides the `MPI_COMM_NODE` and `MPI_COMM_NETWORK` communicators, first proposed in the paper [Bi-modal MPI and MPI+threads Computing on Scalable Multicore Systems](http://www.sandia.gov/~maherou/docs/ShMPI.pdf).

`MPI_COMM_NODE` is defined to contain the ranks located on the same node (shared memory domain).

`MPI_COMM_NETWORK` is defined to contain one rank from each node.  That is, rank X of from each `MPI_COMM_NODE` is grouped into an `MPI_COMM_NETWORK` communicator.

If the MPI job has M nodes with N ranks per node, the size of `MPI_COMM_NODE` is N, and the size of `MPI_COMM_NETWORK` is M.  The size of `MPI_COMM_WORLD` is N`*`M.


## Rank Locality ##

With a shared heap it becomes much more important for determining whether some rank is located in the same node or not (and thus safe to share memory with).  HMPI adds the following function:

```
void HMPI_Comm_node_rank(HMPI_Comm comm, int rank, int* node_rank)
```

This function translates a given `comm` and `rank` to a node-specific rank or ID.  If the specified rank is on the same node, `node_rank` is set to a value `0 <= node_rank < NUM_RANKS_ON_THIS_NODE`.  Each rank will be mapped to a node\_rank value that is unique to its node.  Otherwise, if `rank == MPI_ANY_SOURCE`, `node_rank` is set to `MPI_ANY_SOURCE`, and for any other value it is set to `MPI_UNDEFINED`.


## Testing for shared heap memory ##

To determine if a given address resides in the shared heap memory region, use the following `IS_SM_BUF` macro.  For example:

```
if(!IS_SM_BUF(ptr)) {
    sm_ptr = malloc(size);
    memcpy(sm_ptr, ptr, size);
} else {
    sm_ptr = ptr;
}
```