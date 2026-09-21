#!/bin/bash

# ============================================================
#             SYSTEM HEALTH CHECKER & ANALYZER
# ============================================================

# -------------------- CONFIGURATION --------------------------

LOG_DIR="reports"
REPORT_FILE="$LOG_DIR/health_report_$(date '+%Y-%m-%d_%H-%M-%S').log"

CPU_WARNING=70
CPU_CRITICAL=90

MEM_WARNING=70
MEM_CRITICAL=90

DISK_WARNING=70
DISK_CRITICAL=90

# -------------------- COLORS ---------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# -------------------- SETUP ----------------------------------

mkdir -p "$LOG_DIR"

# -------------------- FUNCTIONS ------------------------------

print_header() {
    echo "============================================================"
    echo "              SYSTEM HEALTH CHECKER & ANALYZER"
    echo "============================================================"
}

print_section() {
    echo
    echo "-------------------- $1 --------------------"
}

check_status() {

    local VALUE=$1
    local WARNING=$2
    local CRITICAL=$3

    if (( VALUE >= CRITICAL )); then
        echo -e "${RED}CRITICAL${NC}"
    elif (( VALUE >= WARNING )); then
        echo -e "${YELLOW}WARNING${NC}"
    else
        echo -e "${GREEN}HEALTHY${NC}"
    fi
}

# -------------------- SYSTEM INFORMATION ---------------------

get_system_info() {

    print_section "SYSTEM INFORMATION"

    HOSTNAME=$(hostname)

    if [ -f /etc/os-release ]; then
        OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d '"' -f2)
    else
        OS="Unknown"
    fi

    KERNEL=$(uname -r)
    ARCH=$(uname -m)
    UPTIME=$(uptime -p)

    echo "Hostname       : $HOSTNAME"
    echo "Operating System: $OS"
    echo "Kernel         : $KERNEL"
    echo "Architecture   : $ARCH"
    echo "Uptime         : $UPTIME"
}

# -------------------- CPU CHECK -------------------------------

check_cpu() {

    print_section "CPU ANALYSIS"

    CPU_USAGE=$(top -bn1 | awk '/Cpu\(s\)/ {
        print 100 - $8
    }')

    CPU_USAGE=${CPU_USAGE%.*}

    echo "CPU Usage      : ${CPU_USAGE}%"
    echo -n "CPU Status     : "
    check_status "$CPU_USAGE" "$CPU_WARNING" "$CPU_CRITICAL"

    CPU_CORES=$(nproc)

    echo "CPU Cores      : $CPU_CORES"

    LOAD=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

    echo "Load Average   : $LOAD"
}

# -------------------- MEMORY CHECK ----------------------------

check_memory() {

    print_section "MEMORY ANALYSIS"

    MEMORY_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
    MEMORY_USED=$(free -m | awk '/Mem:/ {print $3}')
    MEMORY_FREE=$(free -m | awk '/Mem:/ {print $4}')

    MEMORY_USAGE=$((MEMORY_USED * 100 / MEMORY_TOTAL))

    echo "Total Memory   : ${MEMORY_TOTAL} MB"
    echo "Used Memory    : ${MEMORY_USED} MB"
    echo "Free Memory    : ${MEMORY_FREE} MB"
    echo "Memory Usage   : ${MEMORY_USAGE}%"

    echo -n "Memory Status  : "
    check_status "$MEMORY_USAGE" "$MEM_WARNING" "$MEM_CRITICAL"
}

# -------------------- DISK CHECK ------------------------------

check_disk() {

    print_section "DISK ANALYSIS"

    df -hP | awk 'NR > 1 && $1 !~ /tmpfs|udev|loop/ {

        usage=$5
        gsub("%","",usage)

        printf "%-25s %-10s %-10s %-10s %-10s\n",
        $6, $2, $3, $4, $5
    }'

    echo

    ROOT_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

    echo "Root Disk Usage : ${ROOT_USAGE}%"

    echo -n "Disk Status     : "
    check_status "$ROOT_USAGE" "$DISK_WARNING" "$DISK_CRITICAL"
}

# -------------------- PROCESS ANALYSIS ------------------------

check_processes() {

    print_section "TOP CPU PROCESSES"

    ps aux --sort=-%cpu | head -n 6

    echo
    echo "-------------------- TOP MEMORY PROCESSES --------------------"

    ps aux --sort=-%mem | head -n 6
}

# -------------------- NETWORK CHECK ---------------------------

check_network() {

    print_section "NETWORK ANALYSIS"

    if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
        echo -e "Internet Status : ${GREEN}CONNECTED${NC}"
    else
        echo -e "Internet Status : ${RED}DISCONNECTED${NC}"
    fi

    echo
    echo "Network Interfaces:"

    ip -brief address 2>/dev/null || ifconfig 2>/dev/null
}

