---
name: owner-working-preferences
description: "Owner working prefs (2026-06-17) — parallelize via subagents; many small reusable skills not monoliths; skill-ify repeated actions; automate (do, don't tell); concise caveman actionable-only replies; rich handoffs + copy-paste primer."
metadata: 
  node_type: memory
  type: feedback
  source: "owner statement, session 9f0ff006 (2026-06-17); +2026-06-27 (main-only / no branches); +2026-06-29 (web sessions target main); +2026-06-30 (auto commit+push by default; never leave open PRs)"
  updated: 2026-06-30
  originSessionId: 9f0ff006-412e-4529-aed7-032cd4dbd18a
---

Owner stated 2026-06-17 (to be formalized as global rules in the Rules-domain consolidation; interim record here):

1. **Parallelize.** When multiple independent things to do, use subagents/fan-out to cut response time.
2. **Small reusable skills, not monoliths.** Prefer multiple efficient single-purpose skills over large all-encompassing ones.
3. **Skill-ify repetition.** Any action the owner or I do repeatedly → turn it into a skill.
4. **Automate; do, don't tell.** Don't instruct the owner to copy/paste or run things I can run. Run the command, read the output, proceed. Only surface genuinely owner-only steps (e.g. 1P-admin mint, third-party console regen).
5. **Concise, actionable-only.** Reply with what needs owner input or action. Assume long detail goes unread. When important, write no-prose/caveman (drop preambles, fillers, hedging). Detail only on request.
6. **Handoffs = primer + file.** On any handoff request, always (a) provide a copy-paste-ready primer block for a new chat/session, AND (b) write a handoff file packing maximal relevant context in a concise format built to let me resume seamlessly.
7. **Main-only, no branches — every surface (2026-06-27; web sessions clarified 2026-06-29).** Commit directed work straight to `main` — no feature branches, no PRs (decisions/0011 #9; **ADR 0016** makes this absolute; ADR 0015 grants standing merge/act authority). Run tests + a local review pass before pushing; CI runs on the push. Autonomous self-edits use the **pre-commit gate** (ADR 0016), not a branch. **Claude Code on the web sessions target `main` directly** (**ADR 0017**) — no per-session `claude/*` branch; the prior default left orphaned branch residue across many sessions (14 swept 2026-06-29). The `sync/unmerged` scheduled routine now flags any stray branch as a backstop. **Commit + push automatically, by default (2026-06-30).** Do not wait to be asked per change: stage, commit, and push directed work to `main` as soon as it is verified — this overrides the harness default of pushing only when the user asks. **Never leave open PRs:** for the owner's own repos (SchnappAPI / personal), proactively close stray or dead PRs and merge clean, reviewed work straight to `main`; the only exception is a genuinely external/client repo that uses a PR flow. Still run a local review/verify pass before pushing, and review (do not blind-merge) any unreviewed production or security change first — ADR 0015 authorizes auto-merging *green* engineering work, not unvetted changes.

**Why:** owner is fighting sprawl/staleness/overload; these reduce friction and round-trips.
**How to apply:** every session, all surfaces. Links: [[credential-leak-2026-06-17]], [[keep-tracker-current]].
