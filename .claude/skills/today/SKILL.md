---
name: today
description: Generates a prioritized daily task summary from Calendar, Gmail, and Jira, saved to daily_notes/. Use when asked for today's tasks, daily summary, or standup prep.
disable-model-invocation: true
---

# Today Command

Generate a daily task summary from Google Calendar, Gmail, and Jira, intelligently prioritized.

## What This Command Does

1. Spawns 3 parallel Task subagents to fetch and normalize data from each source
2. Each subagent processes data in its own context window, returning compact summaries
3. Main agent merges summaries and generates plain text output
4. Saves to: `/Users/tute/Code/ai/railspilot/daily_notes/YYYY-MM-DD.txt`

## Requirements

- Google Workspace MCP server configured
- Atlassian Jira MCP server configured
- User email: you@example.com
- Permissions for Calendar, Gmail, and Jira access

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

### 0. Verify MCP Server Availability (CRITICAL)

Before proceeding, check if the required MCP servers are enabled:

1. Read the file: `./.claude/settings.local.json`
2. Check the `disabledMcpjsonServers` array
3. **If it contains "google_workspace" OR "atlassian_jira":**
   - STOP immediately
   - Display this error message to the user:

   ```
   ⚠️  MCP Servers Required but Disabled

   To enable them:
   1. Edit: /Users/tute/Code/ai/railspilot/.claude/settings.local.json
   2. Remove "google_workspace" and "atlassian_jira" from the "disabledMcpjsonServers" array
   3. Restart Claude Code

   Note: These servers are disabled by default to avoid polluting the context window
   in unrelated sessions. You can disable them again after running /today.
   ```
   - Do NOT proceed with the rest of the command
   - Do NOT attempt to modify the settings file automatically
4. **If the array is empty or doesn't contain these servers:**
   - Proceed to next step below

### 1. Calculate Today's Date and Time Boundaries

Determine the current date and create RFC3339 formatted timestamps for today's start and end:

- Get today's date in YYYY-MM-DD format
- Determine the day of week (important for POD-3 standup logic)
- Create today_start: `YYYY-MM-DDT00:00:00` with local timezone (e.g., `-08:00`)
- Create today_end: `YYYY-MM-DDT23:59:59` with local timezone
- Note the current time for time-sensitive priority calculations

### 2. Spawn Three Task Subagents in Parallel

Make THREE Task tool calls in parallel in a single message. Each Task has its own context window, processes the raw MCP data, and returns only the compact normalized JSON.

**IMPORTANT**:
- Pass the calculated date boundaries and current time to each Task in its description.
- Use the specialized subagent_type for each task to ensure they have access to the correct MCP tools:
  - Calendar: `subagent_type: "calendar-fetcher"`
  - Gmail: `subagent_type: "gmail-fetcher"`
  - Jira: `subagent_type: "jira-fetcher"`

---

#### Task 1: Calendar Subagent

```
Task(
  subagent_type: "calendar-fetcher",
  description: "Fetch and normalize today's calendar events. Return JSON array only.

TODAY'S INFO:
- Date: {YYYY-MM-DD}
- Day of week: {day_name}
- Current time: {HH:MM}
- Time range: {today_start} to {today_end}
- Timezone: {timezone}

STEP 1: Fetch calendar events using:
mcp__google_workspace__get_events(
  user_google_email: 'you@example.com',
  calendar_id: 'primary',
  time_min: '{today_start}',
  time_max: '{today_end}',
  detailed: true
)

STEP 2: For each event, apply priority logic:

1. POD-3 Standups:
   - If title contains 'POD-3' AND today is NOT Friday → priority = 'low', low_priority_reason = 'POD-3 standup (not Friday)'
   - If title contains 'POD-3' AND today IS Friday → apply normal rules below

2. Family Reminders:
   - If title contains 'Family' (case-insensitive) → priority = 'low', low_priority_reason = 'Family reminder'

3. Time-Sensitive:
   - If event starts within 8 hours AND not low priority → priority = 'high'
   - Action should include 'Leave by X:XX' if location requires travel

4. Default: priority = 'medium'

STEP 3: Return ONLY a JSON array (no explanation) with this structure for each event:
{
  'title': event summary,
  'source': 'calendar',
  'source_type': 'event',
  'priority': 'high' | 'medium' | 'low',
  'due_date': event start time (ISO 8601),
  'url': event.htmlLink,
  'action': specific actionable step (or null if low priority),
  'low_priority_reason': reason string (only if low priority),
  'metadata': {
    'start_time': formatted start time (12-hour format),
    'end_time': formatted end time (12-hour format),
    'location': location or null
  }
}

If no events found, return empty array: []
If API fails, return: {'error': 'Could not fetch calendar events'}
"
)
```

