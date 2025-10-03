#!/bin/sh -ex

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dirname)
            XFS_DIRNAME="$2"
            shift 2
            ;;
        --destdir)
            XFS_DESTDIR="$2"
            shift 2
            ;;
        --fstype)
            FSTYPE="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Set defaults if not set
XFS_DIRNAME="${XFS_DIRNAME:-xfstests-dev}"
XFS_DESTDIR="${XFS_DESTDIR:-/var/lib/xfstests}"
FSTYPE="${FSTYPE:-xfs}"

if [ "$FSTYPE" != "xfs" ] && [ "$FSTYPE" != "ext4" ]; then
    echo "Invalid FSTYPE: $FSTYPE. Only 'xfs' and 'ext4' are supported."
    exit 1
fi

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
        dd if=/dev/zero of=$i.img bs=1G count=15
    else
        echo "$i.img already exists"
    fi

    if [ "$FSTYPE" = "xfs" ]; then
        mkfs.xfs -f $i.img
    elif [ "$FSTYPE" = "ext4" ]; then
        mkfs.ext4 -F $i.img
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

useradd -m fsgqa
useradd 123456-fsgqa
useradd fsgqa2
groupadd fsgqa