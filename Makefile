# Netdata Monitoring System Makefile
# Provides convenient commands for setup, testing, and management

.PHONY: help install configure test clean docker-setup docker-clean all

# Default target
help:
	@echo "Netdata Monitoring System - Available Commands:"
	@echo ""
	@echo "Setup Commands:"
	@echo "  install          - Install Netdata with enhanced configuration"
	@echo "  configure        - Apply advanced monitoring configurations"
	@echo "  docker-setup     - Setup using Docker containers"
	@echo ""
	@echo "Testing Commands:"
	@echo "  test             - Run basic dashboard tests"
	@echo "  test-full        - Run comprehensive end-to-end test suite"
	@echo "  test-stress      - Run stress tests with custom duration"
	@echo ""
	@echo "Management Commands:"
	@echo "  status           - Check Netdata service status"
	@echo "  restart          - Restart Netdata service"
	@echo "  logs             - View Netdata logs"
	@echo "  backup           - Create configuration backup"
	@echo ""
	@echo "Cleanup Commands:"
	@echo "  clean            - Remove Netdata completely"
	@echo "  docker-clean     - Stop and remove Docker containers"
	@echo ""
	@echo "Utility Commands:"
	@echo "  permissions      - Fix file permissions"
	@echo "  validate         - Validate configuration files"
	@echo "  all              - Complete setup (install + configure + test)"
	@echo ""
	@echo "Examples:"
	@echo "  make install                    # Basic installation"
	@echo "  make all                        # Complete setup"
	@echo "  make test-stress DURATION=600   # 10-minute stress test"
	@echo "  make docker-setup               # Docker-based setup"

# Installation targets
install:
	@echo "🚀 Installing Netdata with enhanced configuration..."
	@sudo chmod +x setup.sh
	@sudo ./setup.sh
	@echo "✅ Installation completed!"

configure:
	@echo "⚙️  Applying advanced monitoring configurations..."
	@sudo chmod +x monitoring-config.sh
	@sudo ./monitoring-config.sh
	@echo "✅ Configuration completed!"

docker-setup:
	@echo "🐳 Setting up Netdata using Docker..."
	@chmod +x docker-setup.sh
	@./docker-setup.sh
	@echo "✅ Docker setup completed!"

# Testing targets
test:
	@echo "🧪 Running basic dashboard tests..."
	@sudo chmod +x test_dashboard.sh
	@sudo ./test_dashboard.sh $(DURATION)
	@echo "✅ Basic tests completed!"

test-full:
	@echo "🔍 Running comprehensive end-to-end test suite..."
	@sudo chmod +x test-suite.sh
	@sudo ./test-suite.sh
	@echo "✅ Full test suite completed!"

test-stress:
	@echo "💪 Running stress tests..."
	@sudo chmod +x test_dashboard.sh
	@sudo ./test_dashboard.sh $(or $(DURATION),300)
	@echo "✅ Stress tests completed!"

# Management targets
status:
	@echo "📊 Checking Netdata service status..."
	@systemctl status netdata --no-pager || true
	@echo ""
	@echo "🌐 Web interface: http://localhost:19999"
	@echo "📈 API endpoint: http://localhost:19999/api/v1/info"

restart:
	@echo "🔄 Restarting Netdata service..."
	@sudo systemctl restart netdata
	@sleep 5
	@sudo systemctl status netdata --no-pager
	@echo "✅ Netdata restarted!"

logs:
	@echo "📋 Viewing Netdata logs..."
	@sudo journalctl -u netdata -f --no-pager

backup:
	@echo "💾 Creating configuration backup..."
	@sudo mkdir -p /opt/netdata-backup/manual-backup-$(shell date +%Y%m%d_%H%M%S)
	@sudo cp -r /etc/netdata /opt/netdata-backup/manual-backup-$(shell date +%Y%m%d_%H%M%S)/ 2>/dev/null || true
	@echo "✅ Backup created in /opt/netdata-backup/"

# Cleanup targets
clean:
	@echo "🧹 Removing Netdata completely..."
	@sudo chmod +x cleanup.sh
	@sudo ./cleanup.sh --force
	@echo "✅ Cleanup completed!"

docker-clean:
	@echo "🐳 Stopping and removing Docker containers..."
	@docker-compose down -v 2>/dev/null || true
	@docker system prune -f 2>/dev/null || true
	@echo "✅ Docker cleanup completed!"

