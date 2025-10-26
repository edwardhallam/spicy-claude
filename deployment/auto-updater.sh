#!/bin/bash
# Auto-updater for Spicy Claude
# Checks for updates from origin/main every 10 minutes
# Automatically pulls, tests, and deploys if tests pass
# Rolls back automatically if tests fail

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SLACK_NOTIFY="${SCRIPT_DIR}/slack-notify.sh"
LOCK_FILE="${PROJECT_ROOT}/.auto-updater.lock"
LAST_UPDATE_FILE="${PROJECT_ROOT}/.last-auto-update"

cd "${PROJECT_ROOT}"

# Load environment variables
if [ -f "${PROJECT_ROOT}/.env" ]; then
    export $(grep -v '^#' "${PROJECT_ROOT}/.env" | xargs)
fi

# Check if auto-rollback is enabled (default: true)
AUTO_ROLLBACK_ENABLED="${AUTO_ROLLBACK_ENABLED:-true}"

# Rate limiting: Maximum 1 update per hour
check_rate_limit() {
    if [ -f "${LAST_UPDATE_FILE}" ]; then
        LAST_UPDATE=$(cat "${LAST_UPDATE_FILE}")
        CURRENT_TIME=$(date +%s)
        TIME_DIFF=$((CURRENT_TIME - LAST_UPDATE))
        MIN_INTERVAL=3600  # 1 hour in seconds

        if [ ${TIME_DIFF} -lt ${MIN_INTERVAL} ]; then
            REMAINING=$((MIN_INTERVAL - TIME_DIFF))
            echo "⏸️  Rate limit: Last update was ${TIME_DIFF}s ago. Waiting ${REMAINING}s more."
            exit 0
        fi
    fi
}

# Acquire lock to prevent concurrent updates
acquire_lock() {
    if [ -f "${LOCK_FILE}" ]; then
        PID=$(cat "${LOCK_FILE}")
        if ps -p ${PID} > /dev/null 2>&1; then
            echo "⏸️  Another update is in progress (PID: ${PID})"
            exit 0
        else
            echo "🧹 Removing stale lock file"
            rm -f "${LOCK_FILE}"
        fi
    fi

    echo $$ > "${LOCK_FILE}"
    trap 'rm -f "${LOCK_FILE}"' EXIT
}

# Release lock
release_lock() {
    rm -f "${LOCK_FILE}"
}

# Check for new commits from origin/main
check_for_updates() {
    echo "🔄 Fetching from origin..."
    git fetch origin

    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)

    if [ "${LOCAL}" = "${REMOTE}" ]; then
        echo "✅ Already up to date"
        return 1
    fi

    echo "📦 New commits available:"
    git log --oneline ${LOCAL}..${REMOTE}
    return 0
}

# Create backup branch
create_backup() {
    BACKUP_BRANCH="backup-$(date +%Y%m%d-%H%M%S)"
    echo "💾 Creating backup branch: ${BACKUP_BRANCH}"
    git branch "${BACKUP_BRANCH}"
    echo "${BACKUP_BRANCH}"
}

# Pull latest changes
pull_updates() {
    echo "⬇️  Pulling latest changes..."
    if ! git pull origin main; then
        echo "❌ Error: Failed to pull updates"
        "${SLACK_NOTIFY}" error "Failed to pull updates from origin/main"
        return 1
    fi
    return 0
}

# Run tests
run_tests() {
    echo "🧪 Running test suite..."
    "${SLACK_NOTIFY}" tests-running

    cd "${PROJECT_ROOT}"

    # Run Playwright tests
    if npm run test:ui > /tmp/test-output.log 2>&1; then
        TEST_SUMMARY=$(grep -A 5 "passed\|failed" /tmp/test-output.log | head -10 || echo "All tests passed")
        echo "✅ All tests passed"
        "${SLACK_NOTIFY}" tests-passed "${TEST_SUMMARY}"
        rm -f /tmp/test-output.log
        return 0
    else
        TEST_RESULTS=$(grep -A 10 "failed\|error" /tmp/test-output.log | head -20 || cat /tmp/test-output.log | head -20)
        echo "❌ Tests failed"
        "${SLACK_NOTIFY}" tests-failed "${TEST_RESULTS}"
        rm -f /tmp/test-output.log
        return 1
    fi
}

