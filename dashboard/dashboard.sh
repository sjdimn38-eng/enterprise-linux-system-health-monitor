#!/usr/bin/env bash

###############################################################################
# Enterprise Linux System Health Monitor
# Dashboard Module v3.0
###############################################################################

dashboard() {

    local SCORE=100
    local STATUS="HEALTHY"

    ############################################################
    # Safety Defaults
    ############################################################

    CPU_USAGE=${CPU_USAGE:-0}
    MEMORY_USAGE=${MEMORY_USAGE:-0}
    DISK_USAGE=${DISK_USAGE:-0}

    ############################################################
    # CPU Score
    ############################################################

    if (( CPU_USAGE >= CPU_CRITICAL )); then
        SCORE=$((SCORE-20))
    elif (( CPU_USAGE >= CPU_WARNING )); then
        SCORE=$((SCORE-10))
    fi

    ############################################################
    # Memory Score
    ############################################################

    if (( MEMORY_USAGE >= MEMORY_CRITICAL )); then
        SCORE=$((SCORE-20))
    elif (( MEMORY_USAGE >= MEMORY_WARNING )); then
        SCORE=$((SCORE-10))
    fi

    ############################################################
    # Disk Score
    ############################################################

    if (( DISK_USAGE >= DISK_CRITICAL )); then
        SCORE=$((SCORE-40))
    elif (( DISK_USAGE >= DISK_WARNING )); then
        SCORE=$((SCORE-20))
    fi

    ############################################################
    # Overall Status
    ############################################################

    if (( SCORE >= 90 )); then
        STATUS="HEALTHY"
    elif (( SCORE >= 70 )); then
        STATUS="WARNING"
    else
        STATUS="CRITICAL"
    fi

    ############################################################
    # Dashboard
    ############################################################

    dashboard_title
   
   print_kv "Health Score" "${SCORE}/100"

printf "%-30s : " "Overall Status"

case "$STATUS" in
    HEALTHY)
        printf "${GREEN}%s${RESET}\n" "$STATUS"
        ;;
    WARNING)
        printf "${YELLOW}%s${RESET}\n" "$STATUS"
        ;;
    CRITICAL)
        printf "${RED}%s${RESET}\n" "$STATUS"
        ;;
    *)
        printf "%s\n" "$STATUS"
        ;;
esac 
    echo

    printf "%-30s : " "CPU Usage"
    progress_bar "$CPU_USAGE"
    echo

    printf "%-30s : " "Memory Usage"
    progress_bar "$MEMORY_USAGE"
    echo

    printf "%-30s : " "Disk Usage"
    progress_bar "$DISK_USAGE"
    echo

    echo
}
