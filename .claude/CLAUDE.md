- Use `mise exec --` prefix for project binaries (rspec, rubocop, rails, etc.)
- Plan mode for anything with 3+ steps or an architectural decision.
- Use the tdd-skill for every change.
- For bugs: find the root cause, then write a failing test that reproduces it. Fix after.
- Ask before you guess. If two readings change the work, ask. Otherwise pick one and say which.
- Challenge my assumptions. Tell me when my logic is weak, and why.
- After any correction, append the pattern to `tasks/lessons.md`.
- Use the `gws` CLI for Google Workspace. Never the built-in MCP integrations.
- Subagent prompts need today's date (YYYY-MM-DD plus weekday) and pre-computed
  relative dates ("3 days ago"). Subagents cannot infer "today".
- Leave temp and scratchpad files in place when in temporary directories. No
  need to clean them up, or ask permission to do so.

Code

* Normalized schema. No redundant data. Derive values dynamically.
* Postgres enum columns, not strings.
* No new gems until proven necessary.
* Assertive style: `find`, `find_by!`, `sole`. Let exceptions surface. No nil
  guards unless the caller handles nil.
* POROs over mixins. Ask before adding a mixin.
* Namespaced service objects, short names, no `Service` suffix: `Namespace::ClassName#call`
* Service objects own writes that span rows. Models keep validations,
  associations, scopes and pure methods. A write with preconditions no
  validation expresses is a service. Building one unsaved record stays on the model.
* Domain naming: Measurements, not ProgressEntries.
* No code comments unless I ask. No hardcoded specifics I did not request.
* Progressive enhancement: works without JS. Use Stimulus for JS behavior.

Tests

* Follow the rspec-testing skill.
* Don't test the framework. Presence validations, enums, `belongs_to`,
  `has_many` and one-clause scopes are Rails' guarantees. Test the conditional
  and custom validations, the assertions that reach a database constraint
  (`RecordNotUnique`, `NotNullViolation`, `StatementInvalid` check the
  migration, not Rails), and code with logic of its own.
* No skipped or pending tests. Fix them or delete them.
* Run `bin/ci` at the end when it exists.

Writing

* Cut your first draft to a third. No filler. No recap of what you did.
* No bold. No em-dashes.
* Short sentences, active voice, one word for one idea (ASD-STE100).