# Utility targets
permissions:
	@echo "🔐 Fixing file permissions..."
	@sudo chown -R netdata:netdata /etc/netdata 2>/dev/null || true
	@sudo chown -R netdata:netdata /var/lib/netdata 2>/dev/null || true
	@sudo chown -R netdata:netdata /var/cache/netdata 2>/dev/null || true
	@sudo chmod 755 /etc/netdata 2>/dev/null || true
	@sudo chmod 644 /etc/netdata/netdata.conf 2>/dev/null || true
	@echo "✅ Permissions fixed!"

validate:
	@echo "✅ Validating configuration files..."
	@sudo /usr/sbin/netdata -W set 2>/dev/null && echo "Configuration is valid" || echo "Configuration has errors"
	@echo "🔍 Checking configuration syntax..."
	@sudo netdata -t 2>/dev/null && echo "Syntax check passed" || echo "Syntax check failed"

# Complete setup target
all: install configure test
	@echo ""
	@echo "🎉 Complete Netdata setup finished!"
	@echo "🌐 Access dashboard: http://localhost:19999"
	@echo "📊 Run 'make status' to check system status"
	@echo "🧪 Run 'make test-full' for comprehensive testing"

# Development targets
dev-setup:
	@echo "🛠️  Setting up development environment..."
	@chmod +x *.sh
	@echo "✅ Development environment ready!"

dev-test:
	@echo "🧪 Running development tests..."
	@bash -n setup.sh && echo "✅ setup.sh syntax OK" || echo "❌ setup.sh syntax error"
	@bash -n test_dashboard.sh && echo "✅ test_dashboard.sh syntax OK" || echo "❌ test_dashboard.sh syntax error"
	@bash -n cleanup.sh && echo "✅ cleanup.sh syntax OK" || echo "❌ cleanup.sh syntax error"
	@bash -n monitoring-config.sh && echo "✅ monitoring-config.sh syntax OK" || echo "❌ monitoring-config.sh syntax error"
	@bash -n test-suite.sh && echo "✅ test-suite.sh syntax OK" || echo "❌ test-suite.sh syntax error"
	@echo "✅ Development tests completed!"

# Quick commands
quick-install: install
quick-test: test
quick-clean: clean

# Docker-specific targets
docker-start:
	@echo "🐳 Starting Docker monitoring stack..."
	@docker-compose up -d
	@echo "✅ Docker stack started!"

docker-stop:
	@echo "🐳 Stopping Docker monitoring stack..."
	@docker-compose down
	@echo "✅ Docker stack stopped!"

docker-logs:
	@echo "📋 Viewing Docker container logs..."
	@docker-compose logs -f

docker-update:
	@echo "🔄 Updating Docker images..."
	@docker-compose pull
	@docker-compose up -d
	@echo "✅ Docker images updated!"

# Monitoring targets
monitor:
	@echo "📊 Opening monitoring dashboard..."
	@command -v xdg-open >/dev/null && xdg-open http://localhost:19999 || \
	 command -v open >/dev/null && open http://localhost:19999 || \
	 echo "Please open http://localhost:19999 in your browser"

alerts:
	@echo "🚨 Checking active alerts..."
	@curl -s http://localhost:19999/api/v1/alarms | python3 -m json.tool 2>/dev/null || \
	 echo "Could not retrieve alerts. Is Netdata running?"

metrics:
	@echo "📈 Displaying current metrics..."
	@curl -s http://localhost:19999/api/v1/info | python3 -m json.tool 2>/dev/null || \
	 echo "Could not retrieve metrics. Is Netdata running?"

# Help for specific categories
help-install:
	@echo "Installation Commands:"
	@echo "  make install      - Install Netdata on the system"
	@echo "  make configure    - Apply advanced configurations"
	@echo "  make docker-setup - Setup using Docker containers"
	@echo "  make all          - Complete installation and setup"

help-test:
	@echo "Testing Commands:"
	@echo "  make test                       - Basic dashboard tests"
	@echo "  make test-full                  - Comprehensive test suite"
	@echo "  make test-stress DURATION=600   - Stress tests (10 minutes)"
	@echo "  make dev-test                   - Development syntax tests"

help-docker:
	@echo "Docker Commands:"
	@echo "  make docker-setup   - Initial Docker setup"
	@echo "  make docker-start   - Start containers"
	@echo "  make docker-stop    - Stop containers"
	@echo "  make docker-clean   - Remove containers and volumes"
	@echo "  make docker-logs    - View container logs"
	@echo "  make docker-update  - Update container images"