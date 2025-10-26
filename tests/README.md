# Spicy Claude UI Testing Guide

**Automated browser testing for agents using Playwright**

## Overview

This test suite enables agents to autonomously test behavioral differences between:
- **Old App** (claude-code-webui v0.1.56 on port 3002)
- **Spicy Claude** (v1.0.0 with bypass permissions mode on port 3003)

## Quick Start for Agents

### Run All Tests

```bash
cd /Users/edwardhallam/projects/spicy-claude
npm run test:ui
```

### Run Specific Test Suites

```bash
# File operations comparison (Write, Read, Edit)
npm run test:comparison

# Permission prompt behavior
npm run test:permissions

# Bypass permissions mode (dangerous mode)
npm run test:bypass
```

### Run Specific Test File

```bash
npm test -- tests/e2e/comparison/file-operations.spec.ts
```

### Run Single Test by Name

```bash
npm test -- -g "W1: Write to /tmp/"
```

### Debug Mode (See Browser)

```bash
npm run test:ui:headed  # Run with visible browser
npm run test:ui:debug   # Interactive debug mode
```

### View Test Results

```bash
npm run test:report  # Opens HTML report in browser
```

## Test Structure

```
tests/
├── e2e/
│   ├── comparison/          # Old App vs Spicy Claude tests
│   │   ├── file-operations.spec.ts   # W1-W4, R1-R3, E1-E2
│   │   └── bash-operations.spec.ts    # B1-B4
│   ├── permissions/
│   │   └── prompt-behavior.spec.ts    # Permission prompts
│   └── bypass/
│       └── dangerous-mode.spec.ts     # BP-W1, BP-W2, BP-B1
├── fixtures/
│   └── app-fixture.ts       # Browser contexts for both apps
├── utils/
│   ├── test-helpers.ts      # Core utilities
│   └── comparison-helpers.ts  # Side-by-side testing
└── reports/                 # Generated artifacts
    ├── html/                # Interactive HTML report
    ├── screenshots/         # Failure screenshots
    ├── network/             # HAR files (API traffic)
    └── differences.json     # Behavioral differences log
```

## Test Categories

### Comparison Tests (Old vs Spicy)

Tests that run identical operations on both apps and compare results:

- **File Operations** (`file-operations.spec.ts`)
  - W1-W4: Write tests (/tmp/, project, home, nested)
  - R1-R3: Read tests
  - E1-E2: Edit tests

- **Bash Operations** (`bash-operations.spec.ts`)
  - B1-B4: Bash commands (echo, touch, heredoc)

### Feature Tests (Spicy Only)

Tests for new features unique to Spicy Claude:

- **Bypass Permissions** (`dangerous-mode.spec.ts`)
  - BP-W1, BP-W2: File operations without prompts
  - BP-B1: Bash operations without prompts
  - Mode switching verification

### Behavior Tests

- **Permission Prompts** (`prompt-behavior.spec.ts`)
  - When prompts appear
  - Approve/deny functionality

## Prerequisites

Both servers must be running before tests:

```bash
# Terminal 1: Old App
claude-code-webui --port 3002

# Terminal 2: Spicy Claude
cd /Users/edwardhallam/projects/spicy-claude/backend
node dist/cli/node.js --port 3003
```

**Verify servers are running:**

```bash
curl -I http://localhost:3002  # Should return 200
curl -I http://localhost:3003  # Should return 200
```

## For Agents: Creating New Tests

### Test Template

```typescript
import { test, expect } from '../../fixtures/app-fixture';
import { clearBrowserState, selectProject, sendMessage, waitForResponse } from '../../utils/test-helpers';

const TEST_PROJECT = '/Users/edwardhallam/projects/homelab-conductor';

test.describe('My New Test Suite', () => {
  test.beforeEach(async ({ oldApp, spicyApp }) => {
    await clearBrowserState(oldApp);
    await clearBrowserState(spicyApp);
    await selectProject(oldApp, TEST_PROJECT);
    await selectProject(spicyApp, TEST_PROJECT);
  });

  test('My test case', async ({ oldApp, spicyApp }) => {
    // Send message to both apps
    await sendMessage(oldApp, 'Your command here');
    await sendMessage(spicyApp, 'Your command here');

    // Wait for responses
    const oldResult = await waitForResponse(oldApp);
    const spicyResult = await waitForResponse(spicyApp);

    // Compare results
    expect(oldResult.success).toBe(spicyResult.success);
  });
});
```

