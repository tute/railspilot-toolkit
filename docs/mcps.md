# MCPs

The `/today` command pulls data from **Google Calendar**, **Gmail**, and **Jira**.

## Google Workspace (`gws` CLI)

Calendar and Gmail are accessed via the `gws` CLI tool (not MCP). See the
[`/today` skill](.claude/skills/today/SKILL.md) for usage details.

Install and authenticate `gws` following its own setup instructions
(https://github.com/googleworkspace/cli). Once authenticated, verify with:

```bash
gws calendar events list --params '{"calendarId": "primary", "singleEvents": true, "maxResults": 1}'
gws gmail users messages list --params '{"userId": "me", "maxResults": 1}'
```

## Atlassian Jira MCP

- **Server**: `@aashari/mcp-server-atlassian-jira`
- Requires Node.js for `npx`
- Docs: `https://www.npmjs.com/package/@aashari/mcp-server-atlassian-jira`

Create an Atlassian API token:
1. In Atlassian account settings → **Security** → **API tokens**, create a token.
2. Add to `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "atlassian_jira": {
      "command": "npx",
      "args": ["-y", "@aashari/mcp-server-atlassian-jira"],
      "env": {
        "ATLASSIAN_SITE_NAME": "YOUR_SITE_NAME (not URL)",
        "ATLASSIAN_USER_EMAIL": "you@example.com",
        "ATLASSIAN_API_TOKEN": "YOUR_API_TOKEN"
      }
    }
  }
}
```

MCPs are configured in `~/.cursor/mcp.json`, which we link to `./.mcp.json`
for Claude (it may contain access tokens):

```bash
ln -s ~/.cursor/mcp.json .mcp.json
```

## Verification (smoke test)

1. Verify `gws` CLI is authenticated (see above).
2. Restart Cursor after updating `~/.cursor/mcp.json`.
3. Confirm the Jira MCP server is available in Cursor/Claude.
4. Run `/today` and verify it can pull:
   - Calendar events (via `gws`)
   - Inbox emails (via `gws`)
   - Jira issues (via MCP, assigned to you)
