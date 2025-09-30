# 📊 Prometheus Query Guide for Netdata Monitoring

A comprehensive guide to querying your Netdata metrics through Prometheus, with practical examples and advanced techniques.

## 🚀 Quick Start

**Access Prometheus:** http://localhost:9090
1. Click the **"Graph"** tab
2. Enter any query from this guide
3. Click **"Execute"**
4. Switch between **"Table"** and **"Graph"** views

## 📈 Essential System Metrics

### 🖥️ CPU Monitoring

#### Basic CPU Queries
```promql
# Current CPU usage by type
netdata_system_cpu_percentage_average{dimension="user"}
netdata_system_cpu_percentage_average{dimension="system"}
netdata_system_cpu_percentage_average{dimension="idle"}
netdata_system_cpu_percentage_average{dimension="iowait"}

# Total CPU utilization (100% - idle)
100 - netdata_system_cpu_percentage_average{dimension="idle"}

# CPU usage over time (5-minute rate)
rate(netdata_system_cpu_percentage_average{dimension="user"}[5m]) * 100
```

#### Advanced CPU Analysis
```promql
# CPU utilization trend (1-hour average)
avg_over_time(netdata_system_cpu_percentage_average{dimension!="idle"}[1h])

# CPU spike detection (usage > 80%)
netdata_system_cpu_percentage_average{dimension="user"} > 80

# CPU context switches per second
netdata_system_ctxt_context_switches_persec_average

# CPU interrupts per second
netdata_system_intr_interrupts_persec_average
```

### 💾 Memory Monitoring

#### Basic Memory Queries
```promql
# Memory usage in MB
netdata_system_ram_MiB_average{dimension="used"}
netdata_system_ram_MiB_average{dimension="free"}
netdata_system_ram_MiB_average{dimension="available"}
netdata_system_ram_MiB_average{dimension="buffers"}
netdata_system_ram_MiB_average{dimension="cached"}

# Memory utilization percentage
(netdata_system_ram_MiB_average{dimension="used"} / netdata_system_ram_MiB_average{dimension="total"}) * 100

# Available memory percentage
(netdata_system_ram_MiB_average{dimension="available"} / netdata_system_ram_MiB_average{dimension="total"}) * 100
```

#### Advanced Memory Analysis
```promql
# Memory pressure indicators
netdata_system_memory_some_pressure_percentage_average
netdata_system_memory_full_pressure_percentage_average

# Swap usage
netdata_mem_swap_MiB_average{dimension="used"}
netdata_mem_swap_MiB_average{dimension="free"}

# Memory page faults
netdata_mem_pgfaults_faults_persec_average{dimension="major"}
netdata_mem_pgfaults_faults_persec_average{dimension="minor"}

# Out of memory kills
netdata_mem_oom_kill_kills_persec_average
```

### 💿 Disk Monitoring

#### Basic Disk Queries
```promql
# Disk space usage in GB
netdata_disk_space_GiB_average{dimension="used"}
netdata_disk_space_GiB_average{dimension="avail"}

# Disk utilization percentage
(netdata_disk_space_GiB_average{dimension="used"} / 
 (netdata_disk_space_GiB_average{dimension="used"} + netdata_disk_space_GiB_average{dimension="avail"})) * 100

# Disk I/O operations per second
netdata_disk_ops_operations_persec_average{dimension="reads"}
netdata_disk_ops_operations_persec_average{dimension="writes"}

# Disk I/O throughput (KB/s)
netdata_disk_io_KiB_persec_average{dimension="reads"}
netdata_disk_io_KiB_persec_average{dimension="writes"}
```

#### Advanced Disk Analysis
```promql
# Disk I/O latency (await time)
netdata_disk_await_milliseconds_operation_average{dimension="reads"}
netdata_disk_await_milliseconds_operation_average{dimension="writes"}

# Disk utilization (% time busy)
netdata_disk_util___of_time_working_average

# Disk queue length
netdata_disk_qops_operations_average

# I/O pressure indicators
netdata_system_io_some_pressure_percentage_average
netdata_system_io_full_pressure_percentage_average

# Disk service time
netdata_disk_svctm_milliseconds_operation_average
```

### 🌐 Network Monitoring

