---
name: figma-fidelity-review
description: Reviews a branch that implements a Figma design. Exports the Figma frames, captures the app at each breakpoint in light and dark, diffs them, probes behaviour (sticky header, filters, keyboard, console errors) and audits the diff against the project's design-system conventions. Use when asked to "review against Figma", "check fidelity", "compare the page with the design", or before sharing a redesign PR.
---

# Figma fidelity review

Turn the Figma-vs-app review of a redesign branch into one scripted pass, so
the fix round happens before anyone else looks.

`$SKILL_DIR` is the folder of this file. Scripts need node 22+ (global
`WebSocket`), ImageMagick 7 (`magick`), python3, and a Chrome you own. Read
`reference/checklist.md` first; every item there is a past fix.

## 0. Config

Write `<scratchpad>/review/config.json` from `assets/config.example.json`:
host, login, widths, schemes, how the app stores the colour scheme, what marks
a page as settled, the pages to review (key to path), and the Figma file plus
frame node per `key-width`. Credentials come from the user or local seed
notes, never from the repo; the login field may need the full email, not the
username. `localStorage` seeds keys before each load (collapse the sidebar if
the frame shows it collapsed). `ignoreErrors` lists regexes for dev-only console
noise such as the webpack-dev-server socket.

One config and one Chrome per signed-in role: the profile holds one session, so
an educator and a student view need two ports and two `--user-data-dir`. A
Chrome already on 9334 may belong to another session; start your own on a free
port when you need a different login.

Start a headless Chrome of your own:
`google-chrome-stable --headless=new --remote-debugging-port=9334 --user-data-dir=<scratchpad>/chrome --no-first-run about:blank`
(Bash `run_in_background`). Never drive or `Page.bringToFront` a visible
Chrome; a hidden tab never fires scroll or rAF.

## 1. Figma references

Try the API first: `curl -sD - -o /dev/null -H "X-Figma-Token: $KEY" "https://api.figma.com/v1/images/<file>?ids=<a:b>&format=png&scale=1"`.
A `retry-after` header means the account is rate-limited for that long. Then
export through the web UI: launch a visible Chrome on port 9333 with its own
profile, ask the user to sign in to Figma once, and run
`node $SKILL_DIR/scripts/export-figma.mjs <file> <a-b> <name> <outdir>` per
frame (it clicks Properties, then the Export button). Save frames to
`~/Documents/<project>/<TICKET>/<key>-<width>.png`. A PNG saved with Figma's
canvas around it: `magick f.png -shave 2x2 -fuzz 2% -trim +repage frame.png`
(the shave drops a 1px edge line that defeats a plain `-trim`).

Tokens: `GET /v1/files/<file>/nodes?ids=<a:b>` to `nodes.json`, then
`python3 -I $SKILL_DIR/scripts/figma_tokens.py nodes.json` lists every text
style, fill, gap and padding in reading order. If the API is limited, read
them from the PNG: `magick f.png -format '%[pixel:p{x,y}]' info:` for
colours, crops for spacing.

## 2. Capture the app

`node $SKILL_DIR/scripts/capture.mjs config.json <outdir> [keys]` writes
`<key>-<width>-<scheme>.png` and `errors.json` (console errors and uncaught
exceptions per capture, merged across reruns). `WIDTHS=393 SCHEMES=light`
narrow a rerun. A page that never settles prints `NOT SETTLED`; a failed login
throws.

Per frame: `bash $SKILL_DIR/scripts/compare.sh figma.png app.png <outprefix>`
gives `-side.png`, `-diff.png` and the differing-pixel ratio. Read the diff
image, not just the ratio: the ratio flags drift, the image shows where.

## 3. Measure

`node $SKILL_DIR/scripts/probe.mjs config.json <key> <width> '<expr>'` runs
JS on the settled page, in light unless `SCHEME=dark`. Use it for computed styles of the elements the token
list names, `scrollWidth > clientWidth` on the table wrapper at 393, focus
order (`Tab` via `Input.dispatchKeyEvent` if needed), and Escape on open
menus. `node $SKILL_DIR/scripts/sticky.mjs config.json <key> <width>` reports
whether the header row stays pinned.

Walk `reference/checklist.md` items 1 to 15 with these results. Record each
as pass, fail, or "kept on purpose" with the reason.

## 4. Audit the diff

