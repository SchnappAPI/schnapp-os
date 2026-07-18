# 0040: Plugin parity across surfaces via committed manifest + installer sync

Date: 2026-07-18
Status: Accepted
Refines: 0024 (no plugin packaging of schnapp-os itself - unchanged), 0033 (portable shell)

## Context

Third-party and Anthropic marketplace plugins (superpowers, caveman, code-review,
compound-engineering, and ~18 more) were installed only on the Mac's ~/.claude. Cloud/web
environment sessions bootstrap the portable shell (ADR 0033: rules, skills, hooks, agents,
memory all wire to the live clones) but got NONE of the plugin-provided skills, so surfaces
behaved differently. Owner 2026-07-18: "Unless I build one specific to a repo, I want to
always work from the same rules/hooks/skills/agents/etc."

ADR 0024 rejected packaging schnapp-os's OWN components as a plugin; that stands. This is the
inverse problem: keeping the externally-sourced plugin set identical everywhere.

## Decision

1. The Mac's enabled plugin set is the source of truth. `scripts/gen-plugins-manifest.sh`
   projects it (enabled only, plus their marketplaces) into `shell/plugins-manifest.txt`,
   a generated committed file. Run it after any plugin install/remove on the Mac.
2. `shell/sync-plugins.sh` converges any surface to the manifest: adds missing marketplaces,
   installs/enables missing plugins via the `claude plugin` CLI. Additive only (extras are
   never auto-uninstalled), idempotent, always exits 0.
3. `shell/install.sh` runs the sync as its layer 4, so every surface that bootstraps the
   portable shell (Mac install, web-setup.sh at environment init) also converges plugins.

## Consequences

- Same skill/command/agent surface everywhere the shell installs. Web environments converge
  at environment init (result cached ~7 days), so a plugin added on the Mac reaches cloud
  sessions on the next container re-init, not the next session. Acceptable lag; re-run
  web-setup (or `bash ~/code/schnapp-os/shell/sync-plugins.sh` in-session, effective next
  session) to force it.
- Marketplace fetches need github.com reachable in the environment allowlist (already
  required by web-setup for the clones).
- Plugin context cost now applies on every surface; prune the manifest by disabling on the
  Mac and regenerating, per the context-budget skill.
- Version pinning is NOT solved here: surfaces may hold different plugin versions until
  their next marketplace update (the stale-pin gotcha in memory/plugin-registry-snapshot-gotchas
  remains). Parity is set-level, not commit-level.
