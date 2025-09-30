# 🔍 Enhanced Netdata Monitoring System

A comprehensive, production-ready monitoring solution built on Netdata with extensive enhancements for enterprise use.

## 🚀 Quick Start

### Fastest Way (Docker - 30 seconds)
```bash
# Start Netdata immediately with Docker
docker run -d --name netdata -p 19999:19999 \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --cap-add SYS_PTRACE \
  --security-opt apparmor=unconfined \
  netdata/netdata:latest

# Then open: http://localhost:19999
```

### Complete Setup (Production)
```bash
# Complete setup with one command
make all

# Or step by step
make install    # Install Netdata
make configure  # Apply advanced configurations  
make test       # Run validation tests
```

## 📋 What's Included

### Core Components
- **Enhanced Installation** (`setup.sh`) - Multi-distribution support with security hardening
- **Advanced Testing** (`test_dashboard.sh`) - Comprehensive load testing and validation
- **Professional Cleanup** (`cleanup.sh`) - Complete system removal with backup
- **Configuration Management** (`monitoring-config.sh`) - Enterprise-grade monitoring setup
- **End-to-End Testing** (`test-suite.sh`) - Complete system validation
- **Docker Deployment** (`docker-compose.yml`) - Containerized monitoring stack

### Management Tools
- **Makefile** - Standardized build and deployment commands
- **Docker Setup** (`docker-setup.sh`) - Automated container deployment
- **Prometheus Integration** - Advanced metrics collection
- **Grafana Dashboards** - Professional visualization

## 🎯 Key Features

### ✅ Production Ready
- Multi-distribution Linux support (Ubuntu, Debian, CentOS, RHEL, Fedora)
- Security hardening with proper user permissions
- Automatic firewall configuration
- Comprehensive backup and recovery

### 📊 Advanced Monitoring
- Custom health score metrics
- Application monitoring (Docker, MySQL, Redis, Nginx)
- Advanced alerting with multi-tier notifications
- Real-time performance tracking

### 🔧 Enterprise Features
- Docker-based deployment option
- Prometheus and Grafana integration
- Custom notification channels (Email, Slack, Discord)
- Professional web interface customization

### 🧪 Comprehensive Testing
- End-to-end test suite with 50+ test cases
- Performance and stress testing
- Security validation
- Integration testing
- Automated reporting

## 📖 Quick Reference

### Installation Options

```bash
# Native installation
make install

# Docker-based setup
make docker-setup

# Complete setup (install + configure + test)
make all
```

### Testing Commands

```bash
# 🍎 macOS/Docker Users (Recommended)
./simple-test.sh 60        # Clean, simple test
./test_dashboard.sh 60     # Enhanced test (some warnings expected)

# 🐧 Linux Native Install Users  
make test                  # Basic dashboard tests
make test-full            # Comprehensive test suite
make test-stress DURATION=600  # Stress testing (10 minutes)
```

### Management Commands

```bash
# Check status
make status

# View logs
make logs

# Restart service
make restart

# Create backup
make backup

# Complete removal
make clean
```

### Docker Commands

```bash
# Start monitoring stack
make docker-start

# Stop containers
make docker-stop

# View container logs
make docker-logs

# Update images
make docker-update
```

## 🌐 Access Points

After installation, access your monitoring dashboard:

- **Netdata Dashboard**: http://localhost:19999
- **Prometheus** (if using Docker): http://localhost:9090
- **Grafana** (if using Docker): http://localhost:3000

## 📊 Monitoring Capabilities

### System Metrics
- CPU usage and frequency
- Memory and swap utilization
- Disk space and I/O performance
- Network traffic and connections
- Load averages and processes

### Advanced Metrics
- Custom health score
- Application performance
- Container monitoring
- Database metrics
- Web server statistics

### Alerting
- CPU usage > 80% (warning) / 90% (critical)
- Memory usage > 80% (warning) / 95% (critical)
- Disk space > 80% (warning) / 95% (critical)
- Load average > 1.5x cores (warning) / 2x cores (critical)
- Custom business metrics

## 🔒 Security Features

- Non-root service execution
- IP-based access restrictions
- Firewall integration
- Audit logging
- Configuration backup
- Secure defaults

## 🐳 Docker Deployment

The Docker setup includes:
- **Netdata**: Real-time monitoring
- **Prometheus**: Metrics collection
- **Grafana**: Advanced dashboards

```bash
# Setup Docker monitoring stack
make docker-setup

# Access services
# Netdata: http://localhost:19999
# Prometheus: http://localhost:9090  
# Grafana: http://localhost:3000 (admin/admin123)
```

## 🧪 Testing Framework

Comprehensive testing includes:

### Test Categories
- **Service Status**: Verify Netdata is running correctly
- **Web Interface**: Test dashboard and API endpoints
- **Metrics Collection**: Validate data collection
- **Alert System**: Test alerting rules
- **Performance**: Check resource usage
- **Configuration**: Validate settings
- **Security**: Verify security measures
- **Integration**: Test third-party integrations
- **Stress Testing**: System stability under load
- **Backup/Recovery**: Data protection validation

### Test Execution
```bash
# Run all tests
make test-full

# View test results
open /tmp/netdata-e2e-tests/comprehensive_test_report.html
```

## 📚 Documentation & Guides

