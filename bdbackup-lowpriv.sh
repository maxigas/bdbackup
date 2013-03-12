#!/bin/bash

if [[ $# -ne 5 ]]; then
    echo "Usage: ${0##*/} VGLOCAL LVLOCAL VGREMOTE LVREMOTE TARGETMACHINE"
    exit
fi

echo '----'              1>&2
echo `date`              1>&2
echo "Started, args: $@" 1>&2
set -e
# DEBUG:
set -x
TARGETMACHINE="$1"
LVLOCAL="$2"
VGLOCAL="$3"
LVREMOTE="$4"
VGREMOTE="$5"
DIFF="$HOME/diff.bds.gz"

echo
echo Dropped privileges. Syncing block devices. This may take a while.
echo

bdsync "ssh $TARGETMACHINE bdsync --server" /dev/$VGLOCAL/$LVLOCAL-snap /dev/$VGREMOTE/$LVREMOTE | gzip > "$DIFF"
scp "$DIFF" "$TARGETMACHINE:."
rm "$DIFF"
# TODO:
# 1. I don't get while I can't write this w/o using a variable.
#    - Maybe escape pipe?
# 2. I think bdsync exits with exit value 1 on success.
#    - Either I am wrong or have to fix bdsync source code...
CMDREMOTE="gzip -d -c $DIFF | bdsync --patch='/dev/$VGREMOTE/$LVREMOTE'"
set +e
ssh "$TARGETMACHINE" "$CMDREMOTE"
set -e
ssh "$TARGETMACHINE" rm "$DIFF"

echo `date`      1>&2
echo 'Finished.' 1>&2


