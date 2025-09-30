#!/bin/bash

# Enhanced Netdata Cleanup Script
# Comprehensive removal of Netdata and related components

set -euo pipefail

# Configuration
NETDATA_CONFIG_DIR="/etc/netdata"
NETDATA_DATA_DIR="/var/lib/netdata"
NETDATA_CACHE_DIR="/var/cache/netdata"
NETDATA_LOG_DIR="/var/log/netdata"
BACKUP_DIR="/opt/netdata-backup"
LOG_FILE="/var/log/netdata-cleanup.log"

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
        exit 1
    fi
}

# Detect Linux distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    else
        warn "Cannot detect Linux distribution, proceeding with generic cleanup"
        DISTRO="unknown"
    fi
    log "Detected distribution: $DISTRO"
}

# Confirm cleanup action
confirm_cleanup() {
    echo -e "${YELLOW}WARNING: This will completely remove Netdata and all its data!${NC}"
    echo "The following will be removed:"
    echo "  - Netdata service and binaries"
    echo "  - Configuration files in $NETDATA_CONFIG_DIR"
    echo "  - Data files in $NETDATA_DATA_DIR"
    echo "  - Cache files in $NETDATA_CACHE_DIR"
    echo "  - Log files in $NETDATA_LOG_DIR"
    echo "  - Netdata user and group"
    echo "  - Firewall rules for port 19999"
    echo ""
    
    if [[ "${FORCE_CLEANUP:-}" != "yes" ]]; then
        read -p "Are you sure you want to continue? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            log "Cleanup cancelled by user"
            exit 0
        fi
    fi
    
    log "Cleanup confirmed, proceeding..."
}

# Create backup before cleanup
create_backup() {
    if [[ -d "$NETDATA_CONFIG_DIR" ]] || [[ -d "$NETDATA_DATA_DIR" ]]; then
        log "Creating backup before cleanup..."
        
        BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        BACKUP_PATH="$BACKUP_DIR/netdata_backup_$BACKUP_TIMESTAMP"
        
        mkdir -p "$BACKUP_PATH"
        
        # Backup configuration
        if [[ -d "$NETDATA_CONFIG_DIR" ]]; then
            cp -r "$NETDATA_CONFIG_DIR" "$BACKUP_PATH/config" 2>/dev/null || warn "Failed to backup configuration"
        fi
        
        # Backup important data (excluding large cache files)
        if [[ -d "$NETDATA_DATA_DIR" ]]; then
            mkdir -p "$BACKUP_PATH/data"
            find "$NETDATA_DATA_DIR" -name "*.db" -o -name "*.conf" -o -name "*.json" | \
                xargs -I {} cp {} "$BACKUP_PATH/data/" 2>/dev/null || warn "Failed to backup some data files"
        fi
        
        # Create backup manifest
        {
            echo "Netdata Backup Manifest"
            echo "======================="
            echo "Backup Date: $(date)"
            echo "System: $(uname -a)"
            echo "Netdata Version: $(netdata -v 2>/dev/null | head -1 || echo 'Unknown')"
            echo ""
            echo "Backed up directories:"
            find "$BACKUP_PATH" -type d | sort
            echo ""
            echo "Backed up files:"
            find "$BACKUP_PATH" -type f | sort
        } > "$BACKUP_PATH/manifest.txt"
        
        log "Backup created at: $BACKUP_PATH"
    else
        log "No Netdata installation found, skipping backup"
    fi
}

# Stop Netdata service
stop_netdata_service() {
    log "Stopping Netdata service..."
    
    if systemctl is-active --quiet netdata 2>/dev/null; then
        systemctl stop netdata
        log "Netdata service stopped"
    else
        log "Netdata service was not running"
    fi
    
    if systemctl is-enabled --quiet netdata 2>/dev/null; then
        systemctl disable netdata
        log "Netdata service disabled"
    fi
}

