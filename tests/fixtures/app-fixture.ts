import { test as base, type Page, type BrowserContext } from '@playwright/test';

/**
 * App Fixture for Old App and Spicy Claude
 *
 * Provides pre-configured browser contexts for both applications:
 * - Old App: http://localhost:3002
 * - Spicy Claude: http://localhost:3003
 *
 * Usage in tests:
 *   test('My test', async ({ oldApp, spicyApp }) => {
 *     await oldApp.goto('/');
 *     await spicyApp.goto('/');
 *   });
 */

type AppFixtures = {
  oldApp: Page;
  spicyApp: Page;
  oldAppContext: BrowserContext;
  spicyAppContext: BrowserContext;
};

export const test = base.extend<AppFixtures>({
  // Old App browser context (port 3002)
  oldAppContext: async ({ browser }, use) => {
    const context = await browser.newContext({
      baseURL: 'http://localhost:3002',
      recordHar: { path: 'tests/reports/network/old-app.har' },
    });
    await use(context);
    await context.close();
  },

  // Spicy Claude browser context (port 3003)
  spicyAppContext: async ({ browser }, use) => {
    const context = await browser.newContext({
      baseURL: 'http://localhost:3003',
      recordHar: { path: 'tests/reports/network/spicy-claude.har' },
    });
    await use(context);
    await context.close();
  },

  // Old App page
  oldApp: async ({ oldAppContext }, use) => {
    const page = await oldAppContext.newPage();
    await use(page);
    await page.close();
  },

  // Spicy Claude page
  spicyApp: async ({ spicyAppContext }, use) => {
    const page = await spicyAppContext.newPage();
    await use(page);
    await page.close();
  },
});

export { expect } from '@playwright/test';