#### Basic Network Queries
```promql
# Network traffic (kilobits/sec)
netdata_net_net_kilobits_persec_average{dimension="received"}
netdata_net_net_kilobits_persec_average{dimension="sent"}

# Total network traffic
netdata_net_net_kilobits_persec_average{dimension="received"} + 
netdata_net_net_kilobits_persec_average{dimension="sent"}

# Network packets per second
netdata_net_packets_packets_persec_average{dimension="received"}
netdata_net_packets_packets_persec_average{dimension="sent"}

# Network errors and drops
netdata_net_errors_errors_persec_average
netdata_net_drops_drops_persec_average
```

#### Advanced Network Analysis
```promql
# TCP connection states
netdata_ip_tcpsock_active_connections_average

# TCP connection errors
netdata_ip_tcperrors_packets_persec_average{dimension="InErrs"}
netdata_ip_tcperrors_packets_persec_average{dimension="InCsumErrors"}

# Network interface status
netdata_net_operstate_state_average
netdata_net_carrier_state_average

# TCP handshake metrics
netdata_ip_tcphandshake_events_persec_average{dimension="SynRetrans"}
netdata_ip_tcphandshake_events_persec_average{dimension="ActiveOpens"}

# UDP packet statistics
netdata_ip_udppackets_packets_persec_average{dimension="received"}
netdata_ip_udppackets_packets_persec_average{dimension="sent"}
```

## 📊 System Performance Metrics

### ⚡ System Load
```promql
# Load averages
netdata_system_load_load_average{dimension="load1"}   # 1-minute
netdata_system_load_load_average{dimension="load5"}   # 5-minute
netdata_system_load_load_average{dimension="load15"}  # 15-minute

# Load per CPU core (normalize load)
netdata_system_load_load_average{dimension="load1"} / 
scalar(count(count by (cpu)(netdata_system_cpu_percentage_average)))

# System uptime
netdata_system_uptime_seconds_average
```

### 🔄 Process Monitoring
```promql
# Process counts by state
netdata_system_processes_processes_average{dimension="running"}
netdata_system_processes_processes_average{dimension="sleeping"}
netdata_system_processes_processes_average{dimension="zombie"}
netdata_system_processes_processes_average{dimension="stopped"}

# Process creation rate
netdata_system_forks_processes_persec_average

# File descriptor usage
netdata_system_file_nr_used_files_average
netdata_system_file_nr_utilization_percentage_average
```

## 🐳 Container & Application Monitoring

### Docker Metrics
```promql
# Container counts by state
netdata_docker_containers_state_containers_average{dimension="running"}
netdata_docker_containers_state_containers_average{dimension="paused"}
netdata_docker_containers_state_containers_average{dimension="stopped"}

# Container health status
netdata_docker_containers_health_status_containers_average{dimension="healthy"}
netdata_docker_containers_health_status_containers_average{dimension="unhealthy"}

# Docker images
netdata_docker_images_images_average
netdata_docker_images_size_bytes_average
```

### Application Performance
```promql
# Top CPU consuming applications
topk(5, netdata_app_cpu_utilization_percentage_average)

# Top memory consuming applications
topk(5, netdata_app_mem_usage_MiB_average)

# Application disk I/O
netdata_app_disk_logical_io_KiB_persec_average{dimension="reads"}
netdata_app_disk_physical_io_KiB_persec_average{dimension="writes"}

# Application file descriptors
netdata_app_fds_open_fds_average
netdata_app_fds_open_limit_percent_average
```

## 🔍 Advanced Query Techniques

### 📈 Rate Calculations
```promql
# Calculate rates over time windows
rate(netdata_system_cpu_percentage_average[5m])     # 5-minute rate
rate(netdata_net_net_kilobits_persec_average[1m])   # 1-minute rate
rate(netdata_disk_io_KiB_persec_average[10m])       # 10-minute rate

# Increase calculations (for counters)
increase(netdata_system_intr_interrupts_persec_average[1h])  # 1-hour increase
```