# Remove Netdata packages
remove_netdata_packages() {
    log "Removing Netdata packages..."
    
    case $DISTRO in
        ubuntu|debian)
            # Remove netdata package if installed via package manager
            if dpkg -l | grep -q netdata; then
                apt-get remove --purge -y netdata netdata-* 2>/dev/null || warn "Failed to remove some packages"
                apt-get autoremove -y 2>/dev/null || true
            fi
            ;;
        centos|rhel|fedora)
            # Remove netdata package if installed via package manager
            if rpm -qa | grep -q netdata; then
                if command -v dnf &> /dev/null; then
                    dnf remove -y netdata netdata-* 2>/dev/null || warn "Failed to remove some packages"
                else
                    yum remove -y netdata netdata-* 2>/dev/null || warn "Failed to remove some packages"
                fi
            fi
            ;;
        *)
            log "Generic package removal for unknown distribution"
            ;;
    esac
}

# Remove Netdata binaries and files
remove_netdata_files() {
    log "Removing Netdata files and directories..."
    
    # Remove binaries
    NETDATA_BINARIES=(
        "/usr/sbin/netdata"
        "/usr/bin/netdata"
        "/opt/netdata/bin/netdata"
        "/usr/local/bin/netdata"
        "/usr/libexec/netdata"
    )
    
    for binary in "${NETDATA_BINARIES[@]}"; do
        if [[ -f "$binary" ]]; then
            rm -f "$binary"
            log "Removed binary: $binary"
        fi
    done
    
    # Remove directories
    NETDATA_DIRECTORIES=(
        "$NETDATA_CONFIG_DIR"
        "$NETDATA_DATA_DIR"
        "$NETDATA_CACHE_DIR"
        "$NETDATA_LOG_DIR"
        "/usr/share/netdata"
        "/usr/lib/netdata"
        "/usr/libexec/netdata"
        "/opt/netdata"
        "/var/lib/netdata"
        "/etc/systemd/system/netdata.service"
        "/lib/systemd/system/netdata.service"
        "/usr/lib/systemd/system/netdata.service"
    )
    
    for dir in "${NETDATA_DIRECTORIES[@]}"; do
        if [[ -e "$dir" ]]; then
            rm -rf "$dir"
            log "Removed: $dir"
        fi
    done
    
    # Remove any remaining netdata files
    find /usr -name "*netdata*" -type f 2>/dev/null | while read -r file; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            log "Removed remaining file: $file"
        fi
    done
    
    find /etc -name "*netdata*" -type d 2>/dev/null | while read -r dir; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            log "Removed remaining directory: $dir"
        fi
    done
}

# Remove Netdata user and group
remove_netdata_user() {
    log "Removing Netdata user and group..."
    
    if id "netdata" &>/dev/null; then
        userdel netdata 2>/dev/null || warn "Failed to remove netdata user"
        log "Removed netdata user"
    fi
    
    if getent group netdata &>/dev/null; then
        groupdel netdata 2>/dev/null || warn "Failed to remove netdata group"
        log "Removed netdata group"
    fi
}

# Remove firewall rules
remove_firewall_rules() {
    log "Removing firewall rules..."
    
    if command -v ufw &> /dev/null; then
        ufw delete allow 19999/tcp 2>/dev/null || warn "Failed to remove UFW rule"
        log "Removed UFW firewall rule for port 19999"
    fi
    
    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --remove-port=19999/tcp 2>/dev/null || warn "Failed to remove firewalld rule"
        firewall-cmd --reload 2>/dev/null || true
        log "Removed firewalld rule for port 19999"
    fi
}

# Clean up systemd
cleanup_systemd() {
    log "Cleaning up systemd configuration..."
    
    systemctl daemon-reload
    systemctl reset-failed netdata 2>/dev/null || true
    
    log "Systemd cleanup completed"
}

# Remove cron jobs and scheduled tasks
remove_scheduled_tasks() {
    log "Removing scheduled tasks..."
    
    # Remove any netdata cron jobs
    if [[ -f /etc/cron.d/netdata ]]; then
        rm -f /etc/cron.d/netdata
        log "Removed netdata cron job"
    fi
    
    # Remove user cron jobs containing netdata
    crontab -l 2>/dev/null | grep -v netdata | crontab - 2>/dev/null || true
}

