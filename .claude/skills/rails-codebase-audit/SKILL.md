---
name: rails-codebase-audit
description: Audits a legacy Rails codebase for structural risks, dependency health, test suite quality, model complexity, and architecture signals. Produces a prioritized report with fix-now, fix-this-quarter, and ignore-safely tiers. Use when asked to "audit this Rails app", "assess this codebase", "legacy Rails review", "codebase health", "technical debt assessment", or "what should we fix first".
---

Audit a Rails codebase to separate what looks bad from what is actually dangerous.
Produce a prioritized report, not an exhaustive list.

## Prerequisite skills

- For git history analysis (churn, bus factor, bug clusters), use the
  `codebase-diagnostic` skill.
- For security vulnerabilities (CVEs, secrets, injection patterns), use the
  `vulnerability-scan` skill.

This skill covers structural and architectural signals those skills don't.

## Instructions

### 1. Structural read (Gemfile, schema, routes)

These three files give you a working thesis in minutes.

Gemfile:
- Count total gems. Note duplicated responsibilities (two auth systems, two
  file upload gems, multiple JSON parsers).
- Flag gems with no clear purpose you can't explain from context.
- Check the Rails version. If EOL, note the compliance risk.

```bash
cat Gemfile | grep "^gem " | wc -l
```

db/schema.rb:
- Identify god tables (30+ columns). List them with column counts.
- Check for missing indexes on foreign key columns (`_id` columns without indexes).
- Look for `integer` primary keys in high-volume tables (ID exhaustion timebomb
  when approaching 2.1 billion rows).
- Find dead tables: tables in schema with no corresponding model file.

```bash
grep -c "t\." db/schema.rb
grep "create_table" db/schema.rb | wc -l
```

To find god tables (30+ columns):

```bash
ruby -e '
  current_table = nil
  counts = {}
  File.readlines("db/schema.rb").each do |line|
    if line =~ /create_table "(\w+)"/
      current_table = $1
      counts[current_table] = 0
    elsif current_table && line =~ /^\s+t\./
      counts[current_table] += 1
    end
  end
  counts.select { |_, v| v >= 30 }.sort_by { |_, v| -v }.each { |t, c| puts "#{c}\t#{t}" }
'
```

config/routes.rb:
- Count total routes and ratio of RESTful resources to custom routes.
  500+ custom routes is an architecture signal, not a style problem.

```bash
mise exec -- rails routes | wc -l
```

### 2. Dependency health

```bash
bundle outdated
```

Focus on:
- Rails version and EOL status.
- Major version gaps in critical gems (devise, sidekiq, puma, etc.).
- For regulated industries, EOL framework versions are compliance liabilities.

If `next_rails` is available:

```bash
mise exec -- bundle_report compatibility --rails-version=8.0
```

### 3. SLOC and complexity distribution

```bash
cloc app/
```

Where the lines live matters more than the total. If 80% is in `app/models`,
business logic is tightly coupled to ActiveRecord. A healthy `app/services`
or plain Ruby objects directory is a good sign.

If `rubycritic` is available:

```bash
mise exec -- rubycritic app/ --no-browser
```

Files in the upper-right quadrant (high churn, high complexity) are actively
hurting the team every sprint.

### 4. Model structure

Walk `app/models/` manually. Look for:
- God models: files over 300 lines. List them with line counts.
- Callback concentration: models with 5+ callbacks. Each callback is a hidden
  side effect that makes behavior hard to trace.
- Association graph complexity: models with 10+ associations.
- `default_scope` usage (silently filters queries application-wide).

```bash
wc -l app/models/*.rb | sort -nr | head -20
```

Find callbacks:

```bash
rg "^\s*(before|after|around)_(save|create|update|destroy|validation|commit)" app/models/ --count-matches | sort -t: -k2 -nr | head -15
```

Find default_scope:

```bash
rg "default_scope" app/models/
```

If `active_record_doctor` is available:

```bash
mise exec -- rails active_record_doctor:run
```

This surfaces missing unique indexes (race condition risk), wrong `dependent:`
options (silent data corruption), and other schema issues.

### 5. Test suite health

```bash
time mise exec -- rspec 2>&1 | tail -5
```

Signals:
- Over 30 minutes: crisis. Developers won't run it locally.
- Intermittent failures: the suite is not trustworthy.
- Commented-out tests: the most honest signal in the codebase.

```bash
rg "(xit |xdescribe |xcontext |pending )" spec/ --count-matches | sort -t: -k2 -nr
```

If SimpleCov is configured, check which critical files have zero coverage.
Zero coverage on models that touch money, auth, or permissions is a direct risk.

### 6. Dead code and dead routes

If `traceroute` is available:

```bash
mise exec -- traceroute
```

This surfaces unreachable controller actions and routes pointing to nothing.

### 7. N+1 queries

If Bullet is configured, note it. Otherwise, check logs or suggest enabling it.

```bash
rg "Bullet" Gemfile
```

### 8. Frontend and deployment signals

- Check for Hotwire/Turbo adoption vs legacy JS layer (Sprockets, Webpacker).
- Check for Dockerfile or Kamal config. Both ship with Rails 8 by default;
  their absence in a recent app is a signal.

```bash
ls Dockerfile* Procfile* config/deploy* 2>/dev/null
rg "(turbo|stimulus|hotwire)" Gemfile
rg "(sprockets|webpacker)" Gemfile
```

## Output format

Produce a single-page report with three tiers, not an exhaustive list.
The goal is to have an opinion, not just observations.

```
# Rails Codebase Audit — [app name]

## Fix this week
Security and compliance risks requiring immediate action.
Each item: what, where, why it's urgent, and the fix.

## Fix this quarter
Architectural problems slowing development.
Each item: what, the impact on velocity, and the approach.

## Don't worry about it
Issues that look bad but aren't dangerous. Explicitly calling these out
prevents the team from wasting effort.

## Key metrics
- Rails version and EOL status
- Gem count
- Total SLOC (app/)
- God tables (30+ columns): list with counts
- God models (300+ lines): list with counts
- Test suite run time
- Test coverage gaps on critical paths
- Bus factor (reference codebase-diagnostic if run)

## The one thing
If this team could only fix one thing this year, what should it be? Why?
```

## Edge cases

- If tools are not installed (rubycritic, active_record_doctor, traceroute,
  cloc), skip those steps and note what's missing. Don't install gems into
  the project without asking.
- If the test suite fails entirely, note it as a critical finding. Don't spend
  time debugging test failures during the audit.
- If schema.rb is missing (structure.sql instead), adapt the schema analysis
  to use structure.sql.
- For API-only apps, skip frontend signal checks.
