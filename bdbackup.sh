#!/bin/bash

# ASSUMPTIONS / CHECKLIST
# TODO: do automatic sanity check based on this list.

# a. Both sides:

# 0. bdsync installed from http://bdsync.rolf-fokkens.nl/
# 1. There is a bdsync:bdsync user.
# 2. udev rule so that *backup* and *snap* volumes are accessible:
# cat /etc/udev/rules.d/92-backup-snap-lvs.rules
# ACTION=="change", SUBSYSTEM=="block", ATTR{dm/name}=="$VGLOCAL-*snap", GROUP="bdsync"
# ACTION=="change", SUBSYSTEM=="block", ATTR{dm/name}=="$VGLOCAL-*backup", GROUP="bdsync"
# 3. Local and remote block devices already exist and they are the same size.

# b. On this side:

# 1. bdsync:backup user has passwordless ssh access to $TARGETMACHINE
# 2. This script plus bdbackup-lowpriv.sh is in $PATH and executable.

# FEATURE REQUEST: freshness tests! :)

USAGE="Usage: ${0##*/} TARGETMACHINE LVLOCAL [VGLOCAL LVREMOTE VGREMOTE]"

set -e
# DEBUG:
# set -x
ARGS="$@"

if [ -z "$1" -o -z "$2" ]; then
    echo $USAGE; exit 1
else
    TARGETMACHINE="$1"
    LVLOCAL="$2"
fi

VGLOCAL=${3:-vg_$(hostname)0}

LVREMOTE=${4:-$LVLOCAL-backup}

VGREMOTE=${5:-vg_$(echo $TARGETMACHINE | cut -d '.' -f1)0}

if [ -n "$6" ]; then
    echo $USAGE; exit 2
fi

echo
 read -p "Sync local /dev/$VGLOCAL/$LVLOCAL with /dev/$VGREMOTE/$LVREMOTE on $TARGETMACHINE (via a snapshot)? [y/n] "
 if [ ! $REPLY == "y" ]; then
     exit 1
 fi

/sbin/lvcreate --snapshot -L 1G -p r --name "$LVLOCAL-snap" "/dev/$VGLOCAL/$LVLOCAL"
/bin/su - bdsync -c "bdbackup-lowpriv.sh $VGLOCAL $LVLOCAL $VGREMOTE $LVREMOTE $TARGETMACHINE"
/sbin/lvremove -f "/dev/$VGLOCAL/$LVLOCAL-snap"
echo READY

