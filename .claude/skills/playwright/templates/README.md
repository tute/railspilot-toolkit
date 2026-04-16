# Playwright e2e proof: project templates

These are the files the `playwright` skill copies when bootstrapping a project that doesn't already have `e2e/` scaffolding. Copy them manually as a one-time setup, or let the skill do it.

## Manual setup

```bash
mkdir -p e2e/{tests,fixtures,helpers,.auth}
cp ~/.claude/skills/playwright/templates/playwright.config.ts e2e/
cp ~/.claude/skills/playwright/templates/fixtures/auth.setup.ts e2e/fixtures/
cp ~/.claude/skills/playwright/templates/helpers/proof.ts e2e/helpers/
cp ~/.claude/skills/playwright/templates/tests/example.spec.ts e2e/tests/

npm install -D @playwright/test
npx playwright install --with-deps chromium

grep -qxF 'e2e/runs/' .git/info/exclude || echo 'e2e/runs/' >> .git/info/exclude
grep -qxF 'e2e/test-results/' .git/info/exclude || echo 'e2e/test-results/' >> .git/info/exclude
grep -qxF 'e2e/.auth/' .git/info/exclude || echo 'e2e/.auth/' >> .git/info/exclude
```

## Files

- `playwright.config.ts`: minimal Rails-aware config. One `setup` project that authenticates, one `chromium` project that runs tests. Video recording gates on `RECORD_VIDEO=true`. `slowMo` when recording so playback is watchable at 1x.
- `fixtures/auth.setup.ts`: Devise login flow. Reads `E2E_USER_EMAIL` / `E2E_USER_PASSWORD` from env. Writes storage state to `e2e/.auth/user.json`.
- `helpers/proof.ts`: three helpers:
  - `highlightElement(page, selector, label)`: force an element visible with `!important` inline styles (overrides any CSS hiding). Outlines it and labels it. Use this for presence proofs. Throws if the selector matches nothing.
  - `showAbsenceBanner(page, label)`: inject a red banner naming what's NOT on the page. Use this for absence proofs. Replaces any existing banner.
  - `stripErrorOverlays(page)`: remove React / webpack dev error overlays before screenshotting. They often come from unrelated JS errors in seeded records.
- `tests/example.spec.ts`: skeleton showing presence proof + absence proof patterns.

## Running

```bash
E2E_USER_EMAIL=dev@example.com \
E2E_USER_PASSWORD=password \
RECORD_VIDEO=true \
npx playwright test --config e2e/playwright.config.ts
```

## See also

The full workflow (feature-slug folders, consolidation, flag-state reporting) lives in `~/.claude/skills/playwright/SKILL.md`.