### Available Utilities

From `test-helpers.ts`:
- `clearBrowserState(page)` - Clear localStorage, cookies
- `selectProject(page, path)` - Navigate to project
- `sendMessage(page, message)` - Send chat message
- `waitForResponse(page)` - Wait for Claude response
- `verifyPermissionPrompt(page)` - Check if prompt shown
- `approvePermission(page)` - Click "Allow"
- `denyPermission(page)` - Click "Deny"
- `switchPermissionMode(page, mode)` - Change permission mode
- `fileExists(path)` - Check file existence
- `deleteTestFile(path)` - Cleanup test files

From `comparison-helpers.ts`:
- `runSideBySide(testFn, oldApp, spicyApp, testId)` - Run test on both apps
- `compareResults(oldResult, spicyResult)` - Compare outcomes
- `recordDifference(testId, result)` - Log behavioral differences
- `generateDifferencesSummary()` - Create markdown report

## Interpreting Test Results

### Success (No Differences)

```
✓ tests/e2e/comparison/file-operations.spec.ts (8 passed)

All tests passed! No behavioral differences detected.
```

### Failure (Differences Found)

```
✗ tests/e2e/comparison/file-operations.spec.ts:45:5 › W1: Write to /tmp/
  Expected: true
  Received: false

  Difference recorded: tests/reports/differences.json
  Screenshots: tests/reports/screenshots/W1-write-tmp/
```

**Next steps:**
1. Open HTML report: `npm run test:report`
2. Check screenshots in `tests/reports/screenshots/`
3. Review network traffic in `tests/reports/network/*.har`
4. Read `tests/reports/differences.json` for detailed comparison
5. Generate summary: `node -e "require('./tests/utils/comparison-helpers').generateDifferencesSummary()"`

## Debugging Failed Tests

### View Screenshots

```bash
open tests/reports/screenshots/W1-write-tmp/old-app.png
open tests/reports/screenshots/W1-write-tmp/spicy-claude.png
```

### Inspect Network Traffic

HAR files capture all API requests/responses:

```bash
# Open in Chrome: chrome://net-export/
# Or use online HAR viewer: https://toolbox.googleapps.com/apps/har_analyzer/
open tests/reports/network/old-app.har
open tests/reports/network/spicy-claude.har
```

### Run Test in Debug Mode

```bash
npm run test:ui:debug -- -g "W1: Write to /tmp/"
```

This opens Playwright Inspector where you can:
- Step through test actions
- Inspect page state
- Take additional screenshots
- View console logs

### Check Test Artifacts

```bash
# All test results
ls -la tests/reports/test-results/

# Videos (only on failure)
open tests/reports/test-results/*/video.webm
```

## Common Issues

### "Servers not running"

```bash
# Check if servers are up
ps aux | grep -E "(claude-code-webui|node.*dist/cli)"

# If not, start them
claude-code-webui --port 3002 &
cd /Users/edwardhallam/projects/spicy-claude/backend && node dist/cli/node.js --port 3003 &
```

### "Browser not found"

```bash
# Reinstall Chromium
npx playwright install chromium
```

### "Permission denied on cleanup"

Test files are created during tests. If cleanup fails:

```bash
rm -f /tmp/test-* /tmp/bash-* /tmp/bypass-* /tmp/perm-*
rm -f ~/test-* ~/bash-*
```

### "Test timeout"

Claude may take longer to respond. Increase timeout:

```typescript
const response = await waitForResponse(page, 60000); // 60 seconds
```

