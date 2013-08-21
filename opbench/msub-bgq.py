#!/usr/bin/env python
#MSUB -l nodes=1
#MSUB -l walltime=2:00:00
#MSUB -l partition=vulcan
#MSUB -l gres=ignore
#MSUB -q pdebug
#MSUB -V

from clusterlib import *

#os.environ['PROFILE_PAPI_EVENTS'] = "PAPI_L1_DCM PAPI_L1_ICM PAPI_L1_DCR PAPI_L1_DCW PAPI_L1_LDM PAPI_L1_STM"
#os.environ['PROFILE_PAPI_EVENTS'] = "PAPI_L1_DCM PAPI_L1_ICM PEVT_L1P_BAS_HIT PEVT_L1P_BAS_PF2DFC"
os.environ['PROFILE_PAPI_EVENTS'] = "PAPI_L1_DCM PAPI_L1_ICM"
#os.environ['PROFILE_PAPI_EVENTS'] = "L2Unit:::PEVT_L2_MISSES"
os.environ['BENCH_ITERS'] = "5000"

NUM_RUNS = 7

mpifile = "results/%d-mpi.out" % JOBID

runcmd("make -f Makefile.bgq clean; make -f Makefile.bgq")

for i in xrange(0, NUM_RUNS):
  #srun(1, 2, "./main-bgq |tee -a %s" % (file,))
  runcmd("srun -N 1 -n 2 ./main-bgq |tee -a %s" % (mpifile,))



hmpifile = "results/%d-hmpi.out" % JOBID

runcmd("make -f Makefile.bgq clean; make -f Makefile.bgq hmpi")

for i in xrange(0, NUM_RUNS):
  runcmd("srun -N 1 -n 2 ./main-bgq |tee -a %s" % (hmpifile,))



opifile = "results/%d-opi.out" % JOBID

runcmd("make -f Makefile.bgq clean; make -f Makefile.bgq opi")

for i in xrange(0, NUM_RUNS):
  runcmd("srun -N 1 -n 2 ./main-bgq |tee -a %s" % (opifile,))

print "MPI"
runcmd("python ../opbench-results-parse.py %s" % mpifile)
print "HMPI"
runcmd("python ../opbench-results-parse.py %s" % hmpifile)
print "OPI"
runcmd("python ../opbench-results-parse.py %s" % opifile)

