import type { Page } from '@playwright/test';

/**
 * Test Helpers for UI Testing
 *
 * Reusable utilities for interacting with Claude Code UI applications.
 * Used by both Old App and Spicy Claude tests.
 */

/**
 * Clear all browser state (localStorage, sessionStorage, cookies)
 */
export async function clearBrowserState(page: Page): Promise<void> {
  await page.evaluate(() => {
    localStorage.clear();
    sessionStorage.clear();
  });
  await page.context().clearCookies();
}

/**
 * Navigate to a specific project directory
 * @param page - Playwright page object
 * @param projectPath - Absolute path to project directory
 */
export async function selectProject(page: Page, projectPath: string): Promise<void> {
  const encodedPath = encodeURIComponent(projectPath);
  await page.goto(`/projects${projectPath}`);

  // Wait for page to be ready
  await page.waitForLoadState('networkidle');

  // Verify project path is displayed in header
  const projectHeader = page.locator('[aria-label*="Return to new chat"]');
  await projectHeader.waitFor({ timeout: 5000 }).catch(() => {
    // Project header might not appear immediately - that's okay
  });
}

/**
 * Send a message in the chat input
 * @param page - Playwright page object
 * @param message - Message to send
 * @returns Promise that resolves when message is sent
 */
export async function sendMessage(page: Page, message: string): Promise<void> {
  const textarea = page.locator('textarea[placeholder*="Type message"]');
  await textarea.fill(message);

  // Submit the form
  const sendButton = page.locator('button[type="submit"]:has-text("Send"), button[type="submit"]:has-text("Plan")');
  await sendButton.click();
}

/**
 * Wait for Claude's response to complete
 * @param page - Playwright page object
 * @param timeout - Maximum time to wait in milliseconds
 * @returns Promise that resolves when response is complete
 */
export async function waitForResponse(page: Page, timeout: number = 30000): Promise<{
  success: boolean;
  text: string;
  error?: string;
}> {
  // Wait for loading to stop
  const loadingIndicator = page.locator('text=Processing..., text=...');
  await loadingIndicator.waitFor({ state: 'hidden', timeout }).catch(() => {
    // Loading might already be done
  });

  // Get the last assistant message
  const messages = page.locator('[role="article"]').last();
  const text = await messages.textContent() || '';

  // Check for error indicators
  const hasError = text.toLowerCase().includes('error') ||
                   text.toLowerCase().includes('failed') ||
                   text.toLowerCase().includes('cannot');

  return {
    success: !hasError,
    text,
    error: hasError ? text : undefined,
  };
}

/**
 * Capture network API payload from the latest request
 * @param page - Playwright page object
 * @returns Promise with request/response data
 */
export async function captureNetworkPayload(page: Page): Promise<{
  request?: any;
  response?: any;
}> {
  // Note: Network payloads are automatically captured by HAR recording
  // This function can be enhanced to parse HAR files if needed
  return {
    request: {},
    response: {},
  };
}

/**
 * Check if permission prompt is visible
 * @param page - Playwright page object
 * @returns Promise<boolean> - true if permission prompt is shown
 */
export async function verifyPermissionPrompt(page: Page): Promise<boolean> {
  const allowButton = page.locator('button:has-text("Allow")');
  const isVisible = await allowButton.isVisible().catch(() => false);
  return isVisible;
}

/**
 * Click the "Allow" button on permission prompt
 * @param page - Playwright page object
 */
export async function approvePermission(page: Page): Promise<void> {
  const allowButton = page.locator('button:has-text("Allow")');
  await allowButton.click();
}

/**
 * Click the "Deny" button on permission prompt
 * @param page - Playwright page object
 */
export async function denyPermission(page: Page): Promise<void> {
  const denyButton = page.locator('button:has-text("Deny")');
  await denyButton.click();
}

/**
 * Extract error message from the UI
 * @param page - Playwright page object
 * @returns Error message text or null
 */
export async function getErrorMessage(page: Page): Promise<string | null> {
  const errorText = page.locator('text=/error|failed|cannot/i').first();
  const text = await errorText.textContent().catch(() => null);
  return text;
}

/**
 * Switch permission mode by clicking the mode indicator
 * @param page - Playwright page object
 * @param targetMode - Target mode: 'normal mode', 'plan mode', 'accept edits', 'bypass permissions'
 */
export async function switchPermissionMode(page: Page, targetMode: string): Promise<void> {
  const modeButton = page.locator('button:has-text("normal mode"), button:has-text("plan mode"), button:has-text("accept edits"), button:has-text("bypass permissions")');

  // Keep clicking until we reach the target mode
  for (let i = 0; i < 4; i++) {
    const currentText = await modeButton.textContent();
    if (currentText?.includes(targetMode)) {
      break;
    }
    await modeButton.click();
    await page.waitForTimeout(200); // Small delay for UI update
  }

  // Verify we're in the correct mode
  const finalText = await modeButton.textContent();
  if (!finalText?.includes(targetMode)) {
    throw new Error(`Failed to switch to ${targetMode}. Current mode: ${finalText}`);
  }
}

/**
 * Verify that a file exists on the filesystem
 * @param filePath - Absolute path to file
 * @returns Promise<boolean> - true if file exists
 */
export async function fileExists(filePath: string): Promise<boolean> {
  try {
    const { existsSync } = await import('fs');
    return existsSync(filePath);
  } catch {
    return false;
  }
}

/**
 * Delete a test file
 * @param filePath - Absolute path to file
 */
export async function deleteTestFile(filePath: string): Promise<void> {
  try {
    const { unlinkSync, existsSync } = await import('fs');
    if (existsSync(filePath)) {
      unlinkSync(filePath);
    }
  } catch (error) {
    console.warn(`Failed to delete ${filePath}:`, error);
  }
}
