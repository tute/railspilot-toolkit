---
name: visual-review
description: Runs the app locally, walks through the current change in the browser, and creates an HTML artifact that tells the story step by step with screenshots, for a client to inspect without running the code. Use when asked for a visual review, a "story with screenshots", a client walkthrough, a demo page of the change, or "launch a local server and show me".
---

Show the client the current change, so they can inspect it without running
the app.

1. Read the diff against the base branch and the ticket. List the user flow
   as steps.
2. If the change involves a third party service and you can't access it, ask the
   user for those screenshots. Continue with the other steps.
3. Start the app. Seed the data the flow needs.
4. Walk the flow with `claude-in-chrome`. Take one screenshot per step.
5. Load `artifact-design`, write the page. Send the screenshots in the `files`
   map.

The page has a brief description of the changes, then numbered steps. Each
step has a heading, one or two sentences, and its screenshot. Write for a
non-technical reader. If a step fails, tell the user before continuing.
