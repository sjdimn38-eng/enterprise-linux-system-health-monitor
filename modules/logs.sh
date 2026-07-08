#!/usr/bin/env bash

###############################################################################
# Enterprise Linux System Health Monitor (ELSHM)
# System Log Monitoring Module
###############################################################################

###############################################################################
# Collect Log Information
###############################################################################

collect_logs() {

    ###########################################################################
    # Verify journalctl
    ###########################################################################

    if ! command -v journalctl >/dev/null 2>&1; then

        JOURNAL_ENTRIES="N/A"
        ERROR_COUNT="N/A"
        WARNING_COUNT="N/A"
        CRITICAL_COUNT="N/A"
        FAILED_SSH_LOGINS="N/A"
        RECENT_EVENTS="journalctl is not available."

        export JOURNAL_ENTRIES
        export ERROR_COUNT
        export WARNING_COUNT
        export CRITICAL_COUNT
        export FAILED_SSH_LOGINS
        export RECENT_EVENTS

        return
    fi

    ###########################################################################
    # Journal Statistics (Last 24 Hours)
    ###########################################################################

    JOURNAL_ENTRIES=$(journalctl --since "24 hours ago" --no-pager 2>/dev/null | wc -l)

    ERROR_COUNT=$(journalctl -p err --since "24 hours ago" --no-pager 2>/dev/null | wc -l)

    WARNING_COUNT=$(journalctl -p warning --since "24 hours ago" --no-pager 2>/dev/null | wc -l)

    CRITICAL_COUNT=$(journalctl -p crit --since "24 hours ago" --no-pager 2>/dev/null | wc -l)

    ###########################################################################
    # Failed SSH Logins
    ###########################################################################

    FAILED_SSH_LOGINS=$(
        journalctl --since "24 hours ago" --no-pager 2>/dev/null |
        grep -Ei "Failed password|authentication failure|Invalid user" |
        wc -l
    )

    ###########################################################################
    # Recent Important Events
    ###########################################################################

    RECENT_EVENTS=$(
        journalctl \
            --since "24 hours ago" \
            --priority=warning \
            --no-pager 2>/dev/null |
        sed 's/\[.*$//' |
        awk '!seen[$0]++' |
        head -10
    )

    [[ -z "$RECENT_EVENTS" ]] && RECENT_EVENTS="No important events found."

    ###########################################################################
    # Export Variables
    ###########################################################################

    export JOURNAL_ENTRIES
    export ERROR_COUNT
    export WARNING_COUNT
    export CRITICAL_COUNT
    export FAILED_SSH_LOGINS
    export RECENT_EVENTS
}

###############################################################################
# Display Log Information
###############################################################################

log_info() {

    section "SYSTEM LOG MONITORING"

    print_kv "Journal Entries (24 Hours)" "$JOURNAL_ENTRIES"
    print_kv "Errors" "$ERROR_COUNT"
    print_kv "Warnings" "$WARNING_COUNT"
    print_kv "Critical Messages" "$CRITICAL_COUNT"
    print_kv "Failed SSH Logins" "$FAILED_SSH_LOGINS"

    echo

    printf "%-30s : " "Status"

    if [[ "$CRITICAL_COUNT" =~ ^[0-9]+$ && "$CRITICAL_COUNT" -gt 0 ]]; then

        printf "${RED}✖ Critical${RESET}\n"

    elif [[ "$ERROR_COUNT" =~ ^[0-9]+$ && "$ERROR_COUNT" -gt 0 ]]; then

        printf "${YELLOW}⚠ Warning${RESET}\n"

    else

        printf "${GREEN}✔ Healthy${RESET}\n"

    fi

    echo

    draw_line
    echo "Recent Critical Events"
    draw_line

    if [[ "$RECENT_EVENTS" == "No important events found." ]]; then

        echo "$RECENT_EVENTS"

    else

        while IFS= read -r event
        do
            [[ -z "$event" ]] && continue
            printf "• %s\n" "$event"
        done <<< "$RECENT_EVENTS"

    fi

    echo
}
