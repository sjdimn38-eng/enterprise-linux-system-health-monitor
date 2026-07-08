#!/usr/bin/env bash

###############################################################################
# Enterprise Linux System Health Monitor (ELSHM)
# CPU Monitoring Module
###############################################################################

###############################################################################
# Collect CPU Information
###############################################################################

collect_cpu() {

    ############################
    # CPU Model
    ############################

    CPU_MODEL=$(
        lscpu 2>/dev/null |
        awk -F: '/Model name/ {
            gsub(/^[ \t]+/, "", $2)
            print $2
        }'
    )

    [[ -z "$CPU_MODEL" ]] && CPU_MODEL="Unknown"

    ############################
    # Architecture
    ############################

    CPU_ARCH=$(uname -m 2>/dev/null)

    [[ -z "$CPU_ARCH" ]] && CPU_ARCH="Unknown"

    ############################
    # CPU Sockets
    ############################

    CPU_SOCKET=$(
        lscpu 2>/dev/null |
        awk -F: '/Socket\(s\)/ {
            gsub(/^[ \t]+/, "", $2)
            print $2
        }'
    )

    [[ -z "$CPU_SOCKET" ]] && CPU_SOCKET="Unknown"

    ############################
    # CPU Cores
    ############################

    CPU_CORES=$(
        lscpu 2>/dev/null |
        awk -F: '/Core\(s\) per socket/ {
            gsub(/^[ \t]+/, "", $2)
            print $2
        }'
    )

    [[ -z "$CPU_CORES" ]] && CPU_CORES="Unknown"

    ############################
    # Logical CPUs
    ############################

    CPU_THREADS=$(nproc 2>/dev/null)

    [[ -z "$CPU_THREADS" ]] && CPU_THREADS="Unknown"

    ############################
    # CPU Usage
    ############################

    CPU_USAGE=$(
        top -bn1 2>/dev/null |
        awk '/Cpu\(s\)/ {
            print int(100-$8)
            exit
        }'
    )

    [[ -z "$CPU_USAGE" ]] && CPU_USAGE=0

    ############################
    # Load Average
    ############################

    CPU_LOAD=$(
        uptime 2>/dev/null |
        awk -F'load average:' '{print $2}' |
        xargs
    )

    [[ -z "$CPU_LOAD" ]] && CPU_LOAD="Unavailable"

    ############################
    # Export Variables
    ############################

    export CPU_MODEL
    export CPU_ARCH
    export CPU_SOCKET
    export CPU_CORES
    export CPU_THREADS
    export CPU_USAGE
    export CPU_LOAD
}

###############################################################################
# Display CPU Information
###############################################################################

cpu_info() {

    section "CPU INFORMATION"

    print_kv "CPU Model" "$CPU_MODEL"
    print_kv "Architecture" "$CPU_ARCH"
    print_kv "Socket(s)" "$CPU_SOCKET"
    print_kv "Core(s) per Socket" "$CPU_CORES"
    print_kv "Logical CPU(s)" "$CPU_THREADS"

    echo

    printf "%-30s : " "CPU Usage"
    progress_bar "$CPU_USAGE"

    echo

    print_kv "Load Average" "$CPU_LOAD"

    echo

    printf "%-30s : " "Status"
    health_status "$CPU_USAGE" "$CPU_WARNING" "$CPU_CRITICAL"

    echo
}
