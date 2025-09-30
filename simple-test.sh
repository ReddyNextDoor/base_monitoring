#!/bin/bash

# Simple Netdata Dashboard Test
# Works on macOS without sudo requirements

set -euo pipefail

DURATION=${1:-60}
NETDATA_URL="http://localhost:19999"

echo "🧪 Starting simple Netdata dashboard test..."
echo "Duration: ${DURATION} seconds"
echo "Dashboard: $NETDATA_URL"
echo ""

# Check if Netdata is accessible
echo "📡 Checking Netdata accessibility..."
if curl -s -f "$NETDATA_URL" > /dev/null; then
    echo "✅ Netdata is accessible"
else
    echo "❌ Netdata is not accessible at $NETDATA_URL"
    echo "Make sure Netdata is running with:"
    echo "docker ps | grep netdata"
    exit 1
fi

# Test API endpoints
echo ""
echo "🔍 Testing API endpoints..."
endpoints=(
    "/api/v1/info"
    "/api/v1/charts" 
    "/api/v1/alarms"
)

for endpoint in "${endpoints[@]}"; do
    if curl -s -f "$NETDATA_URL$endpoint" > /dev/null; then
        echo "✅ API endpoint working: $endpoint"
    else
        echo "❌ API endpoint failed: $endpoint"
    fi
done

# Generate some system load
echo ""
echo "💪 Generating system load for ${DURATION} seconds..."
echo "Watch the dashboard at: $NETDATA_URL"
echo ""

# Start background processes to generate load
echo "Starting CPU load..."
(
    end_time=$(($(date +%s) + DURATION))
    while [ $(date +%s) -lt $end_time ]; do
        # Simple CPU load
        yes > /dev/null &
        sleep 1
        kill $! 2>/dev/null || true
    done
) &
CPU_PID=$!

echo "Starting memory allocation..."
(
    python3 -c "
import time
import sys
end_time = time.time() + $DURATION
while time.time() < end_time:
    try:
        # Allocate 50MB chunks
        data = bytearray(50 * 1024 * 1024)
        time.sleep(2)
        del data
    except:
        break
" 2>/dev/null
) &
MEM_PID=$!

echo "Starting disk I/O..."
(
    end_time=$(($(date +%s) + DURATION))
    while [ $(date +%s) -lt $end_time ]; do
        dd if=/dev/zero of=./test_file bs=1M count=10 2>/dev/null
        rm -f ./test_file
        sleep 2
    done
) &
DISK_PID=$!

# Monitor progress
echo ""
echo "⏱️  Test progress:"
for ((i=1; i<=DURATION; i++)); do
    if ((i % 10 == 0)); then
        echo "   ${i}/${DURATION} seconds completed..."
    fi
    sleep 1
done

# Cleanup
echo ""
echo "🧹 Cleaning up..."
kill $CPU_PID $MEM_PID $DISK_PID 2>/dev/null || true
wait 2>/dev/null || true
rm -f ./test_file

# Final check
echo ""
echo "📊 Final dashboard check..."
if curl -s -f "$NETDATA_URL/api/v1/info" > /dev/null; then
    echo "✅ Dashboard is still responsive"
else
    echo "❌ Dashboard became unresponsive"
fi

echo ""
echo "🎉 Test completed!"
echo "📈 View your dashboard: $NETDATA_URL"
echo ""
echo "💡 Tips:"
echo "- Look at the CPU charts to see the load we generated"
echo "- Check Memory usage for the allocation patterns"
echo "- Observe Disk I/O for the write operations"
echo "- All metrics should return to normal levels now"