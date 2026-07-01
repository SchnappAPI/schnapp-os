---
name: owner-working-preferences
description: "Owner working prefs (2026-06-17) — parallelize via subagents; many small reusable skills not monoliths; skill-ify repeated actions; automate (do, don't tell); concise caveman actionable-only replies; handoffs delivered as a one-click spawn_task chip (+ a handoff file); decide resolvable calls instead of asking."
metadata: 
  node_type: memory
  scope: global
  type: feedback
  source: "owner statement, session 9f0ff006 (2026-06-17); +2026-06-27 (main-only / no branches); +2026-06-29 (web sessions target main); +2026-06-30 (auto commit+push by default; never leave open PRs); +2026-06-30 (handoffs delivered as one-click spawn_task chips, not copy-paste primers); +2026-06-30 (decide resolvable calls, don't AskUserQuestion them — PROGRESS.md rotation-policy session)"
  updated: 2026-06-30
  originSessionId: 9f0ff006-412e-4529-aed7-032cd4dbd18a
---

Owner stated 2026-06-17 (to be formalized as global rules in the Rules-domain consolidation; interim record here):

1. **Parallelize.** When multiple independent things to do, use subagents/fan-out to cut response time.
2. **Small reusable skills, not monoliths.** Prefer multiple efficient single-purpose skills over large all-encompassing ones.
3. **Skill-ify repetition.** Any action the owner or I do repeatedly → turn it into a skill.
4. **Automate; do, don't tell.** Don't instruct the owner to copy/paste or run things I can run. Run the command, read the output, proceed. Only surface genuinely owner-only steps (e.g. 1P-admin mint, third-party console regen).
5. **Concise, actionable-only.** Reply with what needs owner input or action. Assume long detail goes unread. When important, write no-prose/caveman (drop preambles, fillers, hedging). Detail only on request.
6. **Handoffs = a one-click chip + a handoff file (NOT a copy-paste primer).** On any handoff or
   "continue in a new session" request: (a) write a handoff file (newest `handoffs/NNN`) packing maximal
   context to resume cold, AND (b) deliver the continuation as a **`spawn_task` chip**
   (`mcp__ccd_session__spawn_task`) — the owner clicks it once and it opens a fresh session in its own
   worktree, seeded with a self-contained prompt that points at the handoff file. The chip is the default
   delivery, replacing the old copy-paste primer; fall back to a pasteable primer only if the chip
   mechanism is unavailable on the surface. The spawned session commits + pushes to `main` from its
   worktree, so main-only stays intact.
7. **Main-only, no branches — every surface (2026-06-27; web sessions clarified 2026-06-29).** Commit directed work straight to `main` — no feature branches, no PRs (decisions/0011 #9; **ADR 0016** makes this absolute; ADR 0015 grants standing merge/act authority). Run tests + a local review pass before pushing; CI runs on the push. Autonomous self-edits use the **pre-commit gate** (ADR 0016), not a branch. **Claude Code on the web sessions target `main` directly** (**ADR 0017**) — no per-session `claude/*` branch; the prior default left orphaned branch residue across many sessions (14 swept 2026-06-29). The `sync/unmerged` scheduled routine now flags any stray branch as a backstop. **Commit + push automatically, by default (2026-06-30).** Do not wait to be asked per change: stage, commit, and push directed work to `main` as soon as it is verified — this overrides the harness default of pushing only when the user asks. **Never leave open PRs:** for the owner's own repos (SchnappAPI / personal), proactively close stray or dead PRs and merge clean, reviewed work straight to `main`; the only exception is a genuinely external/client repo that uses a PR flow. Still run a local review/verify pass before pushing, and review (do not blind-merge) any unreviewed production or security change first — ADR 0015 authorizes auto-merging *green* engineering work, not unvetted changes.

8. **Decide resolvable calls; don't ask.** `AskUserQuestion` is for genuine forks the objective
   underdetermines (values/priority tradeoffs, information only the owner has). A scoped
   engineering/process judgment call — pick a size threshold, pick a retention window, pick a
   file layout — is mine to decide and state the reasoning for, not to present as a multiple-choice.
   Owner reaction when I got this wrong: "you are an expert in this, why are you asking me."

**Why:** owner is fighting sprawl/staleness/overload; these reduce friction and round-trips.
Point 8 is the same principle applied to decisions, not just execution: an unnecessary question
is a round-trip too.
**How to apply:** every session, all surfaces. Before calling `AskUserQuestion`, check whether
the fork is actually resolvable from context/expertise — if so, decide and say why instead.
Links: [[credential-leak-2026-06-17]], [[keep-tracker-current]].
