# Spicy Claude - Monitoring Documentation

Complete monitoring and alerting guide for Spicy Claude.

## Overview

Spicy Claude is monitored by the homelab-conductor Prometheus stack. All monitoring and alerting were migrated from the previous claude-code-webui installation without any configuration changes required.

## Monitoring Architecture

```
Spicy Claude (port 3002)
    ↓
Blackbox Exporter (HTTP probe)
    ↓
Prometheus (scrape + store metrics)
    ↓
Alertmanager (route alerts)
    ↓
Slack (#homelab-updates channel)
```

## Prometheus Configuration

**Job Configuration**: `/Users/edwardhallam/projects/homelab-conductor/config/prometheus/prometheus.yml:447-486`

```yaml
- job_name: 'claudecodeui'
  scrape_interval: 30s
  scrape_timeout: 20s
  metrics_path: '/probe'

  params:
    module: [http_2xx]  # HTTP probe module

  static_configs:
    - targets:
        - 'http://host.docker.internal:3002'
      labels:
        service: 'claudecodeui'
        service_name: 'Claude Code Web UI'
        service_type: 'web-application'
        environment: 'production'
        target: 'mac-studio'
        monitoring_role: 'developer_tools'
```

**Key Metrics**:
- `probe_success{job="claudecodeui"}` - Service health (1=up, 0=down)
- `probe_http_duration_seconds{job="claudecodeui"}` - Response time
- `probe_http_status_code{job="claudecodeui"}` - HTTP status code

## Alert Rules

**Configuration**: `/Users/edwardhallam/projects/homelab-conductor/config/prometheus/alerts/claudecodeui-alerts.yml`

### ClaudeCodeUIDown
- **Severity**: Warning
- **Condition**: Service down for 5+ minutes
- **Priority**: P2
- **Actions**: Check service status, verify port, review logs, restart if needed

### ClaudeCodeUICritical
- **Severity**: Critical
- **Condition**: Service down for 15+ minutes
- **Priority**: P1
- **Actions**: Immediate investigation required - extended outage

### ClaudeCodeUISlow
- **Severity**: Warning
- **Condition**: Response time >3 seconds for 10+ minutes
- **Priority**: P2
- **Possible Causes**: High CPU/memory, application performance issues

### ClaudeCodeUIVerySlow
- **Severity**: Warning
- **Condition**: Response time >10 seconds for 5+ minutes
- **Priority**: P1
- **Impact**: Service severely degraded

### ClaudeCodeUIFlapping
- **Severity**: Warning
- **Condition**: Service state changes >4 times in 15 minutes
- **Priority**: P2
- **Indicates**: Service instability - check logs for errors

### ClaudeCodeUIHTTPError
- **Severity**: Warning
- **Condition**: HTTP status code ≥400 for 5+ minutes
- **Priority**: P2
- **Indicates**: Application misconfiguration or errors

### ClaudeCodeUINotDeployed
- **Severity**: Info
- **Condition**: No metrics for 1+ hour
- **Priority**: P2
- **Indicates**: Service not deployed (informational only)

## Viewing Monitoring Data

### Prometheus UI

**URL**: http://localhost:9090

**Useful Queries**:
```promql
# Service health (1=up, 0=down)
probe_success{job="claudecodeui"}

# Response time
probe_http_duration_seconds{job="claudecodeui"}

# HTTP status code
probe_http_status_code{job="claudecodeui"}

# Average response time over 5 minutes
rate(probe_http_duration_seconds{job="claudecodeui"}[5m])

# Uptime percentage (last 24 hours)
avg_over_time(probe_success{job="claudecodeui"}[24h]) * 100
```

### Grafana Dashboard

**URL**: http://localhost:3000

**Dashboard**: macOS Host (includes Spicy Claude metrics)

**Panels**:
- Service Health Status
- Response Time Graph
- HTTP Status Codes
- Uptime Percentage
- Alert Status

### Alertmanager

**URL**: http://localhost:9093

**Features**:
- View active alerts
- See alert history
- Silence alerts temporarily
- View routing configuration

## Slack Integration

**Channel**: #homelab-updates

**Notification Format**:
```
🔥 ClaudeCodeUIDown (warning)
Service: Claude Code Web UI
Status: Unreachable for 5 minutes

Troubleshooting:
1. Check service: cd ~/projects/spicy-claude/deployment && ./status.sh
2. View logs: tail -f ~/Library/Logs/spicy-claude/stderr.log
3. Restart: cd ~/projects/spicy-claude/deployment && ./restart.sh
```

**Alert Colors**:
- 🔴 Critical - Immediate attention required
- 🟠 Warning - Investigation needed
- 🔵 Info - Informational only
- ✅ Resolved - Alert cleared

