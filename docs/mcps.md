# MCPs

The `/today` command pulls data from **Google Calendar**, **Gmail**, and **Jira**.

MCPs are configured in `~/.cursor/mcp.json`, which we link to `./.mcp.json` for Claude (it may contain access tokens):

```bash
ln -s ~/.cursor/mcp.json .mcp.json
```

## Google Workspace MCP (Gmail + Calendar)

- **Server**: `workspace-mcp` (Google Workspace MCP)
- Requires [`uv`/`uvx`](https://github.com/astral-sh/uv)
- Docs: https://github.com/taylorwilsdon/google_workspace_mcp

Configure OAuth credentials:
1. Create a Google Cloud OAuth client (Desktop is simplest for local use).
2. Set credentials in `~/.mcp-servers/google_workspace_mcp/.env` (`GOOGLE_OAUTH_CLIENT_ID`,
  `GOOGLE_OAUTH_CLIENT_SECRET`)

In `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "google_workspace": {
      "command": "uvx",
      "args": ["workspace-mcp", "--tools", "gmail", "calendar"]
    }
  }
}
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

## Verification (smoke test)

1. Restart Cursor after updating `~/.cursor/mcp.json`.
2. Confirm the MCP servers are available in Cursor/Claude.
3. Run `/today` and verify it can pull:
   - Calendar events
   - Inbox emails
   - Jira issues (assigned to you)