# -------------------- SERVICE CHECK ---------------------------

check_services() {

    print_section "SERVICE ANALYSIS"

    SERVICES=("ssh" "cron" "docker")

    for SERVICE in "${SERVICES[@]}"; do

        if systemctl list-unit-files "$SERVICE.service" &>/dev/null; then

            if systemctl is-active --quiet "$SERVICE"; then
                echo -e "$SERVICE : ${GREEN}RUNNING${NC}"
            else
                echo -e "$SERVICE : ${RED}NOT RUNNING${NC}"
            fi

        else
            echo "$SERVICE : NOT INSTALLED"
        fi

    done
}

# -------------------- STORAGE ANALYSIS ------------------------

check_storage() {

    print_section "STORAGE ANALYSIS"

    echo "Largest directories under /home:"

    if [ -d /home ]; then

        du -h /home 2>/dev/null |
        sort -hr |
        head -n 5

    else

        echo "/home directory not available."

    fi
}

# -------------------- SYSTEM LOAD ANALYSIS --------------------

analyze_load() {

    print_section "SYSTEM LOAD ANALYSIS"

    LOAD_1=$(awk '{print $1}' /proc/loadavg)

    CPU_CORES=$(nproc)

    LOAD_PERCENT=$(awk -v load="$LOAD_1" -v cores="$CPU_CORES" \
        'BEGIN {printf "%.0f", (load/cores)*100}')

    echo "1 Minute Load  : $LOAD_1"
    echo "CPU Cores      : $CPU_CORES"
    echo "Estimated Load : ${LOAD_PERCENT}%"

    echo -n "Load Status    : "

    if (( LOAD_PERCENT >= 90 )); then
        echo -e "${RED}CRITICAL${NC}"
    elif (( LOAD_PERCENT >= 70 )); then
        echo -e "${YELLOW}WARNING${NC}"
    else
        echo -e "${GREEN}HEALTHY${NC}"
    fi
}

# -------------------- HEALTH SUMMARY --------------------------

health_summary() {

    print_section "HEALTH SUMMARY"

    echo "Checking overall system condition..."
    echo

    ISSUES=0

    if (( CPU_USAGE >= CPU_CRITICAL )); then
        echo -e "${RED}[CRITICAL]${NC} CPU usage is very high."
        ((ISSUES++))
    elif (( CPU_USAGE >= CPU_WARNING )); then
        echo -e "${YELLOW}[WARNING]${NC} CPU usage is elevated."
        ((ISSUES++))
    else
        echo -e "${GREEN}[OK]${NC} CPU usage is normal."
    fi

    if (( MEMORY_USAGE >= MEM_CRITICAL )); then
        echo -e "${RED}[CRITICAL]${NC} Memory usage is very high."
        ((ISSUES++))
    elif (( MEMORY_USAGE >= MEM_WARNING )); then
        echo -e "${YELLOW}[WARNING]${NC} Memory usage is elevated."
        ((ISSUES++))
    else
        echo -e "${GREEN}[OK]${NC} Memory usage is normal."
    fi

    if (( ROOT_USAGE >= DISK_CRITICAL )); then
        echo -e "${RED}[CRITICAL]${NC} Root disk usage is very high."
        ((ISSUES++))
    elif (( ROOT_USAGE >= DISK_WARNING )); then
        echo -e "${YELLOW}[WARNING]${NC} Root disk usage is elevated."
        ((ISSUES++))
    else
        echo -e "${GREEN}[OK]${NC} Root disk usage is normal."
    fi

    echo

    if (( ISSUES == 0 )); then
        echo -e "Overall System Status : ${GREEN}HEALTHY${NC}"
    elif (( ISSUES <= 2 )); then
        echo -e "Overall System Status : ${YELLOW}WARNING${NC}"
    else
        echo -e "Overall System Status : ${RED}CRITICAL${NC}"
    fi
}

# -------------------- REPORT FOOTER ---------------------------

print_footer() {

    echo
    echo "============================================================"
    echo "              HEALTH CHECK COMPLETED"
    echo "============================================================"

    echo
    echo "Report saved to:"
    echo "$REPORT_FILE"

    echo
    echo "Generated at:"
    date
}

# ============================================================
#                    MAIN PROGRAM
# ============================================================

{

    clear

    print_header

    get_system_info

    check_cpu

    check_memory

    check_disk

    analyze_load

    check_processes

    check_network

    check_services

    check_storage

    health_summary

    print_footer

} | tee "$REPORT_FILE"