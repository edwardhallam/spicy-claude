# Spicy Claude - Deployment Documentation

Complete deployment guide for running Spicy Claude in production on macOS.

## Overview

Spicy Claude is deployed as a macOS LaunchAgent service running on port 3002. It replaces the previous claude-code-webui installation while maintaining all monitoring and alerting integration.

## Deployment Status

- **Version**: 1.0.0
- **Port**: 3002
- **Platform**: macOS (LaunchAgent)
- **Auto-start**: Yes (RunAtLoad + KeepAlive)
- **Monitoring**: Via homelab-conductor Prometheus stack
- **Alerting**: Slack #homelab-updates channel
- **Updates**: Manual only (no automation)

## Quick Deployment

```bash
cd /Users/edwardhallam/projects/spicy-claude/deployment
./install.sh
```

The installation script will:
1. ✅ Check prerequisites (Node.js, npm)
2. 🔨 Build backend (`npm install && npm run build`)
3. 📦 Install LaunchAgent to `~/Library/LaunchAgents/`
4. 🚀 Start service on port 3002
5. ✅ Run health check

## Network Access

By default, Spicy Claude is configured to be accessible from any device on your local network.

### Accessing the Application

- **From the host machine**: http://localhost:3002/ or http://127.0.0.1:3002/
- **From other devices on the network**: http://<host-machine-ip>:3002/
  - To find your machine's IP: `ifconfig | grep "inet "` (look for your local network IP, typically 192.168.x.x or 10.0.x.x)

### Security Considerations

The application binds to all network interfaces (0.0.0.0) to allow access from other devices. This means:
- Any device on your local network can access the application
- The application is NOT accessible from the internet (assuming standard home network NAT)
- No authentication is currently implemented

If you want to restrict access to localhost only, edit the plist file and change `<string>0.0.0.0</string>` to `<string>127.0.0.1</string>`, then restart the service.

## Service Management

### Start Service
```bash
cd /Users/edwardhallam/projects/spicy-claude/deployment
./start.sh
```

### Stop Service
```bash
cd /Users/edwardhallam/projects/spicy-claude/deployment
./stop.sh
```

### Restart Service
```bash
cd /Users/edwardhallam/projects/spicy-claude/deployment
./restart.sh
```

### Check Status
```bash
cd /Users/edwardhallam/projects/spicy-claude/deployment
./status.sh
```

## LaunchAgent Configuration

**Location**: `~/Library/LaunchAgents/com.homelab.spicy-claude.plist`

**Key Settings**:
- Program: `/opt/homebrew/bin/node` (macOS Apple Silicon)
- Arguments: `dist/cli/node.js --port 3002 --host 0.0.0.0`
- Working Directory: `/Users/edwardhallam/projects/spicy-claude/backend`
- RunAtLoad: `true` (starts automatically on login)
- KeepAlive: `true` (auto-restart if crashes)
- Logs: `~/Library/Logs/spicy-claude/`

**Manual LaunchAgent Control**:
```bash
# Load (start)
launchctl load ~/Library/LaunchAgents/com.homelab.spicy-claude.plist

# Unload (stop)
launchctl unload ~/Library/LaunchAgents/com.homelab.spicy-claude.plist

# Check status
launchctl list | grep spicy-claude
```

## Prerequisites

### Required Software
- **Node.js**: v20.11.0+ (installed via Homebrew)
- **npm**: Comes with Node.js
- **Git**: For source code management

**Verify Prerequisites**:
```bash
node --version  # Should be v20.11.0+
npm --version
git --version
```

### System Requirements
- **OS**: macOS (tested on macOS 15.0+)
- **Architecture**: Apple Silicon (M1/M2/M3) or Intel
- **RAM**: 2GB+ available
- **Disk**: 500MB+ for application and build artifacts

## Build Process

The backend is built from TypeScript source:

```bash
cd /Users/edwardhallam/projects/spicy-claude/backend
npm install
npm run build
```

**Build Output**: `dist/cli/node.js` (entry point)

**Build Steps**:
1. `prebuild`: Generate version file (`scripts/generate-version.js`)
2. `build:clean`: Remove old dist/ directory
3. `build:bundle`: Create JavaScript bundle (`scripts/build-bundle.js`)
4. `build:static`: Copy frontend files to dist/static

## Logs

**Location**: `~/Library/Logs/spicy-claude/`

**Files**:
- `stdout.log` - Application output
- `stderr.log` - Error messages

**View Logs**:
```bash
# Follow stdout
tail -f ~/Library/Logs/spicy-claude/stdout.log

# Follow stderr
tail -f ~/Library/Logs/spicy-claude/stderr.log

# Last 50 lines
tail -50 ~/Library/Logs/spicy-claude/stdout.log
```

## Monitoring Integration

Spicy Claude is monitored by the homelab-conductor Prometheus stack:

