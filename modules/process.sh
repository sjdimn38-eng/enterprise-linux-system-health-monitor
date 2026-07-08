#!/usr/bin/env bash

###############################################################################
# Enterprise Linux System Health Monitor (ELSHM)
# Process Monitoring Module
###############################################################################

###############################################################################
# Collect Process Information
###############################################################################

collect_process() {

    ############################
    # Process Counts
    ############################

    TOTAL_PROCESSES=$(ps -e --no-headers 2>/dev/null | wc -l)

    RUNNING_PROCESSES=$(ps -eo state= 2>/dev/null | grep -c "^R")

    SLEEPING_PROCESSES=$(ps -eo state= 2>/dev/null | grep -c "^S")

    STOPPED_PROCESSES=$(ps -eo state= 2>/dev/null | grep -c "^T")

    ZOMBIE_PROCESSES=$(ps -eo state= 2>/dev/null | grep -c "^Z")

    ############################
    # Top CPU Processes
    ############################

    TOP_CPU_PROCESSES=$(
        ps -eo pid,user,%cpu,%mem,comm,args \
        --sort=-%cpu \
        --no-headers 2>/dev/null | head -10
    )

    ############################
    # Top Memory Processes
    ############################

    TOP_MEMORY_PROCESSES=$(
        ps -eo pid,user,%cpu,%mem,comm,args \
        --sort=-%mem \
        --no-headers 2>/dev/null | head -10
    )

    ############################
    # Export Variables
    ############################

    export TOTAL_PROCESSES
    export RUNNING_PROCESSES
    export SLEEPING_PROCESSES
    export STOPPED_PROCESSES
    export ZOMBIE_PROCESSES
    export TOP_CPU_PROCESSES
    export TOP_MEMORY_PROCESSES
}

###############################################################################
# Display Process Information
###############################################################################

process_info() {

    section "PROCESS INFORMATION"

    print_kv "Total Processes" "$TOTAL_PROCESSES"
    print_kv "Running" "$RUNNING_PROCESSES"
    print_kv "Sleeping" "$SLEEPING_PROCESSES"
    print_kv "Stopped" "$STOPPED_PROCESSES"
    print_kv "Zombie" "$ZOMBIE_PROCESSES"

    echo

    ###########################################################################
    # Status
    ###########################################################################

    printf "%-30s : " "Status"

    if (( ZOMBIE_PROCESSES > 0 )); then
        printf "${YELLOW}⚠ Warning${RESET}\n"
    else
        printf "${GREEN}✔ Healthy${RESET}\n"
    fi

    echo

    ###########################################################################
    # Top CPU Processes
    ###########################################################################

    draw_line
    echo "Top 10 CPU Consuming Processes"
    draw_line

    printf "%-8s %-12s %-7s %-7s %-20s %s\n" \
        "PID" "USER" "%CPU" "%MEM" "COMMAND" "ARGS"

    printf "%-8s %-12s %-7s %-7s %-20s %s\n" \
        "--------" "------------" "------" "------" \
        "--------------------" "----"

    while read -r pid user cpu mem cmd args
    do
        printf "%-8s %-12s %-7s %-7s %-20s %s\n" \
            "$pid" "$user" "$cpu" "$mem" "$cmd" "$args"
    done <<< "$TOP_CPU_PROCESSES"

    echo

    ###########################################################################
    # Top Memory Processes
    ###########################################################################

    draw_line
    echo "Top 10 Memory Consuming Processes"
    draw_line

    printf "%-8s %-12s %-7s %-7s %-20s %s\n" \
        "PID" "USER" "%CPU" "%MEM" "COMMAND" "ARGS"

    printf "%-8s %-12s %-7s %-7s %-20s %s\n" \
        "--------" "------------" "------" "------" \
        "--------------------" "----"

    while read -r pid user cpu mem cmd args
    do
        printf "%-8s %-12s %-7s %-7s %-20s %s\n" \
            "$pid" "$user" "$cpu" "$mem" "$cmd" "$args"
    done <<< "$TOP_MEMORY_PROCESSES"

    echo
}
