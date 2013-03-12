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

USAGE="Usage: ${0##*/} TARGETMACHINE LVLOCAL VGLOCAL LVREMOTE VGREMOTE"

set -e
# DEBUG:
#set -x
ARGS="$@"

if [ -z "$1" -o -z "$2" ]; then
    echo $USAGE; exit 1
else
    TARGETMACHINE="$1"
    LVLOCAL="$2"
fi

if [ -z "$3" ]; then
    VGLOCAL="vg_$(hostname)0"
else
    VGLOCAL="$3"
fi

if [ -z "$4" ]; then
    LVREMOTE="$LVLOCAL-backup"
else
    LVREMOTE="$4"
fi

if [ -z "$5" ]; then
    VGREMOTE=$(echo $TARGETMACHINE | cut -d '.' -f1)
else
    VGREMOTE="$5"
fi

if [ -n "$6" ]; then
    echo $USAGE; exit 2
fi

echo
read -p "Sync local /dev/$VGLOCAL/$LVLOCAL with /dev/$VGREMOTE/$LVREMOTE on $TARGETMACHINE (via a snapshot)? (y/n) "
if [ ! $REPLY == "y" ]; then
    exit 1
fi

lvcreate --snapshot -L 1G -p r --name "$LVLOCAL-snap" "/dev/$VGLOCAL/$LVLOCAL"
su - bdsync -c "bdbackup-lowpriv.sh $ARGS" 2> /var/log/bdsync.log
lvremove -f "/dev/$VGLOCAL/$LVLOCAL-snap"
echo READY

