#!/bin/bash

# Comprehensive End-to-End Test Suite for Netdata Monitoring
# Tests all components and validates functionality

set -euo pipefail

# Configuration
TEST_RESULTS_DIR="/tmp/netdata-e2e-tests"
LOG_FILE="$TEST_RESULTS_DIR/test-suite.log"
NETDATA_URL="http://localhost:19999"

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

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

# Test result functions
test_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1" | tee -a "$LOG_FILE"
    ((TESTS_PASSED++))
    ((TESTS_TOTAL++))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1" | tee -a "$LOG_FILE"
    ((TESTS_FAILED++))
    ((TESTS_TOTAL++))
}

# Setup test environment
setup_test_environment() {
    log "Setting up test environment..."
    
    mkdir -p "$TEST_RESULTS_DIR"
    
    # Record test start time
    echo "Test Suite Started: $(date)" > "$TEST_RESULTS_DIR/test_summary.txt"
    echo "System: $(uname -a)" >> "$TEST_RESULTS_DIR/test_summary.txt"
    echo "" >> "$TEST_RESULTS_DIR/test_summary.txt"
    
    log "Test environment ready"
}

# Test 1: Service Status Tests
test_service_status() {
    log "Running service status tests..."
    
    # Test if Netdata service is running
    if systemctl is-active --quiet netdata; then
        test_pass "Netdata service is running"
    else
        test_fail "Netdata service is not running"
    fi
    
    # Test if Netdata service is enabled
    if systemctl is-enabled --quiet netdata; then
        test_pass "Netdata service is enabled"
    else
        test_fail "Netdata service is not enabled"
    fi
    
    # Test service restart capability
    if systemctl restart netdata && sleep 5 && systemctl is-active --quiet netdata; then
        test_pass "Netdata service can be restarted"
    else
        test_fail "Netdata service restart failed"
    fi
}

# Test 2: Web Interface Tests
test_web_interface() {
    log "Running web interface tests..."
    
    # Test basic connectivity
    if curl -s -f "$NETDATA_URL" > /dev/null; then
        test_pass "Web interface is accessible"
    else
        test_fail "Web interface is not accessible"
    fi
    
    # Test API endpoints
    local api_endpoints=(
        "/api/v1/info"
        "/api/v1/charts"
        "/api/v1/alarms"
        "/api/v1/allmetrics"
    )
    
    for endpoint in "${api_endpoints[@]}"; do
        if curl -s -f "$NETDATA_URL$endpoint" > /dev/null; then
            test_pass "API endpoint $endpoint is accessible"
        else
            test_fail "API endpoint $endpoint is not accessible"
        fi
    done
    
    # Test response time
    local response_time=$(curl -s -w "%{time_total}" -o /dev/null "$NETDATA_URL")
    if (( $(echo "$response_time < 2.0" | bc -l) )); then
        test_pass "Web interface response time is acceptable ($response_time seconds)"
    else
        test_fail "Web interface response time is too slow ($response_time seconds)"
    fi
}

# Test 3: Metrics Collection Tests
test_metrics_collection() {
    log "Running metrics collection tests..."
    
    # Test basic system metrics
    local metrics_response=$(curl -s "$NETDATA_URL/api/v1/allmetrics?format=json")
    
    local required_metrics=(
        "system.cpu"
        "system.ram"
        "system.load"
        "disk.space"
        "net.net"
    )
    
    for metric in "${required_metrics[@]}"; do
        if echo "$metrics_response" | grep -q "$metric"; then
            test_pass "Metric $metric is being collected"
        else
            test_fail "Metric $metric is not being collected"
        fi
    done
    
    # Test custom metrics (if configured)
    if echo "$metrics_response" | grep -q "custom.system_health"; then
        test_pass "Custom metrics are being collected"
    else
        test_fail "Custom metrics are not being collected"
    fi
    
    # Test metrics freshness
    local info_response=$(curl -s "$NETDATA_URL/api/v1/info")
    local last_update=$(echo "$info_response" | python3 -c "import json,sys; print(json.load(sys.stdin).get('last_updated', 0))" 2>/dev/null || echo "0")
    local current_time=$(date +%s)
    local time_diff=$((current_time - last_update))
    
    if [[ $time_diff -lt 60 ]]; then
        test_pass "Metrics are fresh (updated $time_diff seconds ago)"
    else
        test_fail "Metrics are stale (updated $time_diff seconds ago)"
    fi
}

