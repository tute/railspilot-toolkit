- Ask more questions until you have enough context to give an accurate &
  confident answer.
- Use `mise exec --` prefix for any project binaries (rspec, rubocop, brakeman,
  rails, etc.)
- Use task agents for preliminary explorations when appropriate.
- When spawning subagents, always include the current date (YYYY-MM-DD) and day
  of week in the prompt. Subagents don't inherit system context — they can't
  infer "today". When passing dates, pre-compute relative labels ("3 days ago",
  "yesterday") — LLMs struggle with date math on raw timestamps.
- Enter plan mode for any non-trivial task (3+ steps or architectural decisions)
- For every change, use the TDD skill, as can be found in `.claude/skills/tdd-skill`
- When I report a bug, don't start by trying to fix it. Instead, start by
  finding the root cause, and then write a test that reproduces the bug. Then,
  have subagents try to fix the bug and prove it with a passing test.
- Don't add code comments unless requested. Keep changes minimal and avoid
  unnecessary specificity (like hardcoded error numbers) unless requested.
- Prefer namespaced service objects with short class and method names. Avoid the
  `Service` suffix. Example: `Namespace::ClassName#call`
- Self-improvement loop: After ANY correction, update `tasks/lessons.md` with the
  pattern (create the file if it doesn't exist). Review lessons at session start.
  Run `/rails-learn` at the end of productive sessions to extract patterns into
  patterns.md, CLAUDE.md, or skills. Run `/weekly-review` weekly to summarize
  changes and grow the pattern library from accumulated lessons.
- Google Workspace: Always use the `gws` CLI for calendar, drive, gmail, etc.
  Never use built-in Claude Code MCP integrations for Google services.

Architecture & Design

* Normalized database design: No redundant data. Calculate derived values dynamically.
* When creating PostgreSQL columns or tables: prefer Rails PostgreSQL enum in favor of
  string column
* Simplest stack possible: Don't add gems/dependencies until proven necessary
* Rails conventions: Follow Rails Way unless there's specific reason not to
* No premature optimization: Start simple, optimize when bottlenecks proven

Code Quality

* Assertive style: Use `find`, `find_by!`, `sole` — let exceptions surface problems.
  Don't guard with `find_by` + `return unless` unless the caller explicitly needs nil handling.
* Prefer POROs over mixins: Extract plain objects we can test and compose
  independently. If a mixin seems clearly better, ask before proceeding.
* Explicit over implicit: Prefer clarity over cleverness
* Single Responsibility: Each class/method does one thing well
* Domain-driven naming: Use business language (Measurements not ProgressEntries)

UI/UX

* Progressive enhancement: Works without JavaScript, may be augmented by it
* Prefer Stimulus.js conventions for direct JavaScript manipulation when available
* Accessibility: Semantic HTML, proper labels, keyboard navigation-enabled

Project Management

* Organize by epics, not time: Features over sprints
* Tasks are atomic: Each task is testable and deployable
* Dependencies explicit: Note which tasks block others
* Acceptance criteria clear: Each task has a definition of "done"

Communication Preferences

* No filler phrases: Get to the point
* Challenge assumptions: Point out flaws in logic
* Explain trade-offs: Discuss pros/cons of decisions
* Ask clarifying questions: Don't guess requirements

Quality Gates

* All tests pass: Green suite required for merge
* No skipped tests: Fix or delete, never remove or skip
* Code reviewed: (Even if by AI) - check for issues
* When available: Run `bin/ci` as a final "is this healthy?" check

Tests/Rspec:

- Don't use `let` or `before` blocks, use the setup/execute/expect phases, even
  if it results in repeated code. You may extract common setup into methods.
- Don't stub the system under test
- Try not to use doubles, stubs or mocks. If it gets too verbose or dependencies
  get complicated, suggest to refactor the class to be tested.
- Add contexts for the different variations/sections
- When creating models in tests: Prefer `build*` when actual persistence to the
  database is irrelevant for the current spec (for example, background jobs, or
  some service objects)