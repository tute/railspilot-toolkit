---
name: today
description: Generates a prioritized daily task summary from Calendar, Gmail, and Jira, saved to daily_notes/. Use when asked for today's tasks, daily summary, or standup prep.
disable-model-invocation: true
---

# Today Command

Generate a daily task summary from Google Calendar, Gmail, and Jira, intelligently prioritized.

## What This Command Does

1. Spawns 3 parallel subagents to fetch and normalize data from each source using the `gws` and `jira` CLI tools
2. Each subagent processes data in its own context window, returning compact summaries
3. Main agent merges summaries and generates plain text output
4. Saves to: `daily_notes/YYYY-MM-DD.txt` (relative to project root)

## Configuration

Resolve these values before running:

- **USER_EMAIL**: Run `git config user.email` to get the current user's email
- **JIRA_SITE**: Resolve from MCP server configuration or `$ATLASSIAN_SITE_NAME`
- **JIRA_PROJECT**: Resolve from the Jira project key in recent commits, or ask the user

## Requirements

- `gws` CLI installed and authenticated (Google Workspace CLI for Calendar and Gmail)
- Atlassian Jira MCP server configured (for Jira)

## CLI Reference: `gws` (Google Workspace CLI)

### Calendar: List events for a date range

```bash
gws calendar events list --params '{
  "calendarId": "primary",
  "timeMin": "YYYY-MM-DDT00:00:00-03:00",
  "timeMax": "YYYY-MM-DDT23:59:59-03:00",
  "singleEvents": true,
  "orderBy": "startTime"
}'
```

Returns JSON with `items` array. Each item has: `summary`, `start.dateTime`, `end.dateTime`, `location`, `htmlLink`, `attendees`, `description`.

### Gmail: List inbox messages

```bash
gws gmail users messages list --params '{
  "userId": "me",
  "maxResults": 20,
  "q": "in:inbox"
}'
```

IMPORTANT: Do NOT use date filters like `newer_than:` — the user keeps emails in inbox as a pending queue, so older emails are intentional.

Returns JSON with `messages` array of `{id, threadId}`.

### Gmail: Get message metadata

```bash
gws gmail users messages get --params '{
  "userId": "me",
  "id": "MESSAGE_ID",
  "format": "metadata",
  "metadataHeaders": ["From", "Subject", "Date"]
}'
```

Returns JSON with `snippet`, `labelIds`, `internalDate`, and `payload` (headers).

Batch multiple messages by looping IDs in a single shell command for efficiency.

## Normalized Task Schema

All subagents return JSON arrays conforming to this schema:

```json
{
  "title": "string - task title",
  "source": "calendar | gmail | jira",
  "source_type": "event | email | issue",
  "priority": "high | medium | low",
  "due_date": "ISO 8601 datetime or null",
  "url": "string - direct link to item",
  "action": "string - specific actionable next step",
  "low_priority_reason": "string - only present if priority is low",
  "metadata": {
    "start_time": "for calendar events",
    "end_time": "for calendar events",
    "location": "for calendar events",
    "from": "for emails",
    "snippet": "for emails - 1 sentence summary",
    "key": "for Jira issues",
    "status": "for Jira issues",
    "has_qa_comments": "boolean for Jira issues"
  }
}
```

## Instructions

Follow these steps to generate today's task summary:

### 1. Calculate Today's Date and Time Boundaries

Determine the current date and create RFC3339 formatted timestamps for today's start and end:

- Get today's date in YYYY-MM-DD format
- Determine the day of week (important for POD-3 standup logic)
- Create today_start: `YYYY-MM-DDT00:00:00` with local timezone (e.g., `-03:00`)
- Create today_end: `YYYY-MM-DDT23:59:59` with local timezone
- Note the current time for time-sensitive priority calculations

### 2. Spawn Three Subagents in Parallel

Make THREE Agent tool calls in parallel in a single message. Each agent has its own context window, processes the raw CLI/API data, and returns only the compact normalized JSON.

**IMPORTANT**: Pass the calculated date boundaries and current time to each agent in its prompt.

---

#### Agent 1: Calendar (via `gws` CLI)

