Fork of zfssnap.sh but uses Linux's program locations rather than BSD's which is found in IceFlatLine's zfssnap script.

I know that **sanoid** exits but I feel like there needs to be some alternatives options and I believe this one is a good fit for simple replication.

## Process
1. Edit the zfssnap.sh file to match your pool and retention policy you want to keep.
2. Run as sudo or as a user with zfs replication privileges.
```bash
sudo ./zfsnap.sh
```
3. After completing it will create a log folder in the user's home directory telling you it has completed and if any snapshots where destroyed after reaching the threshold of retentions you setup in step 1.
