import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright configuration for Spicy Claude UI testing
 *
 * This config enables agents to run automated browser tests comparing
 * Old App (port 3002) vs Spicy Claude (port 3003).
 *
 * Features:
 * - Screenshots on failure for debugging
 * - Network traffic capture for API analysis
 * - Video recording on failure only (saves disk space)
 * - Serial execution (prevents port conflicts)
 * - HTML reporter for interactive results viewing
 */
export default defineConfig({
  testDir: './tests/e2e',

  /* Run tests in files in serial (not parallel) to avoid port conflicts */
  fullyParallel: false,
  workers: 1,

  /* Increase test timeout to accommodate slow Claude API calls */
  timeout: 120000, // 2 minutes per test (Claude API calls can take 60-90s)

  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,

  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,

  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: [
    ['html', { outputFolder: 'tests/reports/html' }],
    ['list'], // Console output
    ['json', { outputFile: 'tests/reports/results.json' }], // Machine-readable results
  ],

  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL for Old App - override with PLAYWRIGHT_BASE_URL env var */
    baseURL: process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3003',

    /* Collect trace on failure for debugging */
    trace: 'on-first-retry',

    /* Screenshots */
    screenshot: {
      mode: 'only-on-failure',
      fullPage: true,
    },

    /* Video recording (on failure only to save disk space) */
    video: {
      mode: 'retain-on-failure',
      size: { width: 1280, height: 720 },
    },

    /* Network HAR (HTTP Archive) recording for API analysis */
    // Captures all network requests/responses including ChatRequest payloads
    // Essential for debugging permission mode differences
    harRecording: {
      enabled: true,
      mode: 'full', // Capture both request and response bodies
      path: 'tests/reports/network/',
    },

    /* Browser context options */
    viewport: { width: 1280, height: 720 },
    ignoreHTTPSErrors: true, // Allow self-signed certs if needed

    /* Timeout settings */
    actionTimeout: 10000, // 10 seconds for actions like click, fill
    navigationTimeout: 30000, // 30 seconds for page loads
  },

  /* Configure projects for browsers */
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },

    // Uncomment if you need to test on other browsers
    // {
    //   name: 'firefox',
    //   use: { ...devices['Desktop Firefox'] },
    // },
    // {
    //   name: 'webkit',
    //   use: { ...devices['Desktop Safari'] },
    // },
  ],

  /* Folder for test artifacts such as screenshots, videos, traces, etc. */
  outputDir: 'tests/reports/test-results',

  /* Run your local dev server before starting the tests */
  // Commented out - servers should already be running (ports 3002, 3003)
  // webServer: {
  //   command: 'npm run start',
  //   url: 'http://localhost:3003',
  //   reuseExistingServer: !process.env.CI,
  // },
});
