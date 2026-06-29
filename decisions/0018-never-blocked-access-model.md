# 0018 — Never-blocked access model: global allowlist + defined git-write path

Date: 2026-06-29. Status: DECIDED (defaults; owner to confirm the two marked choices).

## Context
The 2026-06-29 session hit three separate access blocks in one task: (1) the Mac MCP host
`mac-mcp.schnapp.bet` was not on the environment's network allowlist (proxy 403); (2) the cloud
env's git relay is read-only (`git push` 403), so commits + branch deletes could not be done locally;
(3) `AskUserQuestion` and the Mac MCP connection were intermittently unavailable. The owner's standing
goal: *neither the owner nor Claude should ever be unable to do the requested job because something
was not configured or allowed*, and *every surface should work off the same data, tools, and rules.*

## Decision
1. **One canonical access spec.** `docs/environment-and-access.md` is the single source of truth for
   the required network allowlist, the git-write path, the known platform limits + workarounds, and
   the cross-surface delivery map. Future environments are configured from it.
2. **Network allowlist (per-environment, applied identically everywhere).** Allow the explicit host
   set in that doc §1 (all `*.schnapp.bet`, the Render hosts, GitHub, Quickbase, MS Graph). Default =
   **explicit list** (tightest security). *Owner choice:* explicit vs broad/unrestricted.
3. **Git-write path.** Cloud env git is read-only; writes go through, in order: (a) a writable-git
   token for the environment if the platform allows it [*owner choice / preferred*]; else (b) the Mac
   (`Schnapp_Mac` `shell_exec`, full git incl. branch delete + mode-preserving); else (c) the GitHub
   MCP API (no Mac dependency, but drops file modes and cannot delete branches).
4. **Global-first.** Tools/data/rules are delivered from the repo (`.mcp.json`, global rules,
   `autoMemoryDirectory`) so they are identical across surfaces. The **network allowlist is the only
   per-surface step** and must be replicated on every environment.

## Why
- Turns "blocked" from a silent dead-end into a one-line config fix located in a known place.
- Removes the per-surface drift that forces new sessions and breaks the "same everywhere" goal.
- Keeps the read-only-git safety default while giving a defined, reliable write path.

## Consequences
- New/changed environments must apply the doc §1 allowlist (owner step; not repo-enforceable).
- Refines `surfaces/README.md` (always-complete model) with the concrete config behind it.
- Open owner confirmations: allowlist breadth (§2) and git-write model (§3). Recorded as defaults
  until the owner says otherwise. Related: ADR 0017 (web→main), [[mac-cloud-access]], [[environment-access]].
