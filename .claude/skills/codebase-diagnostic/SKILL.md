---
name: codebase-diagnostic
description: Runs git history diagnostics on a repository to surface churn hotspots, bus factor, bug clusters, velocity trends, and crisis patterns. Use when asked to "diagnose a codebase", "audit a repo", "what's risky in this codebase", "codebase health check", "bus factor", "churn hotspots", or "where do bugs cluster".
---

Run git history diagnostics to build a risk map of a codebase before reading any code.

## Goal

Produce a structured report that tells you where the codebase hurts: which files
are highest risk, who built it and who maintains it, where bugs cluster, whether
the team is shipping with confidence, and how often they firefight.

## Instructions

### 1. Churn hotspots

The 20 most-changed files in the last year. High churn on a file that also
appears in bug clusters is the single biggest risk signal.

```bash
git log --format=format: --name-only --since="1 year ago" | sort | uniq -c | sort -nr | head -20
```

### 2. Contributor profile

Every contributor ranked by commit count. If one person accounts for 60%+ of
commits, that is the bus factor. Compare overall contributors against the last
6 months to see if the builders are still around.

```bash
git shortlog -sn --no-merges
git shortlog -sn --no-merges --since="6 months ago"
```

Note: squash-merge workflows compress authorship. If commits look uniform, ask
about the merge strategy before drawing conclusions.

### 3. Bug clusters

Files most frequently touched in commits mentioning bug-related keywords.
Cross-reference against churn hotspots: files on both lists are highest risk.

```bash
git log -i -E --grep="fix|bug|broken" --name-only --format='' | sort | uniq -c | sort -nr | head -20
```

### 4. Velocity trend

Commit count by month across the full project history. Look for:
- Steady rhythm (healthy)
- Sharp drops (someone likely left)
- Declining curve over 6-12 months (losing momentum)
- Periodic spikes then quiet (batch releases, not continuous delivery)

```bash
git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c
```

### 5. Crisis patterns

Revert and hotfix frequency in the last year. A handful is normal. Reverts
every couple of weeks means the team does not trust its deploy process.

```bash
git log --oneline --since="1 year ago" | grep -iE 'revert|hotfix|emergency|rollback'
```

### 6. Cross-reference and analyze

- Identify files that appear in both churn hotspots AND bug clusters.
  These are the highest-risk files in the codebase.
- Check whether top overall contributors still appear in the 6-month window.
  Missing names indicate knowledge loss.
- Correlate velocity drops with contributor departures if visible.

## Output format

```
# Codebase Diagnostic — [repo name]

## Risk hotspots
Files that are high-churn AND high-bug, ranked by combined frequency.
Include file path and counts from both lists.

## Bus factor
Top contributors overall vs. last 6 months.
Flag anyone who built significant parts but is no longer active.

## Bug density map
Top 10 files from bug cluster analysis.
Note which ones also appear in churn hotspots.

## Velocity trend
Brief narrative of the commit rhythm.
Flag any sharp drops or sustained declines.

## Crisis patterns
Count and list of reverts/hotfixes/emergencies.
Assessment: stable, occasional issues, or chronic firefighting.

## Recommended reading order
Top 5 files to read first, based on the combined risk signals above.
For each file: why it matters and what to look for.
```

## Edge cases

- If the repo has less than 6 months of history, adjust time windows and note
  the limited data.
- If commit messages are uninformative (e.g., "update stuff"), note that bug
  cluster data is unreliable.
- If the repo uses squash merges exclusively, note that contributor data
  reflects mergers, not authors.
- Zero crisis patterns is itself a signal: either the team is stable, or
  commit messages lack detail.
