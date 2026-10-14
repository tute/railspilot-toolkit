---
paths:
  - "spec/**"
  - "test/**"
---

* Follow the rspec-testing skill.
* Don't test the framework. Presence validations, enums, `belongs_to`,
  `has_many` and one-clause scopes are Rails' guarantees. Test the conditional
  and custom validations, the assertions that reach a database constraint
  (`RecordNotUnique`, `NotNullViolation`, `StatementInvalid` check the
  migration, not Rails), and code with logic of its own.
* No skipped or pending tests. Fix them or delete them.
