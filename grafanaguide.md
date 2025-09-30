# 📊 Grafana Dashboard Guide for Netdata Monitoring

A complete guide to creating professional dashboards and visualizations using Grafana with your Netdata and Prometheus data.

## 🚀 Quick Start

**Access Grafana:** http://localhost:3000

**Login Credentials:**
- **Username:** `admin`
- **Password:** `admin`

**First Login Steps:**
1. Login with admin/admin
2. Skip password change (or set a new one)
3. You'll see the Grafana home dashboard

## 🎯 Initial Setup & Configuration

### 1. Verify Data Source Connection

1. **Go to Configuration** → **Data Sources** (gear icon in left sidebar)
2. **Check Prometheus connection:**
   - Should show "Prometheus" as configured
   - URL: `http://prometheus:9090`
   - Status should be green ✅

3. **Test the connection:**
   - Click **"Save & Test"**
   - Should show "Data source is working"

### 2. Import Pre-built Dashboards

#### Option A: Import by ID (Recommended)
1. **Go to Dashboards** → **New** → **Import**
2. **Enter Dashboard ID:**
   - `11074` - Netdata Overview Dashboard
   - `1860` - Node Exporter Full (system metrics)
   - `3662` - Prometheus 2.0 Overview
   - `12486` - Docker and System Monitoring

3. **Configure Import:**
   - Select "Prometheus" as data source
   - Click **"Import"**

#### Option B: Import from JSON
1. **Download dashboard JSON** from grafana.com
2. **Go to Import** → **Upload JSON file**
3. **Configure and Import**

## 📈 Creating Custom Dashboards

### Step 1: Create New Dashboard
1. **Click "+"** in left sidebar → **Dashboard**
2. **Add new panel** → **Add Query**
3. **Select Prometheus** as data source

### Step 2: Essential Panel Types

#### 📊 **Stat Panel (Single Value)**
```
Panel Type: Stat
Query: 100 - netdata_system_cpu_percentage_average{dimension="idle"}
Title: CPU Usage %
Unit: Percent (0-100)
Thresholds: Green (0-70), Yellow (70-85), Red (85-100)
```

#### 📈 **Time Series Panel (Line Graph)**
```
Panel Type: Time series
Query: netdata_system_ram_MiB_average{dimension="used"}
Title: Memory Usage Over Time
Unit: Bytes (IEC)
Y-Axis: Min 0, Max Auto
```

#### 📊 **Gauge Panel**
```
Panel Type: Gauge
Query: (netdata_disk_space_GiB_average{dimension="used"} / 
        (netdata_disk_space_GiB_average{dimension="used"} + 
         netdata_disk_space_GiB_average{dimension="avail"})) * 100
Title: Disk Usage
Unit: Percent (0-100)
Min: 0, Max: 100
```

#### 🔢 **Table Panel**
```
Panel Type: Table
Query: topk(10, netdata_app_cpu_utilization_percentage_average)
Title: Top CPU Processes
Columns: Process, CPU %
```

## 🎨 Dashboard Design Best Practices

### Layout Structure
```
Row 1: System Overview (4 stat panels)
├── CPU Usage %
├── Memory Usage %  
├── Disk Usage %
└── Network Traffic

Row 2: Performance Graphs (2 panels)
├── CPU Usage Over Time (6 columns)
└── Memory Usage Over Time (6 columns)

Row 3: Detailed Metrics (3 panels)
├── Disk I/O (4 columns)
├── Network Details (4 columns)
└── Process List (4 columns)
```

### Color Schemes & Thresholds
```
CPU/Memory/Disk Usage:
- Green: 0-70%
- Yellow: 70-85%
- Red: 85-100%

Network Traffic:
- Blue: Inbound
- Orange: Outbound

Load Average:
- Green: 0-1.0
- Yellow: 1.0-2.0
- Red: 2.0+
```

## 📊 Essential Dashboard Panels

### 1. System Overview Dashboard

#### CPU Usage Panel
```
Panel: Stat
Query: 100 - netdata_system_cpu_percentage_average{dimension="idle"}
Title: CPU Usage
Unit: Percent (0-100)
Decimals: 1
Thresholds: 70 (yellow), 85 (red)
```

#### Memory Usage Panel
```
Panel: Stat
Query: (netdata_system_ram_MiB_average{dimension="used"} / 
        netdata_system_ram_MiB_average{dimension="total"}) * 100
Title: Memory Usage
Unit: Percent (0-100)
Decimals: 1
Thresholds: 80 (yellow), 95 (red)
```