---

#### Task 2: Gmail Subagent

```
Task(
  subagent_type: "gmail-fetcher",
  description: "Fetch and normalize inbox emails. Return JSON array only.

STEP 1: Search inbox using:
mcp__google_workspace__search_gmail_messages(
  user_google_email: 'you@example.com',
  query: 'in:inbox',
  page_size: 50
)

STEP 2: Batch fetch full content (max 25 per batch):
mcp__google_workspace__get_gmail_messages_content_batch(
  user_google_email: 'you@example.com',
  message_ids: [list of IDs],
  format: 'full'
)

STEP 3: For each email, apply priority logic:

Newsletter Detection (any of these → priority = 'low'):
- Sender domain: substack.com, beehiiv.com, convertkit.com, mailchimp.com, sendgrid.net, buttondown.email
- Content contains 'Unsubscribe' or 'unsubscribe from this list'
- Subject contains 'Issue #', 'Vol.', 'Volume', 'Weekly', 'Monthly', 'Digest', 'Newsletter'
- Sender name contains 'newsletter', 'digest', 'weekly'

If newsletter: low_priority_reason = 'Newsletter'
Otherwise: priority = 'medium'

STEP 4: Return ONLY a JSON array (no explanation) with this structure for each email:
{
  'title': email subject,
  'source': 'gmail',
  'source_type': 'email',
  'priority': 'medium' | 'low',
  'due_date': email date (ISO 8601),
  'url': 'https://mail.google.com/mail/u/0/#inbox/{message_id}',
  'action': specific actionable step extracted from content (reply, review, download, print, etc.) or null if low priority,
  'low_priority_reason': reason string (only if low priority),
  'metadata': {
    'from': sender name and email,
    'snippet': 1-sentence summary of email content
  }
}

If no emails found, return empty array: []
If API fails, return: {'error': 'Could not fetch Gmail messages'}
"
)
```

---

#### Task 3: Jira Subagent

```
Task(
  subagent_type: "jira-fetcher",
  description: "Fetch and normalize Jira issues. Return JSON array only.

TODAY'S DATE: {YYYY-MM-DD}

STEP 1: Fetch assigned issues using:
mcp_atlassian_jira_jira_get(
  path: '/rest/api/3/search/jql',
  queryParams: {
    'jql': 'project = POD-3 AND assignee = currentUser() AND resolution = Unresolved ORDER BY priority DESC, duedate ASC',
    'maxResults': '50',
    'fields': 'key,summary,status,priority,duedate,updated,assignee,comment'
  }
)

STEP 2: For each issue, apply priority logic:

1. QA Comments Check (CRITICAL - do first):
   - If status is 'IN QA' or 'In QA':
     - Check comments for any NOT authored by you@example.com
     - If found: priority = 'high', has_qa_comments = true, action = 'Respond to QA comments and address feedback'.
       Specify what comments specifically need my attention.
       If you can't find specific comments, priority drops to low.
     - If only your comments or none: has_qa_comments = false, continue to next rules

2. Jira Priority Mapping:
   - 'Highest' or 'High' → priority = 'high'
   - 'Medium' → priority = 'medium'
   - 'Low' or 'Lowest' → priority = 'low'
   - Missing → priority = 'medium'

3. Due Date Override:
   - If duedate is today or past → priority = 'high' (unless already high)
   - If duedate within 7 days → at least 'medium'

4. Action Logic:
   - If has_qa_comments: 'Respond to QA comments and address feedback'
   - If status is 'IN QA' and no QA comments: 'Waiting on QA', and priority is low
   - Otherwise: Extract actionable step from status (e.g., 'Continue development', 'Submit for review', 'Update documentation')

STEP 3: Return ONLY a JSON array (no explanation) with this structure for each issue:
{
  'title': '[KEY]: summary' (e.g., 'POD-123: Fix login bug'),
  'source': 'jira',
  'source_type': 'issue',
  'priority': 'high' | 'medium' | 'low',
  'due_date': duedate or null (ISO 8601),
  'url': 'https://your-site.atlassian.net/browse/{KEY}',
  'action': specific actionable step,
  'low_priority_reason': reason string (only if low priority),
  'metadata': {
    'key': issue key,
    'status': status name,
    'has_qa_comments': boolean,
    'relevant_comments': array
  }
}

If no issues found, return empty array: []
If API fails, return: {'error': 'Could not fetch Jira tasks'}
"
)
```

