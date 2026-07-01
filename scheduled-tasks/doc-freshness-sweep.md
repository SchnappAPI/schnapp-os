# Routine: doc-freshness sweep

- **Class:** safe (auto) — read-only.
- **Scheduler:** GitHub Actions cron (nightly). Mac-independent.
- **What it does:** runs [`scripts/check-freshness.sh`](../scripts/check-freshness.sh)
  against the whole repo: regenerates the projection of the component files under `.claude/` +
  top-level `rules/`/`hooks/`/`scripts/` and fails if the committed
  `CATALOG.md` is stale, and checks any `last-verified:` doc whose source changed after its
  verification date. This is the same gate CI runs on push — the cron run catches drift that lands
  on `main` between pushes (e.g. a manual edit, or a merge that skipped regeneration).
- **Reports:** writes the gate output to the job Step Summary every run.
- **Acts on its own?** No mutation. On drift it exits non-zero (visible failure); the fix
  (re-run `gen-catalog.sh`, commit) is done by a human-approved session, never auto-committed.
- **Why it exists:** anti-staleness is a standing schnapp-os invariant (global rule
  `anti-stale.md`); the nightly sweep enforces it continuously, not only at push time.
