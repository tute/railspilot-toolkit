---
name: human-response
description: Write a warm, human-to-human written response (handoffs, status updates, testing notes for QA, sign-off requests, confirming assumptions before merging, or escalating an open question). Use when the user asks to draft a response, reply to a thread, write a handoff, send testing notes, ask the team to confirm something, phrase a Slack or PR comment, or convert dev-flavored notes into a message a teammate would actually enjoy reading.
---

# Human response

Write to a colleague, not a ticket. Greet by name or @mention, frame in one line, end with thanks.

## Pick the shape

- Sign-off / scope confirmation: open with "I'm assuming (please confirm):" + tight bullets, one specific claim each. Then questions prefixed `Question:` / `Another one:`. Parenthetical asides welcome when they carry signal (`(There be dragons!)`).
- Testing notes / step-by-step handoff: group setup by role ("As admin, ..." then "As <user>, ..."). One concrete action per line, in order. Close with the expected outcome in plain prose.
- Per-item status reply: mirror their numbering. Per item, lead with a scannable state tag (`Fixed:`, `Needs input:`, `Couldn't reproduce:`) then a one-line reason or how. Tag is additive, not a substitute for the reason. Items you will not change get no tag, see "Pushing back". Flag gaps ("(#4 absent in your comment)"). Surface side-discoveries inline. For design calls, name alternatives weighed and invite pushback. Close with what's next.

## Pushing back

A report that says "this could be better" is good work, even when you will not change anything. Answering "not a bug" reads as a defensive engineer who uses process to avoid improving the product. The facts stay, the verdict goes.

- Never write "Not a bug", "Nothing to fix", "Won't fix", "Expected behaviour" or "Working as designed". State what the product does and why, and stop.
- Say "not yet available" in place of "has never been available". Same fact, and it leaves the door open.
- Does the item ask for a behaviour change? Call it a good idea or a Product question, and name who owns that call ("worth raising with <product owner>").
- Out of the ticket's acceptance criteria? Open with that: these are new AC, they belong in new tasks, and they should not block this one. Give the real cost once: each day a branch stays unmerged brings merge conflicts, and the same AC get reworked and retested.
- Already answered on another ticket? Point to it neutrally ("same as item 5 on <TICKET>"). No "as I said".
- Does a pattern cost the team time (repeats, scope creep)? One constructive nudge is fine, phrased as a proposal with a question mark: "We should probably keep a list of what works offline, so these don't keep coming up in unrelated tasks?"
- Hedge what you do not control ("I'm not sure we can control that"). No flat "not something we control".
- A real bug that predates the task? Say it is a bug, say it happens the same way on `master` and this task did not change it, and ask them to open a separate task so it does not block the work done here. Never offer to open the task: QA or Product creates it.
- One item? Skip the merge-conflict cost. Keep it for a reply that pushes back on several.
- A fixup of the same code and task (an alignment, a missing banner) is not scope creep. Do it and say so ("Got it, <thing> wasn't there yet, thanks for catching that. I included it now").
- Unsure the current look is the expected one? "Please double check with @<owner> if we need certainty on this", not an invitation to redesign.

## Hard rules

- Thank for the artifact, once ("Thanks for the detailed video", "Thanks for the full retest"). No grades: drop "good work" and "good catch". "Thanks for catching that" is for an in-scope item you fixed.
- American spelling ("colors", "behavior"). "Anyway", not "Anyways". Write "this task" for the ticket the comment is on, not its key.
- Say "is on pod-3" only once it is merged and deployed. Before that: "will shortly be on pod-3", with the new behavior in future tense. After a push: "just pushed the fix to pod-3, please retest in ~3 minutes!"
- Cut the second sentence of any compliment and any cost or context the reader does not need to act.

- No bold. No em-dashes (use commas, periods, colons, parentheses).
- No deflection ("ask dev", "the team will provide"). Look up the real value and inline it. If unknowable, "I will send you X separately" and follow through.
- Quote UI labels exactly ("Offline", "No throttling"). The reader will look for that exact string.
- Use `<angle-bracket>` placeholders for values only the recipient knows (`<user email>`, `/path/<id>`). Never invent realistic-looking examples.
- Hedge optional verification: "You could check X if you think that's necessary, but that's more an implementation detail I think." Never prescribe optional steps.
- Address by name, not by role ("QA", "the reviewer"). Skip "you must", "obviously", "simply", "just".
- Deploy status attaches to the verdict, not the trailing sentence, or it drifts onto unrelated follow-ups.
- `Couldn't reproduce:` owes the reader a verification step. Name the toggle to flip or the cache to clear and ask them to retry.
- Continuing a thread? Reference prior context ("the ticket we discussed") instead of re-proposing from scratch.

## Worked examples

Sign-off:

> Hi @<name>. I'm assuming (please confirm):
> - New per-user feature flag `<flag>`, default off. <Behavior> activates only when `<group_flag>` and `<flag>` are both on.
> - Same `<endpoint>` endpoint. `<unrelated_component>` untouched.
>
> Question: Pilot first or staged per `<group_flag>`-enabled group?
> Another one: <edge case> is <chosen behavior>, no <missing UI>. Acceptable? (There be dragons!)
>
> Thank you!

Per-item status reply:

> Hi @<name>! Status on each item:
> 1. Fixed: <Item 1>.
>    - While in there I noticed <side-discovery>. Standardized to <chosen value>.
> 2. Fixed: <Item 2>. <One-line constraint that shaped the fix>.
> 3. (#3 absent in your comment)
> 4. <Item 4>. <How it works now>. I think it's better than '<alt A>' and '<alt B>'. Do you see we may need to change anything here?
>
> Just pushed. Let me know how each goes. Thanks!

Pushing back on out-of-scope items:

> Hi @<name>! I think these are new AC, we should work on them in new tasks, without blocking the work done for this one. Each day a branch stays unmerged brings more merge conflicts, and we end up testing the same AC again.
>
> 1. <What the product does, and that it does the same in <other context>>. I'm not sure we can control that (or we could discuss <alternative>, but that's a Product question).
> 2. Same as item <n> on <TICKET>: <fact>. <What they can still do>.
> 3. Couldn't reproduce: <what I see>. Could you retest after clearing the cache or in a private session?
> 4. <Feature> is not yet available <in that mode>. Also, it's not related to this ticket.
>
> Thanks!

A real bug that predates the task:

> Hi @<name>! Thanks for the full retest.
> <The symptom> is a bug: <why it is wrong, in one line>. It comes from before this task though (it happens the same way on master), so I think it's a new AC and shouldn't block the work done here.
> The fix is ready on a separate branch and will shortly be on pod-3: <what will happen then>. Could you open a new task for it, so we can track and test it there?
> Thank you!
