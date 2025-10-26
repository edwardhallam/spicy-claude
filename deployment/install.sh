#!/bin/bash
set -euo pipefail

# Spicy Claude - Installation Script
# Builds the project and installs LaunchAgent for automatic startup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
PLIST_TEMPLATE="$SCRIPT_DIR/launchd/com.homelab.spicy-claude.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/com.homelab.spicy-claude.plist"
LOG_DIR="$HOME/Library/Logs/spicy-claude"

echo "========================================"
echo "Spicy Claude - Installation"
echo "========================================"

# Check prerequisites
if ! command -v node &> /dev/null; then
    echo "❌ Error: Node.js not found. Please install Node.js first."
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "❌ Error: npm not found. Please install npm first."
    exit 1
fi

# Create log directory
echo "📁 Creating log directory..."
mkdir -p "$LOG_DIR"

# Build backend
echo "🔨 Building backend..."
cd "$BACKEND_DIR"
npm install
npm run build

# Verify build
if [ ! -f "$BACKEND_DIR/dist/cli/node.js" ]; then
    echo "❌ Error: Build failed - dist/cli/node.js not found"
    exit 1
fi

echo "✅ Build successful"

# Install LaunchAgent
echo "📦 Installing LaunchAgent..."
cp "$PLIST_TEMPLATE" "$PLIST_DEST"

# Load and start service
echo "🚀 Starting Spicy Claude service..."
launchctl load "$PLIST_DEST"

# Wait for service to start
echo "⏳ Waiting for service to start..."
sleep 3

# Health check
if curl -s http://127.0.0.1:3002 > /dev/null; then
    echo "✅ Spicy Claude is running on http://localhost:3002"
else
    echo "⚠️  Service may still be starting. Check logs:"
    echo "   tail -f $LOG_DIR/stdout.log"
fi

echo ""
echo "========================================"
echo "✅ Installation Complete!"
echo "========================================"
echo ""
echo "Service: Spicy Claude"
echo "Port: 3002"
echo "Status: launchctl list | grep spicy-claude"
echo "Logs: tail -f $LOG_DIR/stdout.log"
echo ""
echo "Next steps:"
echo "  - Visit http://localhost:3002 or http://127.0.0.1:3002"
echo "  - Run tests: cd $PROJECT_ROOT && npm run test:ui"
echo "  - Monitoring: http://localhost:9090 (Prometheus)"
echo ""
