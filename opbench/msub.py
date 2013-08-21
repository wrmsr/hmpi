#!/usr/bin/env python
#MSUB -l nodes=1
#MSUB -l walltime=2:00:00
#MSUB -l partition=cab
#MSUB -l gres=ignore
#MSUB -q pbatch
#MSUB -V

from clusterlib import *

os.environ['PROFILE_PAPI_EVENTS'] = "PAPI_L1_DCM PAPI_L2_DCM PAPI_L3_TCM"
os.environ['BENCH_ITERS'] = "5000"

#file = "results/%d-mpi.out" % JOBID


#for i in xrange(0, 3):
##for ctrs in papi_ctrs:
##  write_papi_ctrs(ctrs)
#  runcmd("make clean; make")
#  srun(1, 2, "./main |tee -a %s" % file)
#
#runcmd("python ../opbench-results-parse.py %s" % file)
#
#
#file = "results/%d-hmpi.out" % JOBID
#
#for i in xrange(0, 3):
##for ctrs in papi_ctrs:
##  write_papi_ctrs(ctrs)
#  runcmd("make clean; make hmpi")
#  srun(1, 1, "./main 2 %d %d |tee -a %s" % (ncores, nsockets, file))
#
#runcmd("python ../opbench-results-parse.py %s" % file)



runcmd("make clean; make")

mpisamefile = "results/%d-mpi-same.out" % JOBID

for i in xrange(0, 7):
  runcmd("srun -N 1 -n 2 --auto-affinity=cpt=1 ./main |tee -a %s" % (mpisamefile,))


mpicrossfile = "results/%d-mpi-cross.out" % JOBID

for i in xrange(0, 7):
  runcmd("srun -N 1 -n 2 ./main |tee -a %s" % (mpicrossfile,))



runcmd("make clean; make hmpi")

hmpisamefile = "results/%d-hmpi-same.out" % JOBID

for i in xrange(0, 7):
  runcmd("srun -N 1 -n 2 --auto-affinity=cpt=1 ./main |tee -a %s" % (hmpisamefile,))


hmpicrossfile = "results/%d-hmpi-cross.out" % JOBID

for i in xrange(0, 7):
  runcmd("srun -N 1 -n 2 ./main |tee -a %s" % (hmpicrossfile,))



runcmd("make clean; make opi")

opisamefile = "results/%d-opi-same.out" % JOBID

for i in xrange(0, 7):
  runcmd("srun -N 1 -n 2 --auto-affinity=cpt=1 ./main |tee -a %s" % (opisamefile,))


opicrossfile = "results/%d-opi-cross.out" % JOBID

for i in xrange(0, 7):
  runcmd("srun -N 1 -n 2 ./main |tee -a %s" % (opicrossfile,))

print "MPI same"
runcmd("python ../opbench-results-parse.py %s" % mpisamefile)
print "MPI cross"
runcmd("python ../opbench-results-parse.py %s" % mpicrossfile)
print "HMPI same"
runcmd("python ../opbench-results-parse.py %s" % hmpisamefile)
print "HMPI cross"
runcmd("python ../opbench-results-parse.py %s" % hmpicrossfile)
print "OPI same"
runcmd("python ../opbench-results-parse.py %s" % opisamefile)
print "OPI cross"
runcmd("python ../opbench-results-parse.py %s" % opicrossfile)


