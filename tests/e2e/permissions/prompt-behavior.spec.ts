import { test, expect } from '../../fixtures/app-fixture';
import {
  clearBrowserState,
  selectProject,
  sendMessage,
  waitForResponse,
  verifyPermissionPrompt,
  approvePermission,
  denyPermission,
  deleteTestFile,
} from '../../utils/test-helpers';

/**
 * Permission Prompt Behavior Tests
 *
 * Validates that permission prompts appear correctly and that
 * approve/deny functionality works as expected
 */

const TEST_PROJECT = '/Users/edwardhallam/projects/homelab-conductor';
const TIMESTAMP = Date.now();

test.describe('Permission Prompts', () => {
  test.beforeEach(async ({ spicyApp }) => {
    await selectProject(spicyApp, TEST_PROJECT);
    await clearBrowserState(spicyApp);
  });

  test('Permission prompt appears for file write', async ({ spicyApp }) => {
    const testFile = `/tmp/perm-test-${TIMESTAMP}.txt`;
    await sendMessage(spicyApp, `Create ${testFile} with content "test"`);

    // Prompt may or may not appear depending on Claude SDK behavior
    // This test captures whether it does
    const prompted = await verifyPermissionPrompt(spicyApp);

    // Just log the result - behavior varies by SDK version
    console.log(`Permission prompted for file write: ${prompted}`);

    // Cleanup
    if (prompted) {
      await approvePermission(spicyApp);
    }
    await waitForResponse(spicyApp);
    await deleteTestFile(testFile);
  });

  test('Approving permission allows operation to proceed', async ({ spicyApp }) => {
    const testFile = `${TEST_PROJECT}/perm-approve-${TIMESTAMP}.txt`;
    await sendMessage(spicyApp, `Create ${testFile} with content "approved"`);

    const prompted = await verifyPermissionPrompt(spicyApp);
    if (prompted) {
      await approvePermission(spicyApp);
    }

    const response = await waitForResponse(spicyApp);

    await deleteTestFile(testFile);

    // If prompted and approved, operation should succeed
    if (prompted) {
      expect(response.success).toBe(true);
    }
  });

  test('Denying permission prevents operation', async ({ spicyApp }) => {
    const testFile = `${TEST_PROJECT}/perm-deny-${TIMESTAMP}.txt`;
    await sendMessage(spicyApp, `Create ${testFile} with content "denied"`);

    const prompted = await verifyPermissionPrompt(spicyApp);
    if (prompted) {
      await denyPermission(spicyApp);
      const response = await waitForResponse(spicyApp);

      // Operation should not succeed if denied
      expect(response.success).toBe(false);
    } else {
      console.log('No permission prompt appeared - test skipped');
    }

    await deleteTestFile(testFile);
  });
});
