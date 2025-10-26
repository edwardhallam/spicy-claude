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
import { runSideBySide, type TestResult } from '../../utils/comparison-helpers';

/**
 * File Operations Comparison Tests
 *
 * Tests W1-W4, R1-R3, E1-E2 from TEST-REPORT-OLD-vs-SPICY.md
 * Compares file operation behavior between Old App (port 3002) and Spicy Claude (port 3003)
 */

const TEST_PROJECT = '/Users/edwardhallam/projects/homelab-conductor';
const TIMESTAMP = Date.now();

test.describe('File Operations: Write Tests', () => {
  test.beforeEach(async ({ oldApp, spicyApp }) => {
    // Clear browser state for both apps
    await clearBrowserState(oldApp);
    await clearBrowserState(spicyApp);

    // Select same project on both apps
    await selectProject(oldApp, TEST_PROJECT);
    await selectProject(spicyApp, TEST_PROJECT);
  });

  test('W1: Write to /tmp/ directory', async ({ oldApp, spicyApp }) => {
    const testFile = `/tmp/test-old-vs-spicy-${TIMESTAMP}.txt`;
    const command = `Create a test file at ${testFile} with content "test from automated test"`;

    const result = await runSideBySide(
      async (page) => {
        await sendMessage(page, command);

        // Check if permission prompt appears
        const prompted = await verifyPermissionPrompt(page);

        // Approve if prompted
        if (prompted) {
          await approvePermission(page);
        }

        // Wait for response
        const response = await waitForResponse(page);

        // Verify file was created
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
      'W1-write-tmp',
    );

    // Cleanup
    await deleteTestFile(testFile);

    // Assertions
    expect(result.identical).toBe(true);
    if (!result.identical) {
      console.error('Differences found:', result.differences);
    }
  });

  test('W2: Write to project directory', async ({ oldApp, spicyApp }) => {
    const testFile = `${TEST_PROJECT}/test-write-${TIMESTAMP}.txt`;
    const command = `Create a test file at ${testFile} with content "project test"`;

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
      'W2-write-project',
    );

    await deleteTestFile(testFile);

    expect(result.identical).toBe(true);
  });

  test('W3: Write to home directory', async ({ oldApp, spicyApp }) => {
    const testFile = `~/test-home-${TIMESTAMP}.txt`;
    const command = `Create a test file at ${testFile} with content "home test"`;

    const result = await runSideBySide(
      async (page) => {
        await sendMessage(page, command);

        const prompted = await verifyPermissionPrompt(page);
        if (prompted) {
          await approvePermission(page);
        }

        const response = await waitForResponse(page);

        // Note: Need to expand ~ to actual home path for fileExists
        const expandedPath = testFile.replace('~', process.env.HOME || '');
        const exists = await fileExists(expandedPath);

        return {
          ...response,
          success: response.success && exists,
          permissionPrompted: prompted,
          timestamp: new Date().toISOString(),
        };
      },
      oldApp,
      spicyApp,
      'W3-write-home',
    );

    // Cleanup with expanded path
    const expandedPath = testFile.replace('~', process.env.HOME || '');
    await deleteTestFile(expandedPath);

    expect(result.identical).toBe(true);
  });

  test('W4: Write to nested project subdirectory', async ({ oldApp, spicyApp }) => {
    const testFile = `${TEST_PROJECT}/tests/reports/test-nested-${TIMESTAMP}.txt`;
    const command = `Create a test file at ${testFile} with content "nested test"`;

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
      'W4-write-nested',
    );

    await deleteTestFile(testFile);

    expect(result.identical).toBe(true);
  });
});