#### Disk Usage Panel
```
Panel: Stat
Query: (netdata_disk_space_GiB_average{dimension="used"} / 
        (netdata_disk_space_GiB_average{dimension="used"} + 
         netdata_disk_space_GiB_average{dimension="avail"})) * 100
Title: Disk Usage
Unit: Percent (0-100)
Decimals: 1
Thresholds: 80 (yellow), 95 (red)
```

#### System Load Panel
```
Panel: Stat
Query: netdata_system_load_load_average{dimension="load1"}
Title: Load Average (1m)
Unit: Short
Decimals: 2
Thresholds: 1.0 (yellow), 2.0 (red)
```

### 2. Performance Monitoring Dashboard

#### CPU Usage Over Time
```
Panel: Time series
Queries:
- User: netdata_system_cpu_percentage_average{dimension="user"}
- System: netdata_system_cpu_percentage_average{dimension="system"}
- I/O Wait: netdata_system_cpu_percentage_average{dimension="iowait"}
- Idle: netdata_system_cpu_percentage_average{dimension="idle"}
Title: CPU Usage Over Time
Unit: Percent (0-100)
Stack: Normal
Fill opacity: 10
```

#### Memory Usage Breakdown
```
Panel: Time series
Queries:
- Used: netdata_system_ram_MiB_average{dimension="used"}
- Buffers: netdata_system_ram_MiB_average{dimension="buffers"}
- Cached: netdata_system_ram_MiB_average{dimension="cached"}
- Free: netdata_system_ram_MiB_average{dimension="free"}
Title: Memory Usage Breakdown
Unit: Bytes (IEC)
Stack: Normal
```

#### Network Traffic
```
Panel: Time series
Queries:
- Received: netdata_net_net_kilobits_persec_average{dimension="received"}
- Sent: -netdata_net_net_kilobits_persec_average{dimension="sent"}
Title: Network Traffic
Unit: Bits/sec (SI)
Y-Axis: Standard
```

#### Disk I/O Operations
```
Panel: Time series
Queries:
- Reads: netdata_disk_ops_operations_persec_average{dimension="reads"}
- Writes: -netdata_disk_ops_operations_persec_average{dimension="writes"}
Title: Disk I/O Operations
Unit: Operations/sec
Y-Axis: Standard
```

### 3. Application Monitoring Dashboard

#### Top CPU Processes
```
Panel: Table
Query: topk(10, netdata_app_cpu_utilization_percentage_average)
Title: Top CPU Processes
Columns:
- Process (from label)
- CPU % (value)
Transform: Organize fields
```

#### Top Memory Processes
```
Panel: Table
Query: topk(10, netdata_app_mem_usage_MiB_average)
Title: Top Memory Processes
Columns:
- Process (from label)
- Memory MB (value)
Transform: Organize fields
```

#### Docker Container Status
```
Panel: Stat
Queries:
- Running: netdata_docker_containers_state_containers_average{dimension="running"}
- Stopped: netdata_docker_containers_state_containers_average{dimension="stopped"}
- Paused: netdata_docker_containers_state_containers_average{dimension="paused"}
Title: Container Status
Layout: Auto
```

## 🚨 Alerting & Notifications

### Setting Up Alerts

#### 1. Configure Notification Channels
1. **Go to Alerting** → **Notification channels**
2. **Add notification channel:**
   - **Type:** Email, Slack, Discord, Webhook
   - **Settings:** Configure your endpoints
   - **Test:** Send test notification

#### 2. Create Alert Rules

##### High CPU Alert
```
Panel: Any CPU panel
Alert Tab:
- Name: High CPU Usage
- Evaluate every: 10s
- For: 2m
- Conditions:
  - Query: A (last, 5m, now)
  - IS ABOVE: 85
- No Data: Alerting
- Execution Error: Alerting
```

##### Low Memory Alert
```
Panel: Memory panel
Alert Tab:
- Name: Low Memory Available
- Evaluate every: 30s
- For: 1m
- Conditions:
  - Query: (netdata_system_ram_MiB_average{dimension="available"} / 
           netdata_system_ram_MiB_average{dimension="total"}) * 100
  - IS BELOW: 10
```

##### High Disk Usage Alert
```
Panel: Disk usage panel
Alert Tab:
- Name: High Disk Usage
- Evaluate every: 1m
- For: 5m
- Conditions:
  - Query: Disk usage percentage query
  - IS ABOVE: 90
```

