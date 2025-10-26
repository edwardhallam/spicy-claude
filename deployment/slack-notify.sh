#!/bin/bash
# Slack notification helper for Spicy Claude automation
# Usage: ./slack-notify.sh <message_type> [details]

set -euo pipefail

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load .env if exists
if [ -f "${PROJECT_ROOT}/.env" ]; then
    export $(grep -v '^#' "${PROJECT_ROOT}/.env" | xargs)
fi

# Check if Slack webhook is configured
if [ -z "${SLACK_WEBHOOK_URL:-}" ]; then
    echo "Warning: SLACK_WEBHOOK_URL not configured. Skipping Slack notification."
    exit 0
fi

MESSAGE_TYPE="${1:-info}"
DETAILS="${2:-}"
HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Function to send Slack message
send_slack() {
    local color="$1"
    local title="$2"
    local message="$3"
    local fields="$4"

    payload=$(cat <<EOF
{
    "attachments": [
        {
            "color": "${color}",
            "title": "${title}",
            "text": "${message}",
            "fields": [
                {
                    "title": "Host",
                    "value": "${HOSTNAME}",
                    "short": true
                },
                {
                    "title": "Time",
                    "value": "${TIMESTAMP}",
                    "short": true
                }
                ${fields}
            ],
            "footer": "Spicy Claude Auto-Updater"
        }
    ]
}
EOF
    )

    curl -s -X POST \
        -H 'Content-Type: application/json' \
        -d "${payload}" \
        "${SLACK_WEBHOOK_URL}" > /dev/null
}

# Message templates based on type
case "${MESSAGE_TYPE}" in
    checking)
        send_slack "#36a64f" \
            "🔄 Checking for Updates" \
            "Spicy Claude auto-updater is checking for new commits..." \
            ""
        ;;

    upstream-detected)
        COMMIT_COUNT="${DETAILS}"
        send_slack "#36a64f" \
            "⬇️ Upstream Changes Detected" \
            "New commits available from sugyan/claude-code-webui. Attempting auto-merge..." \
            ",{\"title\": \"Commits\", \"value\": \"${COMMIT_COUNT}\", \"short\": true}"
        ;;

    upstream-merged)
        COMMIT_INFO="${DETAILS}"
        send_slack "good" \
            "✅ Upstream Merge Successful" \
            "Successfully merged upstream changes and pushed to main.\n\nCommits:\n${COMMIT_INFO}" \
            ""
        ;;

    upstream-conflict)
        CONFLICT_FILES="${DETAILS}"
        send_slack "danger" \
            "❌ Merge Conflicts Detected" \
            "Unable to auto-merge upstream changes. Manual resolution required.\n\nConflicting files:\n${CONFLICT_FILES}" \
            ""
        ;;

    deployment-start)
        COMMIT_HASH="${DETAILS}"
        send_slack "#36a64f" \
            "🚀 Deployment Starting" \
            "Deploying new version of Spicy Claude..." \
            ",{\"title\": \"Commit\", \"value\": \"${COMMIT_HASH}\", \"short\": false}"
        ;;

    deployment-success)
        VERSION="${DETAILS}"
        send_slack "good" \
            "✅ Deployment Successful" \
            "Spicy Claude has been successfully deployed and is running." \
            ",{\"title\": \"Version\", \"value\": \"${VERSION}\", \"short\": true},{\"title\": \"URL\", \"value\": \"http://localhost:3002\", \"short\": true}"
        ;;

    tests-running)
        send_slack "#36a64f" \
            "🧪 Running Tests" \
            "Executing full test suite (20 Playwright tests)..." \
            ""
        ;;

    tests-passed)
        TEST_SUMMARY="${DETAILS}"
        send_slack "good" \
            "✅ Tests Passed" \
            "All tests passed successfully.\n\n${TEST_SUMMARY}" \
            ""
        ;;

    tests-failed)
        TEST_RESULTS="${DETAILS}"
        send_slack "danger" \
            "🔴 Tests Failed - Rolling Back" \
            "Test suite failed. Automatically rolling back to previous version.\n\nFailures:\n${TEST_RESULTS}" \
            ""
        ;;

    rollback)
        BACKUP_BRANCH="${DETAILS}"
        send_slack "warning" \
            "⏪ Rolling Back" \
            "Rolling back to previous version due to test failures..." \
            ",{\"title\": \"Backup Branch\", \"value\": \"${BACKUP_BRANCH}\", \"short\": false}"
        ;;

    rollback-success)
        send_slack "good" \
            "✅ Rollback Successful" \
            "Successfully rolled back to previous version. Service is stable." \
            ""
        ;;

    rollback-failed)
        ERROR_MSG="${DETAILS}"
        send_slack "danger" \
            "🚨 Rollback Failed" \
            "CRITICAL: Rollback failed. Manual intervention required immediately!\n\nError:\n${ERROR_MSG}" \
            ""
        ;;

    automation-disabled)
        REASON="${DETAILS}"
        send_slack "warning" \
            "⏸️ Auto-Updates Disabled" \
            "Automatic updates have been disabled.\n\nReason: ${REASON}" \
            ""
        ;;

    error)
        ERROR_MSG="${DETAILS}"
        send_slack "danger" \
            "🚨 Error" \
            "An error occurred in the auto-updater:\n\n${ERROR_MSG}" \
            ""
        ;;

    *)
        echo "Unknown message type: ${MESSAGE_TYPE}"
        echo "Valid types: checking, upstream-detected, upstream-merged, upstream-conflict,"
        echo "             deployment-start, deployment-success, tests-running, tests-passed,"
        echo "             tests-failed, rollback, rollback-success, rollback-failed,"
        echo "             automation-disabled, error"
        exit 1
        ;;
esac

echo "Slack notification sent: ${MESSAGE_TYPE}"
