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
        --kirkdir)
            KIRK_TOP_DIR="$2"
            shift 2
            ;;
        --rebuild)
            LTP_REBUILD=1
            shift
            ;;
        *)
            break
            ;;
    esac
done

DO_TEST=${DO_TEST:-0}
LTP_TOP_DIR=${LTP_TOP_DIR:-/root/ltp}
KIRK_TOP_DIR=${KIRK_TOP_DIR:-/root/kirk}
LTP_DESTDIR=${LTP_DESTDIR:-/}
LTP_REBUILD=${LTP_REBUILD:-0}

KIRK_MODE=1 # runltpを使って実行する場合には0にする

if [ ! -d "$LTP_TOP_DIR" ]; then
    git clone https://github.com/linux-test-project/ltp $LTP_TOP_DIR
    LTP_REBUILD=1
fi

if [ ! -d "$KIRK_TOP_DIR" ]; then
    git clone https://github.com/linux-test-project/kirk $KIRK_TOP_DIR
fi

cd $LTP_TOP_DIR

if [ "$LTP_REBUILD" = "1" ]; then
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
    if [ "$KIRK_MODE" = "1" ]; then
        cd $KIRK_TOP_DIR
        unbuffer ./kirk -f $(ls $LTP_DEST_DIR/opt/ltp/runtest) | tee /root/kirk.log
    else
        # runltpでテストする場合
        cd $LTP_DESTDIR/opt/ltp
        unbuffer ./runltp | tee /root/runltp.log
    fi
else
    echo "Skipping tests as DO_TEST is not set to 1."
fi