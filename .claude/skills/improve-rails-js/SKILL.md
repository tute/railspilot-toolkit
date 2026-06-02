---
name: improve-rails-js
description: Subtractively improve Rails JavaScript — cut conditionals/guards, prefer platform APIs and Hotwired (Turbo/Stimulus), tighten names. Use when asked to improve, simplify, or clean up Rails JS/Stimulus controllers.
---

Improve by deleting. A change adding lines needs justification; one removing them rarely does. Follow the JS/Stimulus patterns in the railspilot-staff-review skill (`references/patterns.md`).

- Grep the codebase first. Before writing new logic, search for existing controllers or modules that already handle the same scenario (e.g. offline detection, retry, fallback). Even 80% overlap is enough — adapt and extract rather than duplicate.
- Assume the platform or framework already has it. Before hand-rolling a method, check [MDN](https://developer.mozilla.org/en-US/docs/Web/API) or the Stimulus/Turbo docs; if it likely exists but you're unsure of the name or signature, search online to confirm rather than reimplement. Replace custom registries, owner-keys, and constants with the native call.
- Prefer Hotwired ([Stimulus](https://stimulus.hotwired.dev/handbook/introduction), [Turbo](https://turbo.hotwired.dev/handbook/introduction)): declarative `data-action` over imperative `addEventListener`; let Stimulus manage listener lifecycle — delete `connect()`/`disconnect()` wiring and `.bind()`s. Reach for the built-in shorthands before hand-rolling: event filters (`keydown.esc@window->c#m` replaces an `event.key` check and its handler method), `@window`/`@document` modifiers, `this.dispatch(name, { prefix: false })` to emit, and targets/values/outlets.
- Custom event names are tokens, never colons: `ai-offline`, not `connectivity:offline`.
- Delete comments the code already states; keep only the why. A `// walk back across the run` above the loop that walks back across the run is noise — cut it.
- Delete redundant guards. If `connect()` already gated setup, the inner `if` is dead — drop it so the method reads as a straight pipeline. Fewer variables, fewer conditionals, lower cyclomatic complexity.
- Remove non-essential `try`/`catch`. Let errors surface unless the catch does real recovery.
- No `if (flag)` around cleanup. If you clean, clean everything, unconditionally.
- Rename for the domain; let the diff show the rest.
- Over 500 lines signals excess complexity. The fix is deletion, not splitting.

## Idioms to reach for before plain/verbose JS

Stimulus:
- Outlets (`static outlets`, `this.xOutlet`, `xOutletConnected(outlet, el)`) instead of `application.getControllerForElementAndIdentifier` + `querySelector` to reach another controller.
- `nameValueChanged(value, prev)` (fires on connect and every change) instead of manually calling an update after each setter.
- `nameTargetConnected(el)` / `nameTargetDisconnected(el)` instead of a hand-rolled `MutationObserver` watching for added/removed nodes.
- `static classes` + `this.xClass` instead of hardcoded class strings like `"show"`/`"hidden"` scattered through the controller.
- Action options instead of handler-body plumbing: `:prevent`, `:stop`, `:once`, `:self`. Omit the event for the element's default (`button#m` = click, `form#m` = submit, `input#m` = input).

Turbo:
- `<turbo-frame src loading="lazy">` for scoped/lazy section loads instead of `fetch().then(r => r.text())` + `innerHTML`.
- `<turbo-stream action="append|replace|update|remove|before|after" target>` (server-rendered) instead of patching the DOM in JS.
- `data-turbo-method="delete"` / `data-turbo-confirm="…"` instead of a click handler doing `preventDefault` + `fetch` + `window.confirm`.
- `data-turbo-permanent` (with a stable `id`) instead of re-initializing element state after each navigation.
