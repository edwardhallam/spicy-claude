#!/bin/bash
set -euo pipefail

#
# Spicy Claude UI Test Runner
#
# Agent-friendly wrapper for running Playwright tests with automatic
# server verification and result reporting.
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log functions (output to stderr to avoid interfering with command substitution)
log_info() { echo -e "${BLUE}[INFO]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" >&2; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Check if servers are running
check_servers() {
    log_info "Checking if test servers are running..."

    local old_app_running=false
    local spicy_running=false

    # Check Old App (port 3002)
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3002 | grep -q "200\|302\|301"; then
        old_app_running=true
        log_success "Old App running on port 3002"
    else
        log_warning "Old App NOT running on port 3002"
    fi

    # Check Spicy Claude (port 3003)
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3003 | grep -q "200\|302\|301"; then
        spicy_running=true
        log_success "Spicy Claude running on port 3003"
    else
        log_warning "Spicy Claude NOT running on port 3003"
    fi

    if ! $old_app_running || ! $spicy_running; then
        log_error "Required servers not running. Please start them:"
        echo "" >&2
        if ! $old_app_running; then
            echo "  Terminal 1: claude-code-webui --port 3002" >&2
        fi
        if ! $spicy_running; then
            echo "  Terminal 2: cd $PROJECT_ROOT/backend && node dist/cli/node.js --port 3003" >&2
        fi
        echo "" >&2
        return 1
    fi

    return 0
}

# Run tests
run_tests() {
    local test_args="$@"

    log_info "Running Playwright tests..."
    echo "" >&2

    # Run tests with npm
    if npm run test:ui -- $test_args; then
        log_success "All tests passed!"
        return 0
    else
        log_error "Some tests failed"
        return 1
    fi
}

# Open test report
open_report() {
    log_info "Opening test report..."
    npm run test:report
}

# Generate differences summary
generate_summary() {
    local report_file="tests/reports/differences.json"

    if [ ! -f "$report_file" ]; then
        log_success "No behavioral differences found between Old App and Spicy Claude!"
        return 0
    fi

    log_info "Generating differences summary..."

    # Count differences
    local diff_count=$(cat "$report_file" | grep -c '"testId"' || echo "0")

    log_warning "Found $diff_count behavioral difference(s)"

    # Generate markdown summary (if Node.js available)
    if command -v node >/dev/null 2>&1; then
        node -e "
            const helpers = require('./tests/utils/comparison-helpers');
            helpers.generateDifferencesSummary().then(summary => {
                console.log(summary);
            });
        " 2>/dev/null || {
            log_info "Summary saved to tests/reports/DIFFERENCES-SUMMARY.md"
        }
    fi

    return 1  # Return non-zero to indicate differences were found
}

# Main script
main() {
    log_info "Spicy Claude UI Test Runner"
    echo "" >&2

    # Verify servers are running
    if ! check_servers; then
        exit 1
    fi

    echo "" >&2

    # Run tests with any provided arguments
    if run_tests "$@"; then
        echo "" >&2
        log_success "✅ All tests passed - No differences detected"

        # Ask if user wants to see report
        echo "" >&2
        log_info "View HTML report? Run: npm run test:report"

        exit 0
    else
        echo "" >&2
        log_error "❌ Tests failed - Differences may have been detected"

        # Generate and show summary
        echo "" >&2
        generate_summary || true

        # Show next steps
        echo "" >&2
        log_info "Next steps:"
        echo "  1. View HTML report: npm run test:report" >&2
        echo "  2. Check screenshots: ls tests/reports/screenshots/" >&2
        echo "  3. Review differences: cat tests/reports/differences.json" >&2
        echo "  4. Inspect network traffic: open tests/reports/network/*.har" >&2
        echo "" >&2

        exit 1
    fi
}

# Run main function with all script arguments
main "$@"
