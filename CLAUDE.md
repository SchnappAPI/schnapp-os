<!--
  Project front door for an agent working IN schnapp-os. THIN and reference-only: it points at
  canonical sources, it never copies them (anti-stale: one fact, one source). Built from this
  repo's own templates/project-CLAUDE.md so it matches the convention shipped to other projects.
-->
# schnapp-os

Central, multi-surface Claude system: rules, skills, commands, hooks, agents, memory, and
credential references, used across Claude Code (all machines), Cowork, and claude.ai. **One source
of truth. No duplication. Nothing siloed. References to secrets, never values.** This repo is also
the *source* of the machine-wide global lane, so a change here ripples into every project on the
machine. Map: [README.md](README.md). Durable why: [docs/framework.md](docs/framework.md).

## Rules in effect

**Global rules**: the always-on global rules (listed in [CATALOG.md](CATALOG.md)) already load in
this repo (and every repo on the machine) via `~/.claude/CLAUDE.md`, which `@import`s them from here. Do **not** re-import them below - that
double-loads. Canonical source (edit here, never in `~/.claude/`):
[rules/global/](rules/global/).

**Path-scoped modules**: an on-demand reference library at
[rules/modules/](rules/modules/) (`lang/ tool/ activity/ coding/
context/`). Nothing is force-loaded at the repo root; pull a module in only when a task needs it.
Full inventory + scopes: [CATALOG.md](CATALOG.md) (generated).

**Skills in reach**: schnapp-os's own skills/agents are plugin-global. The ones most relevant when
working *in this repo*: `status`, `session-hygiene`, `surface-check`, `rules-distill`, `learn-route`,
`update-docs`, `update-codemaps`. Full set: [CATALOG.md](CATALOG.md).

## Project lane (schnapp-os-specific invariants - the one place they live)

These are the non-obvious rules for working *on the system itself*. All point at the owner; none
restate mutable state.

- **This repo IS the global lane's source.** Edit rules in
  [rules/global/](rules/global/), never in `~/.claude/CLAUDE.md`. If the
  global rule *set* changes, update [templates/user-global-CLAUDE.md](templates/user-global-CLAUDE.md)
  and every machine's `~/.claude/CLAUDE.md` together (the `@import` list is explicit, no globs).
- **State-change discipline (anti-stale).** Every state-changing commit flips the matching box in
  the live per-initiative plan doc (under [docs/superpowers/plans/](docs/superpowers/plans/)) **and**
  appends a [PROGRESS.md](PROGRESS.md) line in the **same commit**, then pushes immediately so
  GitHub mirrors local. Partial work is `[~]`, never `[x]`. See
  [anti-stale.md](rules/global/anti-stale.md) and `[[keep-tracker-current]]` in memory.
- **Status lives in the trackers, not in prose.** Never hardcode progress/counts into a doc; read
  [PROGRESS.md](PROGRESS.md) plus the live plan doc. ([PLAN.md](PLAN.md) is a retired pointer, not
  status.) The README and this file carry no status string.
- **Main only. Always merge; never leave a branch.** No feature branches or PRs for directed work
  ([decisions/0016](decisions/0016-no-branches-precommit-gate.md),
  [decisions/0017](decisions/0017-web-sessions-target-main.md)). Run a local review pass, then push.
  A cloud session that ARRIVES pinned to a `claude/*` branch (the entry point's config sets this
  before Claude runs; its git proxy blocks other branches) merges its PR to main the moment checks
  are green - GitHub auto-deletes the head branch on merge - and never ends unmerged. Committing to
  main via the GitHub API is the sanctioned bypass for owner-directed follow-ups from such a
  session. Per-session `claude/*` branches are the PLATFORM default (verified 2026-07-18: the
  environment config exposes no branch field), not an owner misconfiguration - do not flag it;
  merge-on-green is the standing mitigation. If the new-session dialog offers a branch choice,
  the owner picks `main`.
- **Generated docs are regenerated, never hand-edited.** [CATALOG.md](CATALOG.md)
  comes from [scripts/gen-catalog.sh](scripts/gen-catalog.sh). A CI gate
  ([.github/workflows/freshness.yml](.github/workflows/freshness.yml)) fails the push if it is stale
  or a `last-verified` doc's source changed after it.
- **Global memory lane lives in the vault** (`~/code/schnapp-vault`, repo `SchnappAPI/schnapp-vault`),
  not schnapp-os. Procedures (freshness gate, end-of-session write, on-correction routing):
  [docs/memory-lane.md](docs/memory-lane.md). Schema: the vault's `agents.md`. **Supersede, do not
  append:** when a fact changes, replace it; never leave a contradicting copy. Personal/debugging notes
  go to the vault memory lane, not into project files.
- **Secrets are `op://` references, never values** ([secrets-as-references.md](rules/global/secrets-as-references.md)).
  New env vars go in [.env.template](.env.template) as `op://` URIs. Reference map (refs only):
  [credentials-map.md](credentials-map.md). Spot a hardcoded credential: stop and flag it.
- **Hooks**: project wiring in [.claude/settings.json](.claude/settings.json) (SessionStart
  freshness gate, Stop push-gate, SessionEnd backup, force-push guard, write guards); ANY-REPO
  wiring at user scope via the portable shell ([shell/](shell/), ADR
  [0033](decisions/0033-portable-shell-user-scope-wiring.md)) - full map in
  [hooks/README.md](hooks/README.md). Treat a
  non-Code surface as hookless until verified; run the must-happen steps via `session-hygiene`.
- **Decisions are append-only history** in [decisions/](decisions/) (one ADR per choice). Resume
  point for any session is the newest, highest-numbered file in [handoffs/](handoffs/).

<!-- Per-connector CLAUDE.md files are intentionally absent: connectors/ each carry their own
     README.md + DEPLOY.md, and more instruction files would invite drift. Keep to this one. -->
