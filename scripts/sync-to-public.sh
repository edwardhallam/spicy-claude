#!/bin/bash
# Sync to public repository script
# Filters out private/personal files and sanitizes paths before syncing
# Usage: ./sync-to-public.sh [dry-run]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FILTER_FILE="${PROJECT_ROOT}/.github/public-repo-filter.txt"
PUBLIC_BRANCH="public-main"

DRY_RUN=false
if [ "${1:-}" = "dry-run" ]; then
    DRY_RUN=true
    echo "🔍 DRY RUN MODE - No changes will be made"
    echo ""
fi

cd "${PROJECT_ROOT}"

# Verify we're on a clean main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "${CURRENT_BRANCH}" != "main" ]; then
    echo "❌ Error: Must be on main branch (currently on: ${CURRENT_BRANCH})"
    exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
    echo "❌ Error: Working directory is not clean. Commit or stash changes first."
    exit 1
fi

echo "=========================================="
echo "Sync to Public Repository"
echo "=========================================="
echo ""

# Load filter patterns
if [ ! -f "${FILTER_FILE}" ]; then
    echo "❌ Error: Filter file not found: ${FILTER_FILE}"
    exit 1
fi

# Create or update public branch
if git show-ref --verify --quiet "refs/heads/${PUBLIC_BRANCH}"; then
    echo "📦 Updating existing ${PUBLIC_BRANCH} branch"
    if [ "${DRY_RUN}" = false ]; then
        git checkout "${PUBLIC_BRANCH}"
        git reset --hard main
    fi
else
    echo "📦 Creating new ${PUBLIC_BRANCH} branch"
    if [ "${DRY_RUN}" = false ]; then
        git checkout -b "${PUBLIC_BRANCH}"
    fi
fi

