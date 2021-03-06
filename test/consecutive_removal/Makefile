#/******************************************************************************
# Copyright (c) 2010-2011, Duane Merrill.  All rights reserved.
# Copyright (c) 2011-2013, NVIDIA CORPORATION.  All rights reserved.
#  
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the NVIDIA CORPORATION nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# ******************************************************************************/
 
#-------------------------------------------------------------------------------
# Build script for project
#-------------------------------------------------------------------------------

NVCC = "$(shell which nvcc)"
NVCC_VERSION = $(strip $(shell nvcc --version | grep release | sed 's/.*release //' |  sed 's/,.*//'))

KERNELS = 

# detect OS
OSUPPER = $(shell uname -s 2>/dev/null | tr [:lower:] [:upper:])

#-------------------------------------------------------------------------------
# Gen targets
#-------------------------------------------------------------------------------

GEN_SM20 = -gencode=arch=compute_20,code=\"sm_20,compute_20\" 
GEN_SM13 = -gencode=arch=compute_13,code=\"sm_13,compute_13\" 
GEN_SM10 = -gencode=arch=compute_10,code=\"sm_10,compute_10\" 
#SM_TARGETS = $(GEN_SM20) $(GEN_SM13) $(GEN_SM10)
SM_TARGETS = $(GEN_SM20) 

#-------------------------------------------------------------------------------
# Tune arch
#-------------------------------------------------------------------------------

ifdef tunearch
    TUNE_ARCH = $(tunearch)
else 
	TUNE_ARCH = 200
endif

ifeq ($(TUNE_ARCH), 200) 
	TUNE_SM_TARGETS = $(GEN_SM20)
endif
ifeq ($(TUNE_ARCH), 130) 
	TUNE_SM_TARGETS = $(GEN_SM13)
endif
ifeq ($(TUNE_ARCH), 100) 
	TUNE_SM_TARGETS = $(GEN_SM10)
endif

#-------------------------------------------------------------------------------
# Tune size
#-------------------------------------------------------------------------------

ifdef tunesize
    TUNE_SIZE = $(tunesize)
else 
	TUNE_SIZE = 4
endif


#-------------------------------------------------------------------------------
# Libs
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# Includes
#-------------------------------------------------------------------------------

THRUST_INC = "../../../Thrust"
CUDA_INC = "$(shell dirname $(NVCC))/../include"
INC = -I$(CUDA_INC) -I.. -I../.. 

#-------------------------------------------------------------------------------
# Defines
#-------------------------------------------------------------------------------

DEFINES = 

#-------------------------------------------------------------------------------
# Compiler Flags
#-------------------------------------------------------------------------------

ifneq ($(force64), 1)
	# Compile with 32-bit device pointers by default
	ARCH_SUFFIX = i386
	ARCH = -m32
else
	ARCH_SUFFIX = x86_64
	ARCH = -m64
endif

NVCCFLAGS = -Xptxas -v -Xcudafe -\#

ifeq (WIN_NT, $(findstring WIN_NT, $(OSUPPER)))
	NVCCFLAGS += -Xcompiler /bigobj -Xcompiler /Zm500
endif

ifeq (,$(findstring 3.0, $(NVCC_VERSION)))
ifneq ($(abi), 1)
	# Disable the ABI by default for 3.1+
	NVCCFLAGS += -Xptxas -abi=no
endif
endif

ifeq ($(verbose), 1)
    NVCCFLAGS += -v
endif

ifeq ($(keep), 1)
    NVCCFLAGS += -keep
endif

ifdef maxregisters
    NVCCFLAGS += -maxrregcount $(maxregisters)
endif

ifeq (4.1, $(findstring 4.1, $(NVCC_VERSION)))
	# Disable nvvm for 4.1 
	NVCCFLAGS += -open64
endif 

#-------------------------------------------------------------------------------
# Dependency Lists
#-------------------------------------------------------------------------------

