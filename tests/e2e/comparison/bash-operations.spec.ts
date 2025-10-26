import { test, expect } from '../../fixtures/app-fixture';
import {
  clearBrowserState,
  selectProject,
  sendMessage,
  waitForResponse,
  verifyPermissionPrompt,
  approvePermission,
  fileExists,
  deleteTestFile,
} from '../../utils/test-helpers';
import { runSideBySide } from '../../utils/comparison-helpers';

/**
 * Bash Operations Comparison Tests
 *
 * Tests B1-B4 from TEST-REPORT-OLD-vs-SPICY.md
 * Compares bash command behavior between Old App and Spicy Claude
 */

const TEST_PROJECT = '/Users/edwardhallam/projects/homelab-conductor';
const TIMESTAMP = Date.now();

test.describe('Bash Operations', () => {
  test.beforeEach(async ({ oldApp, spicyApp }) => {
    await clearBrowserState(oldApp);
    await clearBrowserState(spicyApp);
    await selectProject(oldApp, TEST_PROJECT);
    await selectProject(spicyApp, TEST_PROJECT);
  });

  test('B1: Bash echo to /tmp/', async ({ oldApp, spicyApp }) => {
    const testFile = `/tmp/bash-echo-${TIMESTAMP}.txt`;
    const command = `Use bash to echo "Hello from bash" > ${testFile}`;

    const result = await runSideBySide(
      async (page) => {
        await sendMessage(page, command);

        const prompted = await verifyPermissionPrompt(page);
        if (prompted) {
          await approvePermission(page);
        }

        const response = await waitForResponse(page);
        const exists = await fileExists(testFile);

        return {
          ...response,
          success: response.success && exists,
          permissionPrompted: prompted,
          timestamp: new Date().toISOString(),
        };
      },
      oldApp,
      spicyApp,
      'B1-bash-echo-tmp',
    );

    await deleteTestFile(testFile);

    expect(result.identical).toBe(true);
  });

  test('B2: Bash touch in /tmp/', async ({ oldApp, spicyApp }) => {
    const testFile = `/tmp/bash-touch-${TIMESTAMP}.txt`;
    const command = `Use bash touch command to create ${testFile}`;

    const result = await runSideBySide(
      async (page) => {
        await sendMessage(page, command);

        const prompted = await verifyPermissionPrompt(page);
        if (prompted) {
          await approvePermission(page);
        }

        const response = await waitForResponse(page);
        const exists = await fileExists(testFile);

        return {
          ...response,
          success: response.success && exists,
          permissionPrompted: prompted,
          timestamp: new Date().toISOString(),
        };
      },
      oldApp,
      spicyApp,
      'B2-bash-touch-tmp',
    );

    await deleteTestFile(testFile);

    expect(result.identical).toBe(true);
  });

  test('B3: Bash touch in project directory', async ({ oldApp, spicyApp }) => {
    const testFile = `${TEST_PROJECT}/bash-touch-project-${TIMESTAMP}.txt`;
    const command = `Use bash touch to create ${testFile}`;

    const result = await runSideBySide(
      async (page) => {
        await sendMessage(page, command);

        const prompted = await verifyPermissionPrompt(page);
        if (prompted) {
          await approvePermission(page);
        }

        const response = await waitForResponse(page);
        const exists = await fileExists(testFile);

        return {
          ...response,
          success: response.success && exists,
          permissionPrompted: prompted,
          timestamp: new Date().toISOString(),
        };
      },
      oldApp,
      spicyApp,
      'B3-bash-touch-project',
    );

    await deleteTestFile(testFile);

    expect(result.identical).toBe(true);
  });

  test('B4: Bash cat with heredoc', async ({ oldApp, spicyApp }) => {
    const testFile = `${TEST_PROJECT}/bash-heredoc-${TIMESTAMP}.txt`;
    const command = `Use bash with heredoc to create ${testFile} with multiple lines:\nLine 1\nLine 2\nLine 3`;

    const result = await runSideBySide(
      async (page) => {
        await sendMessage(page, command);

        const prompted = await verifyPermissionPrompt(page);
        if (prompted) {
          await approvePermission(page);
        }

        const response = await waitForResponse(page);
        const exists = await fileExists(testFile);

        let hasCorrectContent = false;
        if (exists) {
          const fs = await import('fs');
          const content = fs.readFileSync(testFile, 'utf-8');
          hasCorrectContent = content.includes('Line 1') &&
                            content.includes('Line 2') &&
                            content.includes('Line 3');
        }

        return {
          ...response,
          success: response.success && exists && hasCorrectContent,
          permissionPrompted: prompted,
          timestamp: new Date().toISOString(),
        };
      },
      oldApp,
      spicyApp,
      'B4-bash-heredoc',
    );

    await deleteTestFile(testFile);

    expect(result.identical).toBe(true);
  });
});
