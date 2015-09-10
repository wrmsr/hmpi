# Introduction #

HMPI includes a header file (profile.h) to simplify performance measurement.  It supports high-resolution timing with reduction of results across MPI ranks.  PAPI (both preset and native) counters are supported in an easy to use interface.


# Details #

Using the API is best described in an example:

```
#include "profile.h" //Located in HMPI directory

//Should be declared in one source file only. General profiling state.
PROFILE_DECLARE(); 

//Declare profile variables; timing information is stored in here.
//The variable names get prefixed with special stuff so you don't
// have to worry about colliding with existing app variables.
PROFILE_TIMER(app);
PROFILE_TIMER(comm);

//Use a profile var declared in another file:
PROFILE_TIMER_EXTERN(comm);


int main(int argc, char** argv)
{
	MPI_Init(&argc, &argv);

	PROFILE_INIT();
	PROFILE_START(app);

	//Do cool app stuff

	//It should be OK to have multiple profile vars started.
	PROFILE_START(comm);
	//Do crazy communication stuff
	PROFILE_STOP(comm);

	//More cool app stuff

	PROFILE_STOP(app);

	PROFILE_TIMER_SHOW(app);
	PROFILE_TIMER_SHOW(comm);
	MPI_Finalize();
	return 0;
}
```

That's the basic code for timing.  PROFILE\_TIMER\_SHOW prints out timing info, you can get the numbers back in a struct using PROFILE\_TIMER\_RESULTS(), look at profile.h for more details.  Both of these make MPI calls to gather info from all the ranks, so they need to go before MPI\_Finalize. PROFILE\_TIMER\_SHOW prints units of milliseconds, PROFILE\_TIMER\_RESULTS returns values in microseconds.  Total time is summed across time spent in the timing region on all ranks.  Average is thes total divided by how many times the timing region was executed (the count).

Nesting of profile timers is supported, i.e., more than one timer can be started/running at a time.

During initialization, the profiling code will run a calibration loop to measure the overhead of a PROFILE\_START/PROFILE\_STOP sequence.  The computed overhead is subtracted from each measured time region to eliminate the profiling overhead.  However, if timers are used in a nested fashion, the outermost timer will include the profiling overhead time for any profiling start/stop calls within its timing region.

There's also a PROFILE\_COUNTER type you can use to count/measure arbitrary things besides just time.  For example I added this to count how many times eager/synergistic protocol is used, and/or average message size, etc.

Just adding the above profiling code won't cause anything to happen, some defines are needed to turn profiling on.  The rationale is that the profiling code can be left in place, and easily enabled/disabled either in the code, on the command line, in a Makefile, etc.  In compiler command line option form:

```
-D_PROFILE=1
```

## Using PAPI Counters ##

To enable the use of PAPI counters:


1. Add flags to the compile and linker command lines.  Macros are necessary to enable the profiling-specfic code, then more flags to bring in the PAPI includes and library:

```
export PAPI=/usr/local/tools/papi

mpicc -D_PROFILE=1 -D_PROFILE_PAPI_EVENTS=1 -I$(PAPI)/include -c foo.c
mpicc -L$(HMPI)/lib -lpapi foo.o -o foo
```

2. The profile code expects an environment variable PROFILE\_PAPI\_EVENTS to be set.  It should be a space separated list of PAPI counter names as shown by the papi\_avail, papi\_native\_avail, and papi\_event\_chooser programs.  You'll get an error if you run without the environment variable set.  For example:

```
export PROFILE_PAPI_EVENTS="PAPI_L1_TCM PAPI_L2_TCM"

PROFILE_PAPI_EVENTS="PAPI_L1_TCM PAPI_L2_TCM" srun -N 1 -n 2 ./NPhmpi
```

For each profile timer variable declared, separate counts of the requested PAPI events will be maintained.  When printing profiling information using PROFILE\_TIMER\_SHOW, an additional line will be printed for each event.  For example:

```
TIME             app cnt 4096    time 166048071.376866 ms total  40539.079926 ms avg
PAPI          PAPI_L1_DCM 1656120674540 total  404326336.558 avg
PAPI          PAPI_L1_ICM 16691788971 total    4075143.792 avg
PAPI          PAPI_L1_LDM 1267979023371 total  309565191.253 avg
PAPI          PAPI_L1_STM 404833440140 total   98836289.097 avg
TIME       comm_pack cnt 119808000 time 1970690.272356 ms total      0.016449 ms avg
PAPI          PAPI_L1_DCM 127710384319 total       1065.959 avg
PAPI          PAPI_L1_ICM  726181455 total          6.061 avg
PAPI          PAPI_L1_LDM 32928441475 total        274.843 avg
PAPI          PAPI_L1_STM 95508124299 total        797.177 avg
```