# Progress report email template

Canonical sample output. Match this structure and tone when drafting the client email.

```
Hi [Client]! Here's [Month]'s progress:

1. [Topic tag]: brief plain-language summary. #<pr>
2. [Topic tag]: brief plain-language summary. #<pr>
3. [Topic tag]: brief plain-language summary. (#<pr>, #<pr>)
4. In QA: [Topic tag]: brief summary. #<pr>
5. <feature description> (#<pr>, #<pr>)
   - <sub-item from related PR>
   - <sub-item from related PR>
6. Dev improvements:
   - <item> (#<pr> or <sha>)
   - <item> (#<pr>)

<one-line forward-looking note>

Thank you!

[Name].
```

## Format notes

- Each item is one short line: `[Topic tag]: brief summary.`
- The topic tag names the feature area in 2-4 words. The summary is one clause, not a chain of semicolons.
- Keep technical detail minimal. Name what was built, not how every piece works internally.
- Prefix with "In QA:" or "In progress:" for unshipped work.
- Numbered list, warm and specific. Professional but colleague-to-colleague.
- One issue URL per headline feature when resolvable from the PR body. Do not guess issue numbers.
- Consolidated smaller items share one numbered slot as a comma-separated list.
- Dev improvements are the last numbered item, not mixed into feature slots.
- Optional closing sentence with an honest feature count (no invoicing block, no 12-feature baseline framing).
