#!/bin/sh -ex

PYTHON_VERSION="3.10.15"

BUILD_DATE=$(date -u +%Y%m%d)
MPYKDUMP_TOPDIR=mpykdump-${BUILD_DATE}

mkdir -p ${MPYKDUMP_TOPDIR}
cd ${MPYKDUMP_TOPDIR}

# Download mpykdump to build Python using the files in mpykdump
git clone git://git.code.sf.net/p/pykdump/code mpykdump

# Build Python
wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
tar xvfz Python-${PYTHON_VERSION}.tgz
cd Python-${PYTHON_VERSION}

./configure \
    CFLAGS=-fPIC \
    --disable-shared \
	--prefix=/home/nariba/opt/python-${PYTHON_VERSION}

mv Modules/Setup.local Modules/Setup.local-org
cp ../mpykdump/Extension/Setup.local-3.10 Modules/Setup.local
make -j
make install

# Build crash
cd ../
git clone https://github.com/crash-utility/crash
cd crash
# Memory dump may be compressed
make -j4 lzo snappy zstd

# Build mpykdump
cd ../mpykdump/Extension
./configure -p ../../Python-${PYTHON_VERSION} -c ../../crash
make