# Deploy new version
deploy() {
    COMMIT_HASH=$(git rev-parse --short HEAD)
    echo "🚀 Deploying commit: ${COMMIT_HASH}"
    "${SLACK_NOTIFY}" deployment-start "${COMMIT_HASH}"

    # Rebuild backend
    echo "🔨 Rebuilding backend..."
    cd "${PROJECT_ROOT}/backend"

    if ! npm install; then
        echo "❌ Error: npm install failed"
        "${SLACK_NOTIFY}" error "npm install failed during deployment"
        return 1
    fi

    if ! npm run build; then
        echo "❌ Error: build failed"
        "${SLACK_NOTIFY}" error "Build failed during deployment"
        return 1
    fi

    # Verify build artifacts
    if [ ! -f "dist/cli/node.js" ]; then
        echo "❌ Error: Build artifact missing"
        "${SLACK_NOTIFY}" error "Build artifacts missing after build"
        return 1
    fi

    # Restart service
    echo "🔄 Restarting service..."
    cd "${SCRIPT_DIR}"
    if ! ./restart.sh; then
        echo "❌ Error: Failed to restart service"
        "${SLACK_NOTIFY}" error "Failed to restart service"
        return 1
    fi

    # Wait for service to be ready
    echo "⏳ Waiting for service..."
    sleep 5

    # Health check
    HEALTH_CHECK_URL="http://localhost:3002/"
    MAX_RETRIES=10
    RETRY_COUNT=0

    while [ ${RETRY_COUNT} -lt ${MAX_RETRIES} ]; do
        if curl -sf "${HEALTH_CHECK_URL}" > /dev/null 2>&1; then
            echo "✅ Service is healthy"
            VERSION=$(git describe --tags --always)
            "${SLACK_NOTIFY}" deployment-success "${VERSION}"

            # Record successful update time
            date +%s > "${LAST_UPDATE_FILE}"
            return 0
        fi
        echo "⏳ Waiting for service... (${RETRY_COUNT}/${MAX_RETRIES})"
        sleep 2
        RETRY_COUNT=$((RETRY_COUNT + 1))
    done

    echo "❌ Error: Service health check failed"
    "${SLACK_NOTIFY}" error "Service health check failed after deployment"
    return 1
}

# Perform rollback
perform_rollback() {
    BACKUP_BRANCH="$1"
    echo "⏪ Rolling back to ${BACKUP_BRANCH}..."

    if ! "${SCRIPT_DIR}/rollback.sh" "${BACKUP_BRANCH}"; then
        echo "❌ CRITICAL: Rollback failed!"
        "${SLACK_NOTIFY}" error "CRITICAL: Rollback failed. Manual intervention required!"
        return 1
    fi

    echo "✅ Rollback successful"
    return 0
}

# Main update flow
main() {
    echo "========================================"
    echo "Spicy Claude Auto-Updater"
    echo "========================================"
    echo "Time: $(date)"
    echo ""

    # Check rate limit
    check_rate_limit

    # Acquire lock
    acquire_lock

    # Check for updates
    if ! check_for_updates; then
        release_lock
        exit 0
    fi

    # Send notification
    "${SLACK_NOTIFY}" checking

    # Create backup
    BACKUP_BRANCH=$(create_backup)
    if [ -z "${BACKUP_BRANCH}" ]; then
        echo "❌ Error: Failed to create backup"
        "${SLACK_NOTIFY}" error "Failed to create backup branch"
        release_lock
        exit 1
    fi

    # Pull updates
    if ! pull_updates; then
        release_lock
        exit 1
    fi

    # Run tests
    if ! run_tests; then
        echo "❌ Tests failed"

        if [ "${AUTO_ROLLBACK_ENABLED}" = "true" ]; then
            echo "🔄 Auto-rollback is enabled. Rolling back..."
            if ! perform_rollback "${BACKUP_BRANCH}"; then
                release_lock
                exit 1
            fi
        else
            echo "⚠️  Auto-rollback is disabled. Manual intervention required."
            "${SLACK_NOTIFY}" error "Tests failed but auto-rollback is disabled. Manual intervention required."
        fi

        release_lock
        exit 1
    fi

    # Deploy
    if ! deploy; then
        echo "❌ Deployment failed"

        if [ "${AUTO_ROLLBACK_ENABLED}" = "true" ]; then
            echo "🔄 Auto-rollback is enabled. Rolling back..."
            if ! perform_rollback "${BACKUP_BRANCH}"; then
                release_lock
                exit 1
            fi
        fi

        release_lock
        exit 1
    fi

    echo "✅ Update completed successfully!"
    release_lock
}

# Run main function
main
