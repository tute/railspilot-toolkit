import type { Page } from "@playwright/test";

const ABSENCE_SELECTOR = '[data-proof-absence="true"]';

export async function highlightElement(
  page: Page,
  selector: string,
  label: string
): Promise<void> {
  const found = await page.evaluate(
    ({ sel, lbl }) => {
      const el = document.querySelector(sel) as HTMLElement | null;
      if (!el) return false;
      el.classList.remove("hidden");
      const styles: Record<string, string> = {
        transform: "translateY(0)",
        opacity: "1",
        display: "revert",
        "pointer-events": "auto",
        outline: "4px solid #22c55e",
        "outline-offset": "2px",
        "z-index": "99999",
      };
      for (const [k, v] of Object.entries(styles)) {
        el.style.setProperty(k, v, "important");
      }

      el.querySelectorAll("[data-proof-badge]").forEach((b) => b.remove());
      const badge = document.createElement("div");
      badge.setAttribute("data-proof-badge", "");
      badge.textContent = lbl;
      badge.style.cssText =
        "position:absolute;top:100%;left:0;margin-top:4px;background:#22c55e;" +
        "color:#fff;padding:4px 12px;font:bold 14px sans-serif;border-radius:4px;" +
        "z-index:99999;white-space:nowrap;";
      el.appendChild(badge);
      return true;
    },
    { sel: selector, lbl: label }
  );

  if (!found) {
    throw new Error(`highlightElement: no element matched ${selector}`);
  }
}

export async function showAbsenceBanner(page: Page, label: string): Promise<void> {
  await page.evaluate(
    ({ sel, lbl }) => {
      document.querySelectorAll(sel).forEach((el) => el.remove());
      const banner = document.createElement("div");
      banner.setAttribute("data-proof-absence", "true");
      banner.textContent = lbl;
      banner.style.cssText =
        "position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);" +
        "background:#ef4444;color:#fff;padding:20px 40px;font:bold 24px sans-serif;" +
        "border-radius:12px;z-index:99999;box-shadow:0 4px 24px rgba(0,0,0,0.3);";
      document.body.appendChild(banner);
    },
    { sel: ABSENCE_SELECTOR, lbl: label }
  );
}

export async function clearAbsenceBanners(page: Page): Promise<void> {
  await page.evaluate((sel) => {
    document.querySelectorAll(sel).forEach((el) => el.remove());
  }, ABSENCE_SELECTOR);
}

export async function stripErrorOverlays(page: Page): Promise<void> {
  await page.evaluate(() => {
    document
      .querySelectorAll(
        '[id*="error-overlay"], [class*="error-overlay"], [id*="webpack-dev-server"], iframe[src*="webpack"], iframe[id*="error"]'
      )
      .forEach((el) => el.remove());
  });
}
