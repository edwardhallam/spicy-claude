#!/bin/bash
# Emergency disable script for Spicy Claude auto-updater
# Quickly stops the auto-update service and sends notification
# Usage: ./emergency-disable.sh [reason]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SLACK_NOTIFY="${SCRIPT_DIR}/slack-notify.sh"

REASON="${1:-Manual emergency disable}"

echo "🚨 Emergency Disable: Stopping Auto-Updater"
echo "Reason: ${REASON}"
echo ""

# Stop the LaunchAgent
PLIST_NAME="com.homelab.spicy-claude-updater"
PLIST_PATH="${HOME}/Library/LaunchAgents/${PLIST_NAME}.plist"

if [ -f "${PLIST_PATH}" ]; then
    echo "⏹️  Unloading LaunchAgent..."
    launchctl unload "${PLIST_PATH}" 2>/dev/null || true
    echo "✅ LaunchAgent stopped"
else
    echo "⚠️  LaunchAgent not found at ${PLIST_PATH}"
fi

# Remove any lock files
LOCK_FILE="${PROJECT_ROOT}/.auto-updater.lock"
if [ -f "${LOCK_FILE}" ]; then
    echo "🧹 Removing lock file..."
    rm -f "${LOCK_FILE}"
fi

# Send Slack notification
"${SLACK_NOTIFY}" automation-disabled "${REASON}"

echo ""
echo "✅ Auto-updater has been disabled"
echo ""
echo "To re-enable auto-updates:"
echo "  launchctl load ~/Library/LaunchAgents/${PLIST_NAME}.plist"
echo ""
echo "To check status:"
echo "  launchctl list | grep ${PLIST_NAME}"
