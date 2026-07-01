# 0023 — Two-repo split: schnapp-vault (out of OneDrive) + one flat CI-enforced memory schema

Date: 2026-07-01. Status: DECIDED + IMPLEMENTED (streamline Phase 1). Owner-approved (Fork A + the
three infra gates). Supersedes the memory-lane home previously defined in the (now removed)
`memory/README.md`; that file's procedures moved to `docs/memory-lane.md`.

## Context
schnapp-os captured knowledge diligently but shelved it across 5+ stores (`memory/`, `decisions/`,
`handoffs/`, `PROGRESS.md`, the Obsidian vault, memory-mcp). The memory lane alone carried 3
frontmatter schemas and a DEAD supersede-check: it grepped a top-level key that the nested
`metadata:` schema had indented, so it never matched. The streamline design (see references) set
the fix: move load-bearing knowledge from SHELF to GATE, one canonical store, deterministic
enforcement at the moment of action. Revised priorities put ACCURATE and FRESH first.

## Decision
1. **Two git repos, split on the ATOMICITY line.** Anything that must commit atomically with a
   system change stays with the system: `schnapp-os` keeps rules, skills, hooks, commands, agents,
   `PLAN.md`/`PROGRESS.md`, `decisions/`, `handoffs/`, connectors, CATALOG. Cross-surface knowledge
   with no commit-coupling moves to a new PRIVATE repo `schnapp-vault` (the memory lane plus the
   Obsidian second-brain). You cannot make one atomic commit across two repos, and atomicity is what
   prevents staleness, so the seam follows it.
2. **Git is the one truth.** Nothing canonical lives outside git.
3. **The vault is OUT of OneDrive.** A git working tree under a cloud-sync engine corrupts (two sync
   engines race `.git/`). The canonical vault is `~/code/schnapp-vault` (git-native);
   `~/Documents/Obsidian` symlinks to it; the OneDrive copy is retired to an inert cold backup. Git
   already provides versioning, backup, and sync, so OneDrive's role for the vault was redundant.
4. **Consolidate by rename, not rebuild (Fork A).** The Obsidian content already existed as the git
   repo `SchnappAPI/obsidian-vault` (two clones). Rather than build a fresh vault, the empty
   `schnapp-vault` repo was deleted, `obsidian-vault` was renamed to `schnapp-vault`, and the memory
   lane was folded in. This preserves content, history, and the working clones with the least migration.
5. **One flat memory schema, single-defined in the vault `agents.md`, CI-enforced.** The flat 8-key
   frontmatter (`name, description, type, area, source, created, updated, superseded`) is defined ONCE
   in the vault `agents.md`; the README and memory-write instructions REFERENCE it, never restate it
   (3 schema-truth sources caused the drift). The dead supersede-check is FIXED:
   `scripts/check-frontmatter.sh` greps the FLAT top-level keys (the nested `metadata:` form is exactly
   why the old check was dead) and runs as the surface-independent `vault-freshness.yml` CI push-gate,
   blocking bad schema regardless of which surface wrote it.
6. **Every consumer points at the vault.** obsidian-mcp (local launchd `server.py`), the Obsidian
   Brain Agent (in-vault `.github/scripts` watcher, now resolving the vault root dynamically), and
   memory-mcp (Render, env `MEMORY_REPO`) all repoint to `schnapp-vault`. The memory-mcp GitHub token
   `SCHNAPP_OS_PAT` was granted Contents R/W on the private vault.

## Consequences
- schnapp-os no longer owns `memory/`. The global memory lane IS the vault. The memory SYSTEM
  PROCEDURES (freshness gate, end-of-session write, on-correction routing, dual-altitude promotion)
  relocated to `docs/memory-lane.md` (system behavior, not vault knowledge); the SCHEMA lives only in
  the vault `agents.md`. `autoMemoryDirectory` (project and user scope) points at
  `~/code/schnapp-vault/memory`. Every other machine needs the same one-line user-scope edit.
- Off-Mac surfaces (claude.ai, iPhone, Cowork) reach the same lane via memory-mcp, now serving the
  vault. ONE store replaces the `memory/` + OneDrive-Obsidian + memory-mcp-backing split: 5+ knowledge
  homes collapse to 2.
- Cross-repo references (a vault fact citing a schnapp-os rule) are kept resolvable by path-free
  plain-text where a relative link would break across the split.
- Known follow-up, NOT solved here: obsidian-mcp and Obsidian write the vault WORKING TREE but do not
  git-commit, so the git truth lags Obsidian edits. The vault needs an auto-commit/push mechanism (as
  memory-mcp already has). Tracked for a later phase.

## References
Spec: `docs/superpowers/specs/2026-06-30-schnapp-os-streamline-design.md` (§3, §3.5, §3.6, §10, §11).
Plan: `docs/superpowers/plans/2026-06-30-schnapp-os-streamline.md` (Phase 1).
Gate-2 execution spec: `docs/superpowers/plans/2026-07-01-gate-2-onedrive-exit.md`.
Procedures: `docs/memory-lane.md`. Vault contract + schema: `schnapp-vault/agents.md`.
