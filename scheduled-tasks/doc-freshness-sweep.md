# Routine: doc-freshness sweep

- **Class:** safe (auto) — read-only.
- **Scheduler:** GitHub Actions cron (nightly). Mac-independent.
- **What it does:** runs [`plugins/core/scripts/check-freshness.sh`](../plugins/core/scripts/check-freshness.sh)
  against the whole repo: regenerates the projection of `plugins/core/` and fails if the committed
  `CATALOG.md` is stale, and checks any `last-verified:` doc whose source changed after its
  verification date. This is the same gate CI runs on push — the cron run catches drift that lands
  on `main` between pushes (e.g. a manual edit, or a merge that skipped regeneration).
- **Reports:** writes the gate output to the job Step Summary every run.
- **Acts on its own?** No mutation. On drift it exits non-zero (visible failure); the fix
  (re-run `gen-catalog.sh`, commit) is done by a human-approved session, never auto-committed.
- **Why it exists:** anti-staleness is a standing claude-kit invariant (global rule
  `anti-stale.md`); the nightly sweep enforces it continuously, not only at push time.
