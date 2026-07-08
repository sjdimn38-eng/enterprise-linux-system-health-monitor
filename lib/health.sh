#!/usr/bin/env bash

############################################################
#
# Enterprise Linux System Health Monitor (ELSHM)
#
# Health Evaluation Library
#
############################################################

evaluate_health() {

    local VALUE="${1:-0}"
    local WARNING="${2:-70}"
    local CRITICAL="${3:-90}"
    local COMPONENT="${4:-Unknown}"

    # Validate input
    [[ "$VALUE" =~ ^[0-9]+([.][0-9]+)?$ ]] || VALUE=0

    if (( VALUE >= CRITICAL )); then

        HEALTH_STATUS="CRITICAL"

        log_error "${COMPONENT} utilization is critically high."

    elif (( VALUE >= WARNING )); then

        HEALTH_STATUS="WARNING"

        log_warning "${COMPONENT} utilization exceeds warning threshold."

    else

        HEALTH_STATUS="HEALTHY"

        log_success "${COMPONENT} utilization is healthy."

    fi
}
