bdbackup
========

Use bdsync to keep incremental backups of (encrypted) block devices. Incremental in the sense of rsync (i.e. transferring only the changes) and not in the sense of rdiff-backup (i.e. storing old versions of data). At the moment bdbackup makes too many assumptions about its environment.