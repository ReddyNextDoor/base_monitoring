#!/bin/bash

# Docker-based Netdata Setup Script
# Alternative deployment using Docker containers

set -euo pipefail

# Configuration
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"
LOG_FILE="/var/log/netdata-docker-setup.log"

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

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        error "Docker Compose is not installed. Please install Docker Compose first."
    fi
    
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running or you don't have permission to access it."
    fi
    
    log "Docker and Docker Compose are available"
}

# Create environment file
create_env_file() {
    log "Creating environment configuration..."
    
    cat > "$ENV_FILE" << 'EOF'
# Netdata Cloud Configuration (optional)
# Get your claim token from https://app.netdata.cloud
NETDATA_CLAIM_TOKEN=
NETDATA_CLAIM_ROOMS=

# Grafana Configuration
GRAFANA_USER=admin
GRAFANA_PASSWORD=admin123

# Network Configuration
NETDATA_PORT=19999
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
EOF

    log "Environment file created: $ENV_FILE"
    info "Edit $ENV_FILE to configure Netdata Cloud integration and Grafana credentials"
}

# Create Grafana provisioning configuration
setup_grafana_provisioning() {
    log "Setting up Grafana provisioning..."
    
    mkdir -p grafana/provisioning/datasources
    mkdir -p grafana/provisioning/dashboards
    
    # Datasource configuration
    cat > grafana/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

    # Dashboard configuration
    cat > grafana/provisioning/dashboards/dashboard.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

    # Sample dashboard
    cat > grafana/provisioning/dashboards/netdata-overview.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Netdata Overview",
    "tags": ["netdata"],
    "style": "dark",
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "CPU Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "100 - (avg(netdata_cpu_cpu_percentage_average{dimension=\"idle\"}) * 100)",
            "legendFormat": "CPU Usage %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Memory Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "(netdata_system_ram_MiB_average{dimension=\"used\"} / netdata_system_ram_MiB_average{dimension=\"total\"}) * 100",
            "legendFormat": "Memory Usage %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "5s"
  }
}
EOF

    log "Grafana provisioning configured"
}

# Start the monitoring stack
start_monitoring_stack() {
    log "Starting monitoring stack..."
    
    # Pull latest images
    docker-compose pull
    
    # Start services
    docker-compose up -d
    
    # Wait for services to be ready
    log "Waiting for services to start..."
    sleep 30
    
    # Check service health
    check_service_health
}

# Check service health
check_service_health() {
    log "Checking service health..."
    
    # Check Netdata
    if curl -s -f http://localhost:19999/api/v1/info > /dev/null; then
        log "✓ Netdata is healthy and accessible"
    else
        warn "✗ Netdata health check failed"
    fi
    
    # Check Prometheus (if enabled)
    if docker-compose ps prometheus | grep -q "Up"; then
        if curl -s -f http://localhost:9090/-/healthy > /dev/null; then
            log "✓ Prometheus is healthy and accessible"
        else
            warn "✗ Prometheus health check failed"
        fi
    fi
    
    # Check Grafana (if enabled)
    if docker-compose ps grafana | grep -q "Up"; then
        if curl -s -f http://localhost:3000/api/health > /dev/null; then
            log "✓ Grafana is healthy and accessible"
        else
            warn "✗ Grafana health check failed"
        fi
    fi
}

# Display access information
display_access_info() {
    log "Monitoring stack is ready!"
    
    echo ""
    echo "=== Access Information ==="
    echo "Netdata Dashboard: http://localhost:19999"
    
    if docker-compose ps prometheus | grep -q "Up"; then
        echo "Prometheus: http://localhost:9090"
    fi
    
    if docker-compose ps grafana | grep -q "Up"; then
        echo "Grafana: http://localhost:3000"
        echo "  Default credentials: admin/admin123"
    fi
    
    echo ""
    echo "=== Management Commands ==="
    echo "View logs: docker-compose logs -f"
    echo "Stop stack: docker-compose down"
    echo "Restart: docker-compose restart"
    echo "Update: docker-compose pull && docker-compose up -d"
    echo ""
}

# Create management scripts
create_management_scripts() {
    log "Creating management scripts..."
    
    # Start script
    cat > start-monitoring.sh << 'EOF'
#!/bin/bash
echo "Starting monitoring stack..."
docker-compose up -d
echo "Monitoring stack started!"
echo "Netdata: http://localhost:19999"
echo "Prometheus: http://localhost:9090"
echo "Grafana: http://localhost:3000"
EOF
    chmod +x start-monitoring.sh
    
    # Stop script
    cat > stop-monitoring.sh << 'EOF'
#!/bin/bash
echo "Stopping monitoring stack..."
docker-compose down
echo "Monitoring stack stopped!"
EOF
    chmod +x stop-monitoring.sh
    
    # Update script
    cat > update-monitoring.sh << 'EOF'
#!/bin/bash
echo "Updating monitoring stack..."
docker-compose pull
docker-compose up -d
echo "Monitoring stack updated!"
EOF
    chmod +x update-monitoring.sh
    
    log "Management scripts created: start-monitoring.sh, stop-monitoring.sh, update-monitoring.sh"
}

# Main setup function
main() {
    log "Starting Docker-based Netdata setup..."
    
    check_docker
    create_env_file
    setup_grafana_provisioning
    create_management_scripts
    start_monitoring_stack
    display_access_info
    
    log "Docker-based monitoring setup completed successfully!"
}

# Display usage
usage() {
    echo "Usage: $0"
    echo ""
    echo "This script sets up a complete monitoring stack using Docker:"
    echo "- Netdata for real-time monitoring"
    echo "- Prometheus for metrics collection"
    echo "- Grafana for advanced dashboards"
    echo ""
    echo "Requirements:"
    echo "- Docker and Docker Compose installed"
    echo "- Ports 19999, 9090, and 3000 available"
    exit 1
}

# Parse arguments
if [[ $# -gt 0 ]] && [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

# Run main function
main "$@"