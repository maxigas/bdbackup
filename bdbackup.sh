#!/bin/bash

# ASSUMPTIONS / CHECKLIST
# TODO: do automatic sanity check based on this list.

# a. Both sides:

# 1. There is a bdsync:backup user.
# 2. udev rule so that *backup* and *snap* volumes are accessible:
# cat /etc/udev/rules.d/92-backup-snap-lvs.rules
# ACTION=="change", SUBSYSTEM=="block", ATTR{dm/name}=="$VGLOCAL-*snap", GROUP="backup"
# ACTION=="change", SUBSYSTEM=="block", ATTR{dm/name}=="$VGLOCAL-*backup", GROUP="backup"
# 3. Local and remote block devices already exist and they are the same size.

# b. On this side:

# 1. bdsync:backup user has passwordless ssh access to $TARGETMACHINE
# 2. This script plus bdbackup-lowpriv.sh is in $PATH and executable.

if [[ $# -ne 5 ]]; then
    echo "Usage: ${0##*/} VGLOCAL LVLOCAL VGREMOTE LVREMOTE TARGETMACHINE"
    exit
fi
set -e
# DEBUG:
# set -x
ARGS=$@
VGLOCAL=$1
LVLOCAL=$2
VGREMOTE=$3
LVREMOTE=$4
TARGETMACHINE=$5

echo
read -p "Sync local /dev/$VGLOCAL/$LVLOCAL with /dev/$VGREMOTE/$LVREMOTE on $TARGETMACHINE (via a snapshot)? (y/n) "
if [ ! $REPLY == "y" ]; then exit 1; fi

lvcreate --snapshot -L 1G -p r --name $LVLOCAL-snap /dev/$VGLOCAL/$LVLOCAL
su - bdsync -c "bdbackup-lowpriv.sh $ARGS"
lvremove -f /dev/$VGLOCAL/$LVLOCAL-snap
echo READY