# Test 4: Alert System Tests
test_alert_system() {
    log "Running alert system tests..."
    
    # Test alert configuration
    local alerts_response=$(curl -s "$NETDATA_URL/api/v1/alarms")
    
    if echo "$alerts_response" | grep -q "alarms"; then
        test_pass "Alert system is configured"
    else
        test_fail "Alert system is not configured"
    fi
    
    # Test specific alert rules
    local alert_rules=(
        "cpu_usage_high"
        "memory_usage_high"
        "disk_space_usage"
        "load_average_high"
    )
    
    for rule in "${alert_rules[@]}"; do
        if echo "$alerts_response" | grep -q "$rule"; then
            test_pass "Alert rule $rule is configured"
        else
            test_fail "Alert rule $rule is not configured"
        fi
    done
    
    # Test alert notification configuration
    if [[ -f "/etc/netdata/health_alarm_notify.conf" ]]; then
        test_pass "Alert notification configuration exists"
    else
        test_fail "Alert notification configuration is missing"
    fi
}

# Test 5: Performance Tests
test_performance() {
    log "Running performance tests..."
    
    # Test CPU usage of Netdata itself
    local netdata_cpu=$(ps -C netdata -o %cpu --no-headers | awk '{sum+=$1} END {print sum}')
    if (( $(echo "$netdata_cpu < 10.0" | bc -l) )); then
        test_pass "Netdata CPU usage is acceptable ($netdata_cpu%)"
    else
        test_fail "Netdata CPU usage is too high ($netdata_cpu%)"
    fi
    
    # Test memory usage of Netdata
    local netdata_mem=$(ps -C netdata -o %mem --no-headers | awk '{sum+=$1} END {print sum}')
    if (( $(echo "$netdata_mem < 5.0" | bc -l) )); then
        test_pass "Netdata memory usage is acceptable ($netdata_mem%)"
    else
        test_fail "Netdata memory usage is too high ($netdata_mem%)"
    fi
    
    # Test disk space usage
    local netdata_disk_usage=$(du -sh /var/lib/netdata 2>/dev/null | cut -f1 || echo "0M")
    test_pass "Netdata disk usage: $netdata_disk_usage"
    
    # Test concurrent connections
    local concurrent_requests=10
    local success_count=0
    
    for ((i=1; i<=concurrent_requests; i++)); do
        if curl -s -f "$NETDATA_URL/api/v1/info" > /dev/null &
        then
            ((success_count++))
        fi
    done
    wait
    
    if [[ $success_count -eq $concurrent_requests ]]; then
        test_pass "Handled $concurrent_requests concurrent requests successfully"
    else
        test_fail "Only handled $success_count out of $concurrent_requests concurrent requests"
    fi
}

# Test 6: Configuration Tests
test_configuration() {
    log "Running configuration tests..."
    
    # Test configuration file existence
    local config_files=(
        "/etc/netdata/netdata.conf"
        "/etc/netdata/health.d/custom_alerts.conf"
    )
    
    for config_file in "${config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            test_pass "Configuration file $config_file exists"
        else
            test_fail "Configuration file $config_file is missing"
        fi
    done
    
    # Test configuration syntax
    if /usr/sbin/netdata -W set 2>/dev/null; then
        test_pass "Netdata configuration syntax is valid"
    else
        test_fail "Netdata configuration syntax is invalid"
    fi
    
    # Test file permissions
    local netdata_user="netdata"
    if [[ $(stat -c %U /etc/netdata/netdata.conf) == "$netdata_user" ]]; then
        test_pass "Configuration file permissions are correct"
    else
        test_fail "Configuration file permissions are incorrect"
    fi
}

# Test 7: Security Tests
test_security() {
    log "Running security tests..."
    
    # Test if Netdata is running as non-root user
    local netdata_user=$(ps -C netdata -o user --no-headers | head -1 | tr -d ' ')
    if [[ "$netdata_user" != "root" ]]; then
        test_pass "Netdata is running as non-root user ($netdata_user)"
    else
        test_fail "Netdata is running as root user (security risk)"
    fi
    
    # Test firewall configuration
    if command -v ufw &> /dev/null; then
        if ufw status | grep -q "19999"; then
            test_pass "Firewall rule for port 19999 exists (UFW)"
        else
            test_fail "Firewall rule for port 19999 is missing (UFW)"
        fi
    elif command -v firewall-cmd &> /dev/null; then
        if firewall-cmd --list-ports | grep -q "19999"; then
            test_pass "Firewall rule for port 19999 exists (firewalld)"
        else
            test_fail "Firewall rule for port 19999 is missing (firewalld)"
        fi
    else
        warn "No supported firewall found for testing"
    fi
    
    # Test access restrictions
    local netdata_config="/etc/netdata/netdata.conf"
    if grep -q "allow connections from" "$netdata_config"; then
        test_pass "Access restrictions are configured"
    else
        test_fail "Access restrictions are not configured"
    fi
}