- **📖 README.md** - Complete setup and usage guide (this file)
- **🚀 enhancements.md** - Detailed enhancement documentation
- **📊 prometheusguide.md** - Complete Prometheus query guide with 200+ examples
- **🎨 grafanaguide.md** - Comprehensive Grafana dashboard creation guide
- **📋 requirements.md** - Original basic requirements

## 🧪 Testing & Utility Scripts

- **⚡ simple-test.sh** - Quick dashboard test (macOS-friendly)
- **🎨 test-grafana.sh** - Grafana setup test and demo
- **🔧 fix-grafana-datasource.sh** - Fix Docker networking issues
- **💪 test_dashboard.sh** - Enhanced load testing
- **🔍 test-suite.sh** - Comprehensive end-to-end testing

## 📁 Project Structure

```
├── setup.sh                 # Enhanced installation script
├── test_dashboard.sh         # Advanced testing framework
├── cleanup.sh               # Professional cleanup system
├── monitoring-config.sh     # Advanced configuration
├── test-suite.sh           # End-to-end test suite
├── docker-setup.sh         # Docker deployment
├── docker-compose.yml      # Container orchestration
├── prometheus.yml          # Prometheus configuration
├── prometheusguide.md      # Prometheus query guide
├── grafanaguide.md        # Grafana dashboard guide
├── simple-test.sh         # Simple testing script
├── test-grafana.sh        # Grafana testing script
├── fix-grafana-datasource.sh # Fix Grafana Docker networking
├── Makefile               # Build and deployment system
├── requirements.md        # Original requirements
├── enhancements.md       # Detailed enhancement documentation
└── README.md            # This file
```

## 🔧 Configuration

### Environment Variables
```bash
# Netdata Cloud (optional)
export NETDATA_CLAIM_TOKEN="your-token"
export NETDATA_CLAIM_ROOMS="your-room"

# Grafana credentials
export GRAFANA_USER="admin"
export GRAFANA_PASSWORD="your-password"
```

### Custom Configurations
- Netdata config: `/etc/netdata/netdata.conf`
- Custom alerts: `/etc/netdata/health.d/custom_alerts.conf`
- Notifications: `/etc/netdata/health_alarm_notify.conf`

## 🚨 Troubleshooting

### Common Issues

**Service not starting:**
```bash
sudo systemctl status netdata
sudo journalctl -u netdata -f
```

**Web interface not accessible:**
```bash
sudo netstat -tlnp | grep 19999
sudo ufw status  # Check firewall
```

**High resource usage:**
```bash
make status  # Check system resources
```

### Getting Help
1. Check service status: `make status`
2. View logs: `make logs`
3. Run diagnostics: `make test-full`
4. Validate configuration: `make validate`

### What You Should See
When you first access http://localhost:19999, you'll see:
- **System Information**: Kernel version, OS, hardware specs
- **Storage Tiers**: Data retention settings (1s, 1m, 1h resolution)
- **Real-time Charts**: CPU, Memory, Disk, Network metrics
- **Navigation Menu**: Left sidebar with different metric categories

The data you're seeing (Tier/Resolution/Storage info) is normal - it shows Netdata's data retention configuration.

### macOS Notes
- Some test scripts show warnings about missing Linux commands (`free`, `nproc`, etc.) - this is normal
- The `simple-test.sh` script is designed specifically for macOS compatibility
- Docker-based Netdata works perfectly on macOS despite these warnings

### Common Issues & Quick Fixes

#### Grafana Shows Red Exclamation Marks
**Problem:** Dashboard panels show "dial tcp :9090: connection refused"
**Quick Fix:** Run `./fix-grafana-datasource.sh` or manually change Prometheus URL to `http://prometheus:9090` in Grafana data sources.

#### Containers Not Starting
**Quick Fix:** 
```bash
docker-compose down
docker-compose up -d
```

#### Can't Access Dashboards
**Check Status:**
```bash
docker-compose ps  # All should show "Up"
curl http://localhost:19999  # Netdata
curl http://localhost:9090   # Prometheus  
curl http://localhost:3000   # Grafana
```

## 📈 Performance

### Resource Usage
- **CPU**: < 5% under normal load
- **Memory**: < 100MB typical usage
- **Disk**: Configurable retention (default 1GB)
- **Network**: Minimal overhead

### Scalability
- Supports monitoring 1000+ metrics
- Real-time updates every second
- Handles 100+ concurrent connections
- Efficient data compression

## 🔄 Maintenance

### Regular Tasks
```bash
# Weekly health check
make test-full

# Monthly backup
make backup

# Update system
make docker-update  # For Docker setup
# or restart after system updates
make restart
```

### Upgrades
```bash
# Backup current configuration
make backup

# Reinstall with latest version
make clean && make install
```

## 🤝 Contributing

This enhanced monitoring system is designed to be:
- **Extensible**: Easy to add new monitoring capabilities
- **Maintainable**: Clear code structure and documentation
- **Testable**: Comprehensive test coverage
- **Deployable**: Multiple deployment options

## 📄 License

This project enhances the open-source Netdata monitoring tool with additional automation, testing, and enterprise features.

## 🎉 Success Metrics

After deployment, you'll have:
- ✅ Real-time system monitoring
- ✅ Proactive alerting system  
- ✅ Professional dashboards
- ✅ Automated testing framework
- ✅ Enterprise-grade security
- ✅ Complete documentation
- ✅ Backup and recovery procedures
- ✅ Scalable architecture

---

**Ready to monitor like a pro?** Start with `make all` and have a complete monitoring solution running in minutes! 🚀