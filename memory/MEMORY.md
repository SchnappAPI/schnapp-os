# MEMORY — global lane index

Thin index for the cross-everything memory lane. One line per fact, newest-relevant
first. Conventions: [memory/README.md](README.md). Per-fact files live beside this one.

Not a dumping ground: behavioral preferences live as rules
([working-style](../plugins/core/rules/global/working-style.md)), not here. This lane
holds durable cross-surface facts and context.

## Index
- [Owner working preferences](owner-working-preferences.md) — parallelize; small reusable skills; skill-ify repetition; automate (do, don't tell); concise caveman replies; rich handoffs + copy-paste primer. (→ formalize as rules)
- [Credential leak 2026-06-17](credential-leak-2026-06-17.md) — 🔴 plaintext dump of ALL vault secrets (incl. master SA token) committed + pushed in obsidian-vault Claude Export files; every value compromised; **rotate-on-migrate** in progress. See [credentials-state](credentials-state.md).
- [Keep tracker current](keep-tracker-current.md) — flip PLAN box + PROGRESS line in the same commit as the deliverable; never claim verified before the verify ran.
- [Credentials state](credentials-state.md) — **SA TOKEN ROTATED 2026-06-22 (Phase 1 done): old SA `VU2RK…` deleted; new SA `55TZ…` (last4 `bSJ9`) propagated to zshrc/zshenv (UNQUOTED), launchd session env, 11 GH secrets, Render op-mcp; all 6 services restarted + healthy. Pending: Mac MCP client bearer (`OP_MCP_BEARER`) still unauthorized = separate. ROTATION GOTCHA still in force.** Map: [credentials-map](../credentials-map.md).
- [op-wrap token unquoted](op-wrap-token-unquoted.md) — launchd `op-wrap.sh` greps the SA token from `~/.zshrc` and strips the prefix literally (no sourcing) → token line MUST be **unquoted**, or every service crash-loops on `unrecognized auth type`. Quote bug broke all 6 services 2026-06-22.
- [Mac connector tooling](mac-connector-tooling.md) — Schnapp Mac `write_file` OVERWRITES (no append; use `shell_exec` `cat >>` / python rmw); `shell_exec` strips op identity (use `op_run` for secrets).
- [Obsidian state](obsidian-state.md) — vault canonical at OneDrive (symlink at ~/Documents/Obsidian); off-Mac obsidian = Mac-hosted server obsidian-mcp.schnapp.bet (search_notes/read_note/...), Mac-dependent; the Render connectors/obsidian-mcp is superseded.
