#!/usr/bin/env bash

###############################################################################
# Enterprise Linux System Health Monitor (ELSHM)
# System Information Module
###############################################################################

###############################################################################
# Collect System Information
###############################################################################

collect_system() {

    ############################
    # Hostname
    ############################

    HOSTNAME=$(hostname 2>/dev/null)

    ############################
    # Operating System
    ############################

    OS_NAME=$(grep "^PRETTY_NAME=" /etc/os-release 2>/dev/null \
        | cut -d= -f2 \
        | tr -d '"')

    [[ -z "$OS_NAME" ]] && OS_NAME="Unknown"

    ############################
    # Kernel
    ############################

    KERNEL=$(uname -r 2>/dev/null)

    ############################
    # Architecture
    ############################

    ARCHITECTURE=$(uname -m 2>/dev/null)

    ############################
    # Current User
    ############################

    CURRENT_USER=$(whoami 2>/dev/null)

    ############################
    # System Uptime
    ############################

    UPTIME=$(uptime -p 2>/dev/null)

    ############################
    # Last Boot Time
    ############################

    BOOT_TIME=$(uptime -s 2>/dev/null)

    if [[ -z "$BOOT_TIME" ]]; then
        BOOT_TIME=$(who -b 2>/dev/null | awk '{print $3" "$4}')
    fi

    [[ -z "$BOOT_TIME" ]] && BOOT_TIME="Unknown"

    ############################
    # Timezone
    ############################

    TIMEZONE=$(timedatectl show --property=Timezone --value 2>/dev/null)

    if [[ -z "$TIMEZONE" && -f /etc/timezone ]]; then
        TIMEZONE=$(cat /etc/timezone)
    fi

    [[ -z "$TIMEZONE" ]] && TIMEZONE="Unknown"

    ############################
    # Current Time
    ############################

    CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

    ############################
    # Logged-in Users
    ############################

    LOGGED_USERS=$(who 2>/dev/null | wc -l)

    ############################
    # Machine ID
    ############################

    MACHINE_ID=$(cat /etc/machine-id 2>/dev/null)

    [[ -z "$MACHINE_ID" ]] && MACHINE_ID="Unavailable"

    ############################
    # Virtualization
    ############################

    if command -v systemd-detect-virt >/dev/null 2>&1; then

        VIRTUALIZATION=$(systemd-detect-virt 2>/dev/null)

        [[ "$VIRTUALIZATION" == "none" ]] && \
            VIRTUALIZATION="Physical Machine"

    else

        VIRTUALIZATION="Unknown"

    fi

    ############################
    # Export Variables
    ############################

    export HOSTNAME
    export OS_NAME
    export KERNEL
    export ARCHITECTURE
    export CURRENT_USER
    export UPTIME
    export BOOT_TIME
    export TIMEZONE
    export CURRENT_TIME
    export LOGGED_USERS
    export MACHINE_ID
    export VIRTUALIZATION
}

###############################################################################
# Display System Information
###############################################################################

system_info() {

    section "SYSTEM INFORMATION"

    print_kv "Hostname" "$HOSTNAME"
    print_kv "Operating System" "$OS_NAME"
    print_kv "Kernel Version" "$KERNEL"
    print_kv "Architecture" "$ARCHITECTURE"

    echo

    print_kv "Current User" "$CURRENT_USER"
    print_kv "System Uptime" "$UPTIME"
    print_kv "Last Boot Time" "$BOOT_TIME"

    echo

    print_kv "Timezone" "$TIMEZONE"
    print_kv "Current Time" "$CURRENT_TIME"

    echo

    print_kv "Logged Users" "$LOGGED_USERS"
    print_kv "Machine ID" "$MACHINE_ID"
    print_kv "Virtualization" "$VIRTUALIZATION"

    echo

    printf "%-30s : " "Status"
    success "Healthy"

    echo
}