---

### 3. Parse and Merge Subagent Results

After receiving responses from all three Tasks:

1. Parse each JSON response
2. Check for error objects: `{"error": "..."}`
3. Collect all valid task arrays into a unified list
4. Track which sources had errors for the footer

### 4. Sort Unified Task List

Sort all tasks by priority, then by source type within priority:

**Priority Order:** High → Medium → Low

**Within Each Priority Level:**
1. Calendar events (sorted by start_time, earliest first)
2. Jira issues (sorted by due_date, earliest first, then null dates)
3. Emails (sorted by date, newest first)

### 5. Generate plain text summary

Create plain text output optimized for terminal viewing:

```
Daily Tasks - [Month DD, YYYY]
==============================

[List all tasks in priority order: High → Medium → Low]
[Use plain text formatting - no markdown links]

[For each task, render based on source_type:]

**Calendar Event:**
• [title] - [start time] to [end time]
- Location: [location if present]
- Action: [actionable next step]
- [full url]

**Jira Issue:**
• [[KEY]] [summary]
- Status: [status]
- Due: [due date if present]
- Action: [actionable next step]
- [full url]

**Email:**
• [subject]
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
2. Single unified task list organized by priority (High → Medium → Low)
3. NO --- separators between items (only at footer). No PRIORITY titles, order makes it implicit.
4. Event times in 12-hour format (e.g., "9:00 AM to 10:30 AM")
5. High and Medium priority items show `action` field
6. Low priority items show `low_priority_reason` instead of action
7. Jira issue titles always include the key (e.g., "[POD-123] Summary")

### 6. Write File to Daily Notes Directory

1. Calculate output path: `/Users/tute/Code/ai/railspilot/daily_notes/{YYYY-MM-DD}.txt`
2. Use the Write tool with the absolute path
3. This will overwrite any existing file (fresh data on each run)
4. Confirm success by displaying the path to the generated file

### 7. Error Handling

Handle subagent failures gracefully:

- **Calendar Task fails or returns error**: Skip calendar items, add footer note: `⚠️ Could not fetch calendar events`
- **Gmail Task fails or returns error**: Skip email items, add footer note: `⚠️ Could not fetch Gmail messages`
- **Jira Task fails or returns error**: Skip Jira items, add footer note: `⚠️ Could not fetch Jira tasks`
- **Multiple failures**: Create minimal file with all applicable error notes
- **No content from any source**: Show message "No tasks found for today"

Always create the markdown file even if some Tasks fail, so the user has a record of what was attempted.

## Usage

```
/today
```

This will generate a file at `/Users/tute/Code/ai/railspilot/daily_notes/YYYY-MM-DD.txt` with all of today's tasks from Calendar, Gmail, and Jira.

Each run overwrites the existing file for today with fresh data from Google Calendar, Gmail, and Jira.

## Architecture Benefits

By using Task subagents with specialized agent types:
- Raw MCP responses stay in subagent context windows (discarded after task completes)
- Main agent context only contains compact JSON summaries (~5-10 lines per task vs full email bodies)
- Parallel execution is preserved via simultaneous Task calls
- Each source is isolated - one failure doesn't affect others
- Each agent only has access to the MCP tools it needs:
  - `calendar-fetcher`: only `mcp__google_workspace__get_events`
  - `gmail-fetcher`: only `mcp__google_workspace__search_gmail_messages` and `mcp__google_workspace__get_gmail_messages_content_batch`
  - `jira-fetcher`: only `mcp__atlassian_jira__jira_get`
