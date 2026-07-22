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

### SEC-03: Tenant Scoping and Authorization

**Applies to:** Controllers, queries, and models touching tenant data

Verify `acts_as_tenant` scoping on models, authorization (Pundit/policy) on controller actions, and no cross-tenant leaks via raw SQL or `unscoped`.

### SEC-04: Trust Boundaries in Requests and Rendering

**Applies to:** Controllers, routes, views, redirects, and Turbo/JSON endpoints

State-changing actions must not be reachable through GET. Redirects must not accept untrusted external destinations without validation. Treat `html_safe`, `raw`, dynamic partial paths, user-authored rich text, and JavaScript interpolation as trust-boundary changes: verify escaping and sanitization at the final rendering context.

**Detection:** Look for `get`/`match` routes that mutate state, `redirect_to params[...]` or open redirect helpers, and `html_safe`/`raw` applied to user-controlled or partially trusted content.

```ruby
# Bad — state change via GET; open redirect; unsanitized HTML
get "/subscriptions/:id/cancel", to: "subscriptions#cancel"

def create
  redirect_to params[:return_to]
end

<%= user.bio.html_safe %>

# Good — POST for mutation; validated redirect; escaped output
resources :subscriptions do
  member { post :cancel }
end

def create
  redirect_to safe_return_path(params[:return_to])
end

<%= user.bio %>
```

### PERF-01: No N+1 Queries

**Applies to:** Controllers, views, jobs iterating associations

Use `includes`/`preload`/`eager_load` whenever iterating associated records. Detect with Bullet or by spotting `.each` over a collection that calls associations.

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

### ARCH-03: Keep External I/O Outside Database Transactions

**Applies to:** Services, controllers, and jobs that wrap writes with side effects

Trace transaction boundaries across every write and side effect. Avoid HTTP calls, email delivery, storage uploads, and other external I/O inside a database transaction. Jobs and notifications that require committed data should be dispatched after commit.

**Detection:** Look for `Net::HTTP`, API client calls, `deliver_later`/`deliver_now`, or file uploads nested inside `ActiveRecord::Base.transaction` / `Model.transaction` blocks. Prefer `after_commit` (or explicit post-commit enqueue) for side effects that depend on persisted state.

```ruby
# Bad — HTTP and mail inside the transaction
ActiveRecord::Base.transaction do
  order.update!(status: :paid)
  PaymentGateway.charge!(order)
  OrderMailer.receipt(order).deliver_now
end

# Good — commit first, then side effects
ActiveRecord::Base.transaction do
  order.update!(status: :paid)
end
PaymentGateway.charge!(order)
OrderMailer.receipt(order).deliver_later
```

### ARCH-04: Callbacks Maintain Invariants, Not Workflows

**Applies to:** ActiveRecord models with `before_*` / `after_*` callbacks

Treat callbacks as local invariant maintenance, not as a hidden workflow engine. Multi-step business workflows belong in explicit collaborators where transaction ownership, reuse, failure handling, and tests are clear. Check ordering, recursion, skipped-callback APIs (`update_columns`, `insert_all`), and rollback behavior when callbacks remain.

**Detection:** Callbacks that enqueue jobs, call external APIs, fan out to other models, or orchestrate multi-step processes. Prefer extracting that flow into a service or interactor invoked from the controller/job.

```ruby
# Bad — callback orchestrates a workflow
class Order < ApplicationRecord
  after_create :provision_everything

  def provision_everything
    Inventory.reserve!(self)
    ShippingLabel.create!(order: self)
    OrderMailer.confirmation(self).deliver_later
  end
end

# Good — explicit collaborator owns the workflow
class Orders::Place
  def self.call(attrs)
    order = Order.create!(attrs)
    Inventory.reserve!(order)
    ShippingLabel.create!(order:)
    OrderMailer.confirmation(order).deliver_later
    order
  end
end
```

### ARCH-05: Prefer Timestamp-Backed State Over Booleans

**Applies to:** Models and migrations introducing boolean state columns

Prefer timestamp-backed state over boolean columns when the domain benefits from knowing when a transition happened. Check predicate semantics, scopes, backfills, and whether repeated transitions are meaningful before accepting a boolean.

**Detection:** New `boolean` columns named like `active`, `published`, `completed`, `verified`, or `canceled` where a `*_at` timestamp would answer both "is it?" and "when?".

```ruby
# Bad — boolean loses transition time
add_column :articles, :published, :boolean, default: false, null: false

# Good — timestamp carries state and timing
add_column :articles, :published_at, :datetime

# Predicates and scopes derive from the timestamp
def published?
  published_at.present?
end

scope :published, -> { where.not(published_at: nil) }
```

## Deploy Safety

### SAFE-01: Migrations Must Survive Rolling Deploys

**Applies to:** Database migrations and schema changes

Review migrations as production operations, not only schema transformations. Check table size, locks, statement duration, index creation, and constraint validation. Destructive renames, removals, type changes, and new required values usually need expand-and-contract sequencing so old and new app versions can run against the same schema. Bypasses such as `safety_assured` require concrete, change-specific justification.

**Detection:** `remove_column`/`rename_column`/`change_column` in a single deploy step, `add_column ... null: false` without a default/backfill plan, long-running indexes without `algorithm: :concurrently` where required, and unexplained `safety_assured` blocks.

