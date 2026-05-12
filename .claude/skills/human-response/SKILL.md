---
name: human-response
description: Write a warm, human-to-human written response (handoffs, status updates, testing notes for QA, sign-off requests, confirming assumptions before merging, or escalating an open question). Use when the user asks to draft a response, reply to a thread, write a handoff, send testing notes, ask the team to confirm something, phrase a Slack or PR comment, or convert dev-flavored notes into a message a teammate would actually enjoy reading.
---

# Human response

Write to a colleague, not a ticket. Greet by name or @mention, frame in one line, end with thanks.

## Pick the shape

- Sign-off / scope confirmation: open with "I'm assuming (please confirm):" + tight bullets, one specific claim each. Then questions prefixed `Question:` / `Another one:`. Parenthetical asides welcome when they carry signal (`(There be dragons!)`).
- Testing notes / step-by-step handoff: group setup by role ("As admin, ..." then "As <user>, ..."). One concrete action per line, in order. Close with the expected outcome in plain prose.
- Per-item status reply: mirror their numbering. Per item, lead with resolution ("fixed.", "fixed, <one-line how>") or short rationale for judgment calls. Flag gaps ("(#4 absent in your comment)"). Surface side-discoveries inline. For design calls, name alternatives weighed and invite pushback. Close with what's next.

## Hard rules

- No bold. No em-dashes (use commas, periods, colons, parentheses).
- No deflection ("ask dev", "the team will provide"). Look up the real value and inline it. If unknowable, "I will send you X separately" and follow through.
- Quote UI labels exactly ("Offline", "No throttling"). The reader will look for that exact string.
- Use `<angle-bracket>` placeholders for values only the recipient knows (`<user email>`, `/path/<id>`). Never invent realistic-looking examples.
- Hedge optional verification: "You could check X if you think that's necessary, but that's more an implementation detail I think." Never prescribe optional steps.
- Address by name, not by role ("QA", "the reviewer"). Skip "you must", "obviously", "simply", "just".

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
> 1. <Item 1>, fixed.
>    - While in there I noticed <side-discovery>. Standardized to <chosen value>.
> 2. <Item 2>, fixed UX. <One-line constraint that shaped the fix>.
> 3. (#3 absent in your comment)
> 4. <Item 4>. <How it works now>. I think it's better than '<alt A>' and '<alt B>'. Do you see we may need to change anything here?
>
> Just pushed. Let me know how each goes. Thanks!
