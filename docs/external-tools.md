# External Tool Integration

The `/today` command pulls data from **Google Calendar**, **Gmail**, and **Jira**.

## Google Workspace (`gws` CLI)

Calendar and Gmail are accessed via the `gws` CLI tool (not MCP). See the
[`/today` skill](.claude/skills/today/SKILL.md) for usage details.

### Install

```bash
npm install -g @googleworkspace/cli
```

### Prerequisites

`gws auth setup` requires the `gcloud` CLI (Google Cloud SDK) to be installed
and authenticated. Install `gcloud` first:
https://cloud.google.com/sdk/docs/install

Then run the one-time setup:

```bash
gcloud auth login
gws auth setup      # Creates Cloud project, enables APIs, logs you in
```

For subsequent logins:

```bash
gws auth login
```

### Verify

```bash
gws calendar events list --params '{"calendarId": "primary", "singleEvents": true, "maxResults": 1}'
gws gmail users messages list --params '{"userId": "me", "maxResults": 1}'
```

## Atlassian Jira (`acli` CLI)

Jira is accessed via Atlassian's official CLI tool (`acli`).

### Install

macOS:

```bash
brew tap atlassian/homebrew-acli
brew install acli
```

Arch Linux:

```bash
yay -S acli-bin
```

### Authenticate

Create an Atlassian API token at
https://id.atlassian.com/manage-profile/security/api-tokens, then:

```bash
echo "YOUR_API_TOKEN" | acli jira auth login --site YOUR_SITE.atlassian.net --email you@example.com --token
```

### Verify

```bash
acli jira auth status
acli jira workitem search --jql "assignee = currentUser() AND resolution = Unresolved" --limit 3
```

### Common commands

```bash
# Search issues
acli jira workitem search --jql "project = PROJ AND assignee = currentUser()" --limit 50 --json

# View single issue
acli jira workitem view ISSUE-KEY --json

# View issue with specific fields
acli jira workitem view ISSUE-KEY --fields key,summary,status,priority,duedate,updated,comment --json

# Transition issue status
acli jira workitem transition --key ISSUE-KEY --status "In Progress" --yes
```

## Verification (smoke test)

1. Verify `gws` CLI is authenticated (see above).
2. Verify `acli` is authenticated: `acli jira auth status`
3. Run `/today` and verify it can pull:
   - Calendar events (via `gws`)
   - Inbox emails (via `gws`)
   - Jira issues (via `acli`)
