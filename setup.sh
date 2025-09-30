#!/bin/bash

# Enhanced Netdata Monitoring Setup Script
# Supports multiple Linux distributions with comprehensive configuration

set -euo pipefail

# Configuration variables
NETDATA_VERSION="latest"
NETDATA_CONFIG_DIR="/etc/netdata"
NETDATA_USER="netdata"
LOG_FILE="/var/log/netdata-setup.log"
BACKUP_DIR="/opt/netdata-backup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
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

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
}

# Detect Linux distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    else
        error "Cannot detect Linux distribution"
    fi
    log "Detected distribution: $DISTRO $VERSION"
}

# Install dependencies based on distribution
install_dependencies() {
    log "Installing dependencies for $DISTRO..."
    
    case $DISTRO in
        ubuntu|debian)
            apt-get update
            apt-get install -y curl wget gnupg2 software-properties-common \
                build-essential autoconf automake pkg-config zlib1g-dev \
                uuid-dev libuv1-dev liblz4-dev libjudy-dev libssl-dev \
                libelf-dev libmnl-dev libprotobuf-dev protobuf-compiler \
                git cmake python3 python3-pip
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                dnf install -y curl wget gnupg2 gcc gcc-c++ make autoconf \
                    automake pkgconfig zlib-devel libuuid-devel libuv-devel \
                    lz4-devel Judy-devel openssl-devel elfutils-libelf-devel \
                    libmnl-devel protobuf-devel protobuf-compiler git cmake \
                    python3 python3-pip
            else
                yum install -y curl wget gnupg2 gcc gcc-c++ make autoconf \
                    automake pkgconfig zlib-devel libuuid-devel lz4-devel \
                    Judy-devel openssl-devel elfutils-libelf-devel libmnl-devel \
                    git cmake python3 python3-pip
            fi
            ;;
        *)
            warn "Unsupported distribution: $DISTRO. Attempting generic installation..."
            ;;
    esac
}

# Create backup directory
create_backup_dir() {
    mkdir -p "$BACKUP_DIR"
    log "Created backup directory: $BACKUP_DIR"
}

