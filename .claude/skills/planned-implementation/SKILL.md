---
name: planned-implementation
description: Implement an approved plan with parallel agents. Use when the user says "implement the plan", "/planned-implementation", or asks to parallelize implementation with agents and reconcile.
---

Implement the approved plan like this:

1. Split the plan into tracks: disjoint file sets run in parallel; dependent tracks run as sequential waves.
2. Pre-create the shared seams yourself (env getters, registrations in central index files, type contracts) so agents never edit the same file. If file sets can't be made disjoint, give agents isolated worktrees.
3. Fire the parallel agents, using the cheapest model that can do the job (e.g. Sonnet). Each prompt includes: today's date, the exact file list it owns, repo conventions (TDD, test locations, style), pointers to pattern files to imitate, and the instruction to report (not edit) anything belonging to shared files.
4. Run dependent waves as earlier tracks finish.
5. Reconcile everything in your branch: apply reported registrations, run the full test suite and typecheck, fix what's broken, commit, push.