## 🎨 Advanced Visualization Techniques

### 1. Custom Variables

#### Create Dashboard Variables
1. **Dashboard Settings** → **Variables** → **Add variable**

##### Host Variable
```
Name: host
Type: Query
Query: label_values(netdata_system_cpu_percentage_average, instance)
Refresh: On Dashboard Load
Multi-value: Yes
Include All: Yes
```

##### Time Range Variable
```
Name: timerange
Type: Interval
Values: 1m,5m,15m,30m,1h,6h,12h,1d
Auto: Yes
```

### 2. Template Queries
```
# Use variables in queries
netdata_system_cpu_percentage_average{instance=~"$host"}

# Dynamic titles
CPU Usage - $host

# Time range in queries
rate(netdata_system_cpu_percentage_average[$timerange])
```

### 3. Panel Linking
```
# Link panels to detailed dashboards
Data Links:
- Title: View Details
- URL: /d/detailed-dashboard?var-host=${__field.labels.instance}
- Open in: New tab
```

## 📱 Dashboard Organization

### Folder Structure
```
📁 System Monitoring/
├── 📊 Overview Dashboard
├── 📈 Performance Dashboard
├── 🐳 Container Dashboard
└── 🚨 Alerts Dashboard

📁 Application Monitoring/
├── 📊 Web Services
├── 📊 Database Performance
└── 📊 Custom Applications
```

### Dashboard Tags
```
Tags to use:
- system, performance, overview
- containers, docker, kubernetes
- network, security, alerts
- custom, application-specific
```

## 🔧 Dashboard Maintenance

### Regular Tasks

#### 1. Performance Optimization
```
- Review slow queries (Query Inspector)
- Optimize time ranges
- Use recording rules for complex queries
- Cache frequently used panels
```

#### 2. Dashboard Updates
```
- Update panel queries as metrics evolve
- Refresh dashboard imports
- Review and update alert thresholds
- Clean up unused panels/dashboards
```

#### 3. User Management
```
- Review user permissions
- Update team dashboards
- Manage dashboard sharing
- Backup important dashboards
```

## 🎯 Dashboard Templates

### 1. System Administrator Dashboard
```json
{
  "dashboard": {
    "title": "System Overview",
    "panels": [
      {
        "title": "System Health",
        "type": "stat",
        "targets": [
          {
            "expr": "100 - netdata_system_cpu_percentage_average{dimension=\"idle\"}"
          }
        ]
      }
    ]
  }
}
```

### 2. DevOps Dashboard
```json
{
  "dashboard": {
    "title": "Infrastructure Monitoring",
    "panels": [
      {
        "title": "Container Status",
        "type": "table",
        "targets": [
          {
            "expr": "netdata_docker_containers_state_containers_average"
          }
        ]
      }
    ]
  }
}
```

## 🛠️ Troubleshooting Common Issues

### Docker Networking Issues (Most Common)

#### Problem: Red exclamation marks, "dial tcp :9090: connection refused"
This is the most common issue when running Grafana and Prometheus in Docker containers.

**Root Cause:** Grafana is trying to connect to `localhost:9090`, but in Docker containers, `localhost` refers to the container itself, not the host machine.

**Solution:**
1. **Go to Configuration** → **Data Sources**
2. **Click on Prometheus data source**
3. **Change URL from:** `http://localhost:9090`
4. **Change URL to:** `http://prometheus:9090` (use Docker service name)
5. **Click "Save & Test"** - should show "Data source is working" ✅

**Quick Fix Script:** Run `./fix-grafana-datasource.sh` from your project directory.

**Prevention:** Always use Docker service names (`prometheus:9090`, `netdata:19999`) when configuring data sources in containerized environments.

### Data Source Problems
```
Issue: "No data" in panels
Solutions:
1. Check Prometheus connection in Data Sources (see Docker networking above)
2. Verify query syntax in Query Inspector
3. Check time range settings
4. Ensure metrics exist in Prometheus
5. Test query directly in Prometheus UI first
```

### Dashboard Import Issues
```
Issue: Imported dashboard shows all red panels
Solutions:
1. Delete the broken dashboard
2. Fix data source connection first (see Docker networking above)
3. Re-import dashboard with correct data source
4. Verify data source is selected during import
```

### Performance Issues
```
Issue: Slow dashboard loading
Solutions:
1. Reduce time range for heavy queries
2. Use recording rules in Prometheus
3. Optimize panel queries
4. Reduce refresh intervals
5. Check Docker container resources
```

