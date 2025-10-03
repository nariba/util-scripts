#!/bin/sh

while [ $# -gt 0 ]; do
    case "$1" in
        --runtest)
            DO_TEST=1
            shift
            ;;
        --dirname)
            LTP_TOP_DIR="$2"
            shift 2
            ;;
        --destdir)
            LTP_DESTDIR="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

DO_TEST=${DO_TEST:-0}
LTP_TOP_DIR=${LTP_TOP_DIR:-/root/ltp}
LTP_DESTDIR=${LTP_DESTDIR:-/}

if [ ! -d "$LTP_TOP_DIR" ]; then
    git clone https://github.com/linux-test-project/ltp $LTP_TOP_DIR
    cd $LTP_TOP_DIR

    make autotools
    mkdir -p build
    cd build
    ../configure
    make -f ../Makefile "top_srcdir=$LTP_TOP_DIR" "top_builddir=$LTP_TOP_DIR/build" -j$(nproc)
    make -f ../Makefile "top_srcdir=$LTP_TOP_DIR" "top_builddir=$LTP_TOP_DIR/build" -j$(nproc) \
        "DESTDIR=$LTP_DESTDIR" "SKIP_IDCHECK=0" install
else
    echo "$LTP_TOP_DIR already exists. Skipping clone and build."
fi


if [ "$DO_TEST" = "1" ]; then
    cd $LTP_DESTDIR/opt/ltp
    unbuffer ./runltp | tee /root/runltp.log
else
    echo "Skipping tests as DO_TEST is not set to 1."
fi