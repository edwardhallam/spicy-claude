#!/bin/bash
set -euo pipefail

# Spicy Claude - Service Status
# Checks the status of the Spicy Claude service

PLIST_LABEL="com.homelab.spicy-claude"
LOG_DIR="$HOME/Library/Logs/spicy-claude"

echo "=========================================="
echo "Spicy Claude - Service Status"
echo "=========================================="
echo ""

# Check LaunchAgent status
echo "LaunchAgent Status:"
if launchctl list | grep -q "$PLIST_LABEL"; then
    echo "✅ Running"
    launchctl list | grep "$PLIST_LABEL"
else
    echo "❌ Not running"
fi
echo ""

# Check port
echo "Port 3002 Status:"
if lsof -ti:3002 > /dev/null 2>&1; then
    echo "✅ In use"
    lsof -i:3002
else
    echo "❌ Not in use"
fi
echo ""

# Check HTTP endpoint
echo "HTTP Health Check:"
if curl -s http://127.0.0.1:3002 > /dev/null; then
    echo "✅ Responding"
    echo "URL: http://localhost:3002"
else
    echo "❌ Not responding"
fi
echo ""

# Recent logs
echo "Recent Logs (last 10 lines):"
if [ -f "$LOG_DIR/stdout.log" ]; then
    echo "--- stdout.log ---"
    tail -10 "$LOG_DIR/stdout.log"
else
    echo "No stdout.log found"
fi
echo ""

if [ -f "$LOG_DIR/stderr.log" ]; then
    echo "--- stderr.log ---"
    tail -10 "$LOG_DIR/stderr.log"
else
    echo "No stderr.log found"
fi
echo ""

echo "=========================================="
echo "Commands:"
echo "  Start:   ./start.sh"
echo "  Stop:    ./stop.sh"
echo "  Restart: ./restart.sh"
echo "  Logs:    tail -f $LOG_DIR/stdout.log"
echo "=========================================="
