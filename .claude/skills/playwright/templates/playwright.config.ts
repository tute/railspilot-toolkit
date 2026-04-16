import { defineConfig, devices } from "@playwright/test";

const baseURL = process.env.E2E_BASE_URL || "http://localhost:3000";
const isCI = !!process.env.CI;
const VIEWPORT = { width: 1200, height: 800 };

export default defineConfig({
  testDir: ".",
  testMatch: ["tests/**/*.spec.ts"],
  fullyParallel: true,
  forbidOnly: isCI,
  retries: isCI ? 1 : 0,
  timeout: 30_000,
  use: {
    baseURL,
    screenshot: "only-on-failure",
    trace: "on-first-retry",
    video: process.env.RECORD_VIDEO
      ? { mode: "on", size: VIEWPORT }
      : "off",
    viewport: VIEWPORT,
    launchOptions: {
      slowMo: process.env.RECORD_VIDEO ? 1000 : 0,
    },
  },
  outputDir: "./test-results",

  projects: [
    {
      name: "setup",
      testMatch: "fixtures/auth.setup.ts",
      use: { video: "off" },
    },
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        storageState: "e2e/.auth/user.json",
      },
      dependencies: ["setup"],
    },
  ],
});
