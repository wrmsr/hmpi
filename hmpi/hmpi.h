#ifndef _HMPI_H_
#define _HMPI_H_
#include <stdint.h>
#include <mpi.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include "barrier.h"
#include "lock.h"
//#include "opa_primitives.h"

#ifdef __cplusplus
extern "C" {
#endif

extern int g_nthreads;
extern int g_rank;

typedef struct {
  int32_t val;
  int32_t padding[15]; 
} cache_line_t;


typedef struct {
/*  volatile void *rootsbuf;
  volatile void *rootrbuf;
  volatile int rootscount;
  volatile int rootrcount;
  volatile MPI_Datatype rootstype;
  volatile MPI_Datatype rootrtype;
  */
  volatile void** sbuf;
  volatile int* scount;
  volatile MPI_Datatype* stype;
  volatile void** rbuf;
  volatile int* rcount;
  volatile MPI_Datatype* rtype;
  volatile void* mpi_sbuf; //Used by alltoall
  volatile void* mpi_rbuf;
  //volatile uint8_t* flag;
  barrier_t barr;
  MPI_Comm mpicomm;
  //MPI_Comm* tcomms;
} HMPI_Comm_info;

typedef HMPI_Comm_info* HMPI_Comm;

extern HMPI_Comm HMPI_COMM_WORLD;

#define HMPI_SEND 1
#define HMPI_RECV 2
#define MPI_SEND 3
#define MPI_RECV 4
#define HMPI_RECV_ANY_SOURCE 5

//#define HMPI_ANY_SOURCE -55
//#define HMPI_ANY_TAG -55

//ACTIVE and COMPLETE specifically chosen to match MPI test flags
#define HMPI_REQ_ACTIVE 0
#define HMPI_REQ_COMPLETE 1
#define HMPI_REQ_RECV_COMPLETE 2

/* this identifies a message for matching and also acts as request */
typedef struct HMPI_Request {
  int type;
  int proc;
  int tag;
  size_t size;

  void* buf;
  struct HMPI_Request* match_req;

  size_t offset;
  lock_t match;
  volatile uint8_t stat;

  struct HMPI_Request* next;
  struct HMPI_Request* prev;

  //pthread_mutex_t statlock;
  MPI_Request req;
  //MPI_Status* status;
  // following only for HMPI_RECV_ANY_SOURCE
  //MPI_Comm comm;
  MPI_Datatype datatype;
} HMPI_Request;

int HMPI_Init(int *argc, char ***argv, int nthreads, void (*start_routine)(int argc, char** argv));

int HMPI_Comm_rank ( HMPI_Comm comm, int *rank );
int HMPI_Comm_size ( HMPI_Comm comm, int *size );

//AWF new function -- return true (nonzero) if rank is another thread in the
// same process.

static inline int HMPI_Comm_local(HMPI_Comm comm, int rank)
{
#if HMPI_SAFE
  if(comm->mpicomm != MPI_COMM_WORLD) {
    printf("only MPI_COMM_WORLD is supported so far\n");
    MPI_Abort(comm->mpicomm, 0);
  }
#endif
 
    return (g_rank == (rank / g_nthreads));  
}


//AWF new function -- set the thread ID of the specified rank.
static inline void HMPI_Comm_thread(HMPI_Comm comm, int rank, int* tid)
{
#ifdef HMPI_SAFE
  if(comm->mpicomm != MPI_COMM_WORLD) {
    printf("only MPI_COMM_WORLD is supported so far\n");
    MPI_Abort(comm->mpicomm, 0);
  }
#endif

  *tid = rank % g_nthreads;
}


// AWF new function - barrier only among local threads
void HMPI_Barrier_local(HMPI_Comm comm);


int HMPI_Send(void *buf, int count, MPI_Datatype datatype, int dest, int tag, HMPI_Comm comm );
int HMPI_Recv(void *buf, int count, MPI_Datatype datatype, int source, int tag, HMPI_Comm comm, MPI_Status *status );

int HMPI_Isend(void *buf, int count, MPI_Datatype datatype, int dest, int tag, HMPI_Comm comm, HMPI_Request *req );
int HMPI_Irecv(void *buf, int count, MPI_Datatype datatype, int source, int tag, HMPI_Comm comm, HMPI_Request *req );

int HMPI_Test(HMPI_Request *request, int *flag, MPI_Status *status);
int HMPI_Wait(HMPI_Request *request, MPI_Status *status);

int HMPI_Barrier(HMPI_Comm comm);

int HMPI_Reduce(void *sendbuf, void *recvbuf, int count, MPI_Datatype datatype, MPI_Op op, int root, HMPI_Comm comm);


int HMPI_Allreduce(void *sendbuf, void *recvbuf, int count, MPI_Datatype datatype, MPI_Op op, HMPI_Comm comm);


int HMPI_Bcast(void *buffer, int count, MPI_Datatype datatype, int root, HMPI_Comm comm);

int HMPI_Scatter(void* sendbuf, int sendcount, MPI_Datatype sendtype, void* recvbuf, int recvcount, MPI_Datatype recvtype, int root, HMPI_Comm comm);

int HMPI_Gather(void* sendbuf, int sendcount, MPI_Datatype sendtype, void* recvbuf, int recvcount, MPI_Datatype recvtype, int root, HMPI_Comm comm);

int HMPI_Allgather(void* sendbuf, int sendcount, MPI_Datatype sendtype, void* recvbuf, int recvcount, MPI_Datatype recvtype, HMPI_Comm comm);

int HMPI_Allgatherv(void *sendbuf, int sendcount, MPI_Datatype sendtype, void *recvbuf, int *recvcounts, int *displs, MPI_Datatype recvtype, HMPI_Comm comm);

int HMPI_Alltoall(void* sendbuf, int sendcount, MPI_Datatype sendtype, void* recvbuf, int recvcount, MPI_Datatype recvtype, HMPI_Comm comm);

int HMPI_Alltoall_local(void* sendbuf, int sendcount, MPI_Datatype sendtype, void* recvbuf, int recvcount, MPI_Datatype recvtype, HMPI_Comm comm);

//Assumes all ranks are local.
int HMPI_Alltoall_local2(void* sendbuf, void* recvbuf, size_t len, HMPI_Comm comm);

int HMPI_Abort( HMPI_Comm comm, int errorcode );

int HMPI_Finalize();



#ifdef __cplusplus
}
#endif
#endif
