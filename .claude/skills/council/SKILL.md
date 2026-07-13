---
name: council
description: Use when a decision has multiple credible paths and no obvious winner, when the owner asks for second opinions, dissent, or multiple perspectives, when a go/no-go call would benefit from adversarial challenge, or when conversational anchoring is a real risk and tradeoffs need explicit surfacing.
---

# council

Convene four advisors for a decision under ambiguity: the in-context voice (Architect) plus
three fresh subagents - Skeptic, Pragmatist, Critic. This is for **deciding under ambiguity**,
not code review, planning, or architecture design.

Examples: monorepo vs polyrepo; ship the ETL rewrite now vs hold for backfill coverage;
feature flag vs full rollout; narrow scope vs keep strategic breadth.

## When NOT to use

| Instead of council | Use |
| --- | --- |
| Checking whether output is correct | the superpowers:verification-before-completion skill |
| Reviewing code for bugs or security | the `/code-review` skill (or the caveman reviewer agent) |
| Breaking a feature into steps, or designing architecture | the `Plan` agent |
| Widening research coverage across perspectives (not deciding) | the `perspective-research` module (STORM) |
| Straight factual questions, or obvious execution | just answer / just do it |

## Roles

| Voice | Lens |
| --- | --- |
| Architect | correctness, maintainability, long-term implications |
| Skeptic | premise challenge, simplification, breaking assumptions |
| Pragmatist | shipping speed, owner impact, operational reality |
| Critic | edge cases, downside risk, failure modes |

The three external voices launch as **fresh subagents with only the question and the minimal
context**: never the full transcript. That isolation is the anti-anchoring mechanism.

## Workflow

1. **Extract the real question.** One explicit prompt: what are we deciding, what constraints
   matter, what counts as success? If vague, ask one clarifying question first. **Neutralize your
   own framing** before handing it over: strip leading or approving language from the question, or it
   anchors the voices the same way conversational history would.
2. **Gather only necessary context.** Codebase-specific: collect the few relevant
   files/snippets/metrics, keep it compact. Strategic: skip repo snippets unless they change
   the answer.
3. **Form the Architect position first**: your initial call, three strongest reasons, the
   main risk in your preferred path - *before* reading the others, so the synthesis is not
   just an echo.
4. **Launch the three voices in parallel.** Each gets the question, compact context, a strict
   role, no extra history. Prompt shape:

   ```text
   You are the [ROLE] on a four-voice decision council. [ONE-LINE BACKSTORY].

   Question:
   [decision question]

   Context:
   [only the relevant snippets or constraints]

   Respond with:
   1. Position - 1-2 sentences
   2. Reasoning - 3 concise bullets
   3. Risk - biggest risk in your recommendation
   4. Surprise - one thing the other voices may miss

   Prohibitions: do not open with any positive statement; do not say "great idea",
   "interesting approach", or acknowledge strengths unless a specific weakness stems from
   one. Your job is not to be balanced - it is to do your role's job. Be blunt. No hedging.
   Under 300 words.
   ```

   Give each voice a **backstory** that makes the role concrete - a specific person who has
   seen this fail beats an abstract label ("a VC who has written off three bets in this
   category" > "a skeptic"). Role emphasis and backstories:
   - **Skeptic:** a professional stress-tester hired to find every reason this fails. Challenge
     the framing; propose the simplest credible alternative. Your job is not to be balanced.
   - **Pragmatist:** a shipper who has been burned by over-scoped plans. Optimize for speed and
     real-world execution; name what breaks in production.
   - **Critic:** an operator who has watched similar initiatives derail on execution. Surface the
     downside risks and failure modes most likely to actually happen, even if the concept is sound.
   - **Architect** (the in-context voice): correctness, maintainability, long-term implications.

   Where it sharpens the contrast, give voices different **model tiers** (the Agent tool's `model`
   override): a blunt fast tier for the Skeptic, a stronger tier for the Critic or a hard call.
   Different models carry different training biases, so the disagreement runs deeper than the persona.
5. **Synthesize with guardrails.** Do not dismiss an external view without saying why. If one
   changed your call, say so. Always include the strongest dissent even if you reject it. Two
   voices aligning against your initial position is a real signal. Keep raw positions visible
   before the verdict. **Do not resolve disagreements artificially:** where the voices conflict,
   surface the conflict explicitly - a mushy blended middle destroys the signal the council exists
   to produce. Conflict is the output, not a defect to smooth over.
6. **Present a compact verdict** (scannable on a phone):

   ```markdown
   ## Council: [short decision title]

   **Architect:** [position] - [why]
   **Skeptic:** [position] - [why]
   **Pragmatist:** [position] - [why]
   **Critic:** [position] - [why]

   ### Verdict
   - **Consensus:** [where they align]
   - **Strongest dissent:** [most important disagreement]
   - **Premise check:** [did the Skeptic challenge the question itself?]
   - **Recommendation:** [synthesized path]
   ```

## After the council

Persist only when the council changes something real. If it does, route the delta to its
canonical home (see ../../../rules/global/knowledge-capture.md): a durable lesson or decision to
the memory lane (`docs/memory-lane.md`; the global lane is the vault); a long-lived decision to the `decisions/` directory; a
handoff for the next session to `handoffs/`. Do not write ad-hoc notes to shadow paths, and do
not persist every decision.

## Verify it works (known-bad-idea test)

A council that validates everything is broken. When editing the persona prompts, sanity-check them
by running an obviously flawed decision through the voices; if the Skeptic and Critic still bless
it, the prompts are too soft - tighten the prohibitions until a bad idea gets caught. Watch for the
degradation modes: voices agreeing too fast (not adversarial enough), soft hedging language
creeping in ("one potential area for consideration might be..."), or the synthesis washing out the
concerns. Independence is the guard against the first: the three external voices never see each
other's output or the full transcript.

## Multi-round and anti-patterns

Default is one round. For another round, keep the new question focused, include the prior
verdict only if needed, and keep the Skeptic clean to preserve anti-anchoring.

Avoid: using council for code review or plain implementation; feeding subagents the whole
transcript; hiding disagreement in the verdict; persisting every outcome.
