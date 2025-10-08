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
        --runtest)
            DO_TEST=1
            shift
            ;;
        --exclude)
            EXCLUDE=1
            EXCLUDE_FILE="$2"
            shift 2
            ;;
        --update)
            UPDATE=1
            shift
            ;;
        *)
            shift
            ;;
    esac
done

CURRENT_DIR=$(pwd)

# Set defaults if not set
XFS_DIRNAME="${XFS_DIRNAME:-xfstests-dev}"
XFS_DESTDIR="${XFS_DESTDIR:-/var/lib/xfstests}"
FSTYPE="${FSTYPE:-xfs}"
DO_TEST="${DO_TEST:-0}"
EXCLUDE="${EXCLUDE:-0}"
UPDATE="${UPDATE:-0}"

if [ "$FSTYPE" != "xfs" ] && [ "$FSTYPE" != "ext4" ]; then
    echo "Invalid FSTYPE: $FSTYPE. Only 'xfs' and 'ext4' are supported."
    exit 1
fi

if [ ! -d $XFS_DIRNAME ]; then
    git clone https://git.kernel.org/pub/scm/fs/xfs/xfstests-dev $XFS_DIRNAME
    NEED_BUILD=1
else
    echo "$XFS_DIRNAME already exists"
    if [ "$UPDATE" = "1" ]; then
        echo "Updating $XFS_DIRNAME"
        cd $XFS_DIRNAME
        git pull
        cd ..
        NEED_BUILD=1
    fi
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
    if losetup -a | grep -vq $i.img; then
        eval ${j}_DEV=$(losetup -f --show $i.img)
    else
        eval ${j}_DEV=$(losetup -a | grep $i.img | awk -F: '{print $1}')
    fi
    if [ ! -d /mnt/$i ]; then
        mkdir /mnt/$i
    fi
    # eval ${j}_DEV="/dev/loop0"
done

if [ "$NEED_BUILD" = "1" ] || [ ! -d $XFS_DESTDIR ]; then
    cd $XFS_DIRNAME
    make -j && make install
else
    echo "$XFS_DESTDIR already exists. Skipping build."
fi

echo "
export TEST_DEV=$TEST_DEV
export TEST_DIR=/mnt/test
export SCRATCH_DEV=$SCRATCH_DEV
export SCRATCH_MNT=/mnt/scratch
" > $XFS_DESTDIR/local.config

for user in fsgqa 123456-fsgqa fsgqa2; do
    if ! id "$user" >/dev/null 2>&1; then
        useradd -M "$user"
    else
        echo "User $user already exists"
    fi
done

if ! getent group fsgqa >/dev/null 2>&1; then
    groupadd fsgqa
else
    echo "Group fsgqa already exists"
fi

if [ "$DO_TEST" = "1" ]; then
    cd $XFS_DESTDIR
    if [ "$EXCLUDE" = "1" ]; then
        EXCLUDE_FILE_PATH="$CURRENT_DIR/$EXCLUDE_FILE"
        if [ ! -f "$EXCLUDE_FILE_PATH" ]; then
            echo "$EXCLUDE_FILE_PATH not found."
            exit 1
        fi
        unbuffer ./check -E $EXCLUDE_FILE_PATH | tee /root/run-xfstests-$FSTYPE.log
    else
        unbuffer ./check | tee /root/run-xfstests-$FSTYPE.log
    fi
    exit 0
else
    echo "Skipping tests as DO_TEST is not set to 1."
fi
