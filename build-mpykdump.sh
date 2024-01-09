#!/bin/sh -xe

# This script is used to build mpykdump for the current kernel.

PYTHON_VERSION=${1:-3.8.18}
CURRENT_DIR=$(pwd)

# コマンドが存在するかどうかを確認する
for command in wget git tar; do
    if ! type $command > /dev/null 2>&1; then
        echo "$command command not found."
        exit 1
    fi
done

PYTHON_DIRNAME=Python-$PYTHON_VERSION
PYTHON_TARBALL=$PYTHON_DIRNAME.tgz

wget https://www.python.org/ftp/python/$PYTHON_VERSION/$PYTHON_TARBALL
git clone https://github.com/crash-utility/crash
git clone https://git.code.sf.net/p/pykdump/code mpykdump

tar xvf $PYTHON_TARBALL
cd $PYTHON_DIRNAME

# Build Python
./configure \
    CFLAGS=-fPIC \
    --disable-shared \
    --prefix=$HOME/opt/$PYTHON_DIRNAME
cp ../mpykdump/Extension/Setup.local-3.8 Modules/Setup.local
make -j2
# make test
cd $CURRENT_DIR

# Build crash
cd crash
make -j2 -k lzo
cd $CURRENT_DIR

# Build mpykdump
cd mpykdump/Extension
./configure \
    -p $CURRENT_DIR/$PYTHON_DIRNAME \
    -c $CURRENT_DIR/crash
make