```ruby
# Bad — breaks old app code mid-deploy; unjustified bypass
class DropNicknameFromUsers < ActiveRecord::Migration[7.2]
  def change
    safety_assured { remove_column :users, :nickname, :string }
  end
end

# Good — expand first (stop writing/reading), deploy, then contract later
class StopUsingUsersNickname < ActiveRecord::Migration[7.2]
  def change
    # Deploy 1: stop reading/writing nickname in app code.
    # Deploy 2 (this migration, after app no longer references it):
    remove_column :users, :nickname, :string
  end
end
```

## Simplicity

### SIMP-04: Keep Jobs Thin — Let Errors Surface

**Applies to:** Background jobs

Jobs own three things: scheduling/retry semantics, record lifecycle (e.g. marking `processed_at`), and delegating to a service. Business logic belongs in service objects. Retry logic belongs in the framework (Solid Queue, Sidekiq). Don't rescue exceptions in jobs — let them propagate so the framework retries transient failures and surfaces persistent ones in dashboards.

**Detection:** Look for jobs longer than ~15 lines, jobs that contain business logic or conditionals, or jobs that rescue exceptions and return silently instead of letting the framework handle retries.

```ruby
# Bad — business logic in job, swallows errors
class ProcessWebhookJob < ApplicationJob
  def perform(event_id)
    event = WebhookEvent.find(event_id)
    data = JSON.parse(event.payload)
    patient = Patient.find_by(ehr_id: data["patient_id"])
    return unless patient
    appointment = patient.appointments.find_or_initialize_by(ehr_id: data["id"])
    appointment.update!(status: data["status"])
    event.update!(processed_at: Time.current)
  rescue => e
    Rails.logger.error("Webhook failed: #{e.message}")
  end
end

# Good — thin job, delegates to service, lets errors surface
class ProcessWebhookJob < ApplicationJob
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(event_id)
    event = WebhookEvent.find(event_id)
    Webhook::ProcessAppointment.call(event:)
    event.update!(processed_at: Time.current)
  end
end
```

### SIMP-05: Drop Defensive Code the Layer Above Already Owns

**Applies to:** Services wrapped by an error-mapping helper, transaction, `retry_on`, or `around_action`

If an outer wrapper already maps an error class to `Result.failure`/retry, an inner `begin/rescue` for that class (or a subclass) is dead defense. Same for guards that retest a condition another line already enforces. Trim them and prefer idiomatic Ruby: `unless x` over `if x.nil?`, `break unless x` before the equality check instead of `if x && x == y`.

**Detection:** `begin/rescue` inside a `with_*errors`/`safely`/`handle` block rescuing a class the wrapper already maps; `rescue` re-raising a sibling type the caller already rescues via the parent; `if x && x == y` paired with `break unless x`; `if foo.nil?` guarding a single early return; multiple guards re-checking a precondition validations/policies already enforce.

### SIMP-06: Don't Defend Against Impossible States

Applies to all code, JS browser-quirk paranoia most of all. Every guard, try/catch, and feature check is a claim a future reader must verify; once it stops being true the defense is dead code that hides bugs. Audit each one: can it actually fail per spec, is it paranoia for a now-fixed browser bug, is the precondition already guaranteed by surrounding code, does the layer above already own it (SIMP-05)? Keep a guard only if it survives all four, then add one line naming the real scenario it catches.

Detection: empty catch bodies, try/catch around operations the spec says cannot throw, feature checks for capabilities every supported browser already has, target-existence checks for elements your own partial renders, optional chaining where the receiver was assigned the line before, rescues that swallow errors which should bubble.

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

### COMPLETE-03: Jobs Must Tolerate At-Least-Once Delivery

**Applies to:** Background jobs and anything they enqueue

Assume jobs can be delivered more than once, retried after partial work, and run after records have changed or disappeared. Require idempotent effects or an explicit deduplication strategy where duplicates matter. Pass stable identifiers and small serializable values rather than mutable object graphs. Re-authorize or re-check relevant state at execution time instead of assuming enqueue-time state remains true.

**Detection:** Jobs that mutate without a uniqueness/idempotency key, pass ActiveRecord objects as arguments, or trust enqueue-time authorization/state without re-checking in `perform`.

```ruby
# Bad — duplicate delivery double-charges; trusts enqueue-time state
class ChargeOrderJob < ApplicationJob
  def perform(order)
    PaymentGateway.charge!(order)
  end
end

# Good — stable id, idempotent charge, re-check state at execution
class ChargeOrderJob < ApplicationJob
  def perform(order_id)
    order = Order.find(order_id)
    return if order.charged?

    PaymentGateway.charge!(order, idempotency_key: "order-#{order.id}")
  end
end
```

### COMPLETE-04: Cache Keys Must Include Every Result-Changing Input

**Applies to:** Fragment caching, low-level Rails.cache usage, and HTTP cache headers

Review cache keys for every input that can change the result, including tenant, locale, authorization, variants, and versioned records. Verify invalidation and stampede behavior. Never share sensitive cached output across scopes.

**Detection:** `cache`/`Rails.cache.fetch` keys that omit `Current.tenant`, `I18n.locale`, role/permission, or record `cache_key_with_version` when those dimensions affect the rendered or returned data.

```ruby
# Bad — shared across tenants and locales
Rails.cache.fetch("dashboard-stats") do
  Dashboard::Stats.call(account: Current.account)
end

# Good — key includes every dimension that changes the result
Rails.cache.fetch(["dashboard-stats", Current.account_id, I18n.locale]) do
  Dashboard::Stats.call(account: Current.account)
end
```