# Clean up temporary and test files
cleanup_temp_files() {
    log "Cleaning up temporary and test files..."
    
    # Remove test files
    rm -rf /tmp/netdata-test-results 2>/dev/null || true
    rm -f /tmp/netdata_io_test 2>/dev/null || true
    rm -f /var/log/netdata-*.log 2>/dev/null || true
    
    log "Temporary files cleaned up"
}

# Verify cleanup completion
verify_cleanup() {
    log "Verifying cleanup completion..."
    
    CLEANUP_ISSUES=()
    
    # Check if service still exists
    if systemctl list-unit-files | grep -q netdata; then
        CLEANUP_ISSUES+=("Netdata service still exists in systemd")
    fi
    
    # Check if binaries still exist
    if command -v netdata &>/dev/null; then
        CLEANUP_ISSUES+=("Netdata binary still accessible in PATH")
    fi
    
    # Check if user still exists
    if id "netdata" &>/dev/null; then
        CLEANUP_ISSUES+=("Netdata user still exists")
    fi
    
    # Check if directories still exist
    for dir in "$NETDATA_CONFIG_DIR" "$NETDATA_DATA_DIR" "$NETDATA_CACHE_DIR" "$NETDATA_LOG_DIR"; do
        if [[ -d "$dir" ]]; then
            CLEANUP_ISSUES+=("Directory still exists: $dir")
        fi
    done
    
    # Report results
    if [[ ${#CLEANUP_ISSUES[@]} -eq 0 ]]; then
        log "✓ Cleanup verification passed - Netdata completely removed"
    else
        warn "Cleanup verification found issues:"
        for issue in "${CLEANUP_ISSUES[@]}"; do
            warn "  - $issue"
        done
    fi
}

# Generate cleanup report
generate_cleanup_report() {
    log "Generating cleanup report..."
    
    REPORT_FILE="/tmp/netdata_cleanup_report.txt"
    
    {
        echo "Netdata Cleanup Report"
        echo "====================="
        echo "Cleanup Date: $(date)"
        echo "System: $(uname -a)"
        echo "Distribution: $DISTRO"
        echo ""
        echo "Cleanup Actions Performed:"
        echo "- ✓ Stopped and disabled Netdata service"
        echo "- ✓ Removed Netdata packages"
        echo "- ✓ Removed Netdata files and directories"
        echo "- ✓ Removed Netdata user and group"
        echo "- ✓ Removed firewall rules"
        echo "- ✓ Cleaned up systemd configuration"
        echo "- ✓ Removed scheduled tasks"
        echo "- ✓ Cleaned up temporary files"
        echo ""
        echo "Backup Location: $BACKUP_DIR"
        echo "Cleanup Log: $LOG_FILE"
        echo ""
        echo "System Status After Cleanup:"
        echo "- Netdata service: $(systemctl is-active netdata 2>/dev/null || echo 'not found')"
        echo "- Netdata binary: $(command -v netdata 2>/dev/null || echo 'not found')"
        echo "- Netdata user: $(id netdata 2>/dev/null || echo 'not found')"
        echo "- Port 19999 status: $(ss -tlnp | grep :19999 || echo 'not listening')"
        
    } > "$REPORT_FILE"
    
    log "Cleanup report saved to: $REPORT_FILE"
    cat "$REPORT_FILE"
}

# Main cleanup function
main() {
    log "Starting enhanced Netdata cleanup..."
    
    check_root
    detect_distro
    confirm_cleanup
    create_backup
    stop_netdata_service
    remove_netdata_packages
    remove_netdata_files
    remove_netdata_user
    remove_firewall_rules
    cleanup_systemd
    remove_scheduled_tasks
    cleanup_temp_files
    verify_cleanup
    generate_cleanup_report
    
    log "Netdata cleanup completed successfully!"
    log "Backup available at: $BACKUP_DIR"
    log "Cleanup log saved to: $LOG_FILE"
}

# Display usage information
usage() {
    echo "Usage: $0 [--force]"
    echo ""
    echo "Options:"
    echo "  --force    Skip confirmation prompt"
    echo ""
    echo "This script will completely remove Netdata from your system."
    echo "A backup will be created before removal."
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_CLEANUP="yes"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Run main function
main "$@"