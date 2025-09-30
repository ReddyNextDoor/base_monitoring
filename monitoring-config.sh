#!/bin/bash

# Advanced Netdata Configuration Script
# Customizes Netdata with additional monitoring capabilities

set -euo pipefail

# Configuration
NETDATA_CONFIG_DIR="/etc/netdata"
CUSTOM_CONFIG_DIR="$NETDATA_CONFIG_DIR/custom-configs"
LOG_FILE="/var/log/netdata-config.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if Netdata is installed
check_netdata() {
    if ! systemctl is-active --quiet netdata; then
        error "Netdata is not running. Please run setup.sh first."
    fi
    log "Netdata is running"
}

# Create custom configuration directory
setup_custom_configs() {
    mkdir -p "$CUSTOM_CONFIG_DIR"
    chown netdata:netdata "$CUSTOM_CONFIG_DIR"
    log "Created custom configuration directory"
}

# Configure advanced CPU monitoring
configure_cpu_monitoring() {
    log "Configuring advanced CPU monitoring..."
    
    cat > "$NETDATA_CONFIG_DIR/python.d/cpufreq.conf" << 'EOF'
# CPU frequency monitoring
update_every: 1
priority: 90000

cpufreq:
    name: 'cpufreq'
    update_every: 1
EOF

    # CPU temperature monitoring (if available)
    if [[ -d /sys/class/thermal ]]; then
        cat > "$NETDATA_CONFIG_DIR/charts.d/sensors.conf" << 'EOF'
# Temperature sensors
sensors_update_every=2
sensors_priority=90000
sensors_retries=10
EOF
    fi
    
    log "CPU monitoring configured"
}

# Configure network monitoring
configure_network_monitoring() {
    log "Configuring network monitoring..."
    
    cat > "$NETDATA_CONFIG_DIR/python.d/nginx.conf" << 'EOF'
# Nginx monitoring (if nginx is installed)
update_every: 1
priority: 90000

nginx_log:
    name: 'nginx_log'
    path: '/var/log/nginx/access.log'
EOF

    # Network connections monitoring
    cat > "$NETDATA_CONFIG_DIR/python.d/netstat.conf" << 'EOF'
# Network connections monitoring
update_every: 1
priority: 90000
EOF

    log "Network monitoring configured"
}

# Configure application monitoring
configure_app_monitoring() {
    log "Configuring application monitoring..."
    
    # Docker monitoring
    if command -v docker &> /dev/null; then
        cat > "$NETDATA_CONFIG_DIR/python.d/dockerd.conf" << 'EOF'
# Docker monitoring
update_every: 1
priority: 90000

dockerd:
    name: 'dockerd'
    url: 'http://localhost:2375'
EOF
    fi
    
    # MySQL monitoring (if MySQL is installed)
    if command -v mysql &> /dev/null; then
        cat > "$NETDATA_CONFIG_DIR/python.d/mysql.conf" << 'EOF'
# MySQL monitoring
update_every: 3
priority: 90000

mysql:
    name: 'local'
    host: 'localhost'
    port: 3306
    user: 'netdata'
    pass: 'netdata'
EOF
    fi
    
    # Redis monitoring (if Redis is installed)
    if command -v redis-cli &> /dev/null; then
        cat > "$NETDATA_CONFIG_DIR/python.d/redis.conf" << 'EOF'
# Redis monitoring
update_every: 1
priority: 90000

redis:
    name: 'local'
    host: 'localhost'
    port: 6379
EOF
    fi
    
    log "Application monitoring configured"
}

# Configure custom charts
configure_custom_charts() {
    log "Configuring custom charts..."
    
    # Custom script for monitoring custom metrics
    cat > "$NETDATA_CONFIG_DIR/charts.d/custom_metrics.chart.sh" << 'EOF'
#!/bin/bash

# Custom metrics chart
# This script demonstrates how to create custom metrics

custom_metrics_update_every=5
custom_metrics_priority=90000

custom_metrics_check() {
    return 0
}

custom_metrics_create() {
    cat << EOF
CHART custom.system_health '' "Custom System Health Metrics" "score" "custom" "custom.system_health" line $((custom_metrics_priority + 1)) $custom_metrics_update_every
DIMENSION health_score 'Health Score' absolute 1 1
EOF
    return 0
}

custom_metrics_update() {
    # Calculate a simple health score based on system metrics
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local mem_usage=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    
    # Simple health score calculation (100 - weighted average of usage)
    local health_score=$(echo "100 - ($cpu_usage * 0.4 + $mem_usage * 0.4 + $load_avg * 20)" | bc -l | cut -d'.' -f1)
    
    # Ensure score is between 0 and 100
    if [[ $health_score -lt 0 ]]; then
        health_score=0
    elif [[ $health_score -gt 100 ]]; then
        health_score=100
    fi
    
    echo "SET health_score = $health_score"
    return 0
}
EOF

    chmod +x "$NETDATA_CONFIG_DIR/charts.d/custom_metrics.chart.sh"
    chown netdata:netdata "$NETDATA_CONFIG_DIR/charts.d/custom_metrics.chart.sh"
    
    log "Custom charts configured"
}

