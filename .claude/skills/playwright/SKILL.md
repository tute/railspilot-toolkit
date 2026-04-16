---
name: playwright
description: Create and run Playwright e2e proof tests (video + screenshot) for a feature under test. Use when asked to "test with Playwright", "capture e2e proof", "record a browser walkthrough", or "prove this feature works end-to-end". Produces demo-quality recordings saved to e2e/runs/<feature-slug>/, auto-excluded from git.
effort: high
---

Produce demo-quality Playwright e2e proof (video + screenshots) for a specific feature. Outputs land in a feature-named folder under `e2e/runs/`, which this skill auto-excludes from git via `.git/info/exclude` (local, not tracked).

## When to use

- User asks to test a feature with Playwright, capture e2e proof, or record a walkthrough
- User wants visual evidence a feature works (for PR, ticket, demo)
- After implementing a feature that has visible UI state (elements appear/disappear, navigation, forms)

## Prerequisites (check before running)

1. Dev server up: `curl -sf http://localhost:3000/users/sign_in` (or `http://<subdomain>.localhost:3000/users/sign_in` if the app uses subdomain routing). If unreachable, tell the user to start it (e.g. `bin/dev`, `overmind start -f Procfile.dev`, or `bundle exec rails s`) and stop. Do NOT start it yourself, it's long-running.
2. Playwright installed: `npx playwright --version`. If missing: `npx playwright install --with-deps chromium`.
3. Seed data the feature needs (test users, feature flags, fixtures). If missing, write a seed file under `db/seeds/<feature-slug>.rb` and run it via `mise exec -- bundle exec rails runner "load 'db/seeds/<feature-slug>.rb'"`.
4. `e2e/` scaffolding exists. If not, bootstrap from templates (see Bootstrap section below).

## Workflow

### 1. Clarify the feature under test

Get from the user (or infer from recent work):
- Feature slug (kebab-case, becomes folder name): e.g. `pwa-flipper-gating`, `login-mfa`, `search-autocomplete`
- Golden-path scenario(s): what should happen, step by step
- Expected UI changes: selectors that should appear/disappear, URL changes, text content
- Preconditions: which user, which subdomain/tenant, what data must exist
- Flag state: for feature-flagged work, which flags are on/off for each tested scenario

If the user says "test X", briefly echo back what you'll test before writing code.

### 2. Bootstrap e2e/ if it doesn't exist

The skill ships templates at `~/.claude/skills/playwright/templates/`. If the project has no `e2e/` directory:

```bash
mkdir -p e2e/{tests,fixtures,helpers,.auth}
cp ~/.claude/skills/playwright/templates/playwright.config.ts e2e/
cp ~/.claude/skills/playwright/templates/fixtures/auth.setup.ts e2e/fixtures/
cp ~/.claude/skills/playwright/templates/helpers/proof.ts e2e/helpers/
```

Then tell the user to install Playwright if they haven't: `npx playwright install --with-deps chromium`. Adapt the config for their auth flow / base URL.

### 3. Prepare the output folder + exclude from git

```bash
FEATURE_SLUG="pwa-flipper-gating"
OUTPUT_DIR="e2e/runs/$FEATURE_SLUG"
mkdir -p "$OUTPUT_DIR/screenshots" "$OUTPUT_DIR/videos"
for path in 'e2e/runs/' 'e2e/test-results/' 'e2e/.auth/'; do
  grep -qxF "$path" .git/info/exclude || echo "$path" >> .git/info/exclude
done
```

`.git/info/exclude` is preferred over `.gitignore`: it's local-only and doesn't pollute the repo for teammates.

### 4. Write the spec

Place it at `e2e/tests/<feature-slug>.spec.ts`. Import the helpers from `e2e/helpers/proof.ts`:

```typescript
import { test, expect } from "@playwright/test";
import { highlightElement, showAbsenceBanner, stripErrorOverlays } from "../helpers/proof";

test.describe("<Feature name> proof", () => {
  test("<golden-path scenario>", async ({ page }) => {
    await page.goto("/<starting-path>");
    await page.waitForLoadState("domcontentloaded");

    await highlightElement(page, "#<key-selector>", "Label");
    await expect(page.locator("#<key-selector>")).toBeAttached();
    await page.screenshot({ path: "e2e/runs/<slug>/screenshots/01-initial.png" });

    await page.locator("<action-selector>").click();

    await expect(page.locator("<result-selector>")).toBeVisible();
    await page.screenshot({ path: "e2e/runs/<slug>/screenshots/02-result.png" });
  });

  test("<absence proof>", async ({ page }) => {
    await page.goto("/<path>");
    await expect(page.locator("#<should-not-exist>")).toHaveCount(0);
    await stripErrorOverlays(page);
    await showAbsenceBanner(page, "Element not present: <reason>");
    await page.screenshot({ path: "e2e/runs/<slug>/screenshots/absence.png" });
  });
});
```

Key guidelines (learned the hard way):

