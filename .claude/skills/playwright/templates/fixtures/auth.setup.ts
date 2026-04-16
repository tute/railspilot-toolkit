import { test as setup } from "@playwright/test";

const authFile = "e2e/.auth/user.json";

setup("authenticate", async ({ page }) => {
  setup.setTimeout(60_000);

  const email = process.env.E2E_USER_EMAIL;
  const password = process.env.E2E_USER_PASSWORD;

  if (!email || !password) {
    throw new Error(
      "E2E_USER_EMAIL and E2E_USER_PASSWORD environment variables are required"
    );
  }

  await page.goto("/users/sign_in", { waitUntil: "domcontentloaded" });
  await page.locator("#user_email").fill(email);
  await page.locator("#user_password").fill(password);
  await page
    .locator("form[action*='sign_in'] [type='submit']")
    .first()
    .click();
  await page.waitForLoadState("domcontentloaded");

  await page.context().storageState({ path: authFile });
});
