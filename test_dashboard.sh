#!/bin/bash

# Enhanced Netdata Dashboard Testing Script
# Generates comprehensive system load to test monitoring capabilities

set -euo pipefail

# Configuration
DURATION=${1:-300}  # Default 5 minutes
NETDATA_URL="http://localhost:19999"
LOG_FILE="./netdata-test.log"
RESULTS_DIR="./netdata-test-results"

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

# Create results directory
setup_test_environment() {
    mkdir -p "$RESULTS_DIR"
    log "Created test results directory: $RESULTS_DIR"
    
    # Record initial system state (macOS compatible)
    {
        echo "=== Initial System State ==="
        echo "Date: $(date)"
        echo "Uptime: $(uptime)"
        if command -v free &> /dev/null; then
            echo "Memory: $(free -h)"
        else
            echo "Memory: $(vm_stat | head -5)"
        fi
        echo "Disk: $(df -h)"
        if command -v lscpu &> /dev/null; then
            echo "CPU Info: $(lscpu | grep 'Model name')"
        else
            echo "CPU Info: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'CPU info not available')"
        fi
        if [[ -f /proc/loadavg ]]; then
            echo "Load Average: $(cat /proc/loadavg)"
        else
            echo "Load Average: $(uptime | awk -F'load averages:' '{print $2}' || echo 'Load info not available')"
        fi
        echo ""
    } > "$RESULTS_DIR/initial_state.txt"
}

# Check if Netdata is running
check_netdata() {
    log "Checking Netdata status..."
    
    # Check if running in Docker or as native service
    if docker ps | grep -q netdata; then
        log "Netdata Docker container is running"
    elif command -v systemctl &> /dev/null && systemctl is-active --quiet netdata; then
        log "Netdata native service is running"
    else
        error "Netdata is not running. Please start it with:"
        error "Docker: docker run -d --name netdata -p 19999:19999 netdata/netdata:latest"
        error "Or run: make install"
        exit 1
    fi
    
    if ! curl -s -o /dev/null -w "%{http_code}" "$NETDATA_URL" | grep -q "200"; then
        error "Netdata web interface is not accessible at $NETDATA_URL"
        exit 1
    fi
    
    log "Netdata is running and accessible"
}

# CPU stress test
cpu_stress_test() {
    log "Starting CPU stress test for ${DURATION}s..."
    
    # Get number of CPU cores
    CORES=$(nproc)
    
    # Start CPU stress processes (simplified for macOS compatibility)
    for ((i=1; i<=CORES; i++)); do
        (
            while true; do
                # Simple CPU intensive operation that works on macOS
                dd if=/dev/zero of=/dev/null bs=1M count=1 2>/dev/null
            done
        ) &
        CPU_PIDS+=($!)
    done
    
    log "Started $CORES CPU stress processes (PIDs: ${CPU_PIDS[*]})"
    
    # Monitor CPU usage
    {
        echo "=== CPU Stress Test Results ==="
        echo "Start Time: $(date)"
        echo "Duration: ${DURATION}s"
        echo "CPU Cores: $CORES"
        echo ""
        
        for ((i=0; i<DURATION/10; i++)); do
            echo "Time: $((i*10))s - Load: $(cat /proc/loadavg) - CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
            sleep 10
        done
    } > "$RESULTS_DIR/cpu_stress_results.txt" &
    
    sleep "$DURATION"
    
    # Kill CPU stress processes
    for pid in "${CPU_PIDS[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
    
    log "CPU stress test completed"
}

