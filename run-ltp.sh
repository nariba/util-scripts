#!/bin/sh

LTP_TOP_DIR=${1:-/root/ltp}
LTP_DESTDIR=${2:-/}

git clone https://github.com/linux-test-project/ltp $LTP_TOP_DIR
cd $LTP_TOP_DIR

make autotools
mkdir -p build
cd build
../configure
make -f ../Makefile "top_srcdir=$LTP_TOP_DIR" "top_builddir=$LTP_TOP_DIR/build" -j$(nproc)
make -f ../Makefile "top_srcdir=$LTP_TOP_DIR" "top_builddir=$LTP_TOP_DIR/build" -j$(nproc) \
    "DESTDIR=$LTP_DESTDIR" "SKIP_IDCHECK=0" install