DEPS = 			./Makefile \
				../b40c_test_util.h \
				$(wildcard ../../b40c/*.cuh) \
				$(wildcard ../../b40c/util/*.cuh) \
				$(wildcard ../../b40c/util/io/*.cuh) \
				$(wildcard ../../b40c/util/reduction/*.cuh) \
				$(wildcard ../../b40c/util/scan/*.cuh) \
				$(wildcard ../../b40c/consecutive_removal/*.cuh) \
				$(wildcard ../../b40c/reduction/*.cuh) \
				$(wildcard ../../b40c/scan/*.cuh) 
				 


#-------------------------------------------------------------------------------
# (make simple) Simple example driver for segmented scan
#-------------------------------------------------------------------------------

simple: bin/simple_consecutive_removal_$(NVCC_VERSION)_$(ARCH_SUFFIX)

bin/simple_consecutive_removal_$(NVCC_VERSION)_$(ARCH_SUFFIX) : simple_consecutive_removal.cu $(DEPS)
	mkdir -p bin
	$(NVCC) $(DEFINES) $(SM_TARGETS) -o bin/simple_consecutive_removal_$(NVCC_VERSION)_$(ARCH_SUFFIX) simple_consecutive_removal.cu $(NVCCFLAGS) $(ARCH) $(INC) -O3  



#-------------------------------------------------------------------------------
# (make test) Test driver 
#-------------------------------------------------------------------------------

test: bin/test_consecutive_removal_$(NVCC_VERSION)_$(ARCH_SUFFIX)

bin/test_consecutive_removal_$(NVCC_VERSION)_$(ARCH_SUFFIX) : test_consecutive_removal.cu $(DEPS) test_consecutive_removal.h
	mkdir -p bin
	$(NVCC) $(DEFINES) $(SM_TARGETS) -o bin/test_consecutive_removal_$(NVCC_VERSION)_$(ARCH_SUFFIX) test_consecutive_removal.cu $(NVCCFLAGS) $(ARCH) $(INC) -O3  

	
#-------------------------------------------------------------------------------
# (make tune) Evaluates the space of configuration types
#-------------------------------------------------------------------------------

tune: bin/tune_consecutive_removal_$(NVCC_VERSION)_$(ARCH_SUFFIX)_sm$(TUNE_ARCH)_u$(TUNE_SIZE)B

bin/tune_consecutive_removal_$(NVCC_VERSION)_$(ARCH_SUFFIX)_sm$(TUNE_ARCH)_u$(TUNE_SIZE)B : tune_consecutive_removal.cu $(DEPS)
	mkdir -p bin
	$(NVCC) $(DEFINES) $(TUNE_SM_TARGETS) -o bin/tune_consecutive_removal_$(NVCC_VERSION)_$(ARCH_SUFFIX)_sm$(TUNE_ARCH)_u$(TUNE_SIZE)B tune_consecutive_removal.cu $(NVCCFLAGS) $(ARCH) $(INC) -O3 -DTUNE_ARCH=$(TUNE_ARCH) -DTUNE_SIZE=$(TUNE_SIZE) 


#-------------------------------------------------------------------------------
# (make compare) Compares performance against other libraries (e.g., Thrust)
#-------------------------------------------------------------------------------

compare: bin/compare_consecutive_removal_$(NVCC_VERSION)_$(ARCH_SUFFIX)

bin/compare_consecutive_removal_$(NVCC_VERSION)_$(ARCH_SUFFIX) : compare_consecutive_removal.cu $(DEPS) test_consecutive_removal.h
	mkdir -p bin
	$(NVCC) $(DEFINES) $(SM_TARGETS) -o bin/compare_consecutive_removal_$(NVCC_VERSION)_$(ARCH_SUFFIX) compare_consecutive_removal.cu $(NVCCFLAGS) $(ARCH) $(INC) -I$(THRUST_INC) -O3  


#
# Clean
#

clean :
	rm -f bin/*_$(NVCC_VERSION)_$(ARCH_SUFFIX)* 
	rm -f *.i* *.cubin *.cu.c *.cudafe* *.fatbin.c *.ptx *.hash *.cu.cpp *.o




