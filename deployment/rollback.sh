#!/bin/bash
# Enhanced rollback script for Spicy Claude
# Supports both manual and automatic rollback
# Usage: ./rollback.sh [backup-branch-name]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SLACK_NOTIFY="${SCRIPT_DIR}/slack-notify.sh"

cd "${PROJECT_ROOT}"

# Determine backup branch
if [ $# -eq 1 ]; then
    BACKUP_BRANCH="$1"
else
    # Find most recent backup branch
    BACKUP_BRANCH=$(git branch | grep "backup-" | sort -r | head -1 | tr -d ' ')

    if [ -z "${BACKUP_BRANCH}" ]; then
        echo "❌ Error: No backup branch found"
        echo "Available branches:"
        git branch
        "${SLACK_NOTIFY}" error "No backup branch found for rollback"
        exit 1
    fi
fi

echo "🔄 Rolling back to: ${BACKUP_BRANCH}"
"${SLACK_NOTIFY}" rollback "${BACKUP_BRANCH}"

# Stop the service
echo "⏹️  Stopping Spicy Claude service..."
"${SCRIPT_DIR}/stop.sh" || true

# Checkout backup branch
echo "📦 Checking out ${BACKUP_BRANCH}..."
if ! git checkout "${BACKUP_BRANCH}"; then
    echo "❌ Error: Failed to checkout backup branch"
    "${SLACK_NOTIFY}" rollback-failed "Failed to checkout backup branch: ${BACKUP_BRANCH}"
    exit 1
fi

# Update main branch to point to backup
echo "🔄 Resetting main branch to backup..."
if ! git branch -f main "${BACKUP_BRANCH}"; then
    echo "❌ Error: Failed to reset main branch"
    "${SLACK_NOTIFY}" rollback-failed "Failed to reset main branch to backup"
    exit 1
fi

# Checkout main
if ! git checkout main; then
    echo "❌ Error: Failed to checkout main branch"
    "${SLACK_NOTIFY}" rollback-failed "Failed to checkout main branch after reset"
    exit 1
fi

# Rebuild backend
echo "🔨 Rebuilding backend..."
cd "${PROJECT_ROOT}/backend"
if ! npm install; then
    echo "❌ Error: npm install failed"
    "${SLACK_NOTIFY}" rollback-failed "npm install failed during rollback"
    exit 1
fi

if ! npm run build; then
    echo "❌ Error: build failed"
    "${SLACK_NOTIFY}" rollback-failed "Build failed during rollback"
    exit 1
fi

# Verify build artifacts
if [ ! -f "dist/cli/node.js" ]; then
    echo "❌ Error: Build artifact missing"
    "${SLACK_NOTIFY}" rollback-failed "Build artifacts missing after rollback build"
    exit 1
fi

# Start the service
echo "🚀 Starting Spicy Claude service..."
cd "${SCRIPT_DIR}"
if ! ./start.sh; then
    echo "❌ Error: Failed to start service"
    "${SLACK_NOTIFY}" rollback-failed "Failed to start service after rollback"
    exit 1
fi

# Wait for service to be ready
echo "⏳ Waiting for service to be ready..."
sleep 5

# Health check
HEALTH_CHECK_URL="http://localhost:3002/"
MAX_RETRIES=10
RETRY_COUNT=0

while [ ${RETRY_COUNT} -lt ${MAX_RETRIES} ]; do
    if curl -sf "${HEALTH_CHECK_URL}" > /dev/null 2>&1; then
        echo "✅ Service is healthy"
        break
    fi
    echo "⏳ Waiting for service... (${RETRY_COUNT}/${MAX_RETRIES})"
    sleep 2
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [ ${RETRY_COUNT} -eq ${MAX_RETRIES} ]; then
    echo "❌ Error: Service health check failed"
    "${SLACK_NOTIFY}" rollback-failed "Service health check failed after rollback"
    exit 1
fi

# Success
CURRENT_COMMIT=$(git rev-parse --short HEAD)
echo "✅ Rollback successful!"
echo "   Current commit: ${CURRENT_COMMIT}"
echo "   Service running at: ${HEALTH_CHECK_URL}"

"${SLACK_NOTIFY}" rollback-success

# Cleanup old backup branches (keep last 5)
echo "🧹 Cleaning up old backup branches..."
git branch | grep "backup-" | sort -r | tail -n +6 | xargs -r git branch -D || true

echo ""
echo "Rollback complete. You may want to review the logs:"
echo "  tail -f ~/Library/Logs/spicy-claude/stdout.log"
