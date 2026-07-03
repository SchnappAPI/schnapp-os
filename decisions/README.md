# decisions/ - append-only ADRs (the "why")

One file per architectural decision, numbered in order (`NNNN-slug.md`). Append-only history:
never edit a past ADR to reflect new reality; a changed choice gets a NEW ADR that names what it
supersedes. The highest number is the most recent decision, not a status snapshot (status lives in
[PROGRESS.md](../PROGRESS.md) + the live plan under
[docs/superpowers/plans/](../docs/superpowers/plans/)).

To add one: next number, short kebab slug, body = context, the decision, what it supersedes or
locks, consequences. Reference ADRs from live docs by number and link; never paraphrase their
content elsewhere ([anti-stale](../rules/global/anti-stale.md)).

Load-bearing locked choices worth knowing before proposing structure changes: 0011 (subtract,
one-home-per-fact, no gallery/composer), 0016/0017 (main-only, no branches or PRs),
0023 (memory lane lives in the vault repo), 0024 (plugin packaging flattened to native
`.claude/`), 0026 (enforcement ladder: recurring error-classes escalate by proposal, never
auto-land).
