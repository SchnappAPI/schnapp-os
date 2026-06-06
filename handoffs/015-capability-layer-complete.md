# Handoff 015 — Capability layer (C.0–C.3) COMPLETE (supersedes 014). Tracker + docs current.

Date: 2026-06-05.

## TL;DR — what to do next session
The **Capability layer is done**: the locked C.1 set is built, the ~14 archive ports are in,
docs-lookup is built (Obsidian-pointed), and presets name every skill. Next is **Part 10**
(package the plugin + wire the other surfaces), then **Part 11** (agentic OS), then the final
14-point sweep. Pause here was a phase boundary; resume at Part 10.

## Done this session (C.0 → C.3, all [x])
Built lean, house-style, in three pushed commits (`20870c8`, `890b60f`, `b7d65d0`):

**C.1 new GAP components (7):**
- skills: `etl-pipeline-build` (Python ETL → SQL Server: staged MERGE + fast_executemany +
  op:// env + Actions cron), `sql-server-patterns` (T-SQL 2022 dialect guardrails / idempotent
  schema / set-based / TRY-CATCH / 2022 features), `quickbase` (JSON API v1 query/paginate/
  rate-limit/FID-map), `appfolio` (Reporting API custom-report pull + column-drift guard; scoped
  to GENERAL integration, defers reconciliation to `fish-compare`).
