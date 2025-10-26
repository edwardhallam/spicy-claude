import type { Page } from '@playwright/test';
import type { writeFileSync } from 'fs';

/**
 * Comparison Helpers for Side-by-Side Testing
 *
 * Utilities for running identical tests on both Old App and Spicy Claude
 * and comparing the results to detect behavioral differences.
 */

export interface TestResult {
  success: boolean;
  text: string;
  error?: string;
  timestamp: string;
  permissionPrompted: boolean;
}

export interface ComparisonResult {
  testId: string;
  oldAppResult: TestResult;
  spicyResult: TestResult;
  identical: boolean;
  differences: string[];
  screenshots?: {
    oldApp: Buffer;
    spicy: Buffer;
  };
  timestamp: string;
}

/**
 * Run identical test on both apps and compare results
 * @param testFn - Async function that performs the test on a single page
 * @param oldApp - Old App page
 * @param spicyApp - Spicy Claude page
 * @param testId - Unique test identifier
 * @returns Promise<ComparisonResult>
 */
export async function runSideBySide(
  testFn: (page: Page) => Promise<TestResult>,
  oldApp: Page,
  spicyApp: Page,
  testId: string,
): Promise<ComparisonResult> {
  const timestamp = new Date().toISOString();

  // Run test on both apps in parallel
  const [oldAppResult, spicyResult] = await Promise.all([
    testFn(oldApp).catch((error) => ({
      success: false,
      text: '',
      error: error.message,
      timestamp,
      permissionPrompted: false,
    })),
    testFn(spicyApp).catch((error) => ({
      success: false,
      text: '',
      error: error.message,
      timestamp,
      permissionPrompted: false,
    })),
  ]);

  // Compare results
  const comparison = compareResults(oldAppResult, spicyResult);

  // If different, capture screenshots
  let screenshots: { oldApp: Buffer; spicy: Buffer } | undefined;
  if (!comparison.identical) {
    screenshots = {
      oldApp: await oldApp.screenshot({ fullPage: true }),
      spicy: await spicyApp.screenshot({ fullPage: true }),
    };
  }

  const result: ComparisonResult = {
    testId,
    oldAppResult,
    spicyResult,
    identical: comparison.identical,
    differences: comparison.differences,
    screenshots,
    timestamp,
  };

  // Record the difference if any
  if (!comparison.identical) {
    await recordDifference(testId, result);
  }

  return result;
}

/**
 * Compare two test results and identify differences
 * @param oldResult - Result from Old App
 * @param spicyResult - Result from Spicy Claude
 * @returns Object with identical flag and list of differences
 */
export function compareResults(
  oldResult: TestResult,
  spicyResult: TestResult,
): { identical: boolean; differences: string[] } {
  const differences: string[] = [];

  if (oldResult.success !== spicyResult.success) {
    differences.push(
      `SUCCESS MISMATCH: Old=${oldResult.success}, Spicy=${spicyResult.success}`,
    );
  }

  if (oldResult.permissionPrompted !== spicyResult.permissionPrompted) {
    differences.push(
      `PERMISSION PROMPT MISMATCH: Old=${oldResult.permissionPrompted}, Spicy=${spicyResult.permissionPrompted}`,
    );
  }

  if (oldResult.error && !spicyResult.error) {
    differences.push(`ERROR IN OLD APP ONLY: ${oldResult.error}`);
  }

  if (!oldResult.error && spicyResult.error) {
    differences.push(`ERROR IN SPICY CLAUDE ONLY: ${spicyResult.error}`);
  }

  if (oldResult.error && spicyResult.error && oldResult.error !== spicyResult.error) {
    differences.push(
      `DIFFERENT ERROR MESSAGES:\n  Old: ${oldResult.error}\n  Spicy: ${spicyResult.error}`,
    );
  }

  return {
    identical: differences.length === 0,
    differences,
  };
}

/**
 * Record a behavioral difference to JSON file
 * @param testId - Test identifier
 * @param result - Comparison result with difference details
 */
export async function recordDifference(
  testId: string,
  result: ComparisonResult,
): Promise<void> {
  const fs = await import('fs');
  const path = await import('path');

  const reportDir = 'tests/reports';
  const reportFile = path.join(reportDir, 'differences.json');

  // Ensure directory exists
  if (!fs.existsSync(reportDir)) {
    fs.mkdirSync(reportDir, { recursive: true });
  }

  // Load existing differences
  let differences: ComparisonResult[] = [];
  if (fs.existsSync(reportFile)) {
    const content = fs.readFileSync(reportFile, 'utf-8');
    differences = JSON.parse(content);
  }

  // Add new difference (without screenshots to keep file size reasonable)
  differences.push({
    ...result,
    screenshots: undefined, // Screenshots are saved separately
  });

  // Write back to file
  fs.writeFileSync(reportFile, JSON.stringify(differences, null, 2));

  // Save screenshots if present
  if (result.screenshots) {
    const screenshotDir = path.join(reportDir, 'screenshots', testId);
    fs.mkdirSync(screenshotDir, { recursive: true });

    fs.writeFileSync(
      path.join(screenshotDir, 'old-app.png'),
      result.screenshots.oldApp,
    );
    fs.writeFileSync(
      path.join(screenshotDir, 'spicy-claude.png'),
      result.screenshots.spicy,
    );
  }

  console.log(`🔍 Recorded difference for test ${testId}`);
  console.log(`   Differences: ${result.differences.length}`);
  result.differences.forEach((diff) => console.log(`     - ${diff}`));
}

/**
 * Generate a summary report of all differences
 * @returns Promise<string> - Markdown summary of differences
 */
export async function generateDifferencesSummary(): Promise<string> {
  const fs = await import('fs');
  const path = await import('path');

  const reportFile = path.join('tests/reports', 'differences.json');

  if (!fs.existsSync(reportFile)) {
    return '# Test Results\n\n✅ No differences found between Old App and Spicy Claude!';
  }

  const content = fs.readFileSync(reportFile, 'utf-8');
  const differences: ComparisonResult[] = JSON.parse(content);

  let summary = '# Test Results: Behavioral Differences\n\n';
  summary += `**Total Tests with Differences**: ${differences.length}\n\n`;

  differences.forEach((diff, index) => {
    summary += `## ${index + 1}. Test: ${diff.testId}\n\n`;
    summary += `**Timestamp**: ${diff.timestamp}\n\n`;

    summary += '### Old App Result\n';
    summary += `- **Success**: ${diff.oldAppResult.success}\n`;
    summary += `- **Permission Prompted**: ${diff.oldAppResult.permissionPrompted}\n`;
    if (diff.oldAppResult.error) {
      summary += `- **Error**: ${diff.oldAppResult.error}\n`;
    }
    summary += '\n';

    summary += '### Spicy Claude Result\n';
    summary += `- **Success**: ${diff.spicyResult.success}\n`;
    summary += `- **Permission Prompted**: ${diff.spicyResult.permissionPrompted}\n`;
    if (diff.spicyResult.error) {
      summary += `- **Error**: ${diff.spicyResult.error}\n`;
    }
    summary += '\n';

    summary += '### Differences\n';
    diff.differences.forEach((d) => {
      summary += `- ${d}\n`;
    });
    summary += '\n';

    summary += '---\n\n';
  });

  // Write summary to file
  const summaryFile = path.join('tests/reports', 'DIFFERENCES-SUMMARY.md');
  fs.writeFileSync(summaryFile, summary);

  return summary;
}