- **Prometheus Job**: `claudecodeui`
- **Probe Type**: HTTP (Blackbox Exporter)
- **Target**: `http://host.docker.internal:3002`
- **Scrape Interval**: 30s
- **Health Check**: HTTP 200 response

**Alerts** (via Alertmanager → Slack #homelab-updates):
- **ClaudeCodeUIDown**: Service down for 5+ minutes (warning)
- **ClaudeCodeUICritical**: Service down for 15+ minutes (critical)
- **ClaudeCodeUISlow**: Response time >3 seconds
- **ClaudeCodeUIVerySlow**: Response time >10 seconds
- **ClaudeCodeUIFlapping**: Service restarting frequently
- **ClaudeCodeUIHTTPError**: HTTP 4xx/5xx responses

**View Monitoring**:
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000
- Alertmanager: http://localhost:9093

See also: `/Users/edwardhallam/projects/homelab-conductor/config/prometheus/alerts/claudecodeui-alerts.yml`

## Troubleshooting

### Service Won't Start

**Check if port 3002 is in use**:
```bash
lsof -i:3002
```

**Kill process on port 3002**:
```bash
lsof -ti:3002 | xargs kill -9
```

**Check logs for errors**:
```bash
tail -50 ~/Library/Logs/spicy-claude/stderr.log
```

### Build Failed

**Ensure Node.js and npm are installed**:
```bash
node --version  # Should be v20.11.0+
npm --version
```

**Rebuild manually**:
```bash
cd /Users/edwardhallam/projects/spicy-claude/backend
npm install
npm run build
```

**Verify build output**:
```bash
ls -la /Users/edwardhallam/projects/spicy-claude/backend/dist/cli/node.js
```

### LaunchAgent Not Loading

**Check plist syntax**:
```bash
plutil -lint ~/Library/LaunchAgents/com.homelab.spicy-claude.plist
```

**Unload and reload**:
```bash
cd /Users/edwardhallam/projects/spicy-claude/deployment
./stop.sh
./start.sh
```

**Check system logs**:
```bash
log show --predicate 'subsystem == "com.apple.launchd"' --last 10m | grep spicy-claude
```

### Monitoring Not Working

**Verify Prometheus is scraping the target**:
```bash
curl -s "http://localhost:9090/api/v1/targets" | grep claudecodeui
```

**Check if service is responding**:
```bash
curl -I http://localhost:3002
```

**Reload Prometheus config**:
```bash
docker exec prometheus kill -HUP 1
```

## Uninstallation

To completely remove Spicy Claude:

```bash
# Stop service
cd /Users/edwardhallam/projects/spicy-claude/deployment
./stop.sh

# Remove LaunchAgent
rm ~/Library/LaunchAgents/com.homelab.spicy-claude.plist

# Remove logs (optional)
rm -rf ~/Library/Logs/spicy-claude/

# Remove source code (optional)
# cd /Users/edwardhallam/projects/
# rm -rf spicy-claude/
```

## Deployment Architecture

```
spicy-claude/
├── backend/
│   ├── src/                    # TypeScript source
│   ├── dist/cli/node.js        # Built entry point ← LaunchAgent runs this
│   ├── dist/static/            # Frontend assets
│   └── package.json
├── deployment/
│   ├── install.sh              # Initial setup
│   ├── start.sh                # Start service
│   ├── stop.sh                 # Stop service
│   ├── restart.sh              # Restart service
│   ├── status.sh               # Check status
│   ├── launchd/
│   │   └── com.homelab.spicy-claude.plist  ← Copied to ~/Library/LaunchAgents/
│   └── README.md
├── tests/                      # Playwright UI tests (20 tests)
└── docs/                       # This documentation
```

## Integration with Homelab Conductor

Spicy Claude integrates with the homelab-conductor monitoring stack:

**Monitoring Configuration**:
- **Prometheus Config**: `/Users/edwardhallam/projects/homelab-conductor/config/prometheus/prometheus.yml:447-486`
- **Alert Rules**: `/Users/edwardhallam/projects/homelab-conductor/config/prometheus/alerts/claudecodeui-alerts.yml`

**No changes needed** - monitoring continues to use port 3002 after migration from old claude-code-webui.

See also: [MONITORING.md](MONITORING.md)

## Related Documentation

- [README.md](../README.md) - Project overview and features
- [TESTING.md](TESTING.md) - Test suite documentation
- [MONITORING.md](MONITORING.md) - Detailed monitoring guide
- [OPERATIONS.md](OPERATIONS.md) - Day-to-day operations
- [UPDATES.md](UPDATES.md) - Manual update process
- [DEVELOPMENT.md](DEVELOPMENT.md) - Development workflow

---

**Last Updated**: 2025-10-26
**Deployment Version**: 1.0.0
**Platform**: macOS LaunchAgent
**Port**: 3002
**Monitoring**: Via homelab-conductor