test.describe('File Operations: Read Tests', () => {
  test.beforeEach(async ({ oldApp, spicyApp }) => {
    await clearBrowserState(oldApp);
    await clearBrowserState(spicyApp);
    await selectProject(oldApp, TEST_PROJECT);
    await selectProject(spicyApp, TEST_PROJECT);
  });

  test('R1: Read from /tmp/ directory', async ({ oldApp, spicyApp }) => {
    // First, create a test file
    const testFile = `/tmp/test-read-${TIMESTAMP}.txt`;
    const testContent = 'Test content for reading';
    const fs = await import('fs');
    fs.writeFileSync(testFile, testContent);

    const command = `Read the file at ${testFile} and tell me its content`;

    const result = await runSideBySide(
      async (page) => {
        await sendMessage(page, command);

        const prompted = await verifyPermissionPrompt(page);
        if (prompted) {
          await approvePermission(page);
        }

        const response = await waitForResponse(page);

        // Check if response contains the file content
        const containsContent = response.text.includes(testContent);

        return {
          ...response,
          success: response.success && containsContent,
          permissionPrompted: prompted,
          timestamp: new Date().toISOString(),
        };
      },
      oldApp,
      spicyApp,
      'R1-read-tmp',
    );

    await deleteTestFile(testFile);

    expect(result.identical).toBe(true);
  });

  test('R2: Read from project directory', async ({ oldApp, spicyApp }) => {
    const command = 'Read the README.md file and tell me what this project is about';

    const result = await runSideBySide(
      async (page) => {
        await sendMessage(page, command);

        const prompted = await verifyPermissionPrompt(page);
        if (prompted) {
          await approvePermission(page);
        }

        const response = await waitForResponse(page);

        return {
          ...response,
          permissionPrompted: prompted,
          timestamp: new Date().toISOString(),
        };
      },
      oldApp,
      spicyApp,
      'R2-read-project',
    );

    expect(result.identical).toBe(true);
  });
});

test.describe('File Operations: Edit Tests', () => {
  test.beforeEach(async ({ oldApp, spicyApp }) => {
    await clearBrowserState(oldApp);
    await clearBrowserState(spicyApp);
    await selectProject(oldApp, TEST_PROJECT);
    await selectProject(spicyApp, TEST_PROJECT);
  });

  test('E1: Edit file in /tmp/', async ({ oldApp, spicyApp }) => {
    // Create a test file
    const testFile = `/tmp/test-edit-${TIMESTAMP}.txt`;
    const fs = await import('fs');
    fs.writeFileSync(testFile, 'Original content');

    const command = `Edit ${testFile} and change the content to "Modified content"`;

    const result = await runSideBySide(
      async (page) => {
        await sendMessage(page, command);

        const prompted = await verifyPermissionPrompt(page);
        if (prompted) {
          await approvePermission(page);
        }

        const response = await waitForResponse(page);

        // Verify content was changed
        const newContent = fs.readFileSync(testFile, 'utf-8');
        const wasModified = newContent.includes('Modified content');

        return {
          ...response,
          success: response.success && wasModified,
          permissionPrompted: prompted,
          timestamp: new Date().toISOString(),
        };
      },
      oldApp,
      spicyApp,
      'E1-edit-tmp',
    );

    await deleteTestFile(testFile);

    expect(result.identical).toBe(true);
  });

  test('E2: Edit file in project directory', async ({ oldApp, spicyApp }) => {
    // Create a test file in project
    const testFile = `${TEST_PROJECT}/test-edit-project-${TIMESTAMP}.txt`;
    const fs = await import('fs');
    fs.writeFileSync(testFile, 'Original project content');

    const command = `Edit ${testFile} and add a new line: "This line was added by test"`;

    const result = await runSideBySide(
      async (page) => {
        await sendMessage(page, command);

        const prompted = await verifyPermissionPrompt(page);
        if (prompted) {
          await approvePermission(page);
        }

        const response = await waitForResponse(page);

        const newContent = fs.readFileSync(testFile, 'utf-8');
        const wasModified = newContent.includes('This line was added by test');

        return {
          ...response,
          success: response.success && wasModified,
          permissionPrompted: prompted,
          timestamp: new Date().toISOString(),
        };
      },
      oldApp,
      spicyApp,
      'E2-edit-project',
    );

    await deleteTestFile(testFile);

    expect(result.identical).toBe(true);
  });
});
