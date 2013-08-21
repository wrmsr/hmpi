/* Copyright (c) 2010-2013 The Trustees of Indiana University.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * - Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 * 
 * - Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * 
 * - Neither the Indiana University nor the names of its contributors may be
 *   used to endorse or promote products derived from this software without
 *   specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
#ifdef USE_HMPI
#include <hmpi.h>
#else
#include <mpi.h>
#endif
#define _GNU_SOURCE
#include <pthread.h>
#include <sched.h>
#include <stdio.h>
#include <malloc.h>
#include <unistd.h>
#include <stdlib.h>
#include <profile.h>

#define printf(...) printf(__VA_ARGS__); fflush(stdout)

#define max(a, b) ((a)<(b)? (b): (a))

#ifdef THREAD
#undef THREAD
#endif

#ifdef USE_HMPI
#define THREAD __thread
#else
#define THREAD
#endif

#ifndef CACHE_LINE
#define CACHE_LINE 64
#endif

#define MALLOC(t, s) (t*)memalign(CACHE_LINE, sizeof(t) * s)


PROFILE_DECLARE();
PROFILE_TIMER(app);
PROFILE_TIMER(pack);
PROFILE_TIMER(comm);
PROFILE_TIMER(unpack);

//MPI rank and size
THREAD int rank;
THREAD int size;


//Set in do_benchmark() and used in the mpi/app routines.
THREAD uint64_t* app_buf;
THREAD uint64_t* send_buf;
THREAD uint64_t* recv_buf;
THREAD int count;


#ifdef USE_FUSION
void run_benchmark(int iters, int stride)
{
    MPI_Request req[2];
    int neighbor = (rank + 1) % 2;

    for(int i = 0; i < iters; i++) {
        PROFILE_START(pack);
        PROFILE_STOP(pack);

        PROFILE_START(comm);

        //Send the lower half if neighbor is 0, upper if 1.
        void* sbuf = &app_buf[count * neighbor];
        OPI_Give(&sbuf, count, MPI_UNSIGNED_LONG_LONG,
                neighbor, neighbor, MPI_COMM_WORLD, &req[1]);

        void* rbuf;
        OPI_Take(&rbuf, count, MPI_UNSIGNED_LONG_LONG,
                neighbor, rank, MPI_COMM_WORLD, &req[0]);

        MPI_Waitall(2, req, MPI_STATUSES_IGNORE);
        PROFILE_STOP(comm);
        PROFILE_START(unpack);

        //Do the fused loop:
        //Unpack into the lower or upper half of the data depending on the neighbor rank.
        memcpy(&app_buf[count * rank], rbuf, count * sizeof(uint64_t));

#if 0
        uint64_t* src_buf = rbuf;
        uint64_t* dest_buf = &app_buf[count * rank];

        for(int j = 0; j < count; j++) {
            dest_buf[j] = rbuf[j];
        }
#endif

        PROFILE_STOP(unpack);
    }
}

#else

void run_benchmark(int iters, int stride)
{
#ifdef USE_OPI
    MPI_Request req[2];
#else
    MPI_Request req;
#endif
    int neighbor = (rank + 1) % 2;

    for(int i = 0; i < iters; i++) {
        //Pack the buffer
        PROFILE_START(pack);

#ifdef USE_OPI
        OPI_Alloc((void**)&send_buf, count * sizeof(uint64_t));
#endif

#ifdef __bg__
        //For some reason, BGQ memcpy is WAY faster than the direct loop.
        if(stride == 1) {
            memcpy(send_buf,
                    &app_buf[count * neighbor], count * sizeof(uint64_t));
        } else //Ugly but covers teh following for-loop
#endif

        for(int j = 0; j < count; j++) {
            send_buf[j] = app_buf[j*stride];
        }

        PROFILE_STOP(pack);

        MPI_Barrier(MPI_COMM_WORLD);


        //Communicate
        PROFILE_START(comm);
#ifdef USE_OPI
        OPI_Take((void**)&recv_buf, count, MPI_UNSIGNED_LONG_LONG,
                neighbor, rank, MPI_COMM_WORLD, &req[0]);
        OPI_Give((void**)&send_buf, count, MPI_UNSIGNED_LONG_LONG,
                neighbor, neighbor, MPI_COMM_WORLD, &req[1]);

        MPI_Waitall(2, req, MPI_STATUSES_IGNORE);
#else //MPI
        MPI_Irecv(recv_buf, count, MPI_UNSIGNED_LONG_LONG,
            neighbor, rank, MPI_COMM_WORLD, &req);

        MPI_Send(send_buf, count, MPI_UNSIGNED_LONG_LONG,
                neighbor, neighbor, MPI_COMM_WORLD);

        MPI_Wait(&req, MPI_STATUS_IGNORE);
#endif
        PROFILE_STOP(comm);


        PROFILE_START(unpack);

#ifdef __bg__
        //For some reason, BGQ memcpy is WAY faster than the direct loop.
        if(stride == 1) {
            memcpy(&app_buf[count * rank], recv_buf, count * sizeof(uint64_t));
        } else 
#endif
        //Unpack the buffer
        for(int j = 0; j < count; j++) {
            app_buf[j*stride] = recv_buf[j];
        }

#ifdef USE_OPI
        OPI_Free((void**)&recv_buf);
#endif

        PROFILE_STOP(unpack);
    }
}

#endif


void do_benchmark(int bench_iters, int comm_iters, int buf_stride, int buf_size)
{
    buf_stride /= sizeof(uint64_t);
    if(buf_stride == 0) {
        buf_stride = 1;
    }
    
    count = buf_size / sizeof(uint64_t);
    app_buf = MALLOC(uint64_t, count * buf_stride * 2);

#if !defined(USE_OPI)
    send_buf = MALLOC(uint64_t, count);
    recv_buf = MALLOC(uint64_t, count);

    memset(send_buf, 0, count * sizeof(uint64_t));
    memset(recv_buf, 0, count * sizeof(uint64_t));
#endif
    memset(app_buf, 0, count * buf_stride * sizeof(uint64_t) * 2);

    //Really warm up the buffer
#if 0
    for(int i = 0; i < 10; i++) {
        for(int j = 0; j < count * buf_stride; j++) {
            app_buf[j] = j + i;
        }
    }
#endif

    if(rank == 0) {
        printf("%6d %3d %5d %9d ", bench_iters, comm_iters, buf_stride, buf_size);
    }

    //Do a priming run to reduce initial noise.
    for(int i = 0; i < 100; i++) {
        //Do some stuff with the app buffer.
        for(int j = 0; j < count * buf_stride * 2; j++) {
            app_buf[j] += 1 + i;
        }

        run_benchmark(comm_iters, buf_stride);
    }

    PROFILE_TIMER_RESET(pack);
    PROFILE_TIMER_RESET(comm);
    PROFILE_TIMER_RESET(unpack);

    for(int i = 0; i < bench_iters; i++) {

        //Do some stuff with the app buffer.
        PROFILE_START(app);
        for(int j = 0; j < count * buf_stride * 2; j++) {
            app_buf[j] += 1 + i;
        }
        PROFILE_STOP(app);

        MPI_Barrier(MPI_COMM_WORLD);
        run_benchmark(comm_iters, buf_stride);
    }

    //Profile times are in microseconds.
    profile_timer_results_t r_app;
    profile_timer_results_t r_pack;
    profile_timer_results_t r_comm;
    profile_timer_results_t r_unpack;

    PROFILE_TIMER_RESULTS(app, &r_app);
    PROFILE_TIMER_RESULTS(pack, &r_pack);
    PROFILE_TIMER_RESULTS(comm, &r_comm);
    PROFILE_TIMER_RESULTS(unpack, &r_unpack);

    if(rank == 0) {
        printf("%10.3f %10.3f %10.3f %10.3f",
                r_pack.avg, r_comm.avg, r_unpack.avg, r_app.avg);
#if _PROFILE_PAPI_EVENTS
        for(int i = 0; i < _profile_num_events; i++) {
            printf(" %12.3f", r_pack.avg_ctrs[i]);
        }
        for(int i = 0; i < _profile_num_events; i++) {
            printf(" %12.3f", r_comm.avg_ctrs[i]);
        }
        for(int i = 0; i < _profile_num_events; i++) {
            printf(" %12.3f", r_unpack.avg_ctrs[i]);
        }
        for(int i = 0; i < _profile_num_events; i++) {
            printf(" %12.3f", r_app.avg_ctrs[i]);
        }
#endif
        printf("\n");
    }

    free(app_buf);
#if !defined(USE_OPI)
    free(send_buf);
    free(recv_buf);
#endif
}


int main(int argc, char** argv)
{
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

#if 0
    cpu_set_t cpuset;
    CPU_ZERO(&cpuset);
    if(rank == 0) {
        CPU_SET(0, &cpuset);
    } else {
        CPU_SET(8, &cpuset);
    }
    int ret =
        pthread_setaffinity_np(pthread_self(), sizeof(cpuset), &cpuset);
    if(ret) {
        printf("%d ERROR in pthread_setaffinity_np: %s\n", rank, strerror(ret));
        MPI_Abort(MPI_COMM_WORLD, 0);
    }
#endif

    PROFILE_INIT();

    char s[255];
    gethostname(s, 253);
    printf("%d %s\n", rank, s);

    int bench_iters = 200;
    int comm_iters = 4;
    int buf_stride = sizeof(uint64_t);

    if(rank == 0) {
        char* tmp;

        if((tmp = getenv("BENCH_ITERS")) != NULL) {
            bench_iters = atoi(tmp);
        }
        if((tmp = getenv("COMM_ITERS")) != NULL) {
            comm_iters = atoi(tmp);
        }
        if((tmp = getenv("BUF_STRIDE")) != NULL) {
            buf_stride = atoi(tmp);
        }
        //if((tmp = getenv("MSG_SIZE")) != NULL) {
        //    app_size = atoi(tmp);
        //}

        printf("BENCH_ITERS=%d\n", bench_iters);
        printf("COMM_ITERS=%d\n", comm_iters);
        printf("BUF_STRIDE=%d\n", buf_stride);
        //printf("MSG_SIZE=%d\n", app_size);
    }

    MPI_Bcast(&bench_iters, 1, MPI_INT, 0, MPI_COMM_WORLD);
    MPI_Bcast(&comm_iters, 1, MPI_INT, 0, MPI_COMM_WORLD);
    MPI_Bcast(&buf_stride, 1, MPI_INT, 0, MPI_COMM_WORLD);
    //MPI_Bcast(&msg_size, 1, MPI_INT, 0, MPI_COMM_WORLD);



    if(rank == 0) {
        printf("# bench app stride buf_size      pack       comm     unpack        app");
#if _PROFILE_PAPI_EVENTS
        PAPI_event_info_t info;

        for(int i = 0; i < _profile_num_events; i++) {
            PAPI_get_event_info(_profile_event_codes[i], &info);
            printf(" pack_%s", info.symbol);
        }
        for(int i = 0; i < _profile_num_events; i++) {
            PAPI_get_event_info(_profile_event_codes[i], &info);
            printf(" comm_%s", info.symbol);
        }
        for(int i = 0; i < _profile_num_events; i++) {
            PAPI_get_event_info(_profile_event_codes[i], &info);
            printf(" unpack_%s", info.symbol);
        }
        for(int i = 0; i < _profile_num_events; i++) {
            PAPI_get_event_info(_profile_event_codes[i], &info);
            printf(" app_%s", info.symbol);
        }
#endif
        printf("\n");
    }

    //Vary the app buffer size.
    //for(int i = 8; i <= 32 * 1024 * 1024; i <<= 1) {
    for(int i = 8; i <= 4 * 1024 * 1024; i <<= 1) {
    //for(int i = 8; i <= 64; i <<= 1) {
    //for(int i = max(256, app_stride); i <= 32 * 1024; i <<= 1) {
        //do_benchmark(bench_iters, comm_iters, buf_stride, i - 8);
        do_benchmark(bench_iters, comm_iters, buf_stride, i);
        //do_benchmark(bench_iters, comm_iters, buf_stride, i + 8);
    }

    MPI_Finalize();
    return 0;
}