### Alert Issues
```
Issue: Alerts not firing
Solutions:
1. Check alert rule conditions
2. Verify notification channels
3. Review alert history
4. Test with manual threshold breach
5. Ensure data source is working
```

### Container-Specific Issues
```
Issue: Grafana container won't start
Solutions:
1. Check Docker logs: docker logs grafana
2. Verify port 3000 is not in use
3. Check volume permissions
4. Restart containers: docker-compose restart grafana

Issue: Data source connection works but no metrics
Solutions:
1. Verify Prometheus is scraping Netdata: http://localhost:9090/targets
2. Check Prometheus logs: docker logs prometheus
3. Ensure Netdata is exposing metrics: http://localhost:19999/api/v1/allmetrics?format=prometheus
4. Restart the monitoring stack: docker-compose restart
```

## 📚 Advanced Features

### 1. Annotations
```
# Add events to graphs
Annotations:
- Name: Deployments
- Data source: Prometheus
- Query: deployment_events
- Title field: version
- Text field: description
```

### 2. Playlist
```
# Rotate through dashboards
Playlist:
- Add dashboards to rotation
- Set interval (30s, 1m, 5m)
- Enable kiosk mode for displays
```

### 3. Snapshots
```
# Share dashboard state
Snapshot:
- Create snapshot with current data
- Set expiration time
- Share URL with stakeholders
```

## 🎨 Custom Panel Examples

### 1. Heatmap Panel
```
Panel: Heatmap
Query: histogram_quantile(0.95, 
       rate(netdata_disk_await_milliseconds_operation_average[5m]))
Title: Disk Latency Heatmap
X-Axis: Time
Y-Axis: Latency (ms)
```

### 2. Worldmap Panel
```
Panel: Worldmap
Query: netdata_net_net_kilobits_persec_average by (country)
Title: Global Network Traffic
Location: Country
Metric: Traffic
```

### 3. Pie Chart Panel
```
Panel: Pie chart
Query: topk(5, netdata_app_cpu_utilization_percentage_average)
Title: CPU Usage by Process
Legend: Process names
Values: CPU percentage
```

## 🚀 Getting Started Checklist

### Initial Setup
- [ ] Login to Grafana (admin/admin)
- [ ] Verify Prometheus data source
- [ ] Import a pre-built dashboard (ID: 11074)
- [ ] Create your first custom panel
- [ ] Set up basic alerting

### Dashboard Creation
- [ ] Plan your dashboard layout
- [ ] Create system overview panels
- [ ] Add performance monitoring graphs
- [ ] Configure appropriate thresholds
- [ ] Test with different time ranges

### Advanced Features
- [ ] Set up dashboard variables
- [ ] Configure notification channels
- [ ] Create alert rules
- [ ] Organize dashboards in folders
- [ ] Share dashboards with team

## 💡 Pro Tips

### Dashboard Design
1. **Keep it simple** - Don't overcrowd panels
2. **Use consistent colors** - Same metrics = same colors
3. **Logical grouping** - Related metrics together
4. **Appropriate time ranges** - Match panel purpose
5. **Clear titles** - Descriptive panel names

### Query Optimization
1. **Use specific labels** - Reduce data volume
2. **Appropriate intervals** - Match refresh needs
3. **Recording rules** - For complex calculations
4. **Template variables** - For dynamic dashboards
5. **Query inspector** - Debug slow queries

### Alerting Best Practices
1. **Meaningful thresholds** - Based on actual usage patterns
2. **Appropriate timing** - Avoid alert spam
3. **Clear notifications** - Include context and actions
4. **Test regularly** - Ensure alerts work
5. **Document runbooks** - What to do when alerts fire

## 🔗 Useful Resources

### Dashboard Libraries
- **Grafana.com Dashboards:** https://grafana.com/grafana/dashboards/
- **Netdata Dashboards:** Search for "netdata" on grafana.com
- **Prometheus Dashboards:** Community-maintained collections

### Documentation
- **Grafana Docs:** https://grafana.com/docs/
- **Panel Types:** Complete reference for all panel types
- **Alerting Guide:** Comprehensive alerting documentation
- **API Reference:** For programmatic dashboard management

---

**Start exploring!** 🚀 Begin with importing dashboard ID `11074` for a complete Netdata overview, then customize it to match your monitoring needs. Grafana's power lies in its flexibility - experiment with different visualizations to find what works best for your use case!