# Concept integration follow-up (off-theme review) - Implementation Plan

**Goal:** A re-review of the 24 NEW-folder source articles, read raw rather than theme-scoped,
surfaced concepts the 2026-07-02 pass silently dropped: its 4 reader agents extracted "by theme"
(sycophancy / context / skills), so material outside those three buckets never reached a
keep/decline decision (distinct from the four forks ADR 0030 consciously declined). This plan
integrates the owner-approved subset by strengthening existing components, same discipline as ADR
0030. Source: `OneDrive-Schnapp/_RESOURCES/New Articles/NEW/` (24 files, re-read 2026-07-03).

**Owner scoping (2026-07-03):** build #1 ideation-first, #2 STORM perspective-research, #5
post-compact hook, and the minor on-theme refinements. #4 (QA-layer / accept-revise-reject feedback
tagging) explained in-session, parked for an owner decision (new capture channel + ongoing tagging
overhead). #3 (contractor-agent least-privilege security model) declined outright.

**Constraints:** commit/push every logical unit; secrets are `op://` refs; writing-style.md; ISO
dates; no force-push; state-change discipline (flip a box here + append a PROGRESS.md line in the
same commit).

**Git note:** this session was launched on branch `claude/schnapp-os-article-review-pyceiv` by the
web-session harness. The push target (this branch + a PR vs. fast-forward to main per
[decisions/0016](../../../decisions/0016-no-branches-precommit-gate.md) /
[0017](../../../decisions/0017-web-sessions-target-main.md)) is the owner's call, surfaced at
handoff.

---

## Tasks
- [x] T1. **Ideation-first module** - new `rules/modules/activity/ideation-first.md` (diverge into
  4-7 distinct options before converging; the generative front half complementary to `council` /
  `grill-me`). Wired into `/do` step 3.
- [x] T2. **Perspective-diverse research (STORM) module** - new
  `rules/modules/activity/perspective-research.md` (multi-persona question generation before
  retrieval; distinct from `council`: coverage not decision). Wired into `/do` step 2 next to
  `deep-research` and into the `council` "when NOT to use" table.
- [x] T3. **Post-compact re-inject hook** - new `hooks/post-compact-reinject.sh`, wired in
  `.claude/settings.json` as `SessionStart` matcher `compact` (stdout auto-injected; confirmed
  PreCompact runs before compaction so cannot re-inject). Reprints the load-bearing invariants after
  a compaction; restates no mutable state.
- [x] T4. **Minor on-theme refinements** - `council` gains input-framing neutralization (strip
  leading language before handing to voices) + optional per-voice model tiers (different training
  biases deepen the disagreement); `scaffolding-choice.md` gains a validate-before-propagation
  rule of thumb (a shared-lane change ripples to every repo via `@import` + `git pull`).
- [ ] T5. **(Owner decision, not built)** #4 QA-layer + accept/revise/reject feedback tagging -
  explained in-session, parked. #3 contractor security model - declined.

## Decisions
- Both new modules are **on-demand activity modules** (no `paths:` frontmatter), not global rules or
  new skills: they shape *how* a class of task is done, pulled in when relevant
  (`scaffolding-choice.md` branch 2). Strengthen-not-duplicate: wired into existing routes (`/do`,
  `council`), not added as competing siblings.
- STORM stays distinct from `council` (adversarial -> decision) as perspective-diverse -> coverage.
  `deep-research` is a plugin skill (not in-repo), referenced by name, not linked.

## Done when
Approved subset integrated with zero duplication and zero locked-ADR violations; CATALOG current;
CI gates (freshness, writing-style, check-links, shellcheck) green; repo clean + push target
resolved with the owner.
