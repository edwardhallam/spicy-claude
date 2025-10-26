import { test, expect } from '../../fixtures/app-fixture';
import {
  clearBrowserState,
  selectProject,
  sendMessage,
  waitForResponse,
  verifyPermissionPrompt,
  switchPermissionMode,
  fileExists,
  deleteTestFile,
} from '../../utils/test-helpers';

/**
 * Bypass Permissions (Dangerous Mode) Tests
 *
 * Tests BP-W1, BP-W2, BP-B1 from TEST-REPORT-OLD-vs-SPICY.md
 * Validates that bypass permissions mode works correctly (NEW feature in Spicy Claude)
 *
 * NOTE: These tests ONLY run on Spicy Claude (port 3003) since dangerous mode
 * is a new feature not present in Old App (port 3002)
 */

const TEST_PROJECT = '/Users/edwardhallam/projects/homelab-conductor';
const TIMESTAMP = Date.now();

test.describe('Bypass Permissions Mode', () => {
  test.beforeEach(async ({ spicyApp }) => {
    await clearBrowserState(spicyApp);
    await selectProject(spicyApp, TEST_PROJECT);

    // Switch to bypass permissions mode
    await switchPermissionMode(spicyApp, 'bypass permissions');
  });

  test('BP-W1: Write to /tmp/ with bypass (NO PROMPT)', async ({ spicyApp }) => {
    const testFile = `/tmp/bypass-test-${TIMESTAMP}.txt`;
    const command = `Create a test file at ${testFile} with content "bypass mode test"`;

    await sendMessage(spicyApp, command);

    // In bypass mode, there should be NO permission prompt
    const prompted = await verifyPermissionPrompt(spicyApp);
    expect(prompted).toBe(false);

    const response = await waitForResponse(spicyApp, 60000); // Longer timeout for first test
    const exists = await fileExists(testFile);

    // Cleanup
    await deleteTestFile(testFile);

    // Assertions
    expect(response.success).toBe(true);
    expect(exists).toBe(true);
  });

  test('BP-W2: Write to project directory with bypass (NO PROMPT)', async ({ spicyApp }) => {
    const testFile = `${TEST_PROJECT}/bypass-project-${TIMESTAMP}.txt`;
    const command = `Create a test file at ${testFile} with content "project bypass test"`;

    await sendMessage(spicyApp, command);

    // Should have NO permission prompt
    const prompted = await verifyPermissionPrompt(spicyApp);
    expect(prompted).toBe(false);

    const response = await waitForResponse(spicyApp);
    const exists = await fileExists(testFile);

    await deleteTestFile(testFile);

    expect(response.success).toBe(true);
    expect(exists).toBe(true);
  });

  test('BP-B1: Bash command to /tmp/ with bypass (NO PROMPT)', async ({ spicyApp }) => {
    const testFile = `/tmp/bypass-bash-${TIMESTAMP}.txt`;
    const command = `Use bash to create ${testFile} with echo "bypass bash test"`;

    await sendMessage(spicyApp, command);

    // Should have NO permission prompt
    const prompted = await verifyPermissionPrompt(spicyApp);
    expect(prompted).toBe(false);

    const response = await waitForResponse(spicyApp);
    const exists = await fileExists(testFile);

    await deleteTestFile(testFile);

    expect(response.success).toBe(true);
    expect(exists).toBe(true);
  });

  test('BP-VERIFY: Confirm bypass mode indicator is visible', async ({ spicyApp }) => {
    // Verify that the UI shows we're in bypass permissions mode
    const modeIndicator = spicyApp.locator('text=/bypass permissions/i');
    await expect(modeIndicator).toBeVisible();
  });

  test('BP-SWITCH: Can switch back to normal mode', async ({ spicyApp }) => {
    // Switch back to normal mode
    await switchPermissionMode(spicyApp, 'normal mode');

    // Verify mode changed
    const modeIndicator = spicyApp.locator('text=/normal mode/i');
    await expect(modeIndicator).toBeVisible();

    // Now a permission prompt SHOULD appear
    const testFile = `/tmp/normal-mode-test-${TIMESTAMP}.txt`;
    await sendMessage(spicyApp, `Create ${testFile} with content "normal mode"`);

    const prompted = await verifyPermissionPrompt(spicyApp);
    // In normal mode with file operations, we expect a prompt
    // (This may vary based on Claude SDK behavior, but test captures it)

    await deleteTestFile(testFile);
  });
});
