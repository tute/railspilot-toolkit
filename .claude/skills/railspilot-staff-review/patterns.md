# Staff Review Patterns

Patterns learned from staff-engineer code reviews. Each pattern has an ID, category, applies-to scope, and detection hints.

Add new patterns at the bottom as you learn from future reviews.

---

## General: How RailsPilot Thinks

These are not specific rules but the recurring instincts behind every decision
RailsPilot staff engineer makes. When in doubt on any code choice, filter it
through these tendencies.

**Subtractive, not additive.** The default move is to delete code, not add it. A
24-line service beats a 61-line one. If the framework already does something,
remove the application code that duplicates it. The question isn't "what should
I add?" but rather "what can I remove and still have it work?"

**Security is not a phase.** RailsPilot doesn’t bolt on security in a "hardening
pass." It shows up in the first draft. It's not extra work — it's how we write code.

**Trust the infrastructure, not your code.** Sidekiq retries with exponential
backoff. Rails encrypts attributes. Error tracking catches exceptions. We don’t
reimplement what libraries already provide. A corollary: when something goes
wrong, let it go wrong loudly (raise, crash, show in Sidekiq dashboard or
exception notifiers) rather than catching, logging, or returning `false`.

**The user always gets a response.** Buttons never silently do nothing. This
applies to the backend too — the service returns the destroyed record or raises,
never a mystery boolean.

**Follow REST.** Don’t do custom actions, create controllers that map to RESTful
resources with standard actions.

**Tests are not optional — they're part of the code.** No "adding tests later" —
the test is written alongside or before the implementation.

**Views are for HTML, not for logic.** ERB templates should read like HTML with
small Ruby interpolations. If you're counting records, branching on conditions,
or formatting data in a view, that code belongs in a helper or presenter.

**Fix the smallest thing correctly.** Resist the urge to "clean up while you're
in there” or early extractions. Apply first just the minimal correct fix
alongside a test that reproduces the original error.

**Extract after two, not one.** Don't create abstractions for two use cases.
When a third similar implementation appears, then extract. Duplication is
cheaper than the wrong abstraction.

---

## Security

### SEC-02: Encrypt Sensitive Data at Rest

**Applies to:** Models storing keys, tokens, secrets, or PII

Use Rails `encrypts` for any column containing cryptographic keys, API tokens, or sensitive data. One line prevents a database breach from becoming a full compromise.

**Detection:** Look for columns named `*_key`, `*_token`, `*_secret`, or any field that stores credentials.

```ruby
# Bad — plaintext in DB
class PushSubscription < ApplicationRecord
  validates :auth_key, presence: true
end

# Good
class PushSubscription < ApplicationRecord
  encrypts :auth_key
  validates :auth_key, presence: true
end
```

## Architecture


### ARCH-02: Only Rescue What You Can Meaningfully Handle

**Applies to:** All Ruby code, especially services and jobs

Rescue specific exceptions only when you have a meaningful recovery action (like destroying an expired subscription). Let everything else bubble up to the framework. Returning booleans to indicate success/failure forces callers into if/else chains and hides real errors.

**Detection:** Look for `rescue` methods returning `true`/`false` from rescue blocks, or long chains of rescue clauses.

```ruby
# Bad — swallows all errors, returns boolean
def self.send_notification(...)
  do_thing
  true
rescue SomeError
  false
rescue AnotherError
  false
rescue => e
  Rails.logger.error(e.message)
  false
end

# Good — only handle what has a specific recovery
def self.send_notification(...)
  do_thing
rescue ExpiredSubscription => e
  Rails.logger.warn("Subscription expired: #{e.message}")
  subscription.destroy
end
```

## Simplicity

### SIMP-04: Keep Jobs Thin

**Applies to:** Background jobs

Jobs should do three things: fetch data, call a service, log that they ran. Business logic belongs in service objects. Retry logic belongs in the framework. Accounting belongs in monitoring tools.

**Detection:** Look for jobs longer than ~15 lines, or jobs that contain business logic, conditionals, or error handling beyond the basic call.

---

## Scope & Discipline

### SCOPE-01: One Concern Per Commit

**Applies to:** Git commits

Each commit should address one concern. Don't mix infrastructure changes (.gitignore), operational tooling (rake tasks), UI changes (views), and backend logic in one commit. Separate concerns make reviews easier and reverts safer.

**Detection:** Look at the file list — if it spans config, views, models, rake tasks, and JS, consider splitting.

### SCOPE-02: Don't Build What the Ticket Doesn't Ask For

**Applies to:** All code

If the ticket says "add push notification delivery," don't also build a cleanup rake task, an admin dashboard, or extra API endpoints. Features that aren't in scope create maintenance burden and may conflict with future decisions. Build exactly what's needed.

**Detection:** Ask "would this PR be accepted without this file/method?" If yes, it's out of scope.

## Completeness

### COMPLETE-01: Tests Ship With Every Behavior Change

**Applies to:** All commits that change behavior

Every commit that adds or modifies behavior must include tests. A controller action without a request spec, a model validation without a model spec, a JS handler without a JS test — these are unfinished work. "I'll add tests later" means "I won't add tests."

**Detection:** Check if the diff adds/modifies Ruby code in `app/` without corresponding changes in `spec/`. Check if new JS in `app/javascript/` has no matching test in `spec/javascript/`.

### COMPLETE-02: Test Edge Cases, Not Just Happy Paths

**Applies to:** All test files

Happy-path tests prove the feature works. Edge-case tests prove it doesn't break. Test nil inputs, empty collections, missing associations, boundary values, and permission failures. The push subscription specs test valid Chrome endpoints AND invalid HTTP URLs AND unknown domains AND malformed strings — not just "it creates a subscription."

**Detection:** Count the contexts in a spec. If there's only one context (or no contexts, just `it` blocks), edge cases are likely missing. Look for models with validations that have no corresponding rejection tests.

### COMPLETE-03: Stimulus Over Inline Scripts

**Applies to:** JavaScript in views

The project uses Stimulus for progressive enhancement. Inline `<script>` tags in views bypass the Stimulus architecture, can't be tested in isolation, don't get proper lifecycle management, and create implicit global state. New interactivity should be a Stimulus controller.

**Detection:** Look for `<script>` tags in ERB views that contain event handlers, DOM manipulation, or initialization logic. Exception: third-party embed scripts (analytics, widgets) that must be inline.

```erb
<%# Bad — inline script, untestable, no lifecycle %>
<script>
  function initializeSurveyForm() {
    document.querySelector('.survey-form').addEventListener('submit', ...)
  }
  document.addEventListener('turbo:load', initializeSurveyForm)
</script>

<%# Good — Stimulus controller, testable, proper lifecycle %>
<div data-controller="survey-form">
  <%= form_with ... data: { action: "submit->survey-form#handleSubmit" } %>
</div>
```