# Configure advanced alerting
configure_advanced_alerts() {
    log "Configuring advanced alerting..."
    
    cat > "$NETDATA_CONFIG_DIR/health.d/advanced_alerts.conf" << 'EOF'
# Advanced system alerts

# Disk I/O latency alert
template: disk_io_latency_high
      on: disk.await
   class: Latency
    type: System
component: Disk
    calc: $read + $write
   units: ms
   every: 10s
    warn: $this > 50
    crit: $this > 100
   delay: down 15m multiplier 1.5 max 1h
    info: Disk I/O latency is high
      to: sysadmin

# Network packet loss alert
template: network_packet_drops
      on: net.drops
   class: Errors
    type: System
component: Network
    calc: $inbound + $outbound
   units: packets/s
   every: 10s
    warn: $this > 10
    crit: $this > 50
   delay: down 5m multiplier 1.2 max 30m
    info: Network packet drops detected
      to: sysadmin

# File descriptor usage alert
template: fd_usage_high
      on: system.fds
   class: Utilization
    type: System
component: FileDescriptors
    calc: $used * 100 / $max
   units: %
   every: 10s
    warn: $this > 80
    crit: $this > 95
   delay: down 10m multiplier 1.3 max 1h
    info: File descriptor usage is high
      to: sysadmin

# Swap usage alert
template: swap_usage_high
      on: system.swap
   class: Utilization
    type: System
component: Memory
    calc: $used * 100 / $total
   units: %
   every: 30s
    warn: $this > 20
    crit: $this > 50
   delay: down 15m multiplier 1.5 max 2h
    info: Swap usage is high, system may be low on memory
      to: sysadmin

# Custom health score alert
template: system_health_score_low
      on: custom.system_health
   class: Utilization
    type: System
component: Health
    calc: $health_score
   units: score
   every: 30s
    warn: $this < 70
    crit: $this < 50
   delay: down 10m multiplier 1.2 max 1h
    info: System health score is low
      to: sysadmin
EOF

    chown netdata:netdata "$NETDATA_CONFIG_DIR/health.d/advanced_alerts.conf"
    log "Advanced alerting configured"
}

# Configure notification methods
configure_notifications() {
    log "Configuring notification methods..."
    
    cat > "$NETDATA_CONFIG_DIR/health_alarm_notify.conf" << 'EOF'
# Notification configuration

# Email notifications
SEND_EMAIL="YES"
DEFAULT_RECIPIENT_EMAIL="admin@localhost"
EMAIL_SENDER="netdata@$(hostname)"

# Slack notifications (configure webhook URL)
SEND_SLACK="NO"
SLACK_WEBHOOK_URL=""
DEFAULT_RECIPIENT_SLACK="alerts"

# Discord notifications (configure webhook URL)
SEND_DISCORD="NO"
DISCORD_WEBHOOK_URL=""
DEFAULT_RECIPIENT_DISCORD="alerts"

# Custom script notifications
SEND_CUSTOM="YES"
DEFAULT_RECIPIENT_CUSTOM="sysadmin"

# Log all notifications
SEND_NSCA="NO"
NSCA_SERVER=""
NSCA_CONFIG_FILE=""

# Role definitions
role_recipients_email[sysadmin]="admin@localhost"
role_recipients_slack[sysadmin]="alerts"
role_recipients_discord[sysadmin]="alerts"
role_recipients_custom[sysadmin]="sysadmin"
EOF

    # Create custom notification script
    cat > "$NETDATA_CONFIG_DIR/custom-notify.sh" << 'EOF'
#!/bin/bash

# Custom notification script
# This script is called when alerts are triggered

# Parameters passed by Netdata:
# $1 = recipient
# $2 = hostname
# $3 = unique_id
# $4 = alarm_id
# $5 = event_id
# $6 = when
# $7 = name
# $8 = chart
# $9 = family
# $10 = status
# $11 = old_status
# $12 = value
# $13 = old_value
# $14 = src
# $15 = duration
# $16 = non_clear_duration
# $17 = units
# $18 = info

RECIPIENT="$1"
HOSTNAME="$2"
ALARM_NAME="$7"
STATUS="$10"
VALUE="$12"
UNITS="$17"
INFO="$18"

# Log the alert
echo "$(date): Alert - $ALARM_NAME on $HOSTNAME is $STATUS (Value: $VALUE $UNITS)" >> /var/log/netdata-alerts.log

# You can add custom notification logic here
# Examples:
# - Send to external monitoring systems
# - Write to database
# - Trigger automated responses
# - Send to messaging systems

exit 0
EOF

    chmod +x "$NETDATA_CONFIG_DIR/custom-notify.sh"
    chown netdata:netdata "$NETDATA_CONFIG_DIR/custom-notify.sh"
    chown netdata:netdata "$NETDATA_CONFIG_DIR/health_alarm_notify.conf"
    
    log "Notification methods configured"
}