```
Agent(
  description: "Fetch and normalize today's calendar events",
  prompt: "Fetch and normalize today's calendar events. Return JSON array only.

TODAY'S INFO:
- Date: {YYYY-MM-DD}
- Day of week: {day_name}
- Current time: {HH:MM}
- Timezone: {timezone}

STEP 1: Run this Bash command:
gws calendar events list --params '{\"calendarId\": \"primary\", \"timeMin\": \"{today_start}\", \"timeMax\": \"{today_end}\", \"singleEvents\": true, \"orderBy\": \"startTime\"}'

STEP 2: For each event in the items array, apply priority logic:

1. POD-3 Standups:
   - If title contains 'POD-3' AND today is NOT Friday -> priority = 'low', low_priority_reason = 'POD-3 standup (not Friday)'
   - If title contains 'POD-3' AND today IS Friday -> apply normal rules below

2. Family Reminders:
   - If title contains 'Family' (case-insensitive) -> priority = 'low', low_priority_reason = 'Family reminder'

3. Time-Sensitive:
   - If event starts within 8 hours AND not low priority -> priority = 'high'
   - Action should include 'Leave by X:XX' if location requires travel

4. Default: priority = 'medium'

STEP 3: Return ONLY a JSON array with the normalized task schema.
If no events found, return empty array: []
If CLI fails, return: {\"error\": \"Could not fetch calendar events\"}
"
)
```

---

#### Agent 2: Gmail (via `gws` CLI)

```
Agent(
  description: "Fetch and normalize inbox emails",
  prompt: "Fetch and normalize inbox emails. Return JSON array only.

STEP 1: List inbox messages (no date filter — inbox is used as a pending queue):
gws gmail users messages list --params '{\"userId\": \"me\", \"maxResults\": 20, \"q\": \"in:inbox\"}'

STEP 2: For each message, fetch metadata. Batch them efficiently in a single shell command:
for id in ID1 ID2 ID3 ...; do
  gws gmail users messages get --params \"{\\\"userId\\\": \\\"me\\\", \\\"id\\\": \\\"$id\\\", \\\"format\\\": \\\"metadata\\\", \\\"metadataHeaders\\\": [\\\"From\\\", \\\"Subject\\\", \\\"Date\\\"]}\"
  echo '---SEP---'
done

STEP 3: For each email, apply priority logic:

Newsletter Detection (any of these -> priority = 'low'):
- Sender domain: substack.com, beehiiv.com, convertkit.com, mailchimp.com, sendgrid.net, buttondown.email
- Content contains 'Unsubscribe' or 'unsubscribe from this list'
- Subject contains 'Issue #', 'Vol.', 'Volume', 'Weekly', 'Monthly', 'Digest', 'Newsletter'
- Sender name contains 'newsletter', 'digest', 'weekly'

If newsletter: low_priority_reason = 'Newsletter'
Otherwise: priority = 'medium'

STEP 4: Return ONLY a JSON array with the normalized task schema.
URL format: https://mail.google.com/mail/u/0/#inbox/{message_id}
If no emails found, return empty array: []
If CLI fails, return: {\"error\": \"Could not fetch Gmail messages\"}
"
)
```

---

#### Agent 3: Jira (via MCP)

```
Agent(
  subagent_type: "jira-fetcher",
  description: "Fetch and normalize Jira issues",
  prompt: "Fetch and normalize Jira issues. Return JSON array only.

TODAY'S DATE: {YYYY-MM-DD}

STEP 1: Fetch assigned issues using:
mcp__jira__jira_get(
  path: '/rest/api/3/search/jql',
  queryParams: {
    'jql': 'project = {JIRA_PROJECT} AND assignee = currentUser() AND resolution = Unresolved ORDER BY priority DESC, duedate ASC',
    'maxResults': '50',
    'fields': 'key,summary,status,priority,duedate,updated,assignee,comment'
  }
)

STEP 2: For each issue, apply priority logic:

1. QA Comments Check (CRITICAL - do first):
   - If status is 'IN QA' or 'In QA':
     - Check comments for any NOT authored by {USER_EMAIL}
     - If found: priority = 'high', has_qa_comments = true, action = 'Respond to QA comments and address feedback'.
       Specify what comments specifically need my attention.
       If you can't find specific comments, priority drops to low.
     - If only your comments or none: has_qa_comments = false, continue to next rules

2. Jira Priority Mapping:
   - 'Highest' or 'High' -> priority = 'high'
   - 'Medium' -> priority = 'medium'
   - 'Low' or 'Lowest' -> priority = 'low'
   - Missing -> priority = 'medium'

3. Due Date Override:
   - If duedate is today or past -> priority = 'high' (unless already high)
   - If duedate within 7 days -> at least 'medium'

4. Action Logic:
   - If has_qa_comments: 'Respond to QA comments and address feedback'
   - If status is 'IN QA' and no QA comments: 'Waiting on QA', and priority is low
   - Otherwise: Extract actionable step from status (e.g., 'Continue development', 'Submit for review', 'Update documentation')

STEP 3: Return ONLY a JSON array with the normalized task schema.
URL format: https://{JIRA_SITE}.atlassian.net/browse/{KEY}
If no issues found, return empty array: []
If API fails, return: {\"error\": \"Could not fetch Jira tasks\"}
"
)
```

