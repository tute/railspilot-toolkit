---
name: third-party-integration-test
description: Integration-tests the current branch against a third-party integration's real APIs in development using rails runner. Use when asked to "test against <vendor>", "integration test this branch", "smoke test with real APIs", "test in development", or "run against the sandbox".
---

Integration-test the current branch against a third-party integration's real
APIs in development. Use `mise exec -- rails runner` for all scripts.

## Workflow

1. Read the branch diff (`git diff <base>...HEAD`) to identify new or changed
   service objects that call the third-party API (e.g. `<Vendor>::*`).

2. Explore dev data to find a client account with a working integration config
   (e.g. a `<Vendor>Config` pointing at the vendor's sandbox) and the records
   it needs. Print what you find so the output is self-documenting.

3. For each service, write a rails runner script that:
   - Uses the real account, records, and integration config from step 2
   - Tests happy path, expected error/edge cases, and idempotency (run the
     same call twice, confirm no duplicates or side effects)
   - Prints clear PASS/FAIL per test case with context on what was verified

4. Run each script. If a test fails due to our implementation (not sandbox
   data limitations), stop and diagnose the root cause. Propose a fix before
   continuing with other test cases.

5. If the branch has VCR-based integration tests, re-record their cassettes
   (delete, run with `VCR_RECORD_MODE=once`, replay without the env var to
   confirm). Live-API runner scripts do not substitute for refreshed cassettes.

6. Clean up any records created during testing.

7. Summarize results in a table: test name, what it verifies, result.

## Guidelines

- Real persistence is fine in development. Clean up at the end.
- If the sandbox returns errors unrelated to our code (e.g. no open slots,
  endpoint unavailable), note it as a sandbox limitation.
- Keep scripts self-contained so they can be copy-pasted and re-run.
- Don't add code comments explaining the test; the PASS/FAIL output is enough.

## Recording cassettes

- Record against the real sandbox; never hand-craft fixture bodies.
- Some vendors rotate the non-prod `client_id` on every portal Save (scope
  edits, callback URL changes). After any Save, copy it into the app's
  client-id env var and wait ~1 minute before re-recording.
- Grant the read, search, and create/update scopes the branch needs for each
  resource it touches, in the variant matching the data source.
- `VCR_RECORD_MODE=once mise exec -- rails test <path to integration tests>`,
  inspect the diff, commit, then re-run with `VCR_RECORD_MODE` unset to
  confirm replay.

## OAuth backend services + JWKS

- An ngrok tunnel subdomain rotates each restart; re-save the vendor portal's
  JWKS URL after every restart, and only Save once the URL is reachable
  (vendors validate on save and cache empty keys on failure).
- Patch `APPLICATION_HOST` in `.env` (not just `export`); `bin/dev` runs
  overmind, which clobbers exported env.
- On `400 invalid_client`: verify the JWT (`kid`/`alg`/`iss==sub==client_id`/
  `aud==token_endpoint`/`iat<=now<exp`), `curl` the JWKS URL publicly, and
  check the ngrok inspector to confirm the vendor actually fetched it.