# Remove filtered files
echo ""
echo "🧹 Removing private files..."
while IFS= read -r pattern || [ -n "$pattern" ]; do
    # Skip comments and empty lines
    [[ "$pattern" =~ ^#.*$ ]] && continue
    [[ -z "$pattern" ]] && continue

    echo "  Filtering: ${pattern}"

    if [ "${DRY_RUN}" = false ]; then
        # Use git rm to remove files matching pattern
        git rm -rf --ignore-unmatch "${pattern}" || true
    else
        # In dry-run, just show what would be removed
        git ls-files "${pattern}" 2>/dev/null || true
    fi
done < "${FILTER_FILE}"

# Sanitize tests/README.md - remove personal paths
echo ""
echo "🔧 Sanitizing tests/README.md..."
if [ -f "tests/README.md" ] && [ "${DRY_RUN}" = false ]; then
    sed -i.bak \
        -e 's|/Users/edwardhallam/projects/spicy-claude|/path/to/spicy-claude|g' \
        -e 's|/Users/edwardhallam/projects/homelab-conductor|/path/to/test-project|g' \
        -e 's|edwardhallam|user|g' \
        tests/README.md
    rm -f tests/README.md.bak
    git add tests/README.md
    echo "  ✅ Sanitized tests/README.md"
elif [ -f "tests/README.md" ]; then
    echo "  [DRY RUN] Would sanitize tests/README.md"
fi

# Sanitize README.md - replace username with generic reference
echo ""
echo "🔧 Sanitizing README.md..."
if [ -f "README.md" ] && [ "${DRY_RUN}" = false ]; then
    sed -i.bak \
        -e 's|edwardhallam/spicy-claude|edwardhallam/spicy-claude-public|g' \
        -e 's|com.homelab|com.example|g' \
        README.md
    rm -f README.md.bak
    git add README.md
    echo "  ✅ Sanitized README.md"
elif [ -f "README.md" ]; then
    echo "  [DRY RUN] Would sanitize README.md"
fi

# Sanitize package.json files - update repository URLs
echo ""
echo "🔧 Sanitizing package.json files..."
for pkg_file in backend/package.json frontend/package.json; do
    if [ -f "${pkg_file}" ] && [ "${DRY_RUN}" = false ]; then
        if grep -q "edwardhallam/spicy-claude" "${pkg_file}" 2>/dev/null; then
            sed -i.bak \
                -e 's|edwardhallam/spicy-claude|edwardhallam/spicy-claude-public|g' \
                "${pkg_file}"
            rm -f "${pkg_file}.bak"
            git add "${pkg_file}"
            echo "  ✅ Sanitized ${pkg_file}"
        fi
    elif [ -f "${pkg_file}" ]; then
        echo "  [DRY RUN] Would sanitize ${pkg_file}"
    fi
done

# Sanitize other test files if they contain personal paths
echo ""
echo "🔧 Sanitizing test files..."
TEST_FILES=$(find tests -name "*.ts" -o -name "*.spec.ts" -o -name "*.md" 2>/dev/null || true)
if [ -n "${TEST_FILES}" ] && [ "${DRY_RUN}" = false ]; then
    for file in ${TEST_FILES}; do
        if grep -q "/Users/edwardhallam\|homelab-conductor" "${file}" 2>/dev/null; then
            sed -i.bak \
                -e 's|/Users/edwardhallam/projects/spicy-claude|/path/to/spicy-claude|g' \
                -e 's|/Users/edwardhallam/projects/homelab-conductor|/path/to/test-project|g' \
                -e 's|edwardhallam|user|g' \
                "${file}"
            rm -f "${file}.bak"
            git add "${file}"
            echo "  ✅ Sanitized ${file}"
        fi
    done
elif [ -n "${TEST_FILES}" ]; then
    echo "  [DRY RUN] Would sanitize test files with personal paths"
fi

# Sanitize deployment-examples files
echo ""
echo "🔧 Sanitizing deployment-examples..."
if [ "${DRY_RUN}" = false ]; then
    if [ -d "deployment-examples" ]; then
        for example_file in deployment-examples/*; do
            if [ -f "${example_file}" ]; then
                if grep -q "/Users/edwardhallam\|homelab-conductor" "${example_file}" 2>/dev/null; then
                    sed -i.bak \
                        -e 's|/Users/edwardhallam/projects/spicy-claude|/path/to/spicy-claude|g' \
                        -e 's|/Users/edwardhallam/projects/homelab-conductor|/path/to/monitoring-stack|g' \
                        -e 's|/Users/edwardhallam|/Users/user|g' \
                        -e 's|homelab-conductor|monitoring-stack|g' \
                        "${example_file}"
                    rm -f "${example_file}.bak"
                    git add "${example_file}"
                    echo "  ✅ Sanitized ${example_file}"
                fi
            fi
        done
    fi
else
    echo "  [DRY RUN] Would sanitize deployment-examples with personal references"
fi

# Verify no secrets are present
echo ""
echo "🔍 Checking for potential secrets..."

# Only check files that will actually be synced
# Build list of files to exclude from secret check based on filter
EXCLUDE_PATTERNS=""
while IFS= read -r pattern || [ -n "$pattern" ]; do
    [[ "$pattern" =~ ^#.*$ ]] && continue
    [[ -z "$pattern" ]] && continue
    EXCLUDE_PATTERNS="${EXCLUDE_PATTERNS} :(exclude)${pattern}"
done < "${FILTER_FILE}"

SECRET_PATTERNS=(
    "api.*key"
    "password"
    "token"
)

FOUND_SECRETS=false
for pattern in "${SECRET_PATTERNS[@]}"; do
    # Only check in files that would be synced (exclude filtered files)
    if git grep -i "${pattern}" ${EXCLUDE_PATTERNS} -- '*.sh' '*.md' '*.yml' '*.yaml' '*.json' 2>/dev/null \
        | grep -v ".github/public-repo-filter.txt" \
        | grep -v "scripts/sync-to-public.sh" \
        | grep -v "package-lock.json" \
        | grep -v '\${{ secrets\.' \
        | grep -v "edwardhallam/spicy-claude-public" \
        | grep -v "SLACK_WEBHOOK_URL" \
        | grep -v "GitHub personal access token"; then
        echo "  ⚠️  Found potential secret pattern: ${pattern}"
        FOUND_SECRETS=true
    fi
done

# Check for personal references that should be sanitized
PERSONAL_PATTERNS=(
    "edwardhallam[^/]"  # Match edwardhallam but not in github URLs
    "homelab-conductor"
    "/Users/edwardhallam"
)

for pattern in "${PERSONAL_PATTERNS[@]}"; do
    # Only check in files that would be synced, excluding already-sanitized references
    if git grep -E "${pattern}" ${EXCLUDE_PATTERNS} -- '*.sh' '*.md' '*.yml' '*.yaml' '*.json' 2>/dev/null \
        | grep -v ".github/public-repo-filter.txt" \
        | grep -v "scripts/sync-to-public.sh" \
        | grep -v "edwardhallam/spicy-claude-public" \
        | grep -v "/path/to/"; then
        echo "  ⚠️  Found personal reference that should be sanitized: ${pattern}"
        FOUND_SECRETS=true
    fi
done

if [ "${FOUND_SECRETS}" = true ]; then
    echo ""
    echo "❌ Error: Potential secrets or personal information found!"
    echo "   Review the matches above and update the filter or sanitize the files."
    if [ "${DRY_RUN}" = false ]; then
        git checkout main
    fi
    exit 1
fi

echo "  ✅ No obvious secrets found"

# Show diff summary
echo ""
echo "📊 Changes Summary:"
if [ "${DRY_RUN}" = false ]; then
    git diff --stat main..${PUBLIC_BRANCH} || echo "No differences"
else
    echo "  [DRY RUN] Would show diff between main and ${PUBLIC_BRANCH}"
fi

# Commit changes
if [ "${DRY_RUN}" = false ]; then
    if [ -n "$(git status --porcelain)" ]; then
        echo ""
        echo "💾 Committing changes..."
        git add -A
        git commit -m "chore: Sync from main (filtered for public release)

Removed private files:
- Personal deployment docs
- Automation scripts
- Personal notes and configurations

Sanitized:
- Test files (removed personal paths)
- README files (removed personal references)"

        echo "✅ Changes committed to ${PUBLIC_BRANCH}"
    else
        echo ""
        echo "✅ No changes to commit"
    fi
else
    echo ""
    echo "[DRY RUN] Would commit changes to ${PUBLIC_BRANCH}"
fi

# Return to main branch
if [ "${DRY_RUN}" = false ]; then
    git checkout main
    echo ""
    echo "✅ Sync complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Review changes: git diff main..${PUBLIC_BRANCH}"
    echo "  2. Push to public repo: git push public ${PUBLIC_BRANCH}:main --force"
    echo ""
    echo "Note: You'll need to set up the 'public' remote:"
    echo "  git remote add public https://github.com/edwardhallam/spicy-claude-public.git"
else
    echo ""
    echo "[DRY RUN] Complete. Run without 'dry-run' to actually perform the sync."
fi
