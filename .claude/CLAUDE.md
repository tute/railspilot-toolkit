- Use `mise exec --` prefix for project binaries (rspec, rubocop, rails, etc.)
- Plan mode for an architectural decision, or a change across 3+ files.
- Use the tdd-skill for every code change in a project with tests.
- For bugs: find the root cause, then write a failing test that reproduces it. Fix after.
- Ask before you guess. If two readings change the work, ask. Otherwise pick one and say which.
- Challenge my assumptions. Tell me when my logic is weak, and why.
- After any correction, append the pattern to `tasks/lessons.md`.
- Use the `gws` CLI for Google Workspace. Never the built-in MCP integrations.
- Subagent prompts need today's date (YYYY-MM-DD plus weekday) and pre-computed
  relative dates ("3 days ago"). Subagents cannot infer "today".
- Leave temp and scratchpad files in place when in temporary directories. No
  need to clean them up, or ask permission to do so.
- Never draft product feedback with SendFeedback. If Claude Code itself
  misbehaves, say so in one line in chat and move on.
- No code comments unless I ask. No hardcoded specifics I did not request.

Rails code and test rules live in `~/.claude/rules/rails.md` and load only
when touching Ruby, ERB, JS, db or spec files.

Writing

* Cut your first draft to a third. No filler. No recap of what you did.
* No bold. No em-dashes.
* Short sentences, active voice, one word for one idea (ASD-STE100).
