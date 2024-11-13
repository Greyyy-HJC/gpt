#!/bin/bash
#
# Get compilers
#
module load cmake
module load openmpi/4.1.5_gcc_12.3.0
module load lapack
module load gcc/12.3.0
module load fftw/3.3.10_gcc_12.3.0
module load cuda/12.2.1

export OMPI_MCA_btl=^uct,openib
export UCX_MEMTYPE_CACHE=n
export UCX_RNDV_SCHEME=put_zcopy

pip3 install numpy --user

#
# Get root directory
#
root="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." >/dev/null 2>&1 && pwd )"

#
# Precompile python
#
echo "Compile gpt"
python3 -m compileall ${root}/lib/gpt

#
# Create dependencies and download
#
dep=${root}/dependencies
if [ ! -f ${dep}/Grid/build/Grid/libGrid.a ];
then

        if [ -d ${dep} ];
        then
            echo "$dep already exists ; rm -rf $dep before bootstrapping again"
            exit 1
        fi

        mkdir -p ${dep}
        cd ${dep}

        #
        # Lime
        #
        wget https://github.com/usqcd-software/c-lime/tarball/master
        tar xzf master
        mv usqcd-software-c-lime* lime
        rm -f master
        cd lime
        ./autogen.sh
        CC=gcc ./configure
        make -j 16
        cd ..

        #
        # Grid
        #
        git clone https://github.com/lehner/Grid.git
        cd Grid
        git checkout feature/gpt
        ./bootstrap.sh
        mkdir build
        cd build
	../configure \
                --enable-unified=no \
                --enable-accelerator=cuda \
                --enable-alloc-align=4k \
                --enable-accelerator-cshift \
                --enable-shm=nvlink \
                --enable-comms=none \
                --disable-comms-threads \
                --enable-simd=GPU \
                --with-fftw=/usr/include \
                CXX=nvcc \
                CXXFLAGS="-ccbin g++ -gencode arch=compute_80,code=sm_80 -std=c++17 --cudart shared --compiler-options=-fPIC -lcublas" \
                LIBS="-lrt" \
                LDFLAGS="--cudart shared --compiler-options -fopenmp -lcublas"

        cd Grid
        make -j
fi

if [ ! -f ${root}/lib/cgpt/build/cgpt.so ];
then
        #
        # cgpt
        #
        cd ${root}/lib/cgpt
        ./make ${root}/dependencies/Grid/build 16
fi


echo "To use:"
echo "source ${root}/lib/cgpt/build/source.sh"