`git diff <base>...HEAD` for checklist items 16 to 25: hex in the diff
(`git diff <base>... -- app | grep -nE '#[0-9a-fA-F]{3,8}\b'`), edits under
`app/helpers/aquifer_ui/`, new aqui_* helpers without demo and library
registration, legacy views touched, flag-gated route specs without the env
flags, `params.permit!`, local-only config files, size against the baseline
(`git diff --numstat <base>...HEAD`, split on `spec/`).
Run Brakeman on the branch and on the base, and report only new warnings. For
the base without touching the worktree: `git archive <base> app config lib
Gemfile Gemfile.lock | tar -x -C <scratchpad>/base-src`, then
`brakeman -q --no-pager -f json -o base.json <scratchpad>/base-src`.

## 5. Report and fix

Write `<outdir>/review.md`: a table per frame (status, aspect, detail, fix),
the behaviour results, the convention findings, and the designer table
(deviations kept, token ripples, open questions). Copy
`assets/compare.html` next to a `config.js` listing `{name, figma, preview,
figmaUrl}` per screen for a swipe view. Final evidence for the user goes to
`~/Downloads/` at scale 1.

Fix medium and higher findings in one round, re-run only the captures and
probes those fixes touch, then stop. Visual tweaks get no spec.

## 6. Walk-through with the user

When the user wants to compare frame by frame, give them two windows side by
side: Figma on the left, the app on the right, both at the same frame width
and a similar zoom. Rules learned the hard way:

- Same breakpoint on both sides. A 640px window showing a 1536 frame compares
  the tablet layout with the desktop design. Run
  `node $SKILL_DIR/scripts/walkthrough.mjs config.json <key> <width>` against
  the visible Chrome (`cfg.port`): it clears cookies, signs in as the config's
  role, opens the page at `<width>` and scales it to fit the window, like
  Figma's zoom. For phone frames use width 393, the window stays as it is.
- Right role, verified. A GET to `/users/sign_out` does not sign out; the
  previous educator session stayed and the "student view" was the educator
  view. `login()` now clears cookies first and `login.assert` (a JS
  expression) must hold on every page, for example "no tab strip and the
  PracticeSmart heading present" for a student.
- Right frame. An anonymous Figma viewer ignores `node-id` and lands on the
  first frame of the page; the user must be signed in to Figma, then Shift+2
  zooms to the selected frame. Shift+\ hides the side panels.
- Remote screen (Tailscale): forward the app ports (`ssh -R 3000:localhost:3000
  -R 3035:localhost:3035`) and the remote Chrome's debug port (`-L
  9223:localhost:9222`); re-add the forwards if the control master drops (the
  app shows "Viewing offline"). `grim` on the remote plus `scp` shows you what
  the user sees.
- Walk the frames in the ticket's order and read the user's list against the
  checklist before changing code: most "differences" are the wrong window, a
  state the frame shows (active filters) or copy kept on purpose.
- Hold the emulation. Device metrics drop the instant the CDP session
  detaches, so run the walkthrough with `HOLD=1` in the background and kill
  it (by pid from `ps`, never `pkill -f walkthrough`, which kills your own
  shell) before the next frame.
- Confirm the Figma tab before measuring. Several frame tabs are open by the
  end; name a detail only the right frame has ("title on two lines, two
  stats fill half the width") and have the user check it. A "fonts are
  bigger" report with the title on one line was the desktop tab.
- Proportion complaints: crop both images to the same width at scale 1 and
  put them side by side (`magick a.png b.png +append`). Then read font sizes
  and widths from the DOM. Zoom differences vanish and real gaps show.
- Rows the frame draws as one line past its edge (legend, data pills) are a
  design clip. One scrolling row (`flex-wrap: nowrap; overflow-x: auto`,
  `flex-shrink: 0` on the items) matches it; wrapping does not.
- Header rows: a shared `min-height` override can keep a header tall after
  the size option changes. Walk the computed-style chain (`minHeight` on each
  ancestor) before touching labels.

## 7. Before the push

- Full suite with the project's parallel runner (`WORKERS=N bundle exec
  prspec spec`; create `TEST_ENV_NUMBER` databases 1..N first, or every
  example on a missing worker fails). Run the failing files again on the base
  branch and diff the two example lists; push only when the lists match.
- PR screenshots: capture every page at each width, light and dark, with
  `capture.mjs`, then one composite per page and scheme with
  `magick montage <1536> <768> <393> -tile 3x1 -geometry +12+0 -gravity North
  -background white` (a dark token colour for dark). Transparent backgrounds
  render black on GitHub.
- Designer questions: one side-by-side image per open question (Figma left,
  app right, scale 1, caption on top) plus a numbered markdown list naming
  the frame, the app URL and width, and the image. Keep them in their own
  folder.
