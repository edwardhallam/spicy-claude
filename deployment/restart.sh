#!/bin/bash
set -euo pipefail

# Spicy Claude - Restart Service
# Restarts the Spicy Claude service

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Restarting Spicy Claude service..."

# Stop service
"$SCRIPT_DIR/stop.sh"

# Wait for clean shutdown
sleep 2

# Start service
"$SCRIPT_DIR/start.sh"

echo "✅ Spicy Claude restarted successfully"
