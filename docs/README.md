# docs/ - durable docs vs frozen snapshots

Two kinds live here; do not confuse them.

**Live (current-state, kept true):**
- [framework.md](framework.md) - the durable "why" of the whole system.
- [memory-lane.md](memory-lane.md) - memory procedures (freshness gate, end-of-session write,
  on-correction routing). The lane itself lives in the vault repo.
- [environment-and-access.md](environment-and-access.md) - network allowlist, git-write paths,
  per-surface delivery.
- [headless-claude-auth.md](headless-claude-auth.md) - credential runtime for unattended runs.
- [superpowers/](superpowers/) - live per-initiative plans + design specs
  ([superpowers/README.md](superpowers/README.md)).

**Frozen (dated point-in-time; never updated, read as history only):**
- `*-2026-*.md` dated files (repo reviews, research notes, intent capture, credentials
  archaeology). Like [handoffs/](../handoffs/) and [decisions/](../decisions/): append-only
  history, exempt from freshness gates.
- [archive/](archive/) - rotated PLAN/PROGRESS eras.
