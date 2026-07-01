# Gate 2 — OneDrive exit + repoint (execution spec)

**Date:** 2026-07-01. **For:** the Phase-1 execution session. **Status:** ready — every path verified live on the Mac 2026-07-01. Execute top-to-bottom; do NOT re-decide. If a PRE-FLIGHT check fails, STOP and report — do not improvise.

## Context (verified — do not re-discover)
- Gate 1 done: `obsidian-vault` renamed → `SchnappAPI/schnapp-vault`, cloned to `~/code/schnapp-vault` (full Obsidian content + design scaffold + normalized flat-schema memory lane, 0 nested `metadata:`, 0 missing `updated:`). `check-frontmatter.sh` + `vault-freshness.yml` present.
- **Canonical vault = `~/code/schnapp-vault`.** The OneDrive vault (`~/Library/CloudStorage/OneDrive-Schnapp/Obsidian`) is STILL LIVE and still what every consumer points at → DRIFT RISK until this gate closes it. Until done: do NOT edit either vault; keep Obsidian CLOSED.
- Obsidian opens `~/Documents/Obsidian`, a SYMLINK currently → the OneDrive vault.

## Complete repoint surface (every LIVE OneDrive hardcode; archives excluded)
| # | Consumer | File / key | New value |
|---|----------|-----------|-----------|
| 1 | obsidian-mcp | `~/obsidian-mcp/server.py:36` (`VAULT = ...`) | `VAULT = Path.home() / "code/schnapp-vault"` (line 37 `INDEX = VAULT/"_brain/_index.json"` then still resolves) |
| 2 | brain-watcher | `~/Library/LaunchAgents/com.schnapp.brain-watcher.plist` → ProgramArguments[2] | `/Users/schnapp/code/schnapp-vault/.github/scripts/inbox_watcher.py` |
| 3 | brain-watcher | same plist → WorkingDirectory | `/Users/schnapp/code/schnapp-vault/.github` |
| 4 | inbox_watcher | `~/code/schnapp-vault/.github/scripts/inbox_watcher.py:15` (`VAULT = ...`) | `VAULT = Path(__file__).resolve().parents[2]` (dynamic = vault root; robust to future moves) |
| 5 | brain_agent | `~/code/schnapp-vault/.github/scripts/brain_agent.py` (grep `OneDrive`) | same dynamic vault-root form as #4 |
| 6 | Obsidian app | symlink `~/Documents/Obsidian` | `ln -sfn /Users/schnapp/code/schnapp-vault ~/Documents/Obsidian` |
| 7 | knowledge fact | `~/code/schnapp-vault/memory/obsidian-state.md` | SUPERSEDE: canonical = `~/code/schnapp-vault`, git-synced, OUT of OneDrive; bump `updated:` |

**DO NOT touch** `~/code/schnapp-vault/claude-archive/**` — archived history (anti-stale exemption). Its OneDrive references are correct-for-the-past.

## Procedure (rollback-safe order)
1. **Pre-flight — STOP if any fails:** vault CI green; these exist — `~/code/schnapp-vault/{_brain/_index.json, .obsidian/, Inbox/, .github/scripts/inbox_watcher.py, .github/scripts/brain_agent.py}`; **Obsidian app CLOSED**.
2. **Stop both services FIRST** (nothing writes the old path mid-switch): `launchctl bootout gui/$(id -u)/com.schnapp.brain-watcher` and `.../com.schnapp.obsidian-mcp`.
3. **Repoint configs 1–5.** Commit the two in-vault edits (#4, #5) to `schnapp-vault@main`. Back up `server.py` before editing (`cp server.py server.py.bak-2026-07-01`).
4. **Repoint the symlink** (#6).
5. **Reload both services:** `launchctl bootstrap gui/$(id -u) <plist>` (or `kickstart -k`). VERIFY: `obsidian-mcp.log` shows the new VAULT + the server responds; `brain-watcher.log` shows it watching `~/code/schnapp-vault/Inbox`.
6. **Verify Obsidian:** open it → confirm it loads `~/code/schnapp-vault` (via the symlink) with notes present. Then close it.
7. **Supersede fact #7** (`obsidian-state.md`) → new topology, per the schema.
8. **Retire — only after 5–6 pass:** stop treating the OneDrive vault as canonical, but LEAVE it in place as a cold backup (do NOT delete this gate). Remove the stale `~/code/obsidian-vault` clone with `rm -rf` ONLY after confirming `git -C ~/code/obsidian-vault status` is clean and nothing is unpushed.
9. Commit/push (`schnapp-vault` + `schnapp-os` retarget). Flip the PLAN box + append the PROGRESS line. Write the ADR (OneDrive exit + repoint).

## Rollback
Nothing is deleted this gate. If any verify fails: revert the symlink to OneDrive, `git checkout` the config edits, restore `server.py.bak`, reload both services → back on the OneDrive vault. Safe.

## Gate 3 (next — do NOT skip): memory-mcp + de-dup
- Memory currently lives in BOTH `schnapp-os/memory/` (14 files, incl. `handoffs-carry-facts-not-pointers.md`) AND `schnapp-vault/memory/` — migration is mid-flight, so writes can diverge.
- `memory-mcp` (Render, `memory-mcp-rtad.onrender.com`) STILL writes to `schnapp-os/memory/`. Repoint its target → `schnapp-vault/memory/`.
- THEN remove `schnapp-os/memory/` (schnapp-os stops owning memory) + retarget schnapp-os references.
- Reconcile: `schnapp-vault/memory/` is canonical. `handoffs-carry-facts-not-pointers` is already in both — confirm identical, then the schnapp-os copy dies with the dir.

## Design follow-up (NOT gate-2-blocking — track for a later phase)
- obsidian-mcp / Obsidian write to the vault WORKING TREE but do NOT git-commit → the git truth lags edits, breaking "git = one truth" for Obsidian writes. The vault needs an auto-commit/push mechanism (as memory-mcp has). Log it; do not solve it here.

## Done when
Every consumer points at `~/code/schnapp-vault`; both services healthy on the new path; Obsidian opens the vault; OneDrive vault idle (cold backup); `obsidian-state` fact superseded; trackers flipped; ADR written; ZERO live OneDrive hardcodes outside `claude-archive/`.
