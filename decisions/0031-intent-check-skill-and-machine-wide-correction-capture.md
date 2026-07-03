# 0031 - Intent-check skill + machine-wide correction capture (checkpoints article)

Date: 2026-07-02. Status: accepted.

## Context

The owner asked to integrate a 7-step "reason about the true intent before acting" pattern and the
human-in-the-loop **checkpoints** article (mindstudio.ai), cut the "here is what I did" narration
that overwhelms replies, add a "review the ENTIRE thing, not just head and tail" rule, and make the
root-cause-fix discipline actually stick ("there is a rule but it keeps happening"). Recon found most
of this already covered: `anti-stale.md` fix-the-class + the `learn-route` skill route corrections to
their root cause, `writing-style.md` + `length-advisory.sh` keep files lean, `standing-rules.sh`
already injects "be terse, no recap". The real gap: the correction-capture hook (`capture-nudge.sh`)
was wired **project-scoped to schnapp-os only**, so in the owner's other work it never fired. That is
why fixes did not stick outside this repo. Two forks were owner-approved this session.

## Decision

Strengthen existing components; add exactly one skill and re-tier one hook. No new global rule file.

1. **Intent pattern -> lean rule + on-demand skill** (owner fork 1). `working-style.md` gets one
   compact "read for intent, not the literal words" bullet that also names where a checkpoint earns
   its place, pointing at a new `/intent-check` skill. The full 7-question pass + the article's
   checkpoint-placement framework live in `.claude/skills/intent-check/SKILL.md`, run silently with
   an **output contract** (emit only the restated intent, genuine forks, and any checkpoint) so it
   adds rigor without the per-message verbosity the owner is cutting.
2. **Root-cause enforcement -> machine-wide** (owner fork 2). `capture-nudge.sh` is re-tiered from
   the project `.claude/settings.json` to **user scope** in `~/.claude/settings.json`, alongside
   `standing-rules.sh` (both are behavioral, every-repo hooks). Its queue path is made absolute so it
   does not pollute other repos, and its injection now leads with an explicit root-cause step (name
   the missing/ambiguous/unfollowed rule or misread, fix THAT, generalize to the class).
3. **Checkpoints article folded in.** `working-style.md` + the skill carry: checkpoint only before an
   irreversible / outward-facing / high-consequence step or one needing context you lack; elsewhere
   decide and proceed (over-checkpointing trains rubber-stamping); pause **before** the point of no
   return, not after; capture **why** on a rejection and fix that cause. No new checkpoints file.
4. **Review-whole + anti-narration.** `context-discipline.md` gains a "review the whole artifact end
   to end, state the range covered" bullet. `working-style.md` + `standing-rules.sh` gain "report the
   outcome and any decision, not a play-by-play of the steps you took."

## Consequence

`capture-nudge.sh` no longer wired in the project `.claude/settings.json`; wired at user scope on this
Mac. **Other machines owe the one-time user-scope wire** (same as `standing-rules.sh`, PROGRESS
2026-07-02). CATALOG regenerated (new `intent-check` skill, updated hook header). `working-style.md`
holds at 58 lines (three behaviors added; the escalation and owner-actions bullets were compressed to
offset them, for zero net growth; still over the 50-line advisory, a candidate for a future prune). The synchronous root-cause nudge now fires in every repo (the async nightly queue stays schnapp-os-local;
the nudge, not the queue, is the machine-wide mechanism). Cross-references: [working-style.md](../rules/global/working-style.md),
[intent-check](../.claude/skills/intent-check/SKILL.md), [learn-route](../.claude/skills/learn-route/SKILL.md),
[0030](0030-concept-integration-strengthen-not-duplicate.md) (same strengthen-not-duplicate discipline).