### 📊 Aggregation Functions
```promql
# Statistical aggregations
avg(netdata_system_cpu_percentage_average)          # Average across all dimensions
sum(netdata_net_net_kilobits_persec_average)        # Sum all network interfaces
max(netdata_disk_util___of_time_working_average)    # Maximum disk utilization
min(netdata_system_ram_MiB_average{dimension="free"}) # Minimum free memory

# Group by labels
sum(netdata_net_net_kilobits_persec_average) by (dimension)
avg(netdata_disk_io_KiB_persec_average) by (device)
```

### 🎯 Filtering and Selection
```promql
# Filter by dimension
netdata_system_cpu_percentage_average{dimension="user"}
netdata_system_cpu_percentage_average{dimension!="idle"}  # Not idle

# Regular expressions
netdata_net_net_kilobits_persec_average{device=~"eth.*"}  # Ethernet interfaces
netdata_disk_space_GiB_average{mount=~"/.*"}              # All mount points

# Top K values
topk(3, netdata_app_cpu_utilization_percentage_average)   # Top 3 CPU users
bottomk(2, netdata_disk_space_GiB_average{dimension="avail"}) # Lowest 2 available disk space
```

### ⏰ Time-based Queries
```promql
# Time range aggregations
avg_over_time(netdata_system_cpu_percentage_average[1h])     # 1-hour average
max_over_time(netdata_system_load_load_average[30m])        # 30-minute maximum
min_over_time(netdata_system_ram_MiB_average{dimension="free"}[2h]) # 2-hour minimum

# Time shifting (compare with past)
netdata_system_cpu_percentage_average offset 1h            # CPU usage 1 hour ago
netdata_system_ram_MiB_average{dimension="used"} - 
netdata_system_ram_MiB_average{dimension="used"} offset 1d  # Memory change from yesterday
```

## 🚨 Alerting Queries

### Critical System Alerts
```promql
# High CPU usage (>90%)
netdata_system_cpu_percentage_average{dimension="user"} + 
netdata_system_cpu_percentage_average{dimension="system"} > 90

# Low memory (<10% available)
(netdata_system_ram_MiB_average{dimension="available"} / 
 netdata_system_ram_MiB_average{dimension="total"}) * 100 < 10

# High disk usage (>90%)
(netdata_disk_space_GiB_average{dimension="used"} / 
 (netdata_disk_space_GiB_average{dimension="used"} + netdata_disk_space_GiB_average{dimension="avail"})) * 100 > 90

# High load average (>2x CPU cores)
netdata_system_load_load_average{dimension="load5"} > 4  # Adjust based on your CPU count
```

### Performance Degradation Detection
```promql
# Disk I/O latency spike (>100ms)
netdata_disk_await_milliseconds_operation_average > 100

# Network errors increasing
rate(netdata_net_errors_errors_persec_average[5m]) > 0

# Memory pressure
netdata_system_memory_some_pressure_percentage_average > 10

# Too many processes
netdata_system_processes_processes_average{dimension="total"} > 1000
```

## 📋 Useful Query Patterns

### System Health Dashboard
```promql
# Overall system health score (custom calculation)
(
  (100 - netdata_system_cpu_percentage_average{dimension="idle"}) * 0.3 +
  (netdata_system_ram_MiB_average{dimension="used"} / netdata_system_ram_MiB_average{dimension="total"} * 100) * 0.3 +
  (netdata_system_load_load_average{dimension="load5"} / 4 * 100) * 0.2 +
  (netdata_disk_util___of_time_working_average) * 0.2
) / 4

# Resource utilization summary
label_replace(
  netdata_system_cpu_percentage_average{dimension="user"} + 
  netdata_system_cpu_percentage_average{dimension="system"}, 
  "resource", "CPU", "", ""
)
```

### Capacity Planning
```promql
# Predict when disk will be full (linear regression)
predict_linear(netdata_disk_space_GiB_average{dimension="used"}[7d], 86400 * 30)  # 30 days

# Memory growth trend
deriv(netdata_system_ram_MiB_average{dimension="used"}[1h])  # Memory growth rate per hour

# Network bandwidth utilization trend
rate(netdata_net_net_kilobits_persec_average[1h])
```

## 🛠️ Troubleshooting Queries

