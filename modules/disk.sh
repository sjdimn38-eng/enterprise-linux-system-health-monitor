#!/usr/bin/env bash

###############################################################################
# Enterprise Linux System Health Monitor (ELSHM)
# Disk Monitoring Module
#
# Author  : Sajid Imran
# Version : 3.1
###############################################################################

###############################################################################
# Collect Disk Information
###############################################################################

collect_disk() {

    ############################
    # Root Filesystem Usage
    ############################

    ROOT_USAGE=$(
        df --output=pcent / 2>/dev/null |
        awk 'NR==2 { gsub("%",""); print $1 }'
    )

    [[ -z "$ROOT_USAGE" ]] && ROOT_USAGE=0

    DISK_USAGE="$ROOT_USAGE"

    ############################
    # Disk Table
    ############################

    DISK_TABLE=$(
        df -h \
            --exclude-type=tmpfs \
            --exclude-type=devtmpfs \
            --exclude-type=overlay \
            --output=source,target,size,used,avail,pcent \
            2>/dev/null
    )

    ############################
    # Filesystem Information
    ############################

    if command -v lsblk >/dev/null 2>&1; then
        FILESYSTEM_INFO=$(
            lsblk \
                -e7 \
                -o NAME,FSTYPE,SIZE,FSUSE%,MOUNTPOINTS \
                2>/dev/null
        )
    else
        FILESYSTEM_INFO="Not Available"
    fi

    ############################
    # Inode Utilization
    ############################

    INODE_INFO=$(
        df -ih \
            -x tmpfs \
            -x devtmpfs \
            -x overlay \
            2>/dev/null
    )

    ############################
    # Export Variables
    ############################

    export ROOT_USAGE
    export DISK_USAGE
    export DISK_TABLE
    export FILESYSTEM_INFO
    export INODE_INFO
}

###############################################################################
# Display Disk Information
###############################################################################

disk_info() {

    section "DISK & FILESYSTEM INFORMATION"

    printf "%-20s %-20s %-8s %-8s %-8s %-6s\n" \
        "Filesystem" "Mounted On" "Size" "Used" "Avail" "Use%"

    printf "%-20s %-20s %-8s %-8s %-8s %-6s\n" \
        "----------" "----------" "----" "----" "-----" "----"

    echo "$DISK_TABLE" | tail -n +2 | while read -r FS MP SIZE USED AVAIL PERCENT
    do
        printf "%-20s %-20s %-8s %-8s %-8s %-6s\n" \
            "$FS" "$MP" "$SIZE" "$USED" "$AVAIL" "$PERCENT"
    done

    echo

    printf "%-30s : " "Disk Usage"
    progress_bar "$DISK_USAGE"
    echo

    printf "%-30s : " "Status"
    health_status "$DISK_USAGE" "$DISK_WARNING" "$DISK_CRITICAL"
    echo

    ###########################################################################
    # Filesystem Information
    ###########################################################################

    draw_line
    echo "Filesystem Information"
    draw_line

    echo "$FILESYSTEM_INFO"

    echo

    ###########################################################################
    # Inode Utilization
    ###########################################################################

    draw_line
    echo "Inode Utilization"
    draw_line

    echo "$INODE_INFO"

    echo
}
