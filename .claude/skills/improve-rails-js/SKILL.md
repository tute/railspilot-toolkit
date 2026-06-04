---
name: improve-rails-js
description: Subtractively improve Rails JavaScript — cut conditionals/guards, prefer platform APIs and Hotwired (Turbo/Stimulus), tighten names. Use when asked to improve, simplify, or clean up Rails JS/Stimulus controllers.
---

Improve by deleting. New lines of code need justification: do we need to solve for this? Can it be solved with less code than we are trying to add?
Follow the JS/Stimulus patterns in the railspilot-staff-review skill (`references/patterns.md`).

- Assume the platform or framework already has it. Before hand-rolling a method, check [MDN](https://developer.mozilla.org/en-US/docs/Web/API) or the Stimulus/Turbo docs. Confirm the name or signature with documentation.
- Prefer Hotwired ([Stimulus](https://stimulus.hotwired.dev/handbook/introduction), [Turbo](https://turbo.hotwired.dev/handbook/introduction)): declarative `data-action` over imperative `addEventListener`; let Stimulus manage listener lifecycle — delete `connect()`/`disconnect()` wiring and `.bind()`s. For the controller API itself (action filters, `@window`/`@document`, `this.dispatch`, targets/values/outlets), use the `hwc-stimulus-fundamentals` skill.
- Custom event names are tokens, never colons: `ai-offline`, not `connectivity:offline`.
- Delete comments the code already states; keep only the why. A `// walk back across the run` above the loop that walks back across the run is noise — cut it.
- Delete redundant guards. If `connect()` already gated setup, the inner `if` is dead — drop it so the method reads as a straight pipeline. Fewer variables, fewer conditionals, lower cyclomatic complexity.
- Delete defensive state, not just defensive branches. If an invariant is already enforced at the lifecycle boundaries (data wiped on both sign-in and sign-out), drop the ownership/claim/owner-key bookkeeping that re-checks it mid-flight. The cheapest version of "is this queue stale?" is making a stale queue impossible.
- Remove non-essential `try`/`catch`. Let errors surface unless the catch does real recovery.
- No `if (flag)` around cleanup. If you clean, clean everything, unconditionally.
- Rename for the domain; let the diff show the rest.
- Over 500 lines signals excess complexity. The fix is deletion, not splitting.

## Idioms to reach for before plain/verbose JS

For Stimulus controller fundamentals (outlets, `valueChanged` callbacks, target connect/disconnect callbacks, `static classes`, action filters/options, lifecycle-owned setup vs. global `boot()`), use the `hwc-stimulus-fundamentals` skill.

Turbo:
- `<turbo-frame src loading="lazy">` for scoped/lazy section loads instead of `fetch().then(r => r.text())` + `innerHTML`.
- `<turbo-stream action="append|replace|update|remove|before|after" target>` (server-rendered) instead of patching the DOM in JS.
- `data-turbo-method="delete"` / `data-turbo-confirm="…"` instead of a click handler doing `preventDefault` + `fetch` + `window.confirm`.
- `data-turbo-permanent` (with a stable `id`) instead of re-initializing element state after each navigation.
