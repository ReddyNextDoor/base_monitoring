#!/bin/bash

# Quick Grafana Setup Test and Demo
# Tests Grafana connectivity and helps you get started

set -euo pipefail

GRAFANA_URL="http://localhost:3000"
PROMETHEUS_URL="http://localhost:9090"

echo "🎨 Grafana Setup Test & Quick Start Guide"
echo "========================================"
echo ""

# Test Grafana connectivity
echo "📡 Testing Grafana connectivity..."
if curl -s -f "$GRAFANA_URL" > /dev/null; then
    echo "✅ Grafana is accessible at $GRAFANA_URL"
else
    echo "❌ Grafana is not accessible at $GRAFANA_URL"
    echo "Make sure Docker containers are running: docker-compose ps"
    exit 1
fi

# Test Prometheus connectivity
echo "📊 Testing Prometheus connectivity..."
if curl -s -f "$PROMETHEUS_URL" > /dev/null; then
    echo "✅ Prometheus is accessible at $PROMETHEUS_URL"
else
    echo "❌ Prometheus is not accessible at $PROMETHEUS_URL"
    exit 1
fi

# Test Prometheus API
echo "🔍 Testing Prometheus API..."
if curl -s "$PROMETHEUS_URL/api/v1/query?query=up" | grep -q "success"; then
    echo "✅ Prometheus API is working"
else
    echo "❌ Prometheus API is not responding correctly"
fi

# Check available metrics
echo ""
echo "📈 Available Netdata metrics sample:"
curl -s "$PROMETHEUS_URL/api/v1/label/__name__/values" | \
python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    netdata_metrics = [m for m in data['data'] if 'netdata_system' in m][:5]
    for metric in netdata_metrics:
        print(f'  - {metric}')
except:
    print('  Could not retrieve metrics')
"

echo ""
echo "🚀 Quick Start Steps:"
echo "===================="
echo ""
echo "1. 🔐 Login to Grafana:"
echo "   URL: $GRAFANA_URL"
echo "   Username: admin"
echo "   Password: admin"
echo ""
echo "2. 📊 Import a Dashboard:"
echo "   - Go to '+' → Import"
echo "   - Enter ID: 11074 (Netdata Overview)"
echo "   - Select 'Prometheus' as data source"
echo "   - Click Import"
echo ""
echo "3. 🎯 Try These Queries in a New Panel:"
echo "   - CPU Usage: 100 - netdata_system_cpu_percentage_average{dimension=\"idle\"}"
echo "   - Memory Usage: netdata_system_ram_MiB_average{dimension=\"used\"}"
echo "   - Disk Usage: netdata_disk_space_GiB_average{dimension=\"used\"}"
echo ""
echo "4. 📈 Create Your First Dashboard:"
echo "   - Click '+' → Dashboard"
echo "   - Add Panel → Add Query"
echo "   - Select Prometheus data source"
echo "   - Enter a query from above"
echo "   - Choose visualization type (Stat, Time series, etc.)"
echo ""
echo "5. 🚨 Set Up Alerts (Optional):"
echo "   - In any panel, go to Alert tab"
echo "   - Set conditions (e.g., CPU > 80%)"
echo "   - Configure notification channels"
echo ""

# Generate some system load for testing
echo "💪 Generating test load for 30 seconds..."
echo "   (Watch your dashboards to see metrics change!)"
echo ""

# CPU load
(
    for i in {1..30}; do
        yes > /dev/null &
        sleep 1
        kill $! 2>/dev/null || true
        if ((i % 10 == 0)); then
            echo "   ${i}/30 seconds completed..."
        fi
    done
) &
LOAD_PID=$!

# Memory allocation
python3 -c "
import time
for i in range(6):
    try:
        data = bytearray(20 * 1024 * 1024)  # 20MB
        time.sleep(5)
        del data
    except:
        break
" &
MEM_PID=$!

# Wait for load generation
wait $LOAD_PID 2>/dev/null || true
wait $MEM_PID 2>/dev/null || true

echo ""
echo "🎉 Test completed!"
echo ""
echo "📚 Next Steps:"
echo "============="
echo "1. Open Grafana: $GRAFANA_URL"
echo "2. Read the complete guide: grafanaguide.md"
echo "3. Import dashboard ID 11074 for instant monitoring"
echo "4. Experiment with custom panels and queries"
echo "5. Set up alerts for critical metrics"
echo ""
echo "💡 Pro Tip: Start with the 'System Overview' template in grafanaguide.md"
echo "    It provides a complete monitoring dashboard layout!"
echo ""
echo "🔗 Useful Links:"
echo "   - Grafana: $GRAFANA_URL"
echo "   - Prometheus: $PROMETHEUS_URL"
echo "   - Netdata: http://localhost:19999"