---
name: grill-me
description: Use when the owner wants a plan or design stress-tested before building it, asks to "grill me", to "poke holes", to be interviewed about a decision, or when a proposal has unresolved branches and assumptions that need surfacing before code is written.
---

# grill-me

Interview the owner relentlessly about a plan or design until you reach shared
understanding. Walk down each branch of the decision tree, resolving dependencies between
decisions one at a time.

## How

- **One question at a time.** Wait for the answer before the next. No question lists.
- **Recommend, don't just ask.** For each question give your recommended answer and the one-line why, so the owner reacts to a concrete position instead of starting from blank.
- **Explore over ask.** If a question is answerable from the codebase, the trackers
  (PLAN.md / PROGRESS.md), the `decisions/` directory, or the memory lane
  (`memory/README.md`), go find the answer instead of asking.
- **Order by dependency.** Settle the decision other decisions hang on first; let the answer
  prune the branches below it.
- **Surface the gap, not just the literal ask** (see
  ../../rules/global/working-style.md): name the risks and constraints the owner did not
  raise. Catching what the plan left out is the point.

Stop when every live branch is resolved and the owner can act without re-deciding.

For grilling that also challenges the plan against documented terminology and decisions, and
updates docs inline, use the grill-with-docs skill. To make a final go/no-go call across
competing options, use the council skill.
