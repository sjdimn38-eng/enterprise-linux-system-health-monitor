#!/usr/bin/env bash

###############################################################################
# Enterprise Linux System Health Monitor
# Service Monitoring Module
###############################################################################

###############################################################################
# Collect Service Information
###############################################################################

collect_service() {

    # Check whether systemd is available
    if command -v systemctl >/dev/null 2>&1; then

        SYSTEMD_STATUS=$(systemctl is-system-running 2>/dev/null)

        [[ -z "$SYSTEMD_STATUS" ]] && SYSTEMD_STATUS="Unknown"

        FAILED_SERVICES=$(
            systemctl --failed --no-legend 2>/dev/null \
            | grep '\.service' \
            | wc -l
        )

    else

        SYSTEMD_STATUS="Not Available"
        FAILED_SERVICES=0

    fi

    export SYSTEMD_STATUS
    export FAILED_SERVICES
}

###############################################################################
# Display Service Information
###############################################################################

service_info() {

    section "SERVICE INFORMATION"

    print_kv "Systemd Status" "$SYSTEMD_STATUS"
    print_kv "Failed Services" "$FAILED_SERVICES"

    echo

    printf "%-30s : " "Status"

    if (( FAILED_SERVICES == 0 )); then
        printf "${GREEN}✔ Healthy${RESET}\n"

    elif (( FAILED_SERVICES <= 3 )); then
        printf "${YELLOW}⚠ Warning${RESET}\n"

    else
        printf "${RED}✖ Critical${RESET}\n"
    fi

    echo

    draw_line
    echo "Failed Services"
    draw_line

    if (( FAILED_SERVICES == 0 )); then

        echo "No failed services detected."

    else

        systemctl --failed --no-pager

    fi

    echo

    draw_line
    echo "Important Services"
    draw_line

    printf "%-25s %-15s\n" "Service" "Status"
    printf "%-25s %-15s\n" "-------------------------" "--------------"

    SERVICES=(
        ssh
        sshd
        cron
        docker
        mysql
        mariadb
        postgresql
        nginx
        apache2
        NetworkManager
        systemd-resolved
        ufw
    )

    for SERVICE in "${SERVICES[@]}"
    do

        UNIT=$(systemctl show -p LoadState "${SERVICE}.service" 2>/dev/null | cut -d= -f2)

        if [[ "$UNIT" != "not-found" && -n "$UNIT" ]]; then

    STATUS=$(systemctl is-active "$SERVICE" 2>/dev/null)

    case "$STATUS" in
        active)
            STATUS="${GREEN}Running${RESET}"
            ;;

        inactive)
            STATUS="${YELLOW}Stopped${RESET}"
            ;;

        failed)
            STATUS="${RED}Failed${RESET}"
            ;;

        activating)
            STATUS="${BLUE}Starting${RESET}"
            ;;

        deactivating)
            STATUS="${YELLOW}Stopping${RESET}"
            ;;

        *)
            STATUS="$STATUS"
            ;;
    esac

else

    STATUS="Not Installed"

fi

        printf "%-25s %-15b\n" "$SERVICE" "$STATUS"

    done

    echo
}