- Force visibility for screenshots. If an element is in the DOM but hidden by CSS (`display:none`, `opacity:0`, `transform:translateY(-100%)`, etc.), `toBeAttached()` will pass while the screenshot shows nothing. Use `highlightElement` which calls `setProperty(..., "important")` on `transform`, `opacity`, `display` (revert), and `pointer-events` to override any CSS. Do NOT just add inline `position: relative`, it breaks `position: fixed` without forcing visibility.
- Strip dev error overlays before absence screenshots. JS bundler dev overlays (Vite, webpack, esbuild) and React's dev error overlay will obscure the page. Call `stripErrorOverlays(page)` to remove them.
- Absence proofs need a visible banner. A blank screenshot of "the element isn't there" is indistinguishable from a broken page. Inject a red banner naming what's absent (`showAbsenceBanner`).
- Prefer direct URL navigation when the app's index/search pages need extra seed metadata (like search indexes) that your seed didn't populate. If clicking a link fails, fetch a record ID via `rails runner` and navigate directly.
- Avoid `networkidle` on Rails apps with SSE/LiveReload, it never settles. Use `domcontentloaded`.
- Add short waits between steps when `RECORD_VIDEO=true` so the playback is watchable at 1x.
- Name screenshots descriptively. `pwa-enabled-offline-indicator.png` tells a reviewer what they're looking at, `01-initial.png` doesn't.

### 5. Wire up auth / subdomain if needed

If the feature requires a logged-in user or subdomain scoping, the template `auth.setup.ts` reads credentials from env vars. Add a project entry to `e2e/playwright.config.ts`:

```ts
{
  name: "<feature-slug>",
  testMatch: "tests/<feature-slug>.spec.ts",
  use: { ...devices["Desktop Chrome"], baseURL: "http://<subdomain>.localhost:3000", storageState: "e2e/.auth/user.json" },
  dependencies: ["setup"],
}
```

For multi-tenant / multi-user proof, add a second `setup-*` fixture and project pair with its own storageState file.

### 6. Run with video recording

```bash
E2E_USER_EMAIL=test@example.com \
E2E_USER_PASSWORD=Password1234 \
RECORD_VIDEO=true \
npx playwright test \
  --config e2e/playwright.config.ts \
  --project=setup --project="<feature-slug>" \
  --output="$OUTPUT_DIR/output"
```

Videos land in `$OUTPUT_DIR/output/<test-id>/video.webm`. Screenshots from `page.screenshot()` land wherever `path:` pointed.

### 7. Consolidate and prune

After the run:

```bash
cp "$OUTPUT_DIR/output/"*"<test-id-substring>"*/video.webm "$OUTPUT_DIR/videos/<descriptive-name>.webm"
rm -rf "$OUTPUT_DIR/output" "$OUTPUT_DIR/report"
ls "$OUTPUT_DIR/screenshots" "$OUTPUT_DIR/videos"
```

The final folder should contain only `screenshots/` and `videos/`. Raw Playwright output is duplication.

### 8. Report to the user

Include:
1. Folder path (e.g. `e2e/runs/<slug>/`)
2. One-line description per proof file (e.g. "pwa-enabled-offline-indicator.png: yellow banner 'Viewing offline' visible on test-group-1")
3. For feature-flagged features: a flag-state table showing what was configured during capture, otherwise the proof is ambiguous (was the feature off because the flag was off, or because the code is broken?)

Example:

| Subdomain | `FeatureFlag.pwa` (ENV) | `Flipper[:pwa]` (actor=group) | Result |
|---|---|---|---|
| test-group-1 | false | true | PWA shown ✓ |
| test-group-2 | false | false | PWA absent ✓ |

## Output structure

```
e2e/runs/<feature-slug>/
  screenshots/
    <scenario>-<element>.png
    ...
  videos/
    <scenario>.webm
    ...
```

## Simulating offline / browser conditions

Playwright can simulate network conditions directly rather than forcing CSS:

```ts
await page.context().setOffline(true);
```

This is the real way to prove offline behavior. The `highlightElement` CSS-force approach proves presence in the DOM but not that the JS offline-detection actually works. Pick the right tool for what you're proving.

Other useful simulations:
- `await page.context().grantPermissions(['geolocation']);`
- `await page.emulateMedia({ colorScheme: 'dark' });`
- `await page.emulateMedia({ reducedMotion: 'reduce' });`

## Error recovery

- Test fails on first run: often real, the feature may not work, or selectors may be wrong. Investigate before retrying. If the failure is flaky (timing), add explicit `waitFor` instead of blanket retries.
- Auth setup times out: check the sign-in form's selectors match the Devise form the app actually renders. Adjust the template.
- Video not produced: ensure `RECORD_VIDEO=true` is exported. The template config gates video on this env var.
- Screenshot shows nothing where an element should be: the element is in the DOM but hidden by CSS. Use `highlightElement` (which uses `!important` inline styles), not just class removal.
- Screenshot shows a dev error overlay: call `stripErrorOverlays(page)` before the screenshot. The overlay often comes from unrelated JS errors in seeded records and isn't what's under test.
- Test data doesn't appear on index/search pages: index pages often depend on derived data (search indexes, denormalized counters, published-state filters, scopes) that minimal seeds don't populate. Navigate directly to a record URL by ID instead.

## Do not

- Do not silence failing assertions to get a green recording. A failing proof is useful evidence that the feature is broken.
- Do not use `test.skip` to hide gaps; if a precondition is missing, stop and report.
- Do not claim a feature works when the proof only verifies the element is in the DOM. Be explicit that `toBeAttached` is weaker than `toBeVisible`, and that forcing visibility via CSS is weaker than triggering the real UX state.
