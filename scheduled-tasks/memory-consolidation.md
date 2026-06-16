# Routine: nightly memory consolidation

- **Class:** asks-first (queued) — proposes, does not rewrite memory on its own.
- **Scheduler:** Mac LaunchAgent → headless `claude -p` session (repo-only; no Mac services needed,
  but a Claude session is needed for the judgment).
- **What it does:** reviews the global `memory/` lane for: duplicate facts across files, facts that
  contradict a newer one (should be **superseded**, not appended — see `memory/README.md`),
  stale `updated:` dates, and index/file drift. Produces a consolidation proposal.
- **Acts on its own?** No. A memory *rewrite* is a judgment call (which fact wins, what supersedes
  what), so the routine writes the proposal to a memory note / handoff and notifies. An
  interactive session applies it (supersede in place, today's `updated:`, `source: correction`).
- **Reports:** the proposal lands in the repo via the normal end-of-session write; notify on finish.
- **Why it exists:** memory correctness (supersede, never duplicate) is a verified invariant
  (Final-verification #5); consolidation keeps the lane lean as facts accumulate, but must stay
  human-approved because superseding the wrong fact loses information.

## Agent instructions (what the LaunchAgent's `claude -p` runs)
> Run the session-hygiene freshness gate. Review `memory/` for duplicate/contradictory/stale facts
> per `memory/README.md`. Do NOT rewrite memory. Write a consolidation proposal (what to supersede,
> merge, or date-refresh, with the reason for each) to a memory note and append PROGRESS, then push.
> Anything ambiguous: list it as a question for the owner. Notify when done.
