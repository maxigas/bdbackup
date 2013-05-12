#!/bin/bash

if [[ $# -ne 5 ]]; then
    echo "Usage: ${0##*/} VGLOCAL LVLOCAL VGREMOTE LVREMOTE TARGETMACHINE"
    exit
fi

echo '----'              
echo `date`              
echo "Started, args: $@" 
set -e
# DEBUG:
# Next line only works if the script is called directly...
# set -x
VGLOCAL="$1"
LVLOCAL="$2"
VGREMOTE="$3"
LVREMOTE="$4"
TARGETMACHINE="$5"
DIFF="$HOME/diff.bds.gz"

echo
echo Dropped privileges. Syncing block devices. This may take a while.
echo

# WORKS
#bdsync "ssh $TARGETMACHINE bdsync --server" /dev/$VGLOCAL/$LVLOCAL-snap /dev/$VGREMOTE/$LVREMOTE | gzip > "$DIFF"
# BROKEN experimental method, without saving to local disk:
/usr/local/bin/bdsync "ssh $TARGETMACHINE bdsync --server" /dev/$VGLOCAL/$LVLOCAL-snap /dev/$VGREMOTE/$LVREMOTE | gzip | ssh $TARGETMACHINE "cat > $DIFF"
#scp "$DIFF" "$TARGETMACHINE:."
#rm "$DIFF"
# TODO:
# 1. I don't get while I can't write this w/o using a variable.
#    - Maybe escape pipe?
# 2. I think bdsync exits with exit value 1 on success.
#    - Either I am wrong or have to fix bdsync source code...
CMDREMOTE="gzip -d -c $DIFF | bdsync --patch='/dev/$VGREMOTE/$LVREMOTE'"
set +e
/usr/bin/ssh "$TARGETMACHINE" "$CMDREMOTE"
set -e
/usr/bin/ssh "$TARGETMACHINE" rm "$DIFF"

echo `date`
echo 'Finished.'



