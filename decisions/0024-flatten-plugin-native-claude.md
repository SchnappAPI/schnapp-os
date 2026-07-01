# 0024 — Flatten the plugin into native `.claude/`

Date: 2026-07-01. Status: ACCEPTED + IMPLEMENTED (streamline Phase 2, T1-T3b). Executes
decisions/0011 #2 (repo-flattening, deferred since 2026-06-23). Relates to spec §6
(`docs/superpowers/specs/2026-06-30-schnapp-os-streamline-design.md`) and supersedes the
packaging half of decisions/0005 (hook-delivery), already superseded by decisions/0011 #2.

## Context
The repo was both its own private marketplace (`.claude-plugin/marketplace.json`) and a plugin
(`plugins/core/` + `plugin.json`), installed on the dev machine as `schnapp-os-core@schnapp-os`.
For a single-owner system this packaging was dead weight: native `.claude/` discovery +
`.claude/settings.json` hooks already delivered everything a marketplace-plugin install would.
The plugin snapshot pinned old commits (the recurring `stale-plugin-pin` class,
[[plugin-registry-snapshot-gotchas]]); and once components moved to native `.claude/`, keeping
the plugin installed would double-load skills/commands/agents (native + `schnapp-os-core:*`).
Rules were never plugin-delivered — they load via `~/.claude/CLAUDE.md` `@import` from the repo
— so only their path changes.

## Decision
Move `plugins/core/{skills,commands,agents}` → `.claude/{skills,commands,agents}`,
`{rules,scripts,hooks}` → top-level, `CATALOG.md` → repo root; delete `marketplace.json` +
`plugin.json`; rewire every executable/config reference and the `~/.claude/CLAUDE.md` `@import`
path to the native locations. The owner uninstalls the cached `schnapp-os-core@schnapp-os`
plugin and removes the user-scope `enabledPlugins` + `extraKnownMarketplaces.schnapp-os`
entries.

## Consequences
- Native discovery is the single load path: no double-load, no plugin-snapshot drift, and the
  `stale-plugin-pin` recurrence class is deleted (not gated — the cause is gone, per spec §4.3).
- Rules stay `@import`-from-repo (unchanged mechanism; only the path moved to `rules/global/`).
- Per-MACHINE owner action is required and non-optional: edit `~/.claude/CLAUDE.md` (the 7
  `@import` lines → `rules/global/`), `claude plugin uninstall schnapp-os-core@schnapp-os`, drop
  the two user-scope settings entries, and re-render + reload the 2 launchd plists (their
  installed copies bake the old `plugins/core/scripts/` path). Until a machine does this, its
  `@import` breaks on pull and its sessions double-load — so the flatten lands per machine, not
  globally at once.
- The repo is no longer a marketplace; the share-it-later seam is kept clean and deferred
  (spec §12).

## References
Spec: `docs/superpowers/specs/2026-06-30-schnapp-os-streamline-design.md` (§6, §12).
Plan: `docs/superpowers/plans/2026-06-30-schnapp-os-streamline.md` (Phase 2, T1-T5).
Repo work: T1 (c96783b), T2 (3e1c446), T3 (7f300bc), T3b (5f29a72). Prior packaging decision:
decisions/0005. Deferral + reframing: decisions/0011 #2.
