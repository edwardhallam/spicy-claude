#!/bin/bash
set -euo pipefail

# Spicy Claude - Start Service
# Starts the Spicy Claude service via LaunchAgent

PLIST_LABEL="com.homelab.spicy-claude"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_LABEL}.plist"

echo "Starting Spicy Claude service..."

# Check if plist exists
if [ ! -f "$PLIST_PATH" ]; then
    echo "❌ Error: Service not installed. Run ./install.sh first."
    exit 1
fi

# Check if already running
if launchctl list | grep -q "$PLIST_LABEL"; then
    echo "⚠️  Service is already running"
    echo "Use ./status.sh to check status or ./restart.sh to restart"
    exit 0
fi

# Load and start service
launchctl load "$PLIST_PATH"

# Wait for startup
sleep 3

# Health check
if curl -s http://127.0.0.1:3002 > /dev/null; then
    echo "✅ Spicy Claude started successfully on http://localhost:3002"
else
    echo "⚠️  Service started but not responding yet. Check logs:"
    echo "   tail -f ~/Library/Logs/spicy-claude/stdout.log"
    exit 1
fi
