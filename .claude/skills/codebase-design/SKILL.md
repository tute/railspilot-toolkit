---
name: codebase-design
description: Explain how a system is put together, using a shared vocabulary for module depth. Read-only: it produces explanations and recommendations, never edits. Use when the user wants to understand an existing module's interface, see where a seam falls, judge testability, weigh a deepening opportunity, or when another skill needs the deep-module vocabulary.
---

# Codebase Design

> Forked from [mattpocock/skills](https://github.com/mattpocock/skills) v1.2.3
> and modified: read-only instead of a design tool, and explicit that depth
> never means larger units. Not vendored, so `skills update` leaves it alone.
> See "Forked skills" in the repo README.

Explain a system in terms of **deep modules**: a lot of behaviour behind a small interface, placed at a clean seam, testable through that interface. Use this language wherever code is being explained, reviewed, or considered for restructuring. The aim is leverage for callers, locality for maintainers, and testability for everyone.

## Scope

This skill explains and recommends. It does not edit code.

Produce descriptions of how the system is currently put together, where its seams fall, and what a change would buy. Stop at the recommendation. If the user wants the change made, that is a separate, explicit request handled by whatever skill does the work.

Never propose "collapse these classes into one" as a way to add depth. Depth comes from narrowing the public interface, not from growing the units behind it. See [Depth and small units](#depth-and-small-units).

## Depth and small units

Depth and small units are not in tension. They measure different things: depth measures the public interface against the behaviour behind it, size measures each unit of implementation. Keep the units small and the interface narrow. That is one design, not a compromise between two.

Ousterhout's target was never small classes as such, it was making every one of them public:

> Classitis may result in classes that are individually simple, but it increases the complexity of the overall system. Small classes don't contribute much functionality, so there have to be a lot of them, each with its own interface. These interfaces accumulate to create tremendous complexity at the system level.

The cost he names is the accumulation of *interfaces*, not of classes. A dozen small collaborators behind one entry point cost the caller one interface. The same dozen, all public, cost twelve. So the question to ask of a cluster is never "how many classes?" but "how many of them does a caller have to know about?"

Read the size rules as heuristics, which is how their authors wrote them. Sandi Metz on her own four rules:

> You should break these rules only if you have a good reason or your pair lets you.

Martin Fowler, on how long a function should be:

> To me length is not the issue. The key is the semantic distance between the method name and the method body.

DHH's objection is to the same dogma from the other side: units extracted to satisfy a rule rather than a need. He calls the result design damage, "code that is warped out of shape solely to accomodate testing objectives", and warns against extracting logic "into a command object just so you can mock boundaries and have 'fast tests'".

The four positions agree on the thing that matters. Small units, few of them public, extracted when they earn it and not to hit a number.

## Glossary

Use these terms exactly: don't substitute "component," "service," "API," or "boundary." Consistent language is the whole point.

**Module**: anything with an interface and an implementation. Deliberately scale-agnostic: a function, class, package, or tier-spanning slice. _Avoid_: unit, component, service.

**Interface**: everything a caller must know to use the module correctly: the type signature, but also invariants, ordering constraints, error modes, required configuration, and performance characteristics. _Avoid_: API, signature (too narrow, they refer only to the type-level surface).

**Implementation**: what's inside a module, its body of code. Distinct from **Adapter**: a thing can be a small adapter with a large implementation (a Postgres repo) or a large adapter with a small implementation (an in-memory fake). Reach for "adapter" when the seam is the topic; "implementation" otherwise.

**Depth**: leverage at the interface. The amount of behaviour a caller (or test) can exercise per unit of interface they have to learn. A module is **deep** when a large amount of behaviour sits behind a small interface, **shallow** when the interface is nearly as complex as the implementation.

**Seam** _(Michael Feathers)_: a place where you can alter behaviour without editing in that place; the *location* at which a module's interface lives. Where to put the seam is its own design decision, distinct from what goes behind it. _Avoid_: boundary (overloaded with DDD's bounded context).

**Adapter**: a concrete thing that satisfies an interface at a seam. Describes *role* (what slot it fills), not substance (what's inside).

**Leverage**: what callers get from depth. More capability per unit of interface they learn. One implementation pays back across N call sites and M tests.

**Locality**: what maintainers get from depth. Change, bugs, knowledge, and verification concentrate in one place rather than spreading across callers. Fix once, fixed everywhere.

## Deep vs shallow

**Deep module** = small interface + lots of implementation:

```
┌─────────────────────┐
│   Small Interface   │  ← Few methods, simple params
├─────────────────────┤
│                     │
│  Deep Implementation│  ← Complex logic hidden
│                     │
└─────────────────────┘
```

**Shallow module** = large interface + little implementation (avoid):

```
┌─────────────────────────────────┐
│       Large Interface           │  ← Many methods, complex params
├─────────────────────────────────┤
│  Thin Implementation            │  ← Just passes through
└─────────────────────────────────┘
```

When designing an interface, ask:

- Can I reduce the number of methods?
- Can I simplify the parameters?
- Can I hide more complexity inside?

## Principles

- **Depth is a property of the interface, not the implementation.** A deep module can be internally composed of small, mockable, swappable parts; they just aren't part of the interface. A module can have **internal seams** (private to its implementation, used by its own tests) as well as the **external seam** at its interface.
- **The deletion test.** Imagine deleting the module. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it was earning its keep.
- **The interface is the test surface.** Callers and tests cross the same seam. If you want to test *past* the interface, the module is probably the wrong shape.
- **One adapter means a hypothetical seam. Two adapters means a real one.** Don't introduce a seam unless something actually varies across it.

## Designing for testability

Good interfaces make testing natural:

1. **Accept dependencies, don't create them.**

   ```typescript
   // Testable
   function processOrder(order, paymentGateway) {}

   // Hard to test
   function processOrder(order) {
     const gateway = new StripeGateway();
   }
   ```

2. **Return results, don't produce side effects.**

   ```typescript
   // Testable
   function calculateDiscount(cart): Discount {}

   // Hard to test
   function applyDiscount(cart): void {
     cart.total -= discount;
   }
   ```

3. **Small surface area.** Fewer methods = fewer tests needed. Fewer params = simpler test setup.

## Relationships

- A **Module** has exactly one **Interface** (the surface it presents to callers and tests).
- **Depth** is a property of a **Module**, measured against its **Interface**.
- A **Seam** is where a **Module**'s **Interface** lives.
- An **Adapter** sits at a **Seam** and satisfies the **Interface**.
- **Depth** produces **Leverage** for callers and **Locality** for maintainers.

## Rejected framings

- **Depth as ratio of implementation-lines to interface-lines** (Ousterhout): rewards padding the implementation. We use depth-as-leverage instead.
- **"Interface" as the TypeScript `interface` keyword or a class's public methods**: too narrow: interface here includes every fact a caller must know.
- **"Boundary"**: overloaded with DDD's bounded context. Say **seam** or **interface**.

## Going deeper

Both produce written proposals. Neither edits code.

- **Deepening a cluster given its dependencies**, see [DEEPENING.md](DEEPENING.md): dependency categories, seam discipline, and replace-don't-layer testing.
- **Exploring alternative interfaces**, see [DESIGN-IT-TWICE.md](DESIGN-IT-TWICE.md): spin up parallel sub-agents to design the interface several radically different ways, then compare on depth, locality, and seam placement.