# Install Netdata
install_netdata() {
    log "Installing Netdata..."
    
    # Download and run the official installer
    bash <(curl -Ss https://my-netdata.io/kickstart.sh) --stable-channel --disable-telemetry
    
    # Verify installation
    if systemctl is-active --quiet netdata; then
        log "Netdata installed and running successfully"
    else
        error "Netdata installation failed"
    fi
}

# Configure Netdata
configure_netdata() {
    log "Configuring Netdata..."
    
    # Backup original configuration
    if [[ -f "$NETDATA_CONFIG_DIR/netdata.conf" ]]; then
        cp "$NETDATA_CONFIG_DIR/netdata.conf" "$BACKUP_DIR/netdata.conf.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Generate default configuration
    /usr/sbin/netdata -W set 2>/dev/null || true
    
    # Custom configuration
    cat > "$NETDATA_CONFIG_DIR/netdata.conf" << 'EOF'
[global]
    run as user = netdata
    web files owner = root
    web files group = netdata
    bind socket to IP = 0.0.0.0
    default port = 19999
    disconnect idle clients after seconds = 60
    enable web responses gzip compression = yes
    
[web]
    web files owner = root
    web files group = netdata
    respect do not track policy = yes
    allow connections from = localhost 10.* 192.168.* 172.16.* 172.17.* 172.18.* 172.19.* 172.20.* 172.21.* 172.22.* 172.23.* 172.24.* 172.25.* 172.26.* 172.27.* 172.28.* 172.29.* 172.30.* 172.31.*
    
[plugins]
    cgroups = yes
    tc = yes
    idlejitter = yes
    proc = yes
    diskspace = yes
    
[plugin:proc]
    /proc/net/dev = yes
    /proc/diskstats = yes
    /proc/net/sockstat = yes
    /proc/net/netstat = yes
    /proc/net/stat/conntrack = yes
    /proc/net/ip_vs/stats = yes
    /proc/stat = yes
    /proc/meminfo = yes
    /proc/vmstat = yes
    /proc/net/rpc/nfsd = yes
    /proc/sys/kernel/random/entropy_avail = yes
    /proc/interrupts = yes
    /proc/softirqs = yes
    /proc/loadavg = yes
    /proc/sys/fs/file-nr = yes
EOF

    # Set proper permissions
    chown -R netdata:netdata "$NETDATA_CONFIG_DIR"
    chmod 755 "$NETDATA_CONFIG_DIR"
    chmod 644 "$NETDATA_CONFIG_DIR/netdata.conf"
}

# Configure health alerts
configure_alerts() {
    log "Configuring health alerts..."
    
    # Create custom health configuration
    cat > "$NETDATA_CONFIG_DIR/health.d/custom_alerts.conf" << 'EOF'
# Custom CPU usage alert
template: cpu_usage_high
      on: system.cpu
   class: Utilization
    type: System
component: CPU
    calc: $user + $system + $nice + $iowait
   units: %
   every: 10s
    warn: $this > 75
    crit: $this > 90
   delay: down 15m multiplier 1.5 max 1h
    info: CPU utilization is high
      to: sysadmin

# Memory usage alert
template: memory_usage_high
      on: system.ram
   class: Utilization
    type: System
component: Memory
    calc: ($used - $buffers - $cached) * 100 / $used
   units: %
   every: 10s
    warn: $this > 80
    crit: $this > 95
   delay: down 15m multiplier 1.5 max 1h
    info: Memory utilization is high
      to: sysadmin

# Disk space alert
template: disk_space_usage
      on: disk.space
   class: Utilization
    type: System
component: Disk
    calc: $used * 100 / ($avail + $used)
   units: %
   every: 1m
    warn: $this > 80
    crit: $this > 95
   delay: up 1m down 15m multiplier 1.5 max 1h
    info: Disk space utilization is high
      to: sysadmin

# Load average alert
template: load_average_high
      on: system.load
   class: Utilization
    type: System
component: Load
    calc: $load15
   units: load
   every: 10s
    warn: $this > (($system.cpu.processors) * 1.5)
    crit: $this > (($system.cpu.processors) * 2.0)
   delay: down 15m multiplier 1.5 max 1h
    info: System load average is high
      to: sysadmin
EOF

    chown netdata:netdata "$NETDATA_CONFIG_DIR/health.d/custom_alerts.conf"
    chmod 644 "$NETDATA_CONFIG_DIR/health.d/custom_alerts.conf"
}

# Configure firewall
configure_firewall() {
    log "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw allow 19999/tcp
        log "UFW firewall rule added for port 19999"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=19999/tcp
        firewall-cmd --reload
        log "Firewalld rule added for port 19999"
    else
        warn "No supported firewall found. Please manually open port 19999"
    fi
}

# Start and enable Netdata service
start_netdata() {
    log "Starting and enabling Netdata service..."
    
    systemctl daemon-reload
    systemctl enable netdata
    systemctl restart netdata
    
    # Wait for service to start
    sleep 5
    
    if systemctl is-active --quiet netdata; then
        log "Netdata service is running"
    else
        error "Failed to start Netdata service"
    fi
}

# Verify installation
verify_installation() {
    log "Verifying Netdata installation..."
    
    # Check if service is running
    if ! systemctl is-active --quiet netdata; then
        error "Netdata service is not running"
    fi
    
    # Check if web interface is accessible
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:19999 | grep -q "200"; then
        log "Netdata web interface is accessible at http://localhost:19999"
    else
        warn "Netdata web interface may not be accessible"
    fi
    
    # Display system information
    info "System Information:"
    info "- Netdata version: $(netdata -v 2>/dev/null | head -1 || echo 'Unknown')"
    info "- Configuration directory: $NETDATA_CONFIG_DIR"
    info "- Log file: /var/log/netdata/error.log"
    info "- Web interface: http://$(hostname -I | awk '{print $1}'):19999"
}

# Main installation function
main() {
    log "Starting enhanced Netdata installation..."
    
    check_root
    detect_distro
    create_backup_dir
    install_dependencies
    install_netdata
    configure_netdata
    configure_alerts
    configure_firewall
    start_netdata
    verify_installation
    
    log "Netdata installation completed successfully!"
    log "Access the dashboard at: http://$(hostname -I | awk '{print $1}'):19999"
    log "Setup log saved to: $LOG_FILE"
}

# Run main function
main "$@"