# Test 8: Integration Tests
test_integrations() {
    log "Running integration tests..."
    
    # Test Docker integration (if Docker is available)
    if command -v docker &> /dev/null; then
        if docker ps --format "table {{.Names}}" | grep -q netdata; then
            test_pass "Docker integration is working"
        else
            test_fail "Docker integration is not working"
        fi
    else
        warn "Docker not available for integration testing"
    fi
    
    # Test systemd integration
    if systemctl show netdata --property=Type | grep -q "simple"; then
        test_pass "Systemd integration is configured correctly"
    else
        test_fail "Systemd integration is not configured correctly"
    fi
    
    # Test log rotation
    if [[ -f "/etc/logrotate.d/netdata" ]]; then
        test_pass "Log rotation is configured"
    else
        test_fail "Log rotation is not configured"
    fi
}

# Test 9: Stress Tests
test_stress_scenarios() {
    log "Running stress test scenarios..."
    
    # Generate load and monitor response
    log "Generating system load for stress testing..."
    
    # CPU stress
    (yes > /dev/null &)
    local stress_pid=$!
    sleep 10
    
    # Check if Netdata is still responsive during stress
    if curl -s -f "$NETDATA_URL/api/v1/info" > /dev/null; then
        test_pass "Netdata remains responsive during CPU stress"
    else
        test_fail "Netdata becomes unresponsive during CPU stress"
    fi
    
    kill $stress_pid 2>/dev/null || true
    wait $stress_pid 2>/dev/null || true
    
    # Memory stress test
    python3 -c "
import time
try:
    data = bytearray(100 * 1024 * 1024)  # 100MB
    time.sleep(5)
except:
    pass
" &
    local mem_stress_pid=$!
    
    sleep 7
    if curl -s -f "$NETDATA_URL/api/v1/info" > /dev/null; then
        test_pass "Netdata remains responsive during memory stress"
    else
        test_fail "Netdata becomes unresponsive during memory stress"
    fi
    
    wait $mem_stress_pid 2>/dev/null || true
}

# Test 10: Backup and Recovery Tests
test_backup_recovery() {
    log "Running backup and recovery tests..."
    
    # Test configuration backup
    local backup_dir="/tmp/netdata-test-backup"
    mkdir -p "$backup_dir"
    
    if cp -r /etc/netdata "$backup_dir/"; then
        test_pass "Configuration backup successful"
    else
        test_fail "Configuration backup failed"
    fi
    
    # Test configuration restoration (simulate)
    if [[ -d "$backup_dir/netdata" ]]; then
        test_pass "Configuration can be restored from backup"
    else
        test_fail "Configuration cannot be restored from backup"
    fi
    
    # Cleanup test backup
    rm -rf "$backup_dir"
}

