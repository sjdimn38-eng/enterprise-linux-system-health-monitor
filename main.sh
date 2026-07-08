#!/usr/bin/env bash

###############################################################################
# Enterprise Linux System Health Monitor (ELSHM)
#
# Author  : Sajid Imran
# Version : 2.1
###############################################################################

set -uo pipefail

###############################################################################
# Project Root
###############################################################################

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

###############################################################################
# Load Libraries
###############################################################################

source "$PROJECT_ROOT/lib/ui.sh"
source "$PROJECT_ROOT/lib/config.sh"
source "$PROJECT_ROOT/lib/logger.sh"
source "$PROJECT_ROOT/lib/health.sh"
source "$PROJECT_ROOT/report.sh"
###############################################################################
# Load Dashboard
###############################################################################

if [[ -f "$PROJECT_ROOT/dashboard/dashboard.sh" ]]; then
    source "$PROJECT_ROOT/dashboard/dashboard.sh"
fi

###############################################################################
# Load Modules
###############################################################################

source "$PROJECT_ROOT/modules/system_info.sh"
source "$PROJECT_ROOT/modules/cpu.sh"
source "$PROJECT_ROOT/modules/memory.sh"
source "$PROJECT_ROOT/modules/disk.sh"
source "$PROJECT_ROOT/modules/network.sh"
source "$PROJECT_ROOT/modules/process.sh"
source "$PROJECT_ROOT/modules/service.sh"
source "$PROJECT_ROOT/modules/security.sh"
source "$PROJECT_ROOT/modules/logs.sh"

###############################################################################
# Header
###############################################################################

draw_header "ENTERPRISE LINUX SYSTEM HEALTH MONITOR"

print_kv "Hostname" "$(hostname)"
print_kv "Current User" "$(whoami)"
print_kv "Operating System" "$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')"
print_kv "Kernel" "$(uname -r)"
print_kv "Architecture" "$(uname -m)"
print_kv "System Uptime" "$(uptime -p)"
print_kv "Generated At" "$(date '+%Y-%m-%d %H:%M:%S')"

echo

###############################################################################
# Collect Data
###############################################################################

echo "DEBUG: collect_system"
collect_system

echo "DEBUG: collect_cpu"
collect_cpu

echo "DEBUG: collect_memory"
collect_memory

echo "DEBUG: collect_disk"
collect_disk

echo "DEBUG: collect_network"
collect_network

echo "DEBUG: collect_process"
collect_process

echo "DEBUG: collect_service"
collect_service

echo "DEBUG: collect_security"
collect_security

echo "DEBUG: collect_logs"
collect_logs

echo "DEBUG: Collection Finished"
###############################################################################
# Dashboard
###############################################################################

if declare -F dashboard >/dev/null; then
    dashboard
fi

###############################################################################
# Detailed Report
###############################################################################

system_info

cpu_info

memory_info

disk_info

network_info

process_info

service_info

security_info

log_info

###############################################################################
# Finished
###############################################################################

draw_line

echo
generate_html_report

success "Health monitoring completed successfully."

echo
