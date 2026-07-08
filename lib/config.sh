#!/bin/bash

############################################################
# Enterprise Linux System Health Monitor (ELSHM)
# Configuration Loader (SAFE VERSION)
############################################################

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_DIR}/../config/monitor.conf"

# Prevent silent failure
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "[ERROR] Configuration file not found: $CONFIG_FILE"
    return 1 2>/dev/null || exit 1
fi

# Safety: validate file is readable text
if ! file "$CONFIG_FILE" | grep -q "text"; then
    echo "[ERROR] Invalid config format (not a text file)"
    return 1 2>/dev/null || exit 1
fi

# Load config safely
# shellcheck disable=SC1090
source "$CONFIG_FILE"

echo "[INFO] Configuration loaded successfully"