## Troubleshooting Monitoring Issues

### No Metrics in Prometheus

**Check if Prometheus is scraping**:
```bash
curl -s "http://localhost:9090/api/v1/targets" | grep claudecodeui
```

**Expected Response**:
```json
{
  "health": "up",
  "lastScrape": "2025-10-26T12:52:11Z",
  "lastError": ""
}
```

**If health is "down"**:
1. Check if Spicy Claude is running: `curl -I http://localhost:3002`
2. Check Blackbox Exporter: `docker ps | grep blackbox`
3. Review Prometheus logs: `docker logs prometheus`

### Alerts Not Firing

**Check alert rules are loaded**:
```bash
curl -s http://localhost:9090/api/v1/rules | grep ClaudeCodeUI
```

**Check Alertmanager connection**:
```bash
curl -s http://localhost:9090/api/v1/alertmanagers
```

**Reload Prometheus configuration**:
```bash
docker exec prometheus kill -HUP 1
```

### Alerts Not Reaching Slack

**Check Alertmanager status**:
```bash
curl -s http://localhost:9093/-/healthy
```

**Review Alertmanager config**:
```bash
docker exec alertmanager cat /etc/alertmanager/alertmanager.yml
```

**Check Alertmanager logs**:
```bash
docker logs alertmanager | tail -50
```

## Monitoring Thresholds

Current thresholds are conservative for a development tool:

| Metric | Threshold | Tuning |
|--------|-----------|--------|
| Down Time | 5 minutes | Reduce to 2 minutes for stricter monitoring |
| Critical Down | 15 minutes | Adjust based on acceptable downtime |
| Slow Response | 3 seconds | Tune based on typical response times |
| Very Slow | 10 seconds | Indicates severe degradation |
| Flapping | 4 state changes / 15 min | Reduce if service is stable |

**To adjust thresholds**: Edit `/Users/edwardhallam/projects/homelab-conductor/config/prometheus/alerts/claudecodeui-alerts.yml` and reload Prometheus.

## Maintenance Windows

To silence alerts during maintenance:

**Via Alertmanager UI**:
1. Open http://localhost:9093
2. Click "Silences"
3. Click "New Silence"
4. Add matcher: `service=claudecodeui`
5. Set duration (e.g., 1 hour)
6. Add comment: "Maintenance window"
7. Click "Create"

**Via Command Line**:
```bash
# Silence for 1 hour
amtool silence add \
  --alertmanager.url=http://localhost:9093 \
  --duration=1h \
  --comment="Maintenance window" \
  service=claudecodeui
```

## Historical Data

Prometheus retains metrics for:
- **Raw data (15s resolution)**: 15 days
- **5-minute aggregates**: 90 days
- **1-hour aggregates**: 1 year

**Query historical uptime**:
```promql
# Uptime last 7 days
avg_over_time(probe_success{job="claudecodeui"}[7d]) * 100

# Average response time last 30 days
avg_over_time(probe_http_duration_seconds{job="claudecodeui"}[30d])
```

## Related Configuration Files

**Homelab Conductor (monitoring stack)**:
- Prometheus config: `config/prometheus/prometheus.yml:447-486`
- Alert rules: `config/prometheus/alerts/claudecodeui-alerts.yml`
- Alertmanager config: `config/alertmanager/alertmanager.yml`
- Blackbox config: `config/blackbox/blackbox.yml`

**Spicy Claude**:
- Deployment: `deployment/install.sh`
- Service management: `deployment/status.sh`, `deployment/restart.sh`
- Logs: `~/Library/Logs/spicy-claude/`

## Monitoring Best Practices

1. **Check Dashboard Daily**: Quick visual check of service health
2. **Review Alerts Weekly**: Analyze alert patterns and adjust thresholds
3. **Silence During Maintenance**: Prevent false alerts during updates/restarts
4. **Monitor Logs**: Correlate alerts with log messages for faster troubleshooting
5. **Test Alerts**: Periodically stop service to verify alerting works

## Related Documentation

- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment and service management
- [OPERATIONS.md](OPERATIONS.md) - Day-to-day operations
- [README.md](../README.md) - Project overview

**Homelab Conductor Documentation**:
- Update automation: `/Users/edwardhallam/projects/homelab-conductor/docs/claude-code-webui-update-automation.md`
- Monitoring stack: `/Users/edwardhallam/projects/homelab-conductor/README.md`

---

**Last Updated**: 2025-10-26
**Monitoring Stack**: homelab-conductor Prometheus
**Alert Channel**: Slack #homelab-updates
**Retention**: 15 days raw, 90 days aggregated, 1 year hourly
