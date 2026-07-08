#!/usr/bin/env bash

###############################################################################
# Enterprise Linux System Health Monitor (ELSHM)
# Security Monitoring Module
###############################################################################

###############################################################################
# Collect Security Information
###############################################################################

collect_security() {

    ############################
    # Firewall
    ############################

    if command -v ufw >/dev/null 2>&1; then

        FIREWALL_STATUS=$(ufw status 2>/dev/null | awk -F': *' 'NR==1{print $2}')

        [[ -z "$FIREWALL_STATUS" ]] && FIREWALL_STATUS="Inactive"

    elif command -v firewall-cmd >/dev/null 2>&1; then

        if firewall-cmd --state >/dev/null 2>&1; then
            FIREWALL_STATUS="Active"
        else
            FIREWALL_STATUS="Inactive"
        fi

    elif command -v iptables >/dev/null 2>&1; then

        FIREWALL_STATUS="iptables"

    else

        FIREWALL_STATUS="Not Installed"

    fi

    ############################
    # SSH Service
    ############################

    if command -v systemctl >/dev/null 2>&1; then

        if systemctl is-active --quiet ssh; then

            SSH_STATUS="Active"

        elif systemctl is-active --quiet sshd; then

            SSH_STATUS="Active"

        else

            SSH_STATUS="Inactive"

        fi

    else

        SSH_STATUS="Unknown"

    fi

    ############################
    # OpenSSH Version
    ############################

    if command -v ssh >/dev/null 2>&1; then

        SSH_VERSION=$(ssh -V 2>&1 | awk '{print $1}')

    else

        SSH_VERSION="Not Installed"

    fi

    ############################
    # SSH Configuration
    ############################

    SSH_CONFIG=""

    [[ -f /etc/ssh/sshd_config ]] && SSH_CONFIG="/etc/ssh/sshd_config"

    if [[ -n "$SSH_CONFIG" ]]; then

        ROOT_LOGIN=$(awk '/^[[:space:]]*PermitRootLogin/{print $2;exit}' "$SSH_CONFIG")

        PASSWORD_AUTH=$(awk '/^[[:space:]]*PasswordAuthentication/{print $2;exit}' "$SSH_CONFIG")

    fi

    [[ -z "${ROOT_LOGIN:-}" ]] && ROOT_LOGIN="Default"

    [[ -z "${PASSWORD_AUTH:-}" ]] && PASSWORD_AUTH="Default"

    ############################
    # SELinux
    ############################

    if command -v getenforce >/dev/null 2>&1; then

        SELINUX_STATUS=$(getenforce)

    else

        SELINUX_STATUS="Disabled"

    fi

    ############################
    # AppArmor
    ############################

    if [[ -d /sys/module/apparmor ]]; then

        APPARMOR_STATUS="Enabled"

    else

        APPARMOR_STATUS="Disabled"

    fi

    ############################
    # Logged Users
    ############################

    LOGGED_USERS=$(who | wc -l)

    ############################
    # Failed Logins
    ############################

    if command -v journalctl >/dev/null 2>&1; then

        FAILED_LOGINS=$(journalctl --no-pager 2>/dev/null \
            | grep -ci "Failed password")

    else

        FAILED_LOGINS=0

    fi

############################
# Listening Services (Unique Ports)
############################

LISTENING_SERVICES=$(
ss -tlnH 2>/dev/null |
awk '
{
    split($4,a,":")

    port=a[length(a)]

    if(port !~ /^[0-9]+$/)
        next

    if(!(port in seen)){
        seen[port]=$1
    }
}

END{
    for(p in seen)
        printf "%s %s\n",p,seen[p]
}' |
sort -n
)

LISTENING_PORTS=$(echo "$LISTENING_SERVICES" | grep -c '.')

    ############################
    # Administrative Users
    ############################

    SUDO_USERS=$(
        getent group sudo 2>/dev/null | cut -d: -f4
    )

    [[ -z "$SUDO_USERS" ]] && SUDO_USERS="None"

    ############################
    # Last Successful Login
    ############################

    LAST_LOGIN=$(last -a 2>/dev/null \
        | grep -v "reboot" \
        | grep -v "^wtmp" \
        | head -1)

    [[ -z "$LAST_LOGIN" ]] && LAST_LOGIN="No login history available"

    export FIREWALL_STATUS
    export SSH_STATUS
    export SSH_VERSION
    export ROOT_LOGIN
    export PASSWORD_AUTH
    export SELINUX_STATUS
    export APPARMOR_STATUS
    export LOGGED_USERS
    export FAILED_LOGINS
    export LISTENING_PORTS
    export LISTENING_SERVICES
    export SUDO_USERS
    export LAST_LOGIN

}

###############################################################################
# Display Security Information
###############################################################################

security_info() {

    section "SECURITY INFORMATION"

    print_kv "Firewall" "$FIREWALL_STATUS"
    print_kv "SSH Service" "$SSH_STATUS"
    print_kv "OpenSSH Version" "$SSH_VERSION"

    echo

    print_kv "Root Login" "$ROOT_LOGIN"
    print_kv "Password Authentication" "$PASSWORD_AUTH"

    echo

    print_kv "SELinux" "$SELINUX_STATUS"
    print_kv "AppArmor" "$APPARMOR_STATUS"

    echo

    print_kv "Logged-in Users" "$LOGGED_USERS"
    print_kv "Failed Login Attempts" "$FAILED_LOGINS"
    print_kv "Listening TCP Ports" "$LISTENING_PORTS"

    echo

    draw_line
echo "Listening Services"
draw_line

printf "%-8s %-10s\n" "PORT" "STATE"

echo "$LISTENING_SERVICES" |
while read -r port state
do
    printf "%-8s %-10s\n" "$port" "$state"
done  	
    echo

    draw_line
    echo "Administrative Users"
    draw_line

    echo "$SUDO_USERS"

    echo

    draw_line
    echo "Last Successful Login"
    draw_line

    echo "$LAST_LOGIN"

    echo

    printf "%-30s : " "Status"

    if [[ "$FAILED_LOGINS" -eq 0 ]]; then
        success "Healthy"
    else
        warning "Warning"
    fi

    echo
}