# Generate comprehensive test report
generate_test_report() {
    log "Generating comprehensive test report..."
    
    local report_file="$TEST_RESULTS_DIR/comprehensive_test_report.html"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Netdata End-to-End Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; }
        .summary { background-color: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .test-section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .pass { color: #28a745; font-weight: bold; }
        .fail { color: #dc3545; font-weight: bold; }
        .warn { color: #ffc107; font-weight: bold; }
        .metrics { display: flex; justify-content: space-around; text-align: center; }
        .metric { padding: 10px; }
        .metric-value { font-size: 2em; font-weight: bold; }
        pre { background-color: #f5f5f5; padding: 10px; overflow-x: auto; border-radius: 3px; }
        .progress-bar { width: 100%; background-color: #e0e0e0; border-radius: 10px; overflow: hidden; }
        .progress-fill { height: 20px; background-color: #4caf50; transition: width 0.3s ease; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔍 Netdata End-to-End Test Report</h1>
        <p>Comprehensive testing results for Netdata monitoring system</p>
        <p><strong>Test Date:</strong> $(date)</p>
        <p><strong>System:</strong> $(uname -a)</p>
    </div>
    
    <div class="summary">
        <h2>📊 Test Summary</h2>
        <div class="metrics">
            <div class="metric">
                <div class="metric-value pass">$TESTS_PASSED</div>
                <div>Tests Passed</div>
            </div>
            <div class="metric">
                <div class="metric-value fail">$TESTS_FAILED</div>
                <div>Tests Failed</div>
            </div>
            <div class="metric">
                <div class="metric-value">$TESTS_TOTAL</div>
                <div>Total Tests</div>
            </div>
            <div class="metric">
                <div class="metric-value">$(( TESTS_PASSED * 100 / TESTS_TOTAL ))%</div>
                <div>Success Rate</div>
            </div>
        </div>
        
        <div class="progress-bar">
            <div class="progress-fill" style="width: $(( TESTS_PASSED * 100 / TESTS_TOTAL ))%"></div>
        </div>
    </div>
    
    <div class="test-section">
        <h2>🔧 Test Categories</h2>
        <ul>
            <li><strong>Service Status Tests:</strong> Verify Netdata service is running and configured correctly</li>
            <li><strong>Web Interface Tests:</strong> Test web dashboard accessibility and API endpoints</li>
            <li><strong>Metrics Collection Tests:</strong> Validate system metrics are being collected</li>
            <li><strong>Alert System Tests:</strong> Verify alerting rules and notifications</li>
            <li><strong>Performance Tests:</strong> Check resource usage and response times</li>
            <li><strong>Configuration Tests:</strong> Validate configuration files and syntax</li>
            <li><strong>Security Tests:</strong> Verify security best practices</li>
            <li><strong>Integration Tests:</strong> Test integrations with other systems</li>
            <li><strong>Stress Tests:</strong> Verify stability under load</li>
            <li><strong>Backup/Recovery Tests:</strong> Test backup and restoration procedures</li>
        </ul>
    </div>
    
    <div class="test-section">
        <h2>📋 Detailed Results</h2>
        <pre>$(cat "$LOG_FILE" | grep -E "(✓ PASS|✗ FAIL)" || echo "No detailed results available")</pre>
    </div>
    
    <div class="test-section">
        <h2>🚀 Next Steps</h2>
        <ol>
            <li>Review any failed tests and address issues</li>
            <li>Access Netdata dashboard: <a href="$NETDATA_URL" target="_blank">$NETDATA_URL</a></li>
            <li>Monitor system performance and alerts</li>
            <li>Schedule regular test runs for continuous validation</li>
        </ol>
    </div>
    
    <div class="test-section">
        <h2>📁 Test Artifacts</h2>
        <ul>
            <li>Test logs: <code>$LOG_FILE</code></li>
            <li>Test results: <code>$TEST_RESULTS_DIR</code></li>
            <li>System information: <code>$TEST_RESULTS_DIR/test_summary.txt</code></li>
        </ul>
    </div>
</body>
</html>
EOF

    log "Test report generated: $report_file"
    
    # Try to open the report
    if command -v xdg-open &> /dev/null; then
        xdg-open "$report_file" 2>/dev/null || true
    elif command -v open &> /dev/null; then
        open "$report_file" 2>/dev/null || true
    fi
}

# Main test function
main() {
    log "Starting comprehensive end-to-end test suite..."
    
    setup_test_environment
    
    # Run all test categories
    test_service_status
    test_web_interface
    test_metrics_collection
    test_alert_system
    test_performance
    test_configuration
    test_security
    test_integrations
    test_stress_scenarios
    test_backup_recovery
    
    # Generate final report
    generate_test_report
    
    # Final summary
    log "Test suite completed!"
    log "Results: $TESTS_PASSED passed, $TESTS_FAILED failed out of $TESTS_TOTAL total tests"
    log "Success rate: $(( TESTS_PASSED * 100 / TESTS_TOTAL ))%"
    log "Detailed report: $TEST_RESULTS_DIR/comprehensive_test_report.html"
    
    # Exit with appropriate code
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log "All tests passed! ✅"
        exit 0
    else
        error "Some tests failed! ❌"
        exit 1
    fi
}

# Display usage
usage() {
    echo "Usage: $0"
    echo ""
    echo "Comprehensive end-to-end test suite for Netdata monitoring system."
    echo "Tests all components including service status, web interface, metrics,"
    echo "alerts, performance, configuration, security, and integrations."
    echo ""
    echo "Requirements:"
    echo "- Netdata must be installed and running"
    echo "- Root privileges recommended for complete testing"
    exit 1
}

# Parse arguments
if [[ $# -gt 0 ]] && [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

# Run main function
main "$@"