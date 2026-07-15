---
name: code-review
description: Reviews the current branch diff for bugs, edge cases, performance regressions, and behavior interactions. Use when asked for a code review, "review my changes", "check this code", or "anything wrong with this". This is a quick, focused review — for comprehensive multi-agent reviews, use full-code-review instead.
---

Perform a focused code review of the current branch changes compared to main.
Prioritize correctness, edge cases, performance, and how changes interact with
existing behavior.

## Workflow

1. Run `git diff main...HEAD` to get the full diff.
2. Read any changed files in full (not just the diff) to understand context.
3. Review against the checklist below.
4. Verify every candidate finding before reporting it:
   - Re-open the cited lines and surrounding code (do not work from memory of the diff)
   - Confirm the issue is introduced or materially exposed by the diff, not pre-existing
   - Search for callers, tests, config, or documentation that could invalidate the claim
   - Calibrate severity to actual impact and likelihood
   - Discard speculative, non-actionable, or unverifiable items
5. Present findings in the output format specified.

## Review checklist

1. **Bugs & logic errors**: Incorrect assumptions, missing validations, bad
   conditionals, breaks to existing behavior.
2. **Edge cases**: Nils, empty collections, unusual user data, race conditions,
   multi-step workflows, authorization gaps.
3. **Performance**: N+1 queries, unbounded loops, heavy object allocations,
   repeated database hits, anything that scales poorly.
4. **Tests**: Missing coverage for new code paths, failure states, boundary
   conditions. Highlight brittle or misleading tests. Every public method needs
   unit tests. Every controller action needs request specs.
5. **Rails context**: Routing, strong params, callbacks, scopes, i18n keys,
   partial rendering, pack boundaries.

## Output format

### Findings

List each issue in severity order (Critical, Major, Minor). Each finding includes:
- File path and line reference
- What is wrong or risky
- Why it matters (impact or failing scenario)
- Recommended fix or tests to add

If no problems found, state that explicitly and mention residual risks.

### Questions

Assumptions or missing context that need clarification.

### Summary

Overall risk level and suggested next steps.

## Rules

- Only discuss what you observe in the diff — don't speculate beyond the changes
- Do not report a finding merely because it sounds plausible. You are accountable for every finding in the report.
- Use `mise exec --` for any project commands (rspec, rubocop, etc.)
- Read changed files in full to understand surrounding context before flagging issues
