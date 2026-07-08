#!/usr/bin/env bash

###############################################################################
# Enterprise Linux System Health Monitor - HTML Report Generator
# Author: Sajid Imran
# Working version - direct variable expansion, no sed
###############################################################################

generate_html_report() {
    local REPORT_DIR="reports"
    local REPORT_FILE="$REPORT_DIR/report_$(date +%F_%H-%M-%S).html"
    
    mkdir -p "$REPORT_DIR"
    
    # Color codes
    local GREEN='\033[0;32m'
    local RESET='\033[0m'
    
    # Set defaults
    SCORE=${SCORE:-0}
    HOSTNAME=${HOSTNAME:-"Unknown"}
    OS_NAME=${OS_NAME:-"Unknown"}
    KERNEL=${KERNEL:-"Unknown"}
    ARCHITECTURE=${ARCHITECTURE:-"Unknown"}
    CURRENT_USER=${CURRENT_USER:-"Unknown"}
    UPTIME=${UPTIME:-"Unknown"}
    BOOT_TIME=${BOOT_TIME:-"Unknown"}
    TIMEZONE=${TIMEZONE:-"Unknown"}
    VIRTUALIZATION=${VIRTUALIZATION:-"None"}
    CPU_MODEL=${CPU_MODEL:-"Unknown"}
    CPU_ARCH=${CPU_ARCH:-"Unknown"}
    CPU_SOCKET=${CPU_SOCKET:-"0"}
    CPU_CORES=${CPU_CORES:-"0"}
    CPU_THREADS=${CPU_THREADS:-"0"}
    CPU_USAGE=${CPU_USAGE:-"0%"}
    CPU_LOAD=${CPU_LOAD:-"0.00"}
    TOTAL_MEMORY=${TOTAL_MEMORY:-"0"}
    USED_MEMORY=${USED_MEMORY:-"0"}
    FREE_MEMORY=${FREE_MEMORY:-"0"}
    AVAILABLE_MEMORY=${AVAILABLE_MEMORY:-"0"}
    CACHE_MEMORY=${CACHE_MEMORY:-"0"}
    MEMORY_USAGE=${MEMORY_USAGE:-"0%"}
    SWAP_USAGE=${SWAP_USAGE:-"0%"}
    DISK_USAGE=${DISK_USAGE:-"0%"}
    ROOT_USAGE=${ROOT_USAGE:-"0%"}
    PRIMARY_INTERFACE=${PRIMARY_INTERFACE:-"Unknown"}
    INTERFACE_STATUS=${INTERFACE_STATUS:-"Unknown"}
    IPV4_ADDRESS=${IPV4_ADDRESS:-"N/A"}
    IPV6_ADDRESS=${IPV6_ADDRESS:-"N/A"}
    MAC_ADDRESS=${MAC_ADDRESS:-"N/A"}
    DEFAULT_GATEWAY=${DEFAULT_GATEWAY:-"N/A"}
    DNS_SERVERS=${DNS_SERVERS:-"N/A"}
    INTERNET_STATUS=${INTERNET_STATUS:-"Unknown"}
    LATENCY=${LATENCY:-"N/A"}
    TOTAL_PROCESSES=${TOTAL_PROCESSES:-"0"}
    RUNNING_PROCESSES=${RUNNING_PROCESSES:-"0"}
    SLEEPING_PROCESSES=${SLEEPING_PROCESSES:-"0"}
    STOPPED_PROCESSES=${STOPPED_PROCESSES:-"0"}
    ZOMBIE_PROCESSES=${ZOMBIE_PROCESSES:-"0"}
    SYSTEMD_STATUS=${SYSTEMD_STATUS:-"Unknown"}
    FAILED_SERVICES=${FAILED_SERVICES:-"0"}
    FIREWALL_STATUS=${FIREWALL_STATUS:-"Unknown"}
    SSH_STATUS=${SSH_STATUS:-"Unknown"}
    OPENSSH_VERSION=${OPENSSH_VERSION:-"Unknown"}
    ROOT_LOGIN=${ROOT_LOGIN:-"Unknown"}
    PASSWORD_AUTH=${PASSWORD_AUTH:-"Unknown"}
    SELINUX_STATUS=${SELINUX_STATUS:-"Disabled"}
    APPARMOR_STATUS=${APPARMOR_STATUS:-"Disabled"}
    LOGGED_USERS=${LOGGED_USERS:-"0"}
    FAILED_LOGIN_ATTEMPTS=${FAILED_LOGIN_ATTEMPTS:-"0"}
    JOURNAL_ENTRIES=${JOURNAL_ENTRIES:-"0"}
    ERROR_COUNT=${ERROR_COUNT:-"0"}
    WARNING_COUNT=${WARNING_COUNT:-"0"}
    CRITICAL_COUNT=${CRITICAL_COUNT:-"0"}
    FAILED_SSH_LOGINS=${FAILED_SSH_LOGINS:-"0"}
    RECENT_EVENTS=${RECENT_EVENTS:-""}
    
    # Extract percentages
    local cpu_num=${CPU_USAGE%\%}
    local memory_num=${MEMORY_USAGE%\%}
    local disk_num=${DISK_USAGE%\%}
    
    # Progress bar widths
    local cpu_width=$((cpu_num * 2))
    local memory_width=$((memory_num * 2))
    local disk_width=$((disk_num * 2))
    
    # Status colors
    local score_color="status-critical"
    local status_text="CRITICAL"
    if [[ $SCORE -ge 80 ]]; then
        score_color="status-healthy"
        status_text="HEALTHY"
    elif [[ $SCORE -ge 60 ]]; then
        score_color="status-warning"
        status_text="WARNING"
    elif [[ $SCORE -ge 40 ]]; then
        score_color="status-degraded"
        status_text="DEGRADED"
    fi
    
    # BUILD SERVICES TABLE
    local services_html=""
    for service in ssh sshd cron docker mysql mariadb postgresql nginx apache2 NetworkManager systemd-resolved ufw; do
        local svc_status=$(systemctl is-active "$service" 2>/dev/null || echo "Not Installed")
        local badge_class="badge-danger"
        
        if [[ "$svc_status" == "active" ]]; then
            badge_class="badge-success"
            svc_status="Running"
        elif [[ "$svc_status" == "inactive" ]]; then
            badge_class="badge-danger"
            svc_status="Stopped"
        elif [[ "$svc_status" == "failed" ]]; then
            badge_class="badge-danger"
            svc_status="Failed"
        elif [[ "$svc_status" == "Not Installed" ]]; then
            badge_class="badge-info"
        fi
        
        services_html+="<tr><td>$service</td><td><span class=\"badge $badge_class\">$svc_status</span></td></tr>"
    done
    
    # BUILD LISTENING PORTS TABLE
    local ports_html=""
    local ports_output=$(ss -tln 2>/dev/null | grep LISTEN | awk '{print $4}' | sed 's/.*:\([0-9]*\)/\1/' | sort -u)
    if [[ -n "$ports_output" ]]; then
        while IFS= read -r port; do
            [[ -z "$port" ]] && continue
            ports_html+="<tr><td>$port</td><td><span class=\"badge badge-success\">LISTEN</span></td></tr>"
        done <<< "$ports_output"
    else
        ports_html="<tr><td colspan=\"2\" style=\"text-align: center; color: #888;\">No listening ports detected</td></tr>"
    fi
    
    # BUILD ADMIN USERS TABLE
    local admin_html=""
    local admin_users=$(getent group sudo 2>/dev/null | cut -d: -f4 | tr ',' '\n')
    if [[ -n "$admin_users" ]]; then
        while IFS= read -r user; do
            [[ -z "$user" ]] && continue
            admin_html+="<tr><td>$user</td></tr>"
        done <<< "$admin_users"
    else
        admin_html="<tr><td style=\"text-align: center; color: #888;\">No sudoers found</td></tr>"
    fi
    
    # BUILD LOGIN TABLE
    local login_html=""
    local login_output=$(last -n 5 2>/dev/null)
    if [[ -n "$login_output" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" ]] || [[ "$line" =~ "wtmp" ]] && continue
            local user=$(echo "$line" | awk '{print $1}')
            local term=$(echo "$line" | awk '{print $2}')
            local from=$(echo "$line" | awk '{print $3}')
            local datetime=$(echo "$line" | awk '{print $4, $5, $6, $7}')
            [[ -z "$user" ]] && continue
            login_html+="<tr><td>$user</td><td>$term</td><td>$from</td><td>$datetime</td></tr>"
        done <<< "$login_output"
    fi
    [[ -z "$login_html" ]] && login_html="<tr><td colspan=\"4\" style=\"text-align: center; color: #888;\">No login history available</td></tr>"
    
    # BUILD EVENTS LIST
    local events_html=""
    if [[ -n "$RECENT_EVENTS" ]]; then
        while IFS= read -r event; do
            [[ -z "$event" ]] && continue
            events_html+="<li><span class=\"event-icon\"></span>$event</li>"
        done <<< "$RECENT_EVENTS"
    else
        events_html="<li style=\"text-align: center; color: #888; padding: 20px 0;\">No recent critical events detected</li>"
    fi
    
    # INTERFACE & INTERNET BADGES
    local interface_badge='<span class="badge badge-danger">DOWN</span>'
    [[ "${INTERFACE_STATUS}" == "up" ]] || [[ "${INTERFACE_STATUS}" == "UP" ]] && interface_badge='<span class="badge badge-success">UP</span>'
    
    local internet_badge='<span class="badge badge-danger">Disconnected</span>'
    [[ "${INTERNET_STATUS}" == "Connected" ]] || [[ "${INTERNET_STATUS}" == "connected" ]] && internet_badge='<span class="badge badge-success">Connected</span>'
    
    local report_date=$(date '+%Y-%m-%d %H:%M:%S')
    
    # WRITE HTML FILE - using unquoted heredoc for direct variable expansion
    cat > "$REPORT_FILE" << ENDHTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Enterprise Linux System Health Monitor - Report</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%); color: #333; line-height: 1.6; padding: 20px; }
        .container { max-width: 1400px; margin: 0 auto; background: white; border-radius: 12px; box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1); overflow: hidden; }
        header { background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); color: white; padding: 40px 30px; text-align: center; }
        header h1 { font-size: 28px; margin-bottom: 10px; font-weight: 600; }
        header .metadata { font-size: 12px; opacity: 0.9; margin-top: 15px; }
        .content { padding: 30px; }
        .cards-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px; margin-bottom: 40px; }
        .card { background: white; border-radius: 8px; padding: 25px; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08); border-left: 4px solid #2a5298; transition: transform 0.2s; }
        .card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0, 0, 0, 0.12); }
        .card-title { font-size: 12px; color: #888; text-transform: uppercase; margin-bottom: 10px; letter-spacing: 1px; }
        .card-value { font-size: 32px; font-weight: 700; color: #1e3c72; margin-bottom: 15px; }
        .card-bar { width: 100%; height: 8px; background: #e0e0e0; border-radius: 4px; overflow: hidden; }
        .card-bar-fill { height: 100%; background: linear-gradient(90deg, #2a5298 0%, #6a82fb 100%); border-radius: 4px; }
        .section { margin-bottom: 40px; }
        .section-header { display: flex; align-items: center; padding-bottom: 15px; border-bottom: 2px solid #2a5298; margin-bottom: 25px; }
        .section-title { font-size: 20px; font-weight: 600; color: #1e3c72; flex: 1; }
        .section-icon { width: 40px; height: 40px; background: linear-gradient(135deg, #2a5298 0%, #6a82fb 100%); border-radius: 8px; display: flex; align-items: center; justify-content: center; color: white; font-size: 20px; margin-right: 15px; }
        .info-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .info-item { display: flex; flex-direction: column; padding: 15px; background: #f8f9fa; border-radius: 6px; border-left: 3px solid #2a5298; }
        .info-label { font-size: 11px; color: #888; text-transform: uppercase; margin-bottom: 5px; letter-spacing: 0.5px; }
        .info-value { font-size: 16px; font-weight: 600; color: #1e3c72; word-break: break-word; }
        table { width: 100%; border-collapse: collapse; background: white; border-radius: 6px; overflow: hidden; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05); margin-top: 15px; }
        thead { background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); color: white; }
        th { padding: 15px; text-align: left; font-weight: 600; font-size: 12px; text-transform: uppercase; }
        td { padding: 12px 15px; border-bottom: 1px solid #e0e0e0; }
        tbody tr:hover { background: #f8f9fa; }
        .badge { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 11px; font-weight: 600; text-transform: uppercase; }
        .badge-success { background: #d4edda; color: #155724; }
        .badge-danger { background: #f8d7da; color: #721c24; }
        .badge-info { background: #d1ecf1; color: #0c5460; }
        .progress-bar { width: 100%; height: 20px; background: #e0e0e0; border-radius: 10px; overflow: hidden; margin-top: 8px; }
        .progress-fill { height: 100%; background: linear-gradient(90deg, #2a5298 0%, #6a82fb 100%); border-radius: 10px; display: flex; align-items: center; justify-content: flex-end; padding-right: 8px; color: white; font-size: 11px; font-weight: 600; }
        .status-badge { display: inline-block; padding: 8px 16px; border-radius: 6px; font-weight: 600; font-size: 12px; text-transform: uppercase; }
        .status-healthy { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .status-warning { background: #fff3cd; color: #856404; border: 1px solid #ffeeba; }
        .status-degraded { background: #ffe0b2; color: #e65100; border: 1px solid #ffccb2; }
        .status-critical { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .event-list { list-style: none; padding: 0; }
        .event-list li { padding: 10px 0; border-bottom: 1px solid #e0e0e0; font-size: 13px; color: #555; }
        .event-icon { display: inline-block; width: 8px; height: 8px; background: #f44336; border-radius: 50%; margin-right: 10px; }
        footer { background: #f8f9fa; border-top: 1px solid #e0e0e0; padding: 30px; text-align: center; color: #888; font-size: 12px; }
        @media (max-width: 768px) { .cards-grid, .info-grid { grid-template-columns: 1fr; } header { padding: 30px 20px; } header h1 { font-size: 20px; } .content { padding: 20px; } }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🖥️ Enterprise Linux System Health Monitor</h1>
            <div class="metadata">
                <p>Generated: <strong>$report_date</strong> | Author: <strong>Sajid Imran</strong> | Hostname: <strong>$HOSTNAME</strong></p>
            </div>
        </header>
        
        <div class="content">
            <div class="cards-grid">
                <div class="card">
                    <div class="card-title">Health Score</div>
                    <div class="card-value">$SCORE/100</div>
                    <span class="status-badge $score_color">$status_text</span>
                </div>
                <div class="card">
                    <div class="card-title">CPU Usage</div>
                    <div class="card-value">$CPU_USAGE</div>
                    <div class="card-bar"><div class="card-bar-fill" style="width: ${cpu_width}px;"></div></div>
                </div>
                <div class="card">
                    <div class="card-title">Memory Usage</div>
                    <div class="card-value">$MEMORY_USAGE</div>
                    <div class="card-bar"><div class="card-bar-fill" style="width: ${memory_width}px;"></div></div>
                </div>
                <div class="card">
                    <div class="card-title">Disk Usage</div>
                    <div class="card-value">$DISK_USAGE</div>
                    <div class="card-bar"><div class="card-bar-fill" style="width: ${disk_width}px;"></div></div>
                </div>
            </div>
            
            <div class="section">
                <div class="section-header"><div class="section-icon">📋</div><div class="section-title">System Information</div></div>
                <div class="info-grid">
                    <div class="info-item"><div class="info-label">Hostname</div><div class="info-value">$HOSTNAME</div></div>
                    <div class="info-item"><div class="info-label">Operating System</div><div class="info-value">$OS_NAME</div></div>
                    <div class="info-item"><div class="info-label">Kernel Version</div><div class="info-value">$KERNEL</div></div>
                    <div class="info-item"><div class="info-label">Architecture</div><div class="info-value">$ARCHITECTURE</div></div>
                    <div class="info-item"><div class="info-label">Current User</div><div class="info-value">$CURRENT_USER</div></div>
                    <div class="info-item"><div class="info-label">System Uptime</div><div class="info-value">$UPTIME</div></div>
                    <div class="info-item"><div class="info-label">Last Boot Time</div><div class="info-value">$BOOT_TIME</div></div>
                    <div class="info-item"><div class="info-label">Timezone</div><div class="info-value">$TIMEZONE</div></div>
                    <div class="info-item"><div class="info-label">Virtualization</div><div class="info-value">$VIRTUALIZATION</div></div>
                </div>
            </div>
            
            <div class="section">
                <div class="section-header"><div class="section-icon">⚙️</div><div class="section-title">CPU Information</div></div>
                <div class="info-grid">
                    <div class="info-item"><div class="info-label">CPU Model</div><div class="info-value">$CPU_MODEL</div></div>
                    <div class="info-item"><div class="info-label">Architecture</div><div class="info-value">$CPU_ARCH</div></div>
                    <div class="info-item"><div class="info-label">Socket(s)</div><div class="info-value">$CPU_SOCKET</div></div>
                    <div class="info-item"><div class="info-label">Core(s) per Socket</div><div class="info-value">$CPU_CORES</div></div>
                    <div class="info-item"><div class="info-label">Logical CPU(s)</div><div class="info-value">$CPU_THREADS</div></div>
                    <div class="info-item"><div class="info-label">Load Average</div><div class="info-value">$CPU_LOAD</div></div>
                </div>
                <div style="margin-top: 20px;"><div class="info-label">CPU Usage</div><div class="progress-bar"><div class="progress-fill" style="width: ${cpu_num}%;">$CPU_USAGE</div></div></div>
            </div>
            
            <div class="section">
                <div class="section-header"><div class="section-icon">🧠</div><div class="section-title">Memory Information</div></div>
                <div class="info-grid">
                    <div class="info-item"><div class="info-label">Total Memory</div><div class="info-value">$TOTAL_MEMORY</div></div>
                    <div class="info-item"><div class="info-label">Used Memory</div><div class="info-value">$USED_MEMORY</div></div>
                    <div class="info-item"><div class="info-label">Free Memory</div><div class="info-value">$FREE_MEMORY</div></div>
                    <div class="info-item"><div class="info-label">Available Memory</div><div class="info-value">$AVAILABLE_MEMORY</div></div>
                    <div class="info-item"><div class="info-label">Cache/Buffers</div><div class="info-value">$CACHE_MEMORY</div></div>
                    <div class="info-item"><div class="info-label">Swap Usage</div><div class="info-value">$SWAP_USAGE</div></div>
                </div>
                <div style="margin-top: 20px;"><div class="info-label">Memory Usage</div><div class="progress-bar"><div class="progress-fill" style="width: ${memory_num}%;">$MEMORY_USAGE</div></div></div>
            </div>
            
            <div class="section">
                <div class="section-header"><div class="section-icon">💾</div><div class="section-title">Disk & Filesystem Information</div></div>
                <div class="info-grid">
                    <div class="info-item"><div class="info-label">Root Filesystem Usage</div><div class="info-value">$ROOT_USAGE</div></div>
                    <div class="info-item"><div class="info-label">Overall Disk Usage</div><div class="info-value">$DISK_USAGE</div></div>
                </div>
                <div style="margin-top: 20px;"><div class="info-label">Disk Usage</div><div class="progress-bar"><div class="progress-fill" style="width: ${disk_num}%;">$DISK_USAGE</div></div></div>
            </div>
            
            <div class="section">
                <div class="section-header"><div class="section-icon">🌐</div><div class="section-title">Network Information</div></div>
                <div class="info-grid">
                    <div class="info-item"><div class="info-label">Primary Interface</div><div class="info-value">$PRIMARY_INTERFACE</div></div>
                    <div class="info-item"><div class="info-label">Interface Status</div><div class="info-value">$interface_badge</div></div>
                    <div class="info-item"><div class="info-label">IPv4 Address</div><div class="info-value">$IPV4_ADDRESS</div></div>
                    <div class="info-item"><div class="info-label">IPv6 Address</div><div class="info-value">$IPV6_ADDRESS</div></div>
                    <div class="info-item"><div class="info-label">MAC Address</div><div class="info-value">$MAC_ADDRESS</div></div>
                    <div class="info-item"><div class="info-label">Default Gateway</div><div class="info-value">$DEFAULT_GATEWAY</div></div>
                    <div class="info-item"><div class="info-label">DNS Server(s)</div><div class="info-value">$DNS_SERVERS</div></div>
                    <div class="info-item"><div class="info-label">Internet Status</div><div class="info-value">$internet_badge</div></div>
                    <div class="info-item"><div class="info-label">Latency</div><div class="info-value">$LATENCY</div></div>
                </div>
            </div>
            
            <div class="section">
                <div class="section-header"><div class="section-icon">📊</div><div class="section-title">Process Information</div></div>
                <div class="info-grid">
                    <div class="info-item"><div class="info-label">Total Processes</div><div class="info-value">$TOTAL_PROCESSES</div></div>
                    <div class="info-item"><div class="info-label">Running</div><div class="info-value">$RUNNING_PROCESSES</div></div>
                    <div class="info-item"><div class="info-label">Sleeping</div><div class="info-value">$SLEEPING_PROCESSES</div></div>
                    <div class="info-item"><div class="info-label">Stopped</div><div class="info-value">$STOPPED_PROCESSES</div></div>
                    <div class="info-item"><div class="info-label">Zombie</div><div class="info-value">$ZOMBIE_PROCESSES</div></div>
                </div>
            </div>
            
            <div class="section">
                <div class="section-header"><div class="section-icon">⚡</div><div class="section-title">Service Information</div></div>
                <div class="info-grid">
                    <div class="info-item"><div class="info-label">Systemd Status</div><div class="info-value">$SYSTEMD_STATUS</div></div>
                    <div class="info-item"><div class="info-label">Failed Services</div><div class="info-value">$FAILED_SERVICES</div></div>
                </div>
                <h3 style="margin-top: 25px; color: #1e3c72; margin-bottom: 15px;">Important Services</h3>
                <table><thead><tr><th>Service Name</th><th>Status</th></tr></thead><tbody>$services_html</tbody></table>
            </div>
            
            <div class="section">
                <div class="section-header"><div class="section-icon">🔒</div><div class="section-title">Security Information</div></div>
                <div class="info-grid">
                    <div class="info-item"><div class="info-label">Firewall Status</div><div class="info-value">$FIREWALL_STATUS</div></div>
                    <div class="info-item"><div class="info-label">SSH Service</div><div class="info-value">$SSH_STATUS</div></div>
                    <div class="info-item"><div class="info-label">OpenSSH Version</div><div class="info-value">$OPENSSH_VERSION</div></div>
                    <div class="info-item"><div class="info-label">Root Login</div><div class="info-value">$ROOT_LOGIN</div></div>
                    <div class="info-item"><div class="info-label">Password Authentication</div><div class="info-value">$PASSWORD_AUTH</div></div>
                    <div class="info-item"><div class="info-label">SELinux</div><div class="info-value">$SELINUX_STATUS</div></div>
                    <div class="info-item"><div class="info-label">AppArmor</div><div class="info-value">$APPARMOR_STATUS</div></div>
                    <div class="info-item"><div class="info-label">Logged-in Users</div><div class="info-value">$LOGGED_USERS</div></div>
                    <div class="info-item"><div class="info-label">Failed Login Attempts</div><div class="info-value">$FAILED_LOGIN_ATTEMPTS</div></div>
                </div>
                <h3 style="margin-top: 25px; color: #1e3c72; margin-bottom: 15px;">Listening Ports</h3>
                <table><thead><tr><th>Port</th><th>State</th></tr></thead><tbody>$ports_html</tbody></table>
                <h3 style="margin-top: 25px; color: #1e3c72; margin-bottom: 15px;">Administrative Users (Sudoers)</h3>
                <table><thead><tr><th>Username</th></tr></thead><tbody>$admin_html</tbody></table>
                <h3 style="margin-top: 25px; color: #1e3c72; margin-bottom: 15px;">Last Successful Login</h3>
                <table><thead><tr><th>User</th><th>Terminal</th><th>From</th><th>Login Time</th></tr></thead><tbody>$login_html</tbody></table>
            </div>
            
            <div class="section">
                <div class="section-header"><div class="section-icon">📝</div><div class="section-title">System Log Monitoring</div></div>
                <div class="info-grid">
                    <div class="info-item"><div class="info-label">Journal Entries (24h)</div><div class="info-value">$JOURNAL_ENTRIES</div></div>
                    <div class="info-item"><div class="info-label">Error Count</div><div class="info-value">$ERROR_COUNT</div></div>
                    <div class="info-item"><div class="info-label">Warning Count</div><div class="info-value">$WARNING_COUNT</div></div>
                    <div class="info-item"><div class="info-label">Critical Messages</div><div class="info-value">$CRITICAL_COUNT</div></div>
                    <div class="info-item"><div class="info-label">Failed SSH Logins</div><div class="info-value">$FAILED_SSH_LOGINS</div></div>
                </div>
                <h3 style="margin-top: 25px; color: #1e3c72; margin-bottom: 15px;">Recent Critical Events</h3>
                <ul class="event-list">$events_html</ul>
            </div>
        </div>
        
        <footer>
            <p><strong>Enterprise Linux System Health Monitor (ELSHM)</strong></p>
            <p>Author: <strong>Sajid Imran</strong> | Report Generated: <strong>$report_date</strong></p>
            <p style="margin-top: 10px; color: #aaa; font-size: 11px;">This report is automatically generated and contains real-time system metrics.</p>
        </footer>
    </div>
</body>
</html>
ENDHTML

    printf "${GREEN}✔ HTML report generated:${RESET} %s\n" "$REPORT_FILE"
}

generate_html_report
