# Routine: sync / unmerged check

- **Class:** safe (auto) — read-only.
- **Scheduler:** GitHub Actions cron (nightly). Mac-independent.
- **What it does:** reports remote branches that are **ahead of `main` but not merged** (unmerged
  work that risks going stale) and how far ahead/behind each is. This is the cross-session,
  cross-surface version of the SessionStart git gate: the gate catches *your* unmerged work at the
  start of a session; this routine catches work left on *any* branch by *any* surface, even when no
  one opens a session.
- **Reports:** writes the branch report to the job Step Summary every run.
- **Acts on its own?** No. It never merges or deletes; it surfaces the list so a human-approved
  session can merge (via `merge-with-discretion`) or `clean-gone` the stale ones.
- **Why it exists:** the owner's standing rule is "address unmerged/unpushed before new work"
  (`lang/git.md`, Part 8.2). Off-session, nothing was watching for branches left behind; this does.
