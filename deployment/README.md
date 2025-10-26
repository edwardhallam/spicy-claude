# Spicy Claude - Deployment Guide

Deployment scripts for running Spicy Claude as a macOS LaunchAgent service.

## Quick Start

```bash
# Initial installation (builds and starts service)
./install.sh

# Service management
./start.sh      # Start service
./stop.sh       # Stop service
./restart.sh    # Restart service
./status.sh     # Check status
```

## Installation

The `install.sh` script performs a complete setup:

1. ✅ Checks prerequisites (Node.js, npm)
2. 🔨 Builds backend (`npm install && npm run build`)
3. 📦 Installs LaunchAgent to `~/Library/LaunchAgents/`
4. 🚀 Starts service on port 3002
5. ✅ Runs health check

**Run once:**
```bash
./install.sh
```

**What it does:**
- Creates log directory at `~/Library/Logs/spicy-claude/`
- Builds backend from TypeScript source
- Installs LaunchAgent for automatic startup (survives reboots)
- Starts service immediately

## Service Management

### Start Service
```bash
./start.sh
```

Loads the LaunchAgent and starts Spicy Claude on port 3002. Includes health check.

### Stop Service
```bash
./stop.sh
```

Unloads the LaunchAgent and stops Spicy Claude. Verifies clean shutdown.

### Restart Service
```bash
./restart.sh
```

Stops and starts the service. Useful after configuration changes.

### Check Status
```bash
./status.sh
```

Displays:
- LaunchAgent status (running/stopped)
- Port 3002 status
- HTTP health check
- Recent logs (last 10 lines)

## Configuration

### LaunchAgent

Configuration: `launchd/com.homelab.spicy-claude.plist`

Key settings:
- **Port**: 3002
- **Host**: 0.0.0.0 (accessible from local network)
- **Auto-start**: Yes (RunAtLoad)
- **Auto-restart**: Yes (KeepAlive)
- **Logs**: `~/Library/Logs/spicy-claude/`

### Logs

Location: `~/Library/Logs/spicy-claude/`

Files:
- `stdout.log` - Application output
- `stderr.log` - Error messages

**View logs:**
```bash
# Follow stdout
tail -f ~/Library/Logs/spicy-claude/stdout.log

# Follow stderr
tail -f ~/Library/Logs/spicy-claude/stderr.log

# Last 50 lines
tail -50 ~/Library/Logs/spicy-claude/stdout.log
```

## Manual LaunchAgent Control

If you need to manage the LaunchAgent directly:

```bash
# Load (start)
launchctl load ~/Library/LaunchAgents/com.homelab.spicy-claude.plist

# Unload (stop)
launchctl unload ~/Library/LaunchAgents/com.homelab.spicy-claude.plist

# Check status
launchctl list | grep spicy-claude

# View details
launchctl list com.homelab.spicy-claude
```

## Troubleshooting

### Service won't start

**Check if port 3002 is in use:**
```bash
lsof -i:3002
```

**Kill process on port 3002:**
```bash
lsof -ti:3002 | xargs kill -9
```

**Check logs for errors:**
```bash
tail -50 ~/Library/Logs/spicy-claude/stderr.log
```

### Build failed

**Ensure Node.js and npm are installed:**
```bash
node --version  # Should be v20.11.0+
npm --version
```

**Rebuild manually:**
```bash
cd /Users/edwardhallam/projects/spicy-claude/backend
npm install
npm run build
```

**Verify build output:**
```bash
ls -la /Users/edwardhallam/projects/spicy-claude/backend/dist/cli/node.js
```

### LaunchAgent not loading

**Check plist syntax:**
```bash
plutil -lint ~/Library/LaunchAgents/com.homelab.spicy-claude.plist
```

**Unload and reload:**
```bash
./stop.sh
./start.sh
```

**Check system logs:**
```bash
log show --predicate 'subsystem == "com.apple.launchd"' --last 10m | grep spicy-claude
```