## Advanced Usage

### Record New Tests Interactively

Playwright Codegen helps create new tests:

```bash
npm run test:ui:codegen
```

This opens a browser where you can:
1. Interact with the UI normally
2. Playwright records your actions as code
3. Copy generated code into new test file

### Run Tests in Parallel

By default, tests run serially to avoid port conflicts. To run in parallel (experimental):

```typescript
// In playwright.config.ts
workers: 2,  // Change from 1 to 2
```

### Custom Reporters

Add to `playwright.config.ts`:

```typescript
reporter: [
  ['html'],
  ['junit', { outputFile: 'results.xml' }],
  ['json', { outputFile: 'results.json' }],
],
```

## Integration with Agent Workflows

### qa-test-engineer Agent

```bash
# Run full test suite
cd /Users/edwardhallam/projects/spicy-claude
npm run test:ui

# Generate summary report
npm run test:report

# Check for differences
cat tests/reports/differences.json
```

### devops-engineer Agent

```bash
# Add to deployment validation
npm run test:bypass  # Verify new feature works
```

### Any Agent Investigating Issues

```bash
# Quick check: Does behavior match?
npm test -- -g "specific test name"

# View last results
npm run test:report
```

## File Locations

- **Config**: `playwright.config.ts` (root level)
- **Tests**: `tests/e2e/`
- **Utilities**: `tests/utils/`, `tests/fixtures/`
- **Reports**: `tests/reports/` (git-ignored)
- **Package scripts**: `package.json` (root level)

## Best Practices for Agents

1. **Always check prerequisites** - Verify both servers running before tests
2. **Use descriptive test names** - Include test ID (W1, B2, etc.)
3. **Clean up test files** - Use `deleteTestFile()` in afterEach or test cleanup
4. **Capture evidence on failure** - Screenshots + HAR files automatically saved
5. **Record differences** - Use `recordDifference()` for any deviations found
6. **Generate summaries** - After test runs, create markdown reports for user

## Recent Fixes (2025-10-26)

### Issue: 5 Tests Timing Out

**Symptoms:**
- Tests BP-W1, BP-W2, BP-B1 failing with "Test timeout of 30000ms exceeded"
- Screenshots showed operations completed successfully
- Files were created but `response.success` was false

**Root Causes:**
1. **Timeout Issue**: Playwright's default 30s test timeout was too short for Claude API calls (60-90s in bypass mode)
2. **Success Detection**: `waitForResponse()` was receiving empty response text, causing false negatives

**Fixes Applied:**
- `playwright.config.ts:24` - Increased global test timeout from 30s to 120s
- `tests/utils/test-helpers.ts:87-100` - Added positive indicators (done/created/result/success) to success detection
- `tests/e2e/bypass/dangerous-mode.spec.ts:51-56, 74-77, 95-98` - Changed assertions to check file existence (primary measure) instead of relying solely on text parsing

**Result:** All 20 tests passing (100% success rate)

### Debugging Empty Response Text

If you encounter `response.success = false` but operations succeed:

1. **Check the actual outcome** (file exists, command executed)
2. **Add debug logging**:
   ```typescript
   const response = await waitForResponse(page);
   console.log('Response text:', response.text);
   console.log('Response length:', response.text.length);
   ```
3. **Use functional assertions** instead of text parsing:
   ```typescript
   // Good: Check actual outcome
   expect(await fileExists(testFile)).toBe(true);

   // Less reliable: Parse response text
   expect(response.success).toBe(true);
   ```

## Questions?

- Playwright docs: https://playwright.dev
- Test examples: See `tests/e2e/` for reference implementations
- Utilities API: Check `tests/utils/test-helpers.ts` and `comparison-helpers.ts`
- Recent fixes: See commit `053e514` for timeout and success detection fixes

---

**Last Updated**: 2025-10-26
**Test Framework**: Playwright v1.56+
**Node Version**: 20.11.0+
**Status**: All 20 tests passing ✅