- commands: `/update-docs`, `/update-codemaps` (generic derived-doc + codemap generators for the
  owner's OTHER ETL repos, not claude-kit).
- agent: `sql-etl-reviewer` (read-only; idempotency/partial-write/set-based/fast_executemany/
  injection/boundary-validation/secrets/naming/dialect; caveman-reviewer finding format). Created
  `plugins/core/agents/`.
- rewired `tool/quickbase` + `tool/appfolio` rule stubs to point at the new skills.

**C.1 archive ports (~14, via 6 parallel subagents, ECC-isms stripped):** `grill-me`,
`grill-with-docs`, `council`, `rules-distill` (scripts dropped; distill targets rewired to
rules/+memory/+decisions/), `data-throughput-accelerator`, `latency-critical-systems`,
`content-hash-cache-pattern`, `benchmark`, `benchmark-optimization-loop`, `cost-aware-llm-pipeline`,
`regex-vs-llm-structured-text`, `token-budget-advisor`, `context-budget`, `strategic-compact`
(skills); `performance-optimizer` (agent, refocused 455→62 lines onto Python/SQL stack);
`clean-gone` (command).

**docs-lookup:** authored, points at the OBSIDIAN vault (filesystem `obsidian` MCP on the Mac:
`search-vault`/`read-note`; the remote `connectors/obsidian-mcp` off-Mac: `vault_search`/`vault_read`).
Explicitly NOT context7 (context7 stays for external library docs).

**C.2 presets:** `presets.md` now names recommended skills per preset (human list + machine-readable
`skills:` map) incl. the HAVE skills (pq-flat-map-type, `data:*`, sports-data-auditor/fish-compare/
xlsx, deep-research, docs-lookup); template got a "Skills in reach" slot; `/new-project` fills it.

**C.3:** schnapp-kit stays the on-demand archive (only the locked checked set was pulled; the
~25-component session/memory cluster deliberately NOT ported — claude-kit replaces it).

**Totals now:** 22 skills · 2 agents · 4 commands (was 3 skills / 0 agents / 1 command).
Verification: every skill frontmatter = `name`+`description` only; 0 ECC-isms repo-wide; all
relative md links resolve; agent frontmatter correct (`tools` array + `model: sonnet`). CATALOG
regenerated each commit; freshness gate green throughout.

## What's next — Part 10 (package + wire surfaces)
1. **Package the plugin:** `.claude-plugin/marketplace.json` + `plugins/core/.claude-plugin/plugin.json`
   (skills/commands/agents auto-discover by directory; hooks via the existing `hooks/hooks.json`).
   Install in Code as a marketplace plugin so the PLUGIN delivers the global gate+push-gate
   everywhere (`${CLAUDE_PLUGIN_ROOT}`), then **REMOVE those two hooks from project
   `.claude/settings.json`** to avoid double-fire, keeping ONLY the backup (decisions/0005).
   EXPLICIT owner approval before the settings.json change.
2. **Wire the other surfaces:** connect the repo in Cowork; add core + domain skills and the
   op-mcp connector in claude.ai + iPhone; enable `session-hygiene` / `surface-check` per surface
   (closes 7.3/7.4/7.5 enablement).
3. Then Part 11 (scheduler / `/do` orchestrator / `status` control plane), then the final
   14-point verification sweep.

## Open / pending (owner-gated, NOT blocking Part 10's package step)
Carried from handoff 014, still open:
1. `~/.git-credentials` hygiene — plaintext token remains (PAT was rotated, leak neutralized);
   recommend `rm ~/.git-credentials` + `git config --global credential.helper osxkeychain`.
2. obsidian-git reauth in the Obsidian GUI post-PAT-rotation (syncs `claude-archive/` to GitHub).
3. Deploy `connectors/obsidian-mcp` (Render + Cloudflare + two op:// secrets — use a fine-grained
   Contents:read-only token for `GITHUB_TOKEN`). Until then docs-lookup off-Mac falls back to the
   GitHub copy / claude-kit's own `memory`+`decisions`.
4. Retire the redundant `~/code/obsidian-vault` clone (confirm before removing).
5. Broader vault-consolidation workstream (scope it; avoid a 4th overlapping store).

## Gotchas (carry forward)
- **CATALOG is generated.** After any rule/skill/command/hook change run
  `plugins/core/scripts/gen-catalog.sh` and commit `plugins/core/CATALOG.md` (freshness CI enforces).
  Connectors (op-mcp/obsidian-mcp) are NOT in CATALOG.
- Hooks/settings load at session start; `~/.claude` / settings.json / secret changes need
  **explicit** owner approval.
- `${CLAUDE_PLUGIN_ROOT}` is the only portable global HOOK delivery (Part 10); `autoMemoryDirectory`
  is user-settings only (already set, README install step).
- Build only the gap; compose what exists; don't recreate the schnapp-kit sprawl.
- zsh does not word-split unquoted vars — use arrays/globs in repo scripts/checks.
- Em dashes: the repo (incl. PLAN.md + existing skills) uses them; the "no em dashes" rule
  governs chat voice, not repo artifacts.

## Locked finish order (unchanged)
Foundation verify ✅ → C.1 build ✅ → C.2 presets ✅ → C.3 archive ✅ → **Part 10 package + wire
surfaces (NEXT)** → Part 11 agentic OS → final 14-point sweep.

## Resume prompt
"Resume claude-kit. Working dir `~/code/claude-kit`. Read PLAN.md ('Finish sequence', 'Capability
layer', 'Part 10', 'Part 11'), PROGRESS.md, decisions/0005 (hook-delivery split) and 0007, and
handoffs/015-capability-layer-complete.md FIRST — tracker + docs current. The Capability layer
(C.0–C.3) is DONE: the full domain capability set is built (22 skills / 2 agents / 4 commands),
ported lean, cataloged, and named in presets. NEXT: Part 10 — package the marketplace plugin
(`.claude-plugin/marketplace.json` + `plugins/core/.claude-plugin/plugin.json`; components
auto-discover, hooks via hooks.json), install in Code so the PLUGIN delivers the global
gate+push-gate via `${CLAUDE_PLUGIN_ROOT}`, then strip those two hooks from project
`.claude/settings.json` keeping only the backup (decisions/0005, EXPLICIT owner approval). Then
wire Cowork/claude.ai/iPhone + per-surface skill enablement (closes 7.3/7.4/7.5), then Part 11
(scheduler / `/do` / `status`), then the final 14-point sweep. Owner-gated leftovers (non-blocking):
`~/.git-credentials` cleanup, obsidian-git reauth, deploy connectors/obsidian-mcp, retire the
redundant ~/code/obsidian-vault clone, vault consolidation. Binding rules: think in systems / trace
ripple; build only the gap, compose what exists; verify load-bearing assumptions first; fix the
class not the instance; keep-tracker-current (flip box + PROGRESS line + push every change;
gen-catalog after any rule/skill/command/hook change); explicit owner approval before any ~/.claude
/ settings.json / secret change. Act autonomously; pause at Part boundaries."
