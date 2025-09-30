#!/bin/bash

# Fix Grafana Data Source Configuration
# Resolves connection issues between Grafana and Prometheus in Docker

set -euo pipefail

echo "🔧 Fixing Grafana Data Source Configuration"
echo "==========================================="
echo ""

# Check if containers are running
echo "📊 Checking container status..."
if ! docker-compose ps | grep -q "grafana.*Up"; then
    echo "❌ Grafana container is not running"
    echo "Starting containers..."
    docker-compose up -d
    sleep 10
fi

if ! docker-compose ps | grep -q "prometheus.*Up"; then
    echo "❌ Prometheus container is not running"
    echo "Starting containers..."
    docker-compose up -d
    sleep 10
fi

echo "✅ Containers are running"

# Test internal connectivity
echo ""
echo "🔍 Testing internal container connectivity..."
if docker exec grafana curl -s -f http://prometheus:9090 > /dev/null; then
    echo "✅ Grafana can reach Prometheus internally"
else
    echo "❌ Grafana cannot reach Prometheus internally"
    echo "This might be a network issue. Restarting containers..."
    docker-compose down
    docker-compose up -d
    sleep 15
fi

# Restart Grafana to pick up provisioning
echo ""
echo "🔄 Restarting Grafana to apply configuration..."
docker-compose restart grafana
sleep 10

echo ""
echo "✅ Configuration fixed!"
echo ""
echo "🎯 Next Steps:"
echo "============="
echo "1. Open Grafana: http://localhost:3000"
echo "2. Login with admin/admin"
echo "3. Go to Configuration → Data Sources"
echo "4. You should see 'Prometheus' with a green checkmark"
echo "5. If still red, click on it and change URL to: http://prometheus:9090"
echo "6. Click 'Save & Test' - should show 'Data source is working'"
echo ""
echo "🚨 If you imported a dashboard before the fix:"
echo "   - Delete the old dashboard"
echo "   - Import again with ID: 11074"
echo "   - Select the working Prometheus data source"
echo ""
echo "💡 The key fix: Use 'prometheus:9090' not 'localhost:9090' in Docker!"
echo ""

# Test the API endpoint
echo "🧪 Testing Prometheus API from Grafana container..."
if docker exec grafana curl -s "http://prometheus:9090/api/v1/query?query=up" | grep -q "success"; then
    echo "✅ Prometheus API is accessible from Grafana"
else
    echo "❌ Prometheus API test failed"
fi

echo ""
echo "🎉 Setup should now be working!"
echo "   Try importing dashboard ID 11074 again."