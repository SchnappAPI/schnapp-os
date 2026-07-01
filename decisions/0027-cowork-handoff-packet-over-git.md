# 0027 - Cowork two-way handoff rides git: the handoff packet

Date: 2026-07-01. Status: DECIDED (streamline Phase 5, T2/T4). Realizes the design spec's Domain 5
([docs/superpowers/specs/2026-06-30-schnapp-os-streamline-design.md](../docs/superpowers/specs/2026-06-30-schnapp-os-streamline-design.md) §7).
Builds on decisions/0023 (two-repo split) and 0024 (flatten deleted the plugin channel).

## Context
Code and Cowork must hand work off with no lost state. Cowork is hookless and shell-less
(surface-check, two sessions, 2026-06-16): no local git, no scripts, none of schnapp-os's hooks.
The Phase-2 flatten deleted the plugin/marketplace channel Cowork once auto-synced, and the vault
never was a plugin. The one CONFIRMED capability shared by every surface is the two git repos,
reachable from Cowork through the GitHub connector (github leg = github-mcp, authenticated with
the all-repos `GITHUB_PAT`). Whether Cowork reaches `memory-mcp` or project `.mcp.json` servers
is unverified at decision time.

## Decision
- **State rides git, nothing else.** The handoff unit is the **handoff packet**, defined once in
  [docs/memory-lane.md](../docs/memory-lane.md) "Handoff packet (cross-surface resume)":
  write-on-stop = the end-of-session write (working-memory facts to the vault + the newest
  `handoffs/NNN` + current indexes + the PROGRESS line + the plan-doc box, BOTH repos pushed);
  read-on-start = the freshness gate (newest handoff, MEMORY.md, the git gate). Same packet on
  every surface; only the transport differs.
- **Transport.** Code = local git + the hooks (automatic). Hookless = the GitHub connector, run
  by hand via the `session-hygiene` skill: read-modify-write whole-file commits; the connector
  commit IS the push.
- **Generated-index emulation** (the one sanctioned deviation from "regenerated, never
  hand-edited"): a shell-less writer updates `handoffs/README.md` by emulating
  `scripts/gen-handoff-index.sh` output byte-for-byte (insert its own line newest-first, move
  the resume-point suffix). The generator stays canonical: `check-freshness.sh` diffs the
  committed index against a fresh regen on the next push, so an emulation slip fails CI
  (fail-closed) instead of rotting.
- **memory-mcp validated writes = optional upgrade, not the base.** The packet requires zero
  unverified Cowork capability. If the owner probe shows Cowork reaches memory-mcp (portal
  memory leg or `.mcp.json`), schema-validated `memory_*` writes become the front-line for the
  vault memory leg; connector file writes remain the floor and the fallback.

## Consequences
- Any surface that can read/write the two repos can stop and resume work; no bespoke sync
  channel to build, secure, or keep fresh.
- Hookless writes are slower (one read-modify-write per file) and follow the vault schema by
  hand; vault CI + freshness CI catch violations on push - surface-independent enforcement,
  rung 4 of the decisions/0026 ladder.
- The acceptance test is the round-trip Code → Cowork → Code with nothing lost; runbook and
  state: [handoffs/049](../handoffs/049-phase-5-cowork-packet-repo-side.md) and the plan doc.

## Alternatives considered
- **Plugin auto-sync as the channel** - gone: the flatten removed the plugin (0024); the vault
  never was one.
- **memory-mcp as the base path** - unverified from Cowork; would block the phase on a probe.
  Kept as the upgrade.
- **A bespoke sync/export channel** - rejected: a second source of truth; violates
  git-is-the-one-truth (0023).
- **Letting `handoffs/README.md` go stale after a hookless write** - rejected: breaks the
  CI-green + anti-stale discipline; emulation + the CI diff keeps the generator canonical
  without needing a shell.

## References
Spec §7; decisions/0016 (main-only), 0023, 0024, 0026. Packet: docs/memory-lane.md. Hookless
transport: `.claude/skills/session-hygiene/SKILL.md`. Surface: surfaces/cowork.md. Runbook:
handoffs/049.
