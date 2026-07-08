#!/usr/bin/env bash

###############################################################################
# Enterprise Linux System Health Monitor (ELSHM)
# Memory Monitoring Module
###############################################################################

###############################################################################
# Collect Memory Information
###############################################################################

collect_memory() {

    ############################
    # Read Memory Information
    ############################

    read TOTAL_MEMORY USED_MEMORY FREE_MEMORY SHARED_MEMORY CACHE_MEMORY AVAILABLE_MEMORY <<< "$(
        free -h 2>/dev/null |
        awk '/^Mem:/ {
            print $2, $3, $4, $5, $6, $7
        }'
    )"

    ############################
    # Fallback Values
    ############################

    [[ -z "$TOTAL_MEMORY" ]] && TOTAL_MEMORY="Unknown"
    [[ -z "$USED_MEMORY" ]] && USED_MEMORY="Unknown"
    [[ -z "$FREE_MEMORY" ]] && FREE_MEMORY="Unknown"
    [[ -z "$CACHE_MEMORY" ]] && CACHE_MEMORY="Unknown"
    [[ -z "$AVAILABLE_MEMORY" ]] && AVAILABLE_MEMORY="Unknown"

    ############################
    # Memory Usage Percentage
    ############################

    MEMORY_USAGE=$(
        free 2>/dev/null |
        awk '/^Mem:/ {
            if ($2 > 0)
                printf "%.0f", ($3/$2)*100
            else
                print 0
        }'
    )

    [[ -z "$MEMORY_USAGE" ]] && MEMORY_USAGE=0

    ############################
    # Swap Usage Percentage
    ############################

    SWAP_USAGE=$(
        free 2>/dev/null |
        awk '/^Swap:/ {
            if ($2 > 0)
                printf "%.0f", ($3/$2)*100
            else
                print 0
        }'
    )

    [[ -z "$SWAP_USAGE" ]] && SWAP_USAGE=0

    ############################
    # Export Variables
    ############################

    export TOTAL_MEMORY
    export USED_MEMORY
    export FREE_MEMORY
    export CACHE_MEMORY
    export AVAILABLE_MEMORY
    export MEMORY_USAGE
    export SWAP_USAGE
}

###############################################################################
# Display Memory Information
###############################################################################

memory_info() {

    section "MEMORY INFORMATION"

    print_kv "Total Memory" "$TOTAL_MEMORY"
    print_kv "Used Memory" "$USED_MEMORY"
    print_kv "Free Memory" "$FREE_MEMORY"
    print_kv "Available Memory" "$AVAILABLE_MEMORY"
    print_kv "Cache/Buffers" "$CACHE_MEMORY"

    echo

    printf "%-30s : " "Memory Usage"
    progress_bar "$MEMORY_USAGE"

    echo

    print_kv "Swap Usage" "${SWAP_USAGE}%"

    echo

    printf "%-30s : " "Status"
    health_status "$MEMORY_USAGE" "$MEMORY_WARNING" "$MEMORY_CRITICAL"

    echo
}
