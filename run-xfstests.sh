#!/bin/sh -ex

XFS_DIRNAME=${1:-xfstests-dev}
echo $XFS_DIRNAME


if [ ! -d $XFS_DIRNAME ]; then
    git clone https://git.kernel.org/pub/scm/fs/xfs/xfstests-dev $XFS_DIRNAME
else
    echo "$XFS_DIRNAME already exists"
    cd $XFS_DIRNAME
    git pull
    cd ..
fi



for i in test scratch;
do
    if [ ! -f $i.img ]; then
        dd if=/dev/zero of=$i.img bs=1G count=10
        mkfs.xfs $i.img
    fi
    j=$(echo $i | tr a-z A-Z)
    if [ ! -z $(losetup -a | grep $i.img) ]; then
        eval ${j}_DEV=$(losetup -f --show $i.img)
    else
        eval ${j}_DEV=$(losetup -a | grep $i.img | awk -F: '{print $1}')
    fi
    if [ ! -d /mnt/$i ]; then
        mkdir /mnt/$i
    fi
    # eval ${j}_DEV="/dev/loop0"
done

cd $XFS_DIRNAME
make -j && make install
echo "
export TEST_DEV=$TEST_DEV
export TEST_DIR=/mnt/test
export SCRATCH_DEV=$SCRATCH_DEV
export SCRATCH_MNT=/mnt/scratch
" > /var/lib/xfstests/local.config