### Performance Investigation
```promql
# Find processes causing high I/O wait
netdata_system_cpu_percentage_average{dimension="iowait"} > 20

# Identify memory leaks (continuously growing memory)
increase(netdata_app_mem_usage_MiB_average[1h]) > 100

# Network bottleneck detection
netdata_net_net_kilobits_persec_average / netdata_net_speed_kilobits_persec_average * 100 > 80
```

### System Anomaly Detection
```promql
# Unusual CPU spikes (>3 standard deviations)
abs(netdata_system_cpu_percentage_average{dimension="user"} - 
    avg_over_time(netdata_system_cpu_percentage_average{dimension="user"}[1h])) > 
    3 * stddev_over_time(netdata_system_cpu_percentage_average{dimension="user"}[1h])

# Memory usage anomalies
abs(netdata_system_ram_MiB_average{dimension="used"} - 
    avg_over_time(netdata_system_ram_MiB_average{dimension="used"}[2h])) > 
    2 * stddev_over_time(netdata_system_ram_MiB_average{dimension="used"}[2h])
```

## 🎯 Query Optimization Tips

### Performance Best Practices
1. **Use specific label filters** to reduce data volume:
   ```promql
   # Good: Specific dimension
   netdata_system_cpu_percentage_average{dimension="user"}
   
   # Avoid: All dimensions
   netdata_system_cpu_percentage_average
   ```

2. **Limit time ranges** for expensive queries:
   ```promql
   # Good: Reasonable time range
   rate(netdata_system_cpu_percentage_average[5m])
   
   # Avoid: Very long ranges without need
   rate(netdata_system_cpu_percentage_average[7d])
   ```

3. **Use recording rules** for frequently used complex queries
4. **Aggregate early** in the query pipeline
5. **Use `topk()` and `bottomk()`** instead of sorting all results

### Common Query Patterns
```promql
# Multi-metric dashboard panel
{
  netdata_system_cpu_percentage_average{dimension="user"},
  netdata_system_ram_MiB_average{dimension="used"} / 1024,  # Convert to GB
  netdata_system_load_load_average{dimension="load1"}
}

# Ratio calculations
netdata_system_ram_MiB_average{dimension="used"} / 
netdata_system_ram_MiB_average{dimension="total"}

# Threshold-based alerts
netdata_system_cpu_percentage_average{dimension="user"} > bool 80
```

## 📚 Additional Resources

### Prometheus Functions Reference
- **Aggregation:** `sum()`, `avg()`, `max()`, `min()`, `count()`
- **Rate/Increase:** `rate()`, `irate()`, `increase()`
- **Time:** `time()`, `timestamp()`, `offset`
- **Math:** `abs()`, `ceil()`, `floor()`, `round()`
- **Sorting:** `topk()`, `bottomk()`, `sort()`, `sort_desc()`

### PromQL Operators
- **Arithmetic:** `+`, `-`, `*`, `/`, `%`, `^`
- **Comparison:** `==`, `!=`, `>`, `<`, `>=`, `<=`
- **Logical:** `and`, `or`, `unless`
- **Set:** `group_left`, `group_right`, `on`, `ignoring`

### Useful Label Matchers
- **Exact match:** `{label="value"}`
- **Negative match:** `{label!="value"}`
- **Regex match:** `{label=~"regex"}`
- **Negative regex:** `{label!~"regex"}`

## 🚀 Getting Started Checklist

1. ✅ **Access Prometheus:** http://localhost:9090
2. ✅ **Try basic queries:** Start with simple CPU/memory queries
3. ✅ **Explore metrics:** Use the metrics browser (click "Metrics" dropdown)
4. ✅ **Create dashboards:** Export queries to Grafana for visualization
5. ✅ **Set up alerts:** Use alerting queries for monitoring
6. ✅ **Practice PromQL:** Experiment with different functions and operators

## 💡 Pro Tips

- **Use the query browser** in Prometheus UI to explore available metrics
- **Start simple** and build complexity gradually
- **Test queries** in small time ranges first
- **Document your queries** for team sharing
- **Use Grafana** for better visualization of Prometheus data
- **Set up recording rules** for expensive queries used in dashboards
- **Monitor query performance** in Prometheus admin interface

---

**Happy querying!** 📊 This guide covers the essential patterns for monitoring your system with Prometheus and Netdata. Experiment with these queries and adapt them to your specific monitoring needs.