# Routine: sync / unmerged check

- **Class:** safe (auto) — read-only.
- **Scheduler:** GitHub Actions cron (nightly). Mac-independent.
- **What it does:** reports **every remote branch besides `main`** — because under ADR 0016/0017
  `main` is the only long-lived branch on any surface, so any other branch is session residue. It
  classifies each as **unmerged** (ahead of `main` — real work that risks going stale, review before
  retiring) or **merged residue** (fully merged — orphaned session litter, safe to delete), with
  ahead/behind counts. This is the cross-session, cross-surface version of the SessionStart git gate:
  the gate catches *your* unmerged work at the start of a session; this routine catches branches left
  by *any* surface (notably the web sessions that previously defaulted to a per-session `claude/*`
  branch — ADR 0017), even when no one opens a session.
- **Reports:** writes the branch report to the job Step Summary every run.
- **Acts on its own?** No. It never merges or deletes; it surfaces the list so a human-approved
  session can merge (via `merge-with-discretion`) or `clean-gone` the stale ones.
- **Why it exists:** the owner's standing rule is "address unmerged/unpushed before new work"
  (`lang/git.md`, Part 8.2). Off-session, nothing was watching for branches left behind; this does.
