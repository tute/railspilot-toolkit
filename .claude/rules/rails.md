---
paths:
  - "Gemfile"
  - "app/**"
  - "lib/**"
  - "db/**"
  - "config/**"
---

* Normalized schema. No redundant data. Derive values dynamically.
* Postgres enum columns, not strings.
* No new gems until proven necessary.
* Assertive style: `find`, `find_by!`, `sole`. Let exceptions surface. No nil
  guards unless the caller handles nil.
* POROs over mixins. Ask before adding a mixin.
* Namespaced service objects, short names, no `Service` suffix: `Namespace::ClassName#call`
* Service objects own writes that span rows. Models keep validations,
  associations, scopes and pure methods. A write with preconditions no
  validation expresses is a service. Building one unsaved record stays on the model.
* Domain naming: Measurements, not ProgressEntries.