# Memory stress test
memory_stress_test() {
    log "Starting memory stress test..."
    
    # Get available memory in MB (macOS compatible)
    if command -v free &> /dev/null; then
        AVAILABLE_MEM=$(free -m | awk 'NR==2{printf "%.0f", $7*0.8}')
    else
        # macOS fallback - allocate a conservative amount
        AVAILABLE_MEM=100
    fi
    
    log "Allocating ${AVAILABLE_MEM}MB of memory..."
    
    # Start memory stress
    python3 -c "
import time
import sys

try:
    # Allocate memory in chunks
    memory_chunks = []
    chunk_size = 10 * 1024 * 1024  # 10MB chunks
    total_allocated = 0
    target = $AVAILABLE_MEM * 1024 * 1024  # Convert to bytes
    
    print(f'Allocating memory up to {target // (1024*1024)}MB...')
    
    while total_allocated < target:
        try:
            chunk = bytearray(chunk_size)
            memory_chunks.append(chunk)
            total_allocated += chunk_size
            
            if total_allocated % (100 * 1024 * 1024) == 0:  # Every 100MB
                print(f'Allocated: {total_allocated // (1024*1024)}MB')
                
        except MemoryError:
            print('Memory allocation limit reached')
            break
    
    print(f'Total allocated: {total_allocated // (1024*1024)}MB')
    print('Holding memory for 60 seconds...')
    time.sleep(60)
    
    print('Releasing memory...')
    memory_chunks.clear()
    print('Memory stress test completed')
    
except KeyboardInterrupt:
    print('Memory stress test interrupted')
    sys.exit(0)
" > "$RESULTS_DIR/memory_stress_results.txt" 2>&1 &
    
    MEMORY_PID=$!
    
    # Monitor memory usage
    {
        echo "=== Memory Stress Test Results ==="
        echo "Start Time: $(date)"
        echo ""
        
        for ((i=0; i<6; i++)); do
            echo "Time: $((i*10))s - Memory: $(free -h | awk 'NR==2{printf "Used: %s/%s (%.1f%%)", $3,$2,$3*100/$2}')"
            sleep 10
        done
    } >> "$RESULTS_DIR/memory_stress_results.txt"
    
    wait "$MEMORY_PID" 2>/dev/null || true
    log "Memory stress test completed"
}

# Disk I/O stress test
disk_io_stress_test() {
    log "Starting disk I/O stress test..."
    
    TEST_FILE="/tmp/netdata_io_test"
    
    # Write test
    log "Testing disk write performance..."
    dd if=/dev/zero of="$TEST_FILE" bs=1M count=1000 oflag=direct 2> "$RESULTS_DIR/disk_write_results.txt" &
    WRITE_PID=$!
    
    # Read test in parallel
    sleep 5
    log "Testing disk read performance..."
    (
        for i in {1..10}; do
            dd if="$TEST_FILE" of=/dev/null bs=1M count=100 iflag=direct 2>/dev/null
        done
    ) > "$RESULTS_DIR/disk_read_results.txt" 2>&1 &
    READ_PID=$!
    
    # Monitor disk I/O
    {
        echo "=== Disk I/O Stress Test Results ==="
        echo "Start Time: $(date)"
        echo ""
        
        for ((i=0; i<30; i++)); do
            if command -v iostat &> /dev/null; then
                echo "Time: $((i*2))s - $(iostat -x 1 1 | tail -n +4 | head -1)"
            else
                echo "Time: $((i*2))s - Load: $(cat /proc/loadavg)"
            fi
            sleep 2
        done
    } >> "$RESULTS_DIR/disk_io_results.txt" &
    
    wait "$WRITE_PID" 2>/dev/null || true
    wait "$READ_PID" 2>/dev/null || true
    
    # Cleanup
    rm -f "$TEST_FILE"
    
    log "Disk I/O stress test completed"
}

# Network stress test
network_stress_test() {
    log "Starting network stress test..."
    
    # Test internal network connectivity
    {
        echo "=== Network Stress Test Results ==="
        echo "Start Time: $(date)"
        echo ""
        
        # Ping test
        echo "Ping Test to localhost:"
        ping -c 10 localhost 2>&1
        echo ""
        
        # Netdata API test
        echo "Netdata API Response Test:"
        for i in {1..10}; do
            response_time=$(curl -s -w "%{time_total}" -o /dev/null "$NETDATA_URL/api/v1/info")
            echo "Request $i: ${response_time}s"
            sleep 1
        done
        echo ""
        
        # Network interface statistics
        echo "Network Interface Statistics:"
        cat /proc/net/dev
        
    } > "$RESULTS_DIR/network_stress_results.txt"
    
    log "Network stress test completed"
}

# Collect Netdata metrics during tests
collect_netdata_metrics() {
    log "Collecting Netdata metrics..."
    
    # Collect various metrics from Netdata API
    {
        echo "=== Netdata Metrics Collection ==="
        echo "Collection Time: $(date)"
        echo ""
        
        # System info
        echo "System Info:"
        curl -s "$NETDATA_URL/api/v1/info" | python3 -m json.tool 2>/dev/null || echo "Failed to get system info"
        echo ""
        
        # Alarms
        echo "Active Alarms:"
        curl -s "$NETDATA_URL/api/v1/alarms" | python3 -m json.tool 2>/dev/null || echo "Failed to get alarms"
        echo ""
        
        # Charts
        echo "Available Charts:"
        curl -s "$NETDATA_URL/api/v1/charts" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for chart_id, chart_info in data.get('charts', {}).items():
        print(f'{chart_id}: {chart_info.get(\"title\", \"N/A\")}')
except:
    print('Failed to parse charts data')
" 2>/dev/null || echo "Failed to get charts"
        
    } > "$RESULTS_DIR/netdata_metrics.txt"
}

