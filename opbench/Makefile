#Copyright (c) 2010-2013 The Trustees of Indiana University.
#All rights reserved.
#
#Redistribution and use in source and binary forms, with or without
#modification, are permitted provided that the following conditions are met:
#
#- Redistributions of source code must retain the above copyright notice, this
#  list of conditions and the following disclaimer.
#
#- Redistributions in binary form must reproduce the above copyright notice,
#  this list of conditions and the following disclaimer in the documentation
#  and/or other materials provided with the distribution.
#
#- Neither the Indiana University nor the names of its contributors may be used
#  to endorse or promote products derived from this software without specific
#  prior written permission.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
#ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
#ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

CC=mpicc -std=gnu99 -pthread -D_GNU_SOURCE
#CC=mpixlc

WARN=-Wall -Wuninitialized #-Wno-unused-function
#CFLAGS=$(WARN) -O3 -mcpu=power7 -fomit-frame-pointer
#CFLAGS=$(WARN) -O3 -march=native -fomit-frame-pointer
CFLAGS=$(WARN) -O3 -g
HMPI=/g/g19/friedley/svn//hmpi
PAPI=/usr/local/tools/papi

LIBS=-L$(HMPI) -lrt -L$(PAPI)/lib -lpapi
INCS=-I. -I$(HMPI) -I$(PAPI)/include -D_PROFILE=1 
#INCS+=-D_PROFILE_PAPI_EVENTS=1
SRCS=main.c #mpiprof.c
OPISRCS=$(SRCS)
MAIN=main
HDRS=

all: mpi

mpi: INCS += -D_PROFILE_MPI=1
mpi: $(SRCS:%.c=%.o)
	$(CC) $(CFLAGS) $(LDFLAGS) -o main $(SRCS:%.c=%.o) $(LIBS)

hmpi: INCS += -D_PROFILE_MPI=1
hmpi: CFLAGS += -DUSE_HMPI
hmpi: $(SRCS:%.c=%.o)
	$(CC) $(CFLAGS) $(LDFLAGS) -o main $(SRCS:%.c=%.o) $(LIBS) -lhmpi

opi: INCS += -D_PROFILE_MPI=1
opi: CFLAGS += -DENABLE_OPI -DUSE_HMPI -DUSE_OPI
opi: $(OPISRCS:%.c=%.o)
	$(CC) $(CFLAGS) $(LDFLAGS) -o main $(OPISRCS:%.c=%.o) $(LIBS) -lhmpi

fuse: INCS += -D_PROFILE_MPI=1
fuse: CFLAGS += -DENABLE_OPI -DUSE_HMPI -DUSE_FUSION 
fuse: $(OPISRCS:%.c=%.o)
	$(CC) $(CFLAGS) $(LDFLAGS) -o main $(OPISRCS:%.c=%.o) $(LIBS) -lhmpi

.c.o: $(HDRS)
	$(CC) $(INCS) $(CFLAGS) $(CPPFLAGS) -c $<

clean:
	rm -f *.o $(MAIN)

