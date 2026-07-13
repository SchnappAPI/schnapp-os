---
name: grill-me
description: Use when the owner wants a plan or design stress-tested before building it, asks to "grill me", to "poke holes", to be interviewed about a decision, or when a proposal has unresolved branches and assumptions that need surfacing before code is written. Docs mode adds domain discipline - challenge the plan against the project's own language and documented decisions, sharpen fuzzy or overloaded terms, and capture resolutions in the canonical docs (glossary, decisions) as choices crystallize.
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

## Docs mode (challenge against the project's language, capture as you go)

When the plan touches a project with recorded terminology or decisions, add domain discipline
to the interview:

- **Challenge against the project's language.** If the owner uses a term that conflicts with
  how the repo already defines it, call it out: "the glossary uses X for that; you mean Y.
  Which?"
- **Sharpen fuzzy terms.** Vague or overloaded words get a precise canonical name. "You said
  'account' - Customer or User? Those differ."
- **Stress-test with concrete scenarios.** Invent edge cases that force precise boundaries
  between concepts.
- **Cross-reference the code.** When the owner states how something works, check the code
  agrees; surface any contradiction.

Capture resolutions where they belong, the moment they resolve - do not batch. Per
../../rules/global/anti-stale.md, one fact lives in one canonical file:

- **A resolved term** goes to the project's glossary doc (a `glossary` or `CONTEXT` note in the
  project, or the memory lane if the project has none). Keep it a glossary: definitions only,
  no implementation detail, no spec, no scratch.
- **A durable decision** goes to the schnapp-os `decisions/` directory convention (one file per
  decision). Record it sparingly - only when **all three** hold:
  1. **Hard to reverse**: changing your mind later costs something real.
  2. **Surprising without context**: a future reader will ask "why this way?"
  3. **A genuine trade-off**: real alternatives existed and you picked one for stated reasons.
  Missing any one: skip it. Create files lazily, only when there is something to write.

To make a final go/no-go call across competing options, use the council skill.
