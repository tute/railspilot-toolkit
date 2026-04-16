import { test, expect } from "@playwright/test";
import {
  highlightElement,
  showAbsenceBanner,
  stripErrorOverlays,
} from "../helpers/proof";

const PAUSE_MS = process.env.RECORD_VIDEO ? 2000 : 0;
const RUN_SLUG = process.env.E2E_RUN_SLUG || "example-feature";

test.describe("Example feature proof", () => {
  test("golden path: element is present and visible", async ({ page }) => {
    await page.goto("/");
    await page.waitForLoadState("domcontentloaded");
    await page.waitForTimeout(PAUSE_MS);

    await highlightElement(page, "#key-element", "Key Element");
    await expect(page.locator("#key-element")).toBeAttached();

    await page.waitForTimeout(PAUSE_MS);
    await page.screenshot({
      path: `e2e/runs/${RUN_SLUG}/screenshots/golden-path.png`,
    });
  });

  test("absence proof: element is NOT present when feature disabled", async ({
    page,
  }) => {
    await page.goto("/");
    await page.waitForLoadState("domcontentloaded");

    await expect(page.locator("#key-element")).toHaveCount(0);

    await stripErrorOverlays(page);
    await showAbsenceBanner(page, "Key Element absent: feature disabled");
    await page.waitForTimeout(PAUSE_MS);
    await page.screenshot({
      path: `e2e/runs/${RUN_SLUG}/screenshots/absence.png`,
    });
  });
});
