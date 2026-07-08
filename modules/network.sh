#!/usr/bin/env bash

###############################################################################
# Enterprise Linux System Health Monitor (ELSHM)
# Network Monitoring Module
###############################################################################

###############################################################################
# Collect Network Information
###############################################################################

collect_network() {

    ############################
    # Hostname
    ############################

    HOSTNAME=$(hostname 2>/dev/null)

    ############################
    # Primary Interface
    ############################

    PRIMARY_INTERFACE=$(
        ip route 2>/dev/null |
        awk '/default/ {print $5; exit}'
    )

    [[ -z "$PRIMARY_INTERFACE" ]] && PRIMARY_INTERFACE="N/A"

    ############################
    # Interface Status
    ############################

    if [[ -e "/sys/class/net/$PRIMARY_INTERFACE/operstate" ]]; then
        INTERFACE_STATUS=$(cat "/sys/class/net/$PRIMARY_INTERFACE/operstate")
    else
        INTERFACE_STATUS="Unknown"
    fi

    ############################
    # IPv4 Address
    ############################

    IPV4_ADDRESS=$(
        ip -4 addr show "$PRIMARY_INTERFACE" 2>/dev/null |
        awk '/inet / {print $2}' |
        cut -d/ -f1
    )

    [[ -z "$IPV4_ADDRESS" ]] && IPV4_ADDRESS="Not Assigned"

    ############################
    # IPv6 Address
    ############################

    IPV6_ADDRESS=$(
        ip -6 addr show "$PRIMARY_INTERFACE" 2>/dev/null |
        awk '/inet6/ {print $2}' |
        head -1
    )

    [[ -z "$IPV6_ADDRESS" ]] && IPV6_ADDRESS="Not Assigned"

    ############################
    # MAC Address
    ############################

    if [[ -e "/sys/class/net/$PRIMARY_INTERFACE/address" ]]; then
        MAC_ADDRESS=$(cat "/sys/class/net/$PRIMARY_INTERFACE/address")
    else
        MAC_ADDRESS="Unknown"
    fi

    ############################
    # Default Gateway
    ############################

    DEFAULT_GATEWAY=$(
        ip route 2>/dev/null |
        awk '/default/ {print $3; exit}'
    )

    [[ -z "$DEFAULT_GATEWAY" ]] && DEFAULT_GATEWAY="Unknown"

    ############################
    # DNS Servers
    ############################

    DNS_SERVERS=$(
        awk '/^nameserver/ {print $2}' /etc/resolv.conf 2>/dev/null |
        paste -sd "," -
    )

    [[ -z "$DNS_SERVERS" ]] && DNS_SERVERS="Unknown"

    ############################
    # Internet Connectivity
    ############################

    if ping -c1 -W2 8.8.8.8 >/dev/null 2>&1; then

        INTERNET_STATUS="Connected"

        LATENCY=$(
            ping -c1 -W2 8.8.8.8 2>/dev/null |
            awk -F'time=' '/time=/{print $2}' |
            cut -d' ' -f1
        )

        [[ -z "$LATENCY" ]] && LATENCY="Unknown"

    else

        INTERNET_STATUS="Disconnected"
        LATENCY="N/A"

    fi

    ############################
    # Export Variables
    ############################

    export HOSTNAME
    export PRIMARY_INTERFACE
    export INTERFACE_STATUS
    export IPV4_ADDRESS
    export IPV6_ADDRESS
    export MAC_ADDRESS
    export DEFAULT_GATEWAY
    export DNS_SERVERS
    export INTERNET_STATUS
    export LATENCY
}

###############################################################################
# Display Network Information
###############################################################################

network_info() {

    section "NETWORK INFORMATION"

    print_kv "Hostname" "$HOSTNAME"
    print_kv "Primary Interface" "$PRIMARY_INTERFACE"
    print_kv "Interface Status" "$INTERFACE_STATUS"

    echo

    print_kv "IPv4 Address" "$IPV4_ADDRESS"
    print_kv "IPv6 Address" "$IPV6_ADDRESS"
    print_kv "MAC Address" "$MAC_ADDRESS"

    echo

    print_kv "Default Gateway" "$DEFAULT_GATEWAY"
    print_kv "DNS Server(s)" "$DNS_SERVERS"

    echo

    print_kv "Internet" "$INTERNET_STATUS"

    if [[ "$LATENCY" == "N/A" ]]; then
        print_kv "Latency" "N/A"
    else
        print_kv "Latency" "${LATENCY} ms"
    fi

    echo

    printf "%-30s : " "Status"

    if [[ "$INTERNET_STATUS" == "Connected" ]]; then
        printf "${GREEN}✔ Healthy${RESET}\n"
    else
        printf "${RED}✖ Disconnected${RESET}\n"
    fi

    echo
}
