# Handoff 014 — C.1 set locked + Obsidian mirror/MCP built (supersedes 013). Tracker + docs current.

Date: 2026-06-05.

## TL;DR — what to do next session
**Build the C.1 capability set** (locked + owner-confirmed in `decisions/0007`). Nothing in it is built yet.
Then C.2 (presets + CATALOG) → C.3 (archive) → Part 10 → Part 11 → final sweep. Foundation verify is DONE;
the Obsidian mirror + remote MCP were built this session (owner-requested side track) and only their
deploy/owner-GUI steps remain.

## Done this session
- **Foundation verify (PLAN 2.4/3.4/5.6) → [x]** via live `claude -p` in a real second repo. Load-bearing
  fix: the global memory lane needs `autoMemoryDirectory` at USER scope (plugins can't deliver it) — added
  to `~/.claude/settings.json` (owner-approved), now a README install step. Detail in handoff 013 + PROGRESS.
- **C.0 capability inventory → recorded in `decisions/0007`** (rewritten to one checkbox per item, 3 plain
  statuses GAP/HAVE/SKIP). Owner went through it and **locked the build/keep set** (below).
- **Obsidian Part A (vault contains claude-archive) → DONE.** `backup-archive.sh` now DUAL-mirrors the
  knowledge md into `$OBSIDIAN_VAULT_DIR/claude-archive/` (default `~/Documents/Obsidian`) as well as
  OneDrive. Ran it; vault populated. obsidian-git pushes it to `SchnappAPI/obsidian-vault`.
- **Obsidian Part B (off-Mac vault access) → BUILT + LOCALLY VERIFIED.** `connectors/obsidian-mcp/` — a
  read-only remote MCP (op-mcp-style) that serves the vault from a git copy (no Obsidian app / Local REST
  API needed). Tools: vault_search/read/list/health. tsc-strict clean; logic + path-escape guard + boot +
  bearer 401 + MCP initialize handshake all verified locally. Deploy is owner-gated (Render + Cloudflare +
  two op:// secrets — `connectors/obsidian-mcp/DEPLOY.md`).
- **Security:** found + removed a hardcoded GitHub PAT from `~/Documents/Obsidian/.git/config` (switched
  that remote to SSH; verified 0 tokens + SSH fetch). **Owner has ROTATED the PAT.**
- Corrected the earlier mis-diagnosis in docs: the obsidian MCP is the FILESYSTEM `obsidian-mcp` npm pkg
  (reads `~/Documents/Obsidian` directly), NOT the Local REST API kind — PLAN 6.2/6.3 updated.

## The locked C.1 set (from decisions/0007 — build these)
**Build new (7):** `etl-pipeline-build` (skill), `sql-server-patterns` (skill), `/update-docs` (cmd),
`/update-codemaps` (cmd), `sql-etl-reviewer` (agent), `tool/quickbase` (skill), `tool/appfolio` (skill —
scope to GENERAL AppFolio integration; point to the existing `fish-compare` skill for reconciliation, don't
duplicate it).
**Pull from schnapp-kit archive, adapted lean (~12):** rules-distill; grill-me; grill-with-docs; council;
regex-vs-llm-structured-text; data-throughput-accelerator; latency-critical-systems; benchmark +
benchmark-optimization-loop + performance-optimizer; content-hash-cache-pattern; cost-aware-llm-pipeline;
clean-gone; token-budget-advisor + context-budget + strategic-compact. (Owner chose "keep everything I
checked" — I flagged a few as generic/low-domain-fit but the owner kept them; respect that.)
**Name in presets at C.2 (already HAVE, just list them):** pq-flat-map-type, the `data:*` suite,
sports-data-auditor/xlsx/fish-compare, deep-research, and **docs-lookup**.
**docs-lookup decision (owner):** point it at the OBSIDIAN VAULT, not context7. On Code, read the vault
files directly (`~/Documents/Obsidian`, or via the filesystem obsidian MCP); off-Mac, use the new
`connectors/obsidian-mcp` remote MCP. Build docs-lookup as a thin skill over those.

## Open / pending (owner-gated or owner-GUI)
1. **`~/.git-credentials` hygiene** — still holds a plaintext GitHub token; global `credential.helper=store`.
   The PAT was rotated (leak neutralized) but the plaintext store remains. Recommend: `rm ~/.git-credentials`
   + `git config --global credential.helper osxkeychain` (SSH already covers GitHub). NOT done — needs
   explicit owner OK (the rm auto-blocked; owner wrapped up before approving).
2. **obsidian-git reauth** — after the PAT rotation, re-enter auth in the Obsidian obsidian-git plugin (GUI)
   so the vault auto-syncs (incl. the new `claude-archive/` folder + 11 local commits) to GitHub.
3. **Deploy `connectors/obsidian-mcp`** — Render Blueprint + Cloudflare portal + the two op:// secrets
   (`connector_auth_token`, `vault_read_token` = fine-grained PAT, Contents:read on the vault repo only).
4. **Retire the redundant clone** `~/code/obsidian-vault` (it equals origin; `~/Documents/Obsidian` is the
   canonical superset). Deletion not done autonomously — confirm before removing.
5. **Knowledge-vault consolidation (bigger workstream, owner raised):** the owner wants ref-vault/obsidian
   to hold ALL context from repos/projects/chats/sessions. Partially served now (claude-archive mirrored in).
   The full "ingest every repo/project/chat" is NOT built — and there are 3+ stores (ref-vault, obsidian-vault,
   OneDrive claude-archive) + the memory lane. Treat as a deliberate, scoped design task (avoid a 4th store).

## Gotchas (carry forward)
- **CATALOG is generated.** After adding/removing any rule/skill/command/hook (the C.1 builds WILL), run
  `plugins/core/scripts/gen-catalog.sh` and commit `plugins/core/CATALOG.md` (freshness CI enforces it).
  Connectors are NOT in CATALOG (op-mcp/obsidian-mcp don't appear there). Keep the generator mawk-safe.
- Hooks/settings load at session start; `~/.claude` / settings.json changes need **explicit** owner approval.
- `${CLAUDE_PLUGIN_ROOT}` is the only portable global HOOK delivery (Part 10); `autoMemoryDirectory` is user
  settings only (not plugin-deliverable).
- Connector deploys mirror op-mcp: Render free Blueprint (rootDir-relative dockerfilePath), Cloudflare MCP
  portal with static-bearer "Custom headers", own Allow policy, ~50s cold start.
- Build only the gap; compose what exists; the session/memory cluster of schnapp-kit is deliberately NOT
  ported (claude-kit replaces it). Don't recreate sprawl.

## Locked finish order (unchanged)
Foundation verify ✅ → **C.1 build (NEXT)** → C.2 presets + CATALOG → C.3 archive → Part 10 package + wire
surfaces (plugin delivers global hooks per 0005, then strip the dup from project settings.json — explicit
owner approval) → Part 11 agentic OS → final 14-point sweep.

## Resume prompt
"Resume claude-kit. Working dir `~/code/claude-kit`. Read PLAN.md ('Finish sequence' + 'Capability layer'),
PROGRESS.md, decisions/0007 (the locked capability set), and handoffs/014-capability-set-locked-and-obsidian.md
FIRST — tracker + docs current. Foundation verify + the C.0 inventory are DONE; the Obsidian vault mirror
(backup-archive.sh dual-mirror) and the off-Mac `connectors/obsidian-mcp` remote MCP are BUILT + locally
verified (deploy owner-gated). NEXT: build the locked **C.1** set from decisions/0007 — build
`sql-server-patterns`, `etl-pipeline-build`, `/update-docs`, `/update-codemaps`, `sql-etl-reviewer`,
`tool/quickbase`, `tool/appfolio` (scope appfolio to general integration, defer reconciliation to
fish-compare); port lean the ~12 checked archive skills; build a `docs-lookup` skill pointed at the Obsidian
vault (filesystem on Mac, the new remote MCP off-Mac), NOT context7. Each new component: catalog it
(gen-catalog.sh → commit CATALOG.md, CI enforces) + slot it into a preset. Then C.2 (extend presets, name the
HAVE skills: pq-flat-map-type/data:*/sports-data-auditor/xlsx/fish-compare/deep-research) → C.3 (schnapp-kit
stays the archive) → Part 10 → Part 11 → final sweep. Owner-gated leftovers from last session:
`~/.git-credentials` plaintext-token cleanup (rm + osxkeychain), obsidian-git reauth post-PAT-rotation, deploy
connectors/obsidian-mcp, retire the redundant ~/code/obsidian-vault clone, and the broader vault-consolidation
workstream. Binding rules: think in systems / trace ripple; build only the gap, compose what exists; verify
load-bearing assumptions first; fix the class not the instance; keep-tracker-current (flip box + PROGRESS +
push every change; gen-catalog after any rule/skill/command/hook change); explicit owner approval before any
~/.claude / settings.json / secret change. Act autonomously; pause at Part boundaries."
