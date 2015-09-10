To compare the performance of MPI, HMPI, and OPI, we wrote a simple microbenchmark that emulates a nearest neighbor stencil written using a pack-communicate-unpack design pattern.  OPBench performs the following steps:

1. Computation time is simulated and measured by performing a simple calculation on each of the elements of an array.

2. A pack loop copies the data from the ‘application’ data structure to a communication buffer.

3. The communication buffers are exchanged between two ranks.

4. An unpack loop copies the data from the received communica- tion buffer back to the application data structure.

For each iteration of the benchmark we perform step 1 once, then repeat steps 2-4 four times to simulate multiple neighbors. We ran our benchmark in two configurations on the Cab system: (i) ranks are located on different cores within the same processor and (ii) ranks are located on different processors. Each data point in the results is an average of 5,000 benchmark iterations, with timings acquired from both ranks.

Our paper, [Ownership Passing: Efficient Distributed Memory Programming on Multi-core Systems](http://htor.inf.ethz.ch/publications/index.php?pub=161), describes OPBench and has experimental results.

The code for OPBench is available in the HMPI project here:

https://code.google.com/p/hmpi/source/browse/#svn%2Fopbench


Compile OPBench for the mode you want to run (MPI, HMPI, OPI):

```
make mpi
```

```
make hmpi
```

```
make opi
```

OPBench assumes two ranks, for example it can be run like this:

```
srun -N 1 -n 2 ./main
```

A number of environment variables can be used to configure the benchmark:

**`BENCH_ITERS`** Number of benchmark iterations to run per message size, default 200.

**`COMM_ITERS`** Number of communication (neighbor stencil exchanges) per benchmark iteration, default 4.

**`BUF_STRIDE`** Stride in which to access the application buffers, default 8 bytes (sizeof(uint64\_t)).

The code is wired to run message sizes from 8 bytes to 4 megabytes.

The output from an HMPI run looks like the following:

```
BENCH_ITERS=200
COMM_ITERS=4
BUF_STRIDE=8
# bench app stride buf_size      pack       comm     unpack        app
   200   4     1         8      0.001      1.183      0.008      0.006
   200   4     1        16      0.001      1.173      0.001      0.005
   200   4     1        32      0.002      1.295      0.002      0.006
   200   4     1        64      0.004      1.260      0.004      0.007
   200   4     1       128      0.007      1.384      0.009      0.008
   200   4     1       256      0.014      1.407      0.018      0.012
   200   4     1       512      0.039      1.326      0.066      0.018
   200   4     1      1024      0.207      1.570      0.146      0.028
   200   4     1      2048      0.310      1.866      0.251      0.044
   200   4     1      4096      0.669      2.221      0.464      0.077
   200   4     1      8192      1.248      4.557      0.992      0.135
   200   4     1     16384      2.476      6.540      1.947      0.235
   200   4     1     32768      5.073      8.878      3.757      0.427
   200   4     1     65536     10.940     15.466      6.984      0.818
   200   4     1    131072     22.603     28.915     13.593      1.622
   200   4     1    262144     44.727     55.986     27.281      3.305
   200   4     1    524288     89.419    110.364     54.853      6.657
   200   4     1   1048576    175.133    219.351    113.820     13.020
   200   4     1   2097152    345.395    418.401    228.882     25.216
   200   4     1   4194304    673.720    798.686    470.269     51.019
```

To compare, the output from an OPI run looks like this:

```
BENCH_ITERS=200
COMM_ITERS=4
BUF_STRIDE=8
# bench app stride buf_size      pack       comm     unpack        app
1 cab22
   200   4     1         8      0.053      1.201      0.110      0.038
   200   4     1        16      0.050      1.200      0.113      0.038
   200   4     1        32      0.056      1.180      0.112      0.039
   200   4     1        64      0.054      1.179      0.118      0.038
   200   4     1       128      0.057      1.201      0.121      0.040
   200   4     1       256      0.075      1.230      0.159      0.043
   200   4     1       512      0.094      1.206      0.232      0.048
   200   4     1      1024      0.135      1.233      0.288      0.057
   200   4     1      2048      0.216      1.163      0.466      0.074
   200   4     1      4096      0.371      1.167      0.738      0.102
   200   4     1      8192      0.687      1.177      1.447      0.154
   200   4     1     16384      1.327      1.236      3.037      0.251
   200   4     1     32768      2.570      1.234      6.422      0.431
   200   4     1     65536      5.068      1.239     13.156      0.800
   200   4     1    131072     10.552      1.216     26.347      1.569
   200   4     1    262144     23.280      1.224     51.214      3.247
   200   4     1    524288     46.497      1.221    101.725      6.561
   200   4     1   1048576     93.164      1.225    203.080     12.903
   200   4     1   2097152    187.323      1.208    404.563     25.054
   200   4     1   4194304    374.805      1.190    807.090     48.723
```

The first four column are benchmark parameters: benchmark iterations, neighbor exchanges, stride, and message size.  The pack column is time, in microseconds, to pack the communication buffer.  Likewise for unpack.  Comm is the nearest neighbor stencil communication time, while the app column represents the time taken by the simulated computation loop.

In the examples above, we see the communication time steadily increasing as a function of message size.  For ownership passing, communication time increases much more slowly, nearly constant.  However the pack time is much higher for OPI, as that is when the actual data transfer -- the processor is moving data from one core's cache to another.  This basic observation is why OPBench was developed -- existing, well-known benchmarks like NetPIPE don't separate out pack, communication, and unpack time.