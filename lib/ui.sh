#!/usr/bin/env bash

###############################################################################
# Enterprise Linux System Health Monitor (ELSHM)
# UI Library
#
# Author  : Sajid Imran
# Version : 3.0
###############################################################################

###############################################################################
# Terminal Width
###############################################################################

TERM_WIDTH=$(tput cols 2>/dev/null || echo 100)

###############################################################################
# Colors
###############################################################################

if [[ -t 1 ]]; then
    RESET="\033[0m"
    BOLD="\033[1m"

    RED="\033[31m"
    GREEN="\033[32m"
    YELLOW="\033[33m"
    BLUE="\033[34m"
    CYAN="\033[36m"
    WHITE="\033[97m"
else
    RESET=""
    BOLD=""

    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    CYAN=""
    WHITE=""
fi

###############################################################################
# Horizontal Line
###############################################################################

draw_line() {
    printf '%*s\n' "$TERM_WIDTH" '' | tr ' ' '='
}

###############################################################################
# Main Header
###############################################################################

draw_header() {

    clear

    draw_line

    printf "${BOLD}${CYAN}%*s${RESET}\n" \
        $(( (${#1} + TERM_WIDTH) / 2 )) "$1"

    draw_line
}

###############################################################################
# Section Header
###############################################################################

section() {

    echo

    printf "${BOLD}${BLUE}► %s${RESET}\n" "$1"

    draw_line
}

###############################################################################
# Dashboard Title
###############################################################################

dashboard_title() {

    echo

    printf "${BOLD}${BLUE}SYSTEM HEALTH SUMMARY${RESET}\n"

    draw_line
}

###############################################################################
# Key : Value
###############################################################################

print_kv() {

    printf "%-30s : %s\n" "$1" "$2"
}
###############################################################################
# Progress Bar
###############################################################################

progress_bar() {

    local percent=${1:-0}

    [[ "$percent" =~ ^[0-9]+$ ]] || percent=0

    (( percent < 0 )) && percent=0
    (( percent > 100 )) && percent=100

    local width=20
    local filled=$((percent * width / 100))
    local empty=$((width - filled))

    local color="$GREEN"

    if (( percent >= 90 )); then
        color="$RED"
    elif (( percent >= 70 )); then
        color="$YELLOW"
    fi

    printf "["

    printf "${color}"

    for ((i=0;i<filled;i++))
    do
        printf "█"
    done

    printf "${RESET}"

    for ((i=0;i<empty;i++))
    do
        printf "░"
    done

    printf "] %3d%%" "$percent"
}

###############################################################################
# Health Status
###############################################################################

health_status() {

    local value=${1:-0}
    local warning=${2:-70}
    local critical=${3:-90}

    [[ "$value" =~ ^[0-9]+$ ]] || value=0

    if (( value >= critical )); then
        printf "${RED}✖ Critical${RESET}"
    elif (( value >= warning )); then
        printf "${YELLOW}⚠ Warning${RESET}"
    else
        printf "${GREEN}✔ Healthy${RESET}"
    fi
}

###############################################################################
# Message Functions
###############################################################################

info() {

    printf "${CYAN}ℹ %s${RESET}\n" "$1"
}

success() {

    printf "${GREEN}✔ %s${RESET}\n" "$1"
}

warning() {

    printf "${YELLOW}⚠ %s${RESET}\n" "$1"
}

error() {

    printf "${RED}✖ %s${RESET}\n" "$1"
}

###############################################################################
# Compatibility Functions
###############################################################################

line() {

    draw_line
}

draw_title() {

    draw_header "$1"
}
###############################################################################
# Status Helpers
###############################################################################

success() {
    printf "${GREEN}✔ %s${RESET}\n" "$1"
}

warning() {
    printf "${YELLOW}⚠ %s${RESET}\n" "$1"
}

critical() {
    printf "${RED}✖ %s${RESET}\n" "$1"
}

info() {
    printf "${BLUE}ℹ %s${RESET}\n" "$1"
}
