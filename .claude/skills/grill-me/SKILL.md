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
- **Explore over ask.** If a question is answerable from the codebase, PROGRESS.md + the plan docs
  (`docs/superpowers/plans/`), the `decisions/` directory, or the memory lane
  (`docs/memory-lane.md`; the global lane is the vault), go find the answer instead of asking.
- **Order by dependency.** Settle the decision other decisions hang on first; let the answer
  prune the branches below it.
- **Surface the gap, not just the literal ask** (see
  ../../rules/global/working-style.md): name the risks and constraints the owner did not
  raise. Catching what the plan left out is the point.

Stop when every live branch is resolved and the owner can act without re-deciding.

## Critique modes (forcing functions against vagueness)

When the ask is "tear this apart" rather than "interview me", drop the one-question cadence and run
one of these framings - each presupposes problems exist, so it cannot dead-end at "looks good":

- **Force-ranked list:** list the top 5 problems, ranked most- to least-serious; for each, why it
  matters and the consequence of not fixing it.
- **Score with justification:** rate 1-10 with a specific number and why; if above 7, name at least
  three things stopping it from being a 9-10; if below 6, what it would take to raise it.
- **Red team:** you are a competitor who wants this to fail - what do you exploit, where do you
  attack, which assumption is wrong or dangerous?
- **Pre-mortem:** it is 12 months later and this failed badly - what went wrong, what were the
  ignored warning signs, which decisions led to the failure?

Pick the mode that fits: red team / pre-mortem for plans and strategy, force-rank / score for a
concrete artifact (a doc, a schema, a design). State the mode you are using.

For grilling that also challenges the plan against documented terminology and decisions, and
updates docs inline, use the grill-with-docs skill. To make a final go/no-go call across
competing options, use the council skill.