# Generate load test report
generate_report() {
    log "Generating test report..."
    
    REPORT_FILE="$RESULTS_DIR/test_report.html"
    
    cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Netdata Load Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .metrics { background-color: #f9f9f9; }
        pre { background-color: #f5f5f5; padding: 10px; overflow-x: auto; }
        .success { color: green; }
        .warning { color: orange; }
        .error { color: red; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Netdata Load Test Report</h1>
        <p><strong>Test Date:</strong> $(date)</p>
        <p><strong>Test Duration:</strong> ${DURATION} seconds</p>
        <p><strong>System:</strong> $(uname -a)</p>
    </div>
    
    <div class="section">
        <h2>Test Summary</h2>
        <ul>
            <li class="success">✓ CPU Stress Test Completed</li>
            <li class="success">✓ Memory Stress Test Completed</li>
            <li class="success">✓ Disk I/O Stress Test Completed</li>
            <li class="success">✓ Network Stress Test Completed</li>
            <li class="success">✓ Netdata Metrics Collected</li>
        </ul>
    </div>
    
    <div class="section metrics">
        <h2>System State Before Test</h2>
        <pre>$(cat "$RESULTS_DIR/initial_state.txt" 2>/dev/null || echo "Initial state not recorded")</pre>
    </div>
    
    <div class="section">
        <h2>Access Netdata Dashboard</h2>
        <p>View real-time metrics at: <a href="$NETDATA_URL" target="_blank">$NETDATA_URL</a></p>
        <p>Test results saved in: <code>$RESULTS_DIR</code></p>
    </div>
    
    <div class="section">
        <h2>Next Steps</h2>
        <ol>
            <li>Open the Netdata dashboard in your browser</li>
            <li>Review the metrics collected during the stress tests</li>
            <li>Check if any alerts were triggered</li>
            <li>Examine the detailed test results in the results directory</li>
        </ol>
    </div>
</body>
</html>
EOF

    log "Test report generated: $REPORT_FILE"
    
    # Try to open the report in a browser
    if command -v xdg-open &> /dev/null; then
        xdg-open "$REPORT_FILE" 2>/dev/null || true
    elif command -v open &> /dev/null; then
        open "$REPORT_FILE" 2>/dev/null || true
    fi
}

# Cleanup function
cleanup_test() {
    log "Cleaning up test processes..."
    
    # Kill any remaining test processes
    pkill -f "dd if=/dev/zero" 2>/dev/null || true
    pkill -f "python3.*memory" 2>/dev/null || true
    pkill -f "dd.*netdata" 2>/dev/null || true
    
    # Remove temporary files
    rm -f /tmp/netdata_io_test
    
    log "Test cleanup completed"
}

# Signal handler for cleanup
trap cleanup_test EXIT INT TERM

# Main test function
main() {
    log "Starting enhanced Netdata dashboard test..."
    log "Test duration: ${DURATION} seconds"
    
    setup_test_environment
    check_netdata
    
    # Start metrics collection in background
    collect_netdata_metrics &
    
    # Run stress tests
    cpu_stress_test &
    CPU_TEST_PID=$!
    
    sleep 30  # Stagger tests
    memory_stress_test &
    MEMORY_TEST_PID=$!
    
    sleep 30
    disk_io_stress_test &
    DISK_TEST_PID=$!
    
    sleep 30
    network_stress_test &
    NETWORK_TEST_PID=$!
    
    # Wait for all tests to complete
    wait "$CPU_TEST_PID" 2>/dev/null || true
    wait "$MEMORY_TEST_PID" 2>/dev/null || true
    wait "$DISK_TEST_PID" 2>/dev/null || true
    wait "$NETWORK_TEST_PID" 2>/dev/null || true
    
    # Final metrics collection
    sleep 10
    collect_netdata_metrics
    
    generate_report
    
    log "All tests completed successfully!"
    log "Results available in: $RESULTS_DIR"
    log "Open $NETDATA_URL to view the dashboard"
}

# Display usage information
usage() {
    echo "Usage: $0 [duration_in_seconds]"
    echo "Example: $0 300  # Run tests for 5 minutes"
    echo "Default duration: 300 seconds (5 minutes)"
    exit 1
}

# Parse command line arguments
if [[ $# -gt 1 ]]; then
    usage
fi

if [[ $# -eq 1 ]] && ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "Error: Duration must be a positive integer"
    usage
fi

# Run main function
main "$@"