# Spicy Claude - Operations Guide

Day-to-day operational tasks for managing Spicy Claude.

## Quick Reference

```bash
# Service Management
cd /Users/edwardhallam/projects/spicy-claude/deployment
./status.sh          # Check service status
./start.sh           # Start service
./stop.sh            # Stop service
./restart.sh         # Restart service

# Testing
cd /Users/edwardhallam/projects/spicy-claude
npm run test:ui      # Run all 20 tests (~15 minutes)
npm run test:bypass  # Run bypass mode tests only (~4 minutes)
npm run test:report  # View HTML test report

# Logs
tail -f ~/Library/Logs/spicy-claude/stdout.log   # Application logs
tail -f ~/Library/Logs/spicy-claude/stderr.log   # Error logs

# Monitoring
open http://localhost:9090   # Prometheus
open http://localhost:3000   # Grafana
open http://localhost:9093   # Alertmanager
open http://localhost:3002   # Spicy Claude UI
```

## Daily Operations

### Morning Check
```bash
# Quick health check
curl -I http://localhost:3002

# View status
cd /Users/edwardhallam/projects/spicy-claude/deployment
./status.sh
```

**Expected**:
- HTTP 200 response
- LaunchAgent running
- Port 3002 in use
- No recent errors in stderr log

### Responding to Alerts

Alert notifications arrive in Slack #homelab-updates.

**ClaudeCodeUIDown (Warning - 5+ min downtime)**:
1. Check status: `cd ~/projects/spicy-claude/deployment && ./status.sh`
2. Review logs: `tail -50 ~/Library/Logs/spicy-claude/stderr.log`
3. Restart service: `./restart.sh`
4. Verify recovery: `curl -I http://localhost:3002`
5. Monitor for 10 minutes to ensure stability

**ClaudeCodeUICritical (Critical - 15+ min downtime)**:
1. Check service: `launchctl list | grep spicy-claude`
2. Review logs: `tail -100 ~/Library/Logs/spicy-claude/stderr.log`
3. Check port conflicts: `lsof -i:3002`
4. Restart: `cd ~/projects/spicy-claude/deployment && ./restart.sh`
5. If still failing: Rebuild (`cd backend && npm run build`)
6. If still failing: Check Node.js version (`node --version`)
7. Document incident and investigate root cause

**ClaudeCodeUISlow (Response time >3s)**:
1. Check Mac Studio resource usage (Activity Monitor)
2. Review application logs for slow operations
3. Restart service if degraded: `./restart.sh`

### Weekly Tasks

**Monday Morning**:
- Review Slack alerts from past week
- Check Grafana dashboard for trends
- Run quick test suite: `npm run test:bypass`

**Wednesday**:
- Review logs for errors: `grep ERROR ~/Library/Logs/spicy-claude/stderr.log`
- Check disk space: `df -h`

**Friday**:
- Review Prometheus metrics: `open http://localhost:9090`
- Plan any needed maintenance for weekend

## Common Tasks

### Restart Service

**When**: After code changes, config changes, or when service is unresponsive

```bash
cd /Users/edwardhallam/projects/spicy-claude/deployment
./restart.sh
```

Waits for clean shutdown, then starts service.

### Network Configuration

The service is configured to accept connections from any device on the local network. To verify:

```bash
# Check what address the service is bound to
lsof -i :3002

# Should show something like:
# node    12345 user   23u  IPv4 0x... TCP *:3002 (LISTEN)
```

To find your machine's IP address for remote access:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

### View Logs

**Real-time**:
```bash
# Application output
tail -f ~/Library/Logs/spicy-claude/stdout.log

# Errors only
tail -f ~/Library/Logs/spicy-claude/stderr.log

# Both
tail -f ~/Library/Logs/spicy-claude/*.log
```

**Search logs**:
```bash
# Find errors
grep -i error ~/Library/Logs/spicy-claude/stderr.log

# Last 100 lines with timestamps
tail -100 ~/Library/Logs/spicy-claude/stdout.log

# Search for specific text
grep "bypass mode" ~/Library/Logs/spicy-claude/stdout.log
```

### Run Tests

**Full test suite**:
```bash
cd /Users/edwardhallam/projects/spicy-claude
npm run test:ui
```

**Specific test suites**:
```bash
npm run test:comparison    # Old App vs Spicy Claude comparison
npm run test:bypass        # Bypass permissions mode tests
npm run test:permissions   # Permission prompt behavior
```

**Single test**:
```bash
npm test -- -g "BP-W1"  # Run test matching "BP-W1"
```

**View test results**:
```bash
npm run test:report  # Opens HTML report in browser
```

### Check Monitoring

**Prometheus Targets**:
```bash
curl -s "http://localhost:9090/api/v1/targets" | grep claudecodeui
```

**Current Metric Value**:
```bash
# Service health (1=up, 0=down)
curl -s "http://localhost:9090/api/v1/query?query=probe_success{job=\"claudecodeui\"}" | python3 -m json.tool

# Response time
curl -s "http://localhost:9090/api/v1/query?query=probe_http_duration_seconds{job=\"claudecodeui\"}" | python3 -m json.tool
```

**Active Alerts**:
```bash
curl -s http://localhost:9093/api/v2/alerts | python3 -m json.tool
```

### Silence Alerts

**Use cases**:
- Planned maintenance
- Known issues being investigated
- Temporary service disruption

**Via Alertmanager UI**:
1. http://localhost:9093
2. Silences → New Silence
3. Matcher: `service=claudecodeui`
4. Duration: 1h (or as needed)
5. Comment: Reason for silence
6. Create

**Via Command Line**:
```bash
# Requires amtool (install via: brew install alertmanager)
amtool silence add \
  --alertmanager.url=http://localhost:9093 \
  --duration=1h \
  --comment="Planned maintenance" \
  service=claudecodeui
```

## Maintenance Windows

### Planned Maintenance

1. **Schedule**: Choose low-usage time (late evening/weekend)
2. **Notify**: Post in Slack #homelab-updates
3. **Silence alerts**: 30 minutes before start
4. **Perform maintenance**
5. **Validate**: Run tests after changes
6. **Monitor**: Watch for 30 minutes post-maintenance
7. **Clear silence**: If completed early

### Emergency Maintenance

If immediate intervention required:

1. **Stop service**: `cd ~/projects/spicy-claude/deployment && ./stop.sh`
2. **Silence alerts**: Via Alertmanager UI (quick)
3. **Investigate**: Review logs, check system resources
4. **Fix issue**: Apply fix (code change, config, restart)
5. **Test**: Run bypass tests to validate
6. **Restart**: `./start.sh`
7. **Monitor**: Watch logs and metrics closely

## Troubleshooting

### Service Won't Start

**Symptoms**: `./start.sh` fails or service crashes immediately

**Diagnosis**:
```bash
# Check if port is in use
lsof -i:3002

# Check recent logs
tail -50 ~/Library/Logs/spicy-claude/stderr.log

# Check LaunchAgent status
launchctl list | grep spicy-claude

# Verify build exists
ls -la backend/dist/cli/node.js
```

**Solutions**:
1. Kill process on port 3002: `lsof -ti:3002 | xargs kill -9`
2. Rebuild backend: `cd backend && npm run build`
3. Check Node.js version: `node --version` (need v20.11.0+)
4. Review plist syntax: `plutil -lint ~/Library/LaunchAgents/com.homelab.spicy-claude.plist`

### Service Keeps Crashing

**Symptoms**: Service starts but exits shortly after

**Diagnosis**:
```bash
# Watch logs in real-time
tail -f ~/Library/Logs/spicy-claude/stderr.log

# Check for out-of-memory errors
grep -i memory ~/Library/Logs/spicy-claude/stderr.log

# Check system resources
top -l 1 | grep -A 5 "CPU usage"
```

**Solutions**:
1. Review stderr log for error messages
2. Check disk space: `df -h`
3. Check memory: `vm_stat`
4. Rebuild from clean state:
   ```bash
   cd backend
   rm -rf node_modules dist
   npm install
   npm run build
   cd ../deployment
   ./restart.sh
   ```

### Tests Failing

**Symptoms**: `npm run test:ui` reports failures

**Diagnosis**:
```bash
# Run tests with more detail
npm run test:ui:headed  # See browser during tests

# Run specific failing test
npm test -- -g "test-name"

# Check test logs
ls tests/reports/test-results/*/test-failed-*.png
```

**Solutions**:
1. Review test screenshots: `open tests/reports/test-results/*/test-failed-*.png`
2. Check if Spicy Claude is running on correct port
3. Verify Old App (port 3002) not interfering with tests
4. Review test documentation: `tests/README.md`

### Monitoring Gaps

**Symptoms**: No metrics in Prometheus

**Diagnosis**:
```bash
# Check if Prometheus is scraping
curl -s "http://localhost:9090/api/v1/targets" | grep claudecodeui

# Check if Spicy Claude is responding
curl -I http://localhost:3002

# Check if Blackbox Exporter is running
docker ps | grep blackbox
```

**Solutions**:
1. Restart Prometheus: `docker restart prometheus`
2. Reload Prometheus config: `docker exec prometheus kill -HUP 1`
3. Check Blackbox Exporter config: `docker logs blackbox-exporter`

## Performance Monitoring

### Key Metrics to Watch

**Service Health**:
- `probe_success{job="claudecodeui"}` - Should be 1 (up)

**Response Time**:
- `probe_http_duration_seconds{job="claudecodeui"}` - Should be <1s typically

**Uptime**:
- `avg_over_time(probe_success{job="claudecodeui"}[24h])` - Should be >0.995 (99.5%+)

### Performance Baselines

**Normal Operation**:
- Response time: 0.5-1.5 seconds
- Memory usage: ~100-200 MB
- CPU usage: <5% when idle
- Uptime: >99.5%

**Degraded Performance Indicators**:
- Response time: >3 seconds (investigate)
- Response time: >10 seconds (critical)
- Service restarts: >4 in 15 minutes (flapping)
- HTTP errors: 4xx/5xx responses

## Related Documentation

- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment and installation
- [MONITORING.md](MONITORING.md) - Monitoring configuration and alerts
- [UPDATES.md](UPDATES.md) - Manual update process
- [TESTING.md](../tests/README.md) - Test suite details
- [README.md](../README.md) - Project overview

---

**Last Updated**: 2025-10-26
**Service**: Spicy Claude v1.0.0
**Port**: 3002
**Platform**: macOS LaunchAgent