# Configure web interface customization
configure_web_interface() {
    log "Configuring web interface customization..."
    
    # Custom CSS for branding
    mkdir -p "$NETDATA_CONFIG_DIR/web/custom"
    
    cat > "$NETDATA_CONFIG_DIR/web/custom/custom.css" << 'EOF'
/* Custom Netdata styling */
.netdata-container {
    font-family: 'Arial', sans-serif;
}

.dashboard-title {
    color: #2196F3;
    font-weight: bold;
}

.alarm-critical {
    background-color: #f44336 !important;
    color: white !important;
}

.alarm-warning {
    background-color: #ff9800 !important;
    color: white !important;
}

.custom-header {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 10px;
    text-align: center;
    margin-bottom: 20px;
}
EOF

    # Custom JavaScript for additional functionality
    cat > "$NETDATA_CONFIG_DIR/web/custom/custom.js" << 'EOF'
// Custom Netdata JavaScript
document.addEventListener('DOMContentLoaded', function() {
    // Add custom header
    const header = document.createElement('div');
    header.className = 'custom-header';
    header.innerHTML = '<h2>System Monitoring Dashboard</h2><p>Real-time performance metrics</p>';
    document.body.insertBefore(header, document.body.firstChild);
    
    // Add timestamp to title
    setInterval(function() {
        document.title = 'Netdata - ' + new Date().toLocaleTimeString();
    }, 1000);
});
EOF

    chown -R netdata:netdata "$NETDATA_CONFIG_DIR/web/custom"
    
    log "Web interface customization configured"
}

# Apply all configurations
apply_configurations() {
    log "Applying all configurations..."
    
    # Restart Netdata to apply changes
    systemctl restart netdata
    
    # Wait for service to start
    sleep 10
    
    if systemctl is-active --quiet netdata; then
        log "Netdata restarted successfully with new configurations"
    else
        error "Failed to restart Netdata with new configurations"
    fi
}

# Verify configuration
verify_configuration() {
    log "Verifying configuration..."
    
    # Check if custom charts are loaded
    if curl -s "http://localhost:19999/api/v1/charts" | grep -q "custom.system_health"; then
        log "✓ Custom charts are loaded"
    else
        warn "✗ Custom charts may not be loaded"
    fi
    
    # Check if alerts are configured
    if curl -s "http://localhost:19999/api/v1/alarms" | grep -q "advanced_alerts"; then
        log "✓ Advanced alerts are configured"
    else
        warn "✗ Advanced alerts may not be configured"
    fi
    
    # Display configuration summary
    info "Configuration Summary:"
    info "- Advanced CPU monitoring: Enabled"
    info "- Network monitoring: Enabled"
    info "- Application monitoring: Enabled"
    info "- Custom charts: Enabled"
    info "- Advanced alerting: Enabled"
    info "- Custom notifications: Enabled"
    info "- Web interface customization: Enabled"
}

# Main configuration function
main() {
    log "Starting advanced Netdata configuration..."
    
    check_netdata
    setup_custom_configs
    configure_cpu_monitoring
    configure_network_monitoring
    configure_app_monitoring
    configure_custom_charts
    configure_advanced_alerts
    configure_notifications
    configure_web_interface
    apply_configurations
    verify_configuration
    
    log "Advanced Netdata configuration completed successfully!"
    log "Access the enhanced dashboard at: http://localhost:19999"
}

# Display usage
usage() {
    echo "Usage: $0"
    echo ""
    echo "This script configures advanced monitoring features for Netdata:"
    echo "- Advanced CPU and network monitoring"
    echo "- Application-specific monitoring"
    echo "- Custom charts and metrics"
    echo "- Advanced alerting rules"
    echo "- Custom notification methods"
    echo "- Web interface customization"
    echo ""
    echo "Requirements:"
    echo "- Netdata must be installed and running"
    echo "- Root privileges required"
    exit 1
}

# Parse arguments
if [[ $# -gt 0 ]] && [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root"
fi

# Run main function
main "$@"