---

### 3. Parse and Merge Subagent Results

After receiving responses from all three agents:

1. Parse each JSON response
2. Check for error objects: `{"error": "..."}`
3. Collect all valid task arrays into a unified list
4. Track which sources had errors for the footer

### 4. Sort Unified Task List

Sort all tasks by priority, then by source type within priority:

**Priority Order:** High -> Medium -> Low

**Within Each Priority Level:**
1. Calendar events (sorted by start_time, earliest first)
2. Jira issues (sorted by due_date, earliest first, then null dates)
3. Emails (sorted by date, newest first)

### 5. Generate plain text summary

Create plain text output optimized for terminal viewing:

```
Daily Tasks - [Month DD, YYYY]
==============================

[List all tasks in priority order: High -> Medium -> Low]
[Use plain text formatting - no markdown links]

[For each task, render based on source_type:]

**Calendar Event:**
* [title] - [start time] to [end time]
- Location: [location if present]
- Action: [actionable next step]
- [full url]

**Jira Issue:**
* [[KEY]] [summary]
- Status: [status]
- Due: [due date if present]
- Action: [actionable next step]
- [full url]

**Email:**
* [subject]
- From: [sender]
- Summary: [snippet]
- Action: [actionable next step]
- [full url]

---
Generated at [YYYY-MM-DD HH:MM:SS]
[Error notes if any sources failed. No need to specify when it worked successfully.]
```

**Formatting Rules:**
1. Plain text format, not markdown
2. Single unified task list organized by priority (High -> Medium -> Low)
3. NO --- separators between items (only at footer). No PRIORITY titles, order makes it implicit.
4. Event times in 12-hour format (e.g., "9:00 AM to 10:30 AM")
5. High and Medium priority items show `action` field
6. Low priority items show `low_priority_reason` instead of action
7. Jira issue titles always include the key (e.g., "[POD-123] Summary")

### 6. Write File to Daily Notes Directory

1. Calculate output path: `daily_notes/{YYYY-MM-DD}.txt` (relative to project root; create directory if missing)
2. Use the Write tool with the absolute path
3. This will overwrite any existing file (fresh data on each run)
4. Confirm success by displaying the path to the generated file

### 7. Error Handling

Handle subagent failures gracefully:

- **Calendar agent fails or returns error**: Skip calendar items, add footer note: "Could not fetch calendar events"
- **Gmail agent fails or returns error**: Skip email items, add footer note: "Could not fetch Gmail messages"
- **Jira agent fails or returns error**: Skip Jira items, add footer note: "Could not fetch Jira tasks"
- **Multiple failures**: Create minimal file with all applicable error notes
- **No content from any source**: Show message "No tasks found for today"

Always create the file even if some agents fail, so the user has a record of what was attempted.

## Usage

```
/today
```

This will generate a file at `daily_notes/YYYY-MM-DD.txt` with all of today's tasks from Calendar, Gmail, and Jira.

Each run overwrites the existing file for today with fresh data.

## Architecture Benefits

By using subagents:
- Raw API responses stay in subagent context windows (discarded after task completes)
- Main agent context only contains compact JSON summaries (~5-10 lines per task vs full email bodies)
- Parallel execution is preserved via simultaneous Agent calls
- Each source is isolated - one failure doesn't affect others
- Calendar and Gmail use `gws` CLI (no MCP dependency), Jira uses MCP
