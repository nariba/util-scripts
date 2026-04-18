#!/bin/sh

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dirname-xfs)
            XFS_DIRNAME="$2"
            shift 2
            ;;
        --destdir-xfs)
            XFS_DESTDIR="$2"
            shift 2
            ;;
        --dirname-ltp)
            LTP_DIRNAME="$2"
            shift 2
            ;;
        --destdir-ltp)
            LTP_DESTDIR="$2"
            shift 2
            ;;
        --fstype)
            FSTYPE="$2"
            shift 2
            ;;
        --exclude-xfs)
            EXCLUDE_FILE_XFS="$2"
            shift 2
            ;;
        --exclude-ext4)
            EXCLUDE_FILE_EXT4="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

dirname=$(hostname)-$(date +%Y%m%d)

mkdir -p /root/$dirname

cd /root/xfstests-dev
git log -1 > /root/$dirname/xfstests-gitlog.txt
cd /root

for fs in xfs ext4; do
    echo "Running xfstests for filesystem: $fs"
    if [ "$fs" = "xfs" ] && [ -n "$EXCLUDE_FILE_XFS" ]; then
        echo "Exclusion file for $fs found. Using it."
        /root/util-scripts/run-xfstests.sh --fstype $fs --runtest --exclude $EXCLUDE_FILE_XFS
        cp $EXCLUDE_FILE_XFS /root/$dirname/
    elif [ "$fs" = "ext4" ] && [ -n "$EXCLUDE_FILE_EXT4" ]; then
        echo "Exclusion file for $fs found. Using it."
        /root/util-scripts/run-xfstests.sh --fstype $fs --runtest --exclude $EXCLUDE_FILE_EXT4
        cp $EXCLUDE_FILE_EXT4 /root/$dirname/
    else
        echo "No exclusion file for $fs found. Running all tests."
        /root/util-scripts/run-xfstests.sh --fstype $fs --runtest
    fi
    mv /var/lib/xfstests/results /root/$dirname/xfstests-$fs-results
    mv /root/run-xfstests-$fs.log /root/$dirname/
done

KIRK_MODE=0
if [ -d "/root/kirk" ]; then
    echo "Kirk directory found. Running Kirk tests."
    KIRK_MODE=1
else
    echo "Kirk directory not found. Skipping Kirk tests."
fi

cd /root/ltp
git log -1 > /root/$dirname/ltp-gitlog.txt
cd /root

if [ "$KIRK_MODE" -eq 1 ]; then
    cd /root/kirk
    git log -1 > /root/$dirname/kirk-gitlog.txt
    cd /root
fi


echo "Running LTP tests..."
/root/util-scripts/run-ltp.sh --runtest

if [ "$KIRK_MODE" -eq 0 ]; then
    mv /opt/ltp/results /root/$dirname/ltp-results
    mv /opt/ltp/output /root/$dirname/ltp-output
    mv /root/runltp.log /root/$dirname/
else
    mv /root/kirk.log /root/$dirname/
fi


echo "Generating sosreport..."
sos report --batch
mv /var/tmp/sosreport-* /root/$dirname/