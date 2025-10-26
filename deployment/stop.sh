#!/bin/bash
set -euo pipefail

# Spicy Claude - Stop Service
# Stops the Spicy Claude service via LaunchAgent

PLIST_LABEL="com.homelab.spicy-claude"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_LABEL}.plist"

echo "Stopping Spicy Claude service..."

# Check if running
if ! launchctl list | grep -q "$PLIST_LABEL"; then
    echo "⚠️  Service is not running"
    exit 0
fi

# Unload service
launchctl unload "$PLIST_PATH"

# Wait for shutdown
sleep 2

# Verify stopped
if launchctl list | grep -q "$PLIST_LABEL"; then
    echo "❌ Error: Service failed to stop"
    exit 1
fi

# Verify port is free
if lsof -ti:3002 > /dev/null 2>&1; then
    echo "⚠️  Warning: Port 3002 still in use by another process"
    echo "Run: lsof -ti:3002 | xargs kill -9"
    exit 1
fi

echo "✅ Spicy Claude stopped successfully"
