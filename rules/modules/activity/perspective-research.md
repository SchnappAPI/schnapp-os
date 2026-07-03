---
module: activity/perspective-research
updated: 2026-07-03
---
# Perspective-diverse research (STORM)

Load for knowledge-intensive research where a single framing misses angles: a topic brief, a
technical analysis, a decision memo, competitive or due-diligence work. STORM widens the *question*
space before any retrieval, then synthesizes. It is the pre-writing discipline the `deep-research`
skill's fan-out should run, and it is distinct from
[`council`](../../../.claude/skills/council/SKILL.md): council is adversarial and converges on a
*decision*; STORM is perspective-diverse and converges on *coverage*.

## The method
1. **Brief.** State scope, audience, depth, and output format once: shared context handed to every
   persona.
2. **Diverge into perspectives.** Generate questions from several distinct lenses independently,
   before any answers. Defaults: Domain Expert (precision, foundations), Skeptic (counterevidence,
   limits), Practitioner (real-world use, failure-in-practice), Journalist (context, the "so what"),
   Newcomer (definitions, unstated assumptions). Personas are whatever angles fit the domain.
3. **Retrieve per question**, tagging each result by the persona that asked, so different lenses pull
   different sources rather than five queries against one search.
4. **Synthesize an outline** that integrates the questions and findings (organize, do not invent),
   surfacing where perspectives conflict instead of smoothing them. Draft from the outline.

## Rules of thumb
- **Isolate question generation per persona.** One agent "playing five" anchors to a single framing
  and loses the benefit: use fresh subagents, the
  [`council`](../../../.claude/skills/council/SKILL.md) anti-anchoring pattern.
- **The outline step is load-bearing.** Skip it and this is just a multi-prompt; the intermediate
  synthesis is what separates STORM from a fancy fan-out.
- **Perspective decomposition, not functional.** Use it where no single framing is "correct"; for a
  clear linear task, splitting into functional subtasks is cheaper.
- **Skip it** for a quick fact, a narrow topic, or a homogeneous audience: one engineered prompt with
  retrieval is faster.
