#!/bin/bash
### BEGIN INFO
# Version 1.1.0
# Optimized script to create ZFS snapshots and remove older snapshots.
# The number of snapshots to retain is defined in the variable retention.
# Author: iceflatline <iceflatline@gmail.com>
# Modified for optimization on Linux
#
# OPTIONS:
# -v: Be verbose
### END INFO

### START OF SCRIPT
set -euo pipefail

# Configuration variables
snap_prefix="snap"          # What you want to snapshot name to start with. 
retention=90                # Amount of snapshots to keep before deleting.
src_0="pool_0/archive"      # Location of your pool. Most likely you will need to change this.
log="/home/$USER/cronlog"   # Location to store the log output

# Full paths to utilities
date=/bin/date
zfs=/sbin/zfs

# Generate snapshot names
today="${snap_prefix}-$($date +%Y%m%d%H%M)"
snap_today="${src_0}@${today}"

# Function to log messages
log_msg() {
    echo "$1" >> "$log"
}

# Function to log with timestamp
log_timestamp() {
    $date >> "$log"
}

# Create blank line and header
echo >> "$log"
log_msg "zfssnap.sh"
log_timestamp
echo >> "$log"

# Check if today's snapshot already exists
if $zfs list -H -o name -t snapshot "$snap_today" >/dev/null 2>&1; then
    log_msg "Today's snapshot '$snap_today' already exists."
    # Uncomment if you want the script to exit when it does not create today's snapshot:
    #exit 1
else
    log_msg "Taking today's snapshot: $snap_today"
    if $zfs snapshot -r "$snap_today" >> "$log" 2>&1; then
        log_msg "Successfully created snapshot: $snap_today"
    else
        log_msg "ERROR: Failed to create snapshot: $snap_today"
        log_msg "**********"
        exit 1
    fi
fi

echo >> "$log"

# Get all snapshots for the dataset, sorted by creation time (oldest first)
# Using native ZFS sorting with -s creation
all_snaps=$($zfs list -t snapshot -H -o name -s creation | \
    grep "^${src_0}@${snap_prefix}" || true)

if [ -z "$all_snaps" ]; then
    log_msg "No snapshots found matching pattern: ${src_0}@${snap_prefix}*"
    log_msg "**********"
    exit 0
fi

# Count total snapshots
snap_count=$(echo "$all_snaps" | wc -l)

log_msg "Found $snap_count snapshot(s) matching pattern."

# Determine if we need to delete old snapshots
if [ "$snap_count" -gt "$retention" ]; then
    # Calculate how many to delete
    to_delete=$((snap_count - retention))
    
    log_msg "Retention set to $retention, removing $to_delete old snapshot(s)..."
    
    # Get snapshots to delete (oldest ones)
    snap_old=$(echo "$all_snaps" | head -n "$to_delete")
    
    log_msg "Destroying the following old snapshots:"
    log_msg "$snap_old"
    
    # Destroy old snapshots
    # Using a while loop for better error handling per snapshot
    echo "$snap_old" | while IFS= read -r snap; do
        if $zfs destroy -r "$snap" >> "$log" 2>&1; then
            log_msg "Successfully destroyed: $snap"
        else
            log_msg "WARNING: Failed to destroy: $snap"
        fi
    done
else
    log_msg "Snapshot count ($snap_count) is within retention ($retention)."
    log_msg "No snapshots need to be destroyed."
fi

# Mark the end of the script with a delimiter
log_msg "**********"
# END OF SCRIPT
