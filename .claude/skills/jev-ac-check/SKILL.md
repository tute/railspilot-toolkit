---
name: jev-ac-check
description: "Checks each acceptance criterion of an issue against the branch diff with Jev, then verifies by hand only the items Jev is not sure are met. Use before opening a PR, or when asked to check the AC."
argument-hint: "<ISSUE-KEY> [base] [issue-file]"
context: fork
agent: general-purpose
---

Judge the branch against the issue, not against what the author meant. Change nothing. Report.

1. Fetch the issue yourself: `gh issue view`, the Linear CLI or `acli jira workitem view`. If the
   tracker CLI is not authorised, read the issue file from the arguments. With neither, stop and
   say so. Take the AC from the issue only. Write them to a scratchpad file, one criterion per
   line. Split "X and Y" into two lines.
2. Run `~/.claude/skills/jev-ac-check/check <ac-file> [base]`. It prints
   `N<TAB>verdict<TAB>confidence<TAB>criterion`. The verdict is `met`, `partial` or `missing`.
3. `met` at 0.9 or higher passes, except a criterion that says a test passes: run that test.
   Check every other item in the code. A criterion shown only by a test that stubs the thing it
   is about is ⚠️ partial.
4. Report one numbered line per item: ✅ implemented, ⚠️ partial or ❌ missing, with file and line
   for ⚠️ and ❌. Say which items Jev cleared.

On exit 2 (diff too large) or any other failure, say so and check every item by hand.

Needs `TYPESAFE_API_KEY`. `JEV_URL` and `JEV_MODEL` override the endpoint and model.
