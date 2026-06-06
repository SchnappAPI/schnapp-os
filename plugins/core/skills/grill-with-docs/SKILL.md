---
name: grill-with-docs
description: Use when the owner wants a plan stress-tested against the project's own language and documented decisions, when terms are fuzzy or overloaded, when a plan may conflict with prior decisions in the repo, or when grilling should also leave the docs (glossary, decisions) updated inline as choices crystallize.
---

# grill-with-docs

grill-me plus domain discipline: challenge the plan against the project's existing language
and recorded decisions, sharpen terms, and capture resolutions in the canonical docs as they
happen.

## Interview the same way as grill-me

One question at a time, wait for each answer, recommend an answer for each, and explore the
codebase / trackers / `decisions/` / memory lane (`memory/README.md`) instead of asking when
the answer is already there. Resolve decisions in dependency order.

## Plus, during the session

- **Challenge against the project's language.** If the owner uses a term that conflicts with
  how the repo already defines it, call it out: "the glossary uses X for that; you mean Y.
  Which?"
- **Sharpen fuzzy terms.** Vague or overloaded words get a precise canonical name. "You said
  'account' — Customer or User? Those differ."
- **Stress-test with concrete scenarios.** Invent edge cases that force precise boundaries
  between concepts.
- **Cross-reference the code.** When the owner states how something works, check the code
  agrees; surface any contradiction.

## Capture as you go (single source of truth)

Write resolutions where they belong, the moment they resolve — do not batch. Per
../../rules/global/anti-stale.md, one fact lives in one canonical file.

- **A resolved term** → the project's glossary doc (a `glossary` or `CONTEXT` note in the
  project, or the memory lane if the project has none). Keep it a glossary: definitions only,
  no implementation detail, no spec, no scratch.
- **A durable decision** → the claude-kit `decisions/` directory convention (one file per
  decision). Record it sparingly — only when **all three** hold:
  1. **Hard to reverse** — changing your mind later costs something real.
  2. **Surprising without context** — a future reader will ask "why this way?"
  3. **A genuine trade-off** — real alternatives existed and you picked one for stated
     reasons.
  Missing any one: skip it. Note what to record, the alternatives, and why you chose; let the
  `decisions/` file format carry the rest. Create files lazily, only when there is something
  to write.

To make a contested go/no-go call across competing options, use the council skill.
