# Review checklist

Every item once cost a fix round on a "match the Figma design" ticket. Source
in brackets: a commit on TEL-2289, a memory note, or `lessons.md`.

## Figma fidelity (per breakpoint, light and dark)

1. Colours. Sample each fill and status dot in the Figma PNG
   (`magick f.png -format '%[pixel:p{x,y}]' info:`) and compare with the
   computed style on the page. Badge dots a shade dark (5cd0d89d35); a
   hardcoded SVG grey wrong in dark mode (9eef3ca4fd).
2. Text. Font family, weight, size and line height of every TEXT node against
   the computed style; headings map to the type tokens (1931b47f14,
   `figma-node-rendering`).
3. Spacing and widths. `itemSpacing`, padding and frame sizes: stat label
   widths, dividers, field widths, wrapping (42df7d924b, 1931b47f14,
   `design-review-catchables`).
4. Inventory. Every control in the frame exists on the page, and nothing on the
   page is missing from the frame. Phone and tablet layouts: select instead of
   tabs, search-first filter order, picker cards (0438dd090f); cards instead
   of the table below 768px (d31edcd341); links read as links, banners centred
   (74dbd5c473). Before you call an element a conflict, find the sibling ticket
   that owns it (lessons 2026-11-06).
5. Overflow at 393px. The table wrapper's `scrollWidth` exceeds its
   `clientWidth`; `min-width` sits on the frame, not the table
   (`aqui-fluid-table-min-width`); first column capped on phones (494f3cbbac).
6. Data labels that differ from the Figma copy stay as the data says and go in
   the designer table, never "fixed" (`tel-2289-pr-notes`).
7. Dark mode without a dark frame: check that no raw light colour survives in
   the new partials (`tel-report-redesign-decisions`).
7a. Placeholders and single-line text fit their boxes at every width:
   `input.scrollWidth <= input.clientWidth` for every text input (the date
   fields clipped "MM-DD-YYYY" at 768; TEL-2292 120d27072d). A fixed-width
   sibling must not shrink: give it `shrink-0` and let the search box flex.
7b. Pagination per width: count the page slots the frame shows (desktop 7,
   tablet 5) and the rows it uses (one row at tablet); the nav region's
   `scrollWidth <= clientWidth`, and First/Last are not overlapped
   (120d27072d: caller-side `report_ds_pagination_compact_class`).
7c. Section order per report and width follows that report's own frame, not a
   sibling report's order; the shared phone reorder is a default to override
   per `data-report-type` (dbdd251086: filters, pills, search, dates).
7d. Role-specific elements per view: tabs and switchers only for the roles the
   frame shows them for, and a section that is role-only (PracticeSmart for
   students) present for that role. Probe with the role assertion, never by
   eye on a window whose session you did not verify.

## Behaviour

8. Sticky header: scroll the real scroller, `th.top` stays pinned at each width
   (494f3cbbac, `background-tab-no-raf`). Hidden tabs never fire scroll or rAF:
   headless Chrome only.
9. Filters: each change submits once (the date picker fires `change` twice,
   `ds-date-picker-double-change`); selections comma-joined, no duplicated
   query params (494f3cbbac); older fetches aborted and totals re-subscribed
   on each change (d6d202afd6); search clear works after a debounced search
   and the no-match copy shows (e57ea71891, d35d9699f2).
10. Pill and chip links carry only permitted filter params; no
    `params.permit!`, no echoed controller or action; Brakeman clean
    (54fe8e9dc2).
11. Modals and dropdowns: Escape closes and returns focus to the trigger; Tab
    and arrows reach every control; Enter and Space activate; modals live
    outside the card flow; submit buttons do not swallow the submit
    (`design-review-catchables`, 05c5012cd6, ae06d03098, 494f3cbbac).
12. A control opens only what its label promises (lessons 2026-11-06).
13. No console errors or uncaught exceptions on any page, width or scheme
    (`capture.mjs` writes `errors.json`).
14. Turbo frame requests render the frame layout (d6d202afd6).
15. Flag off: the legacy page renders unchanged.

## Code conventions

16. Fix aqui_* rendering at the call site with caller-side options, not in
    `app/helpers/aquifer_ui/*`; the rule is lifted only for new aqui_* helpers
    (`fix-in-caller-not-shared-ds-helper`).
17. Every new aqui_* helper is registered in both `/aquifer_ui/demo` and
    `/aquifer_ui/library` in the same PR (e5bfa53de5).
18. No hex in views, CSS or inline SVG in the diff; `--ds-*` tokens only. Any
    edit to shared theme tokens is listed, because it ripples to other pages
    (9eef3ca4fd, `tel-2289-pr-notes`).
19. Flag gating through `UsesDesignSystemLayout`, one Flipper per surface;
    legacy views untouched and pinned by specs (d6d202afd6, db6028e2a3).
20. Specs that render flag-gated routes draw them with the env flags
    (8e7f2d88c3, `ds-layout-specs-need-report-page-flag`).
21. No layout tautology specs, no spec for colour or markup tweaks
    (`aqui-fluid-table-min-width`, `no-spec-for-visual-tweaks`).
22. A state the design shows but the schema lacks renders the real value and
    becomes an open question (`render-known-truth-not-derived-proxy`).

## PR hygiene

23. Size: 600 to 4,400 production lines, specs 30 to 50% of the diff
    (`ui-redesign-pr-size-baseline`).
24. Commits of about 500 lines by area, reorganised after the review passes;
    stage explicit paths; no attribution trailers; never mention QA
    (`one-commit-per-ticket`, `commit-message-framing`, `no-claude-session-trailer`).
25. Local-only files never committed: `config/environments/development.rb`,
    `config/application.yml` (`tel-2289-pr-notes`).
26. The PR carries the designer table: Figma deviations kept on purpose, token
    ripples, open questions (`tel-2289-pr-notes`).
27. One fix round for medium and higher findings, then stop
28. The full suite's failing set equals the base branch's failing set before
    any push; local-only failures (Selenium, PDF, flag env) are listed in the
    hand-off, not fixed on the ticket.
    (`one-fix-round-after-review`).