## Integration with Monitoring

Spicy Claude is monitored via homelab-conductor Prometheus stack:

- **Monitoring**: Port 3002 (Blackbox Exporter HTTP probe)
- **Alerts**: ClaudeCodeUIDown, ClaudeCodeUISlow, ClaudeCodeUILatencyHigh
- **Slack**: #homelab-updates channel
- **Dashboards**: Grafana (service health, response times)

**No changes needed** - monitoring uses same port 3002 as previous claude-code-webui installation.

**View monitoring:**
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000
- Alertmanager: http://localhost:9093

## Testing

Spicy Claude includes comprehensive Playwright UI tests (20 tests, 100% passing).

**Run from spicy-claude project:**
```bash
cd /Users/edwardhallam/projects/spicy-claude

# All tests
npm run test:ui

# Specific suites
npm run test:comparison    # Old App vs Spicy Claude comparison
npm run test:bypass        # Bypass permissions mode tests
npm run test:permissions   # Permission prompt behavior

# View results
npm run test:report
```

**Prerequisites for testing:**
- Spicy Claude running on port 3003 (test server)
- Old App running on port 3002 (comparison baseline)

See `tests/README.md` for comprehensive testing documentation.

## Updates

⚠️ **Manual updates only** - No automatic update process is configured.

**Update process:**
1. Stop service: `./stop.sh`
2. Pull latest code: `git pull`
3. Rebuild: `cd backend && npm run build`
4. Start service: `./start.sh`
5. Run tests: `npm run test:ui`

**Rationale:** Spicy Claude is a fork with custom modifications. Automatic updates could break bypass permissions mode functionality. Manual updates allow validation before deployment.

## Uninstallation

To completely remove Spicy Claude:

```bash
# Stop service
./stop.sh

# Remove LaunchAgent
rm ~/Library/LaunchAgents/com.homelab.spicy-claude.plist

# Remove logs (optional)
rm -rf ~/Library/Logs/spicy-claude/

# Remove source code (optional)
# cd /Users/edwardhallam/projects/
# rm -rf spicy-claude/
```

## Architecture

```
spicy-claude/
├── backend/
│   ├── src/                    # TypeScript source
│   ├── dist/cli/node.js        # Built entry point
│   └── package.json
├── deployment/
│   ├── install.sh              # Initial setup
│   ├── start.sh                # Start service
│   ├── stop.sh                 # Stop service
│   ├── restart.sh              # Restart service
│   ├── status.sh               # Check status
│   ├── launchd/
│   │   └── com.homelab.spicy-claude.plist
│   └── README.md               # This file
└── tests/                      # Playwright tests
```

## Support

**Documentation:**
- Main README: `/Users/edwardhallam/projects/spicy-claude/README.md`
- Testing Guide: `/Users/edwardhallam/projects/spicy-claude/tests/README.md`
- Test Status: `/Users/edwardhallam/projects/spicy-claude/tests/TESTING-STATUS.md`

**Monitoring Documentation (homelab-conductor):**
- Update docs: `docs/claude-code-webui-update-automation.md`
- Dangerous mode: `docs/claude-code-webui-dangerous-mode-installation.md`
- Prometheus: `config/prometheus/`
- Grafana: `config/grafana/`

**Common Commands:**
```bash
# Service status
./status.sh

# View logs
tail -f ~/Library/Logs/spicy-claude/stdout.log

# Restart service
./restart.sh

# Run tests
npm run test:ui

# Check monitoring
curl http://localhost:3002  # Should return 200
```

---

**Version**: 1.0.0
**Port**: 3002
**Host**: 0.0.0.0 (local network accessible)
**Based on**: claude-code-webui v0.1.56
**Platform**: macOS (LaunchAgent)
**Updates**: Manual only (no automation)
**Monitoring**: Via homelab-conductor Prometheus stack
