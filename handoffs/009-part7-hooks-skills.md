# Handoff 009 — Part 7 authored + hooks WIRED (supersedes 008). Tracker + docs current.

Date: 2026-06-05.

## What changed this session (Part 7)
Authored + wired the cross-surface "must happen" enforcement. Closes the buildable half of
5.3/5.4 and all of Part 7's authorable work.

- **Three Code hooks** in `plugins/core/hooks/` (command type, all tested standalone, all exit 0):
  - `session-start-gate.sh` (=5.3): absorbs the Part 0.3 `git pull --ff-only`, then surfaces
    unmerged/unpushed/dirty git + a memory **supersede-orphan** scan to context. Non-blocking.
  - `session-stop-push-gate.sh` (Stop, **Option 2** — owner chose enforcement): **blocks** stopping
    while commits are unpushed (forces `git push`). Anti-loop via `stop_hook_active` (warns+allows on
    a 2nd unpushed stop, e.g. offline); uncommitted edits are warned, not blocked.
  - `session-end-backup.sh` (=5.4): runs `backup-archive.sh` (OneDrive mirror) + reminds of
    unpushed/uncommitted state. Non-blocking.
- **`plugins/core/hooks/hooks.json`** — portable plugin deployment (`${CLAUDE_PLUGIN_ROOT}`,
  SessionStart + Stop + SessionEnd). Inert until Part 10 installs claude-kit as a plugin.
- **`.claude/settings.json` — WIRED (explicit owner approval).** All 3 hooks via
  `${CLAUDE_PROJECT_DIR}` paths; the inline 0.3 pull is now absorbed by the gate. NOTE: the auto-mode
  classifier correctly blocked the FIRST write attempt (a clarifying question ≠ consent); applied only
  after an explicit "Yes, apply now."
- **`plugins/core/skills/session-hygiene/SKILL.md`** (=7.3): the three procedures as a skill for
  hookless surfaces, pointing to canonical `memory/README.md` + hookless execution notes (read git via
  the GitHub connector; persist via `create_or_update_file` or a generated Code prompt; backup caveat).
- **Surface profiles** `claude-ai-web` / `cowork` / `iphone` wired to name the session-hygiene skill.
- Commits: `a085012` (gate+backup) → `31391e5` (Stop gate) → `4237672` (settings.json wiring) →
  `98fc519` (session-hygiene + profiles) → this handoff. All pushed; tree clean + in sync.

## ⚠️ IMMEDIATE next-session verify (the one thing to watch)
Hooks load at **session start**, so they did NOT run this session (this session started under the old
inline pull). **The next fresh session is the live-verify:**
1. At start you should see the **SESSION-START GATE** block (sync + git state + memory scan), not the
   old one-line "Already up to date." If you don't, the trust dialog may need re-accepting.
2. To prove the **Stop push-gate**: make any commit, do NOT push, then end your turn — it should
   block and tell you to `git push`. Push, and the next stop should go clean.
3. End the session → **SESSION-END** should run the backup + print the reminder.
Once seen, flip PLAN **5.3 / 5.4 → [x]** and 7.2's live-verify line.

## State by Part
- **0, 1** DONE. **2**: 2.4 verify pending. **3**: 3.4 verify pending. **4** COMPLETE.
- **5**: 5.1/5.2 done; **5.3/5.4** `[~]` — HOOKS WIRED, live-verify next session (above). 5.5 `[~]`; 5.6 pending (Part 10).
- **6**: 6.1 done; 6.2 `[~]` (owner: open claude-archive in Obsidian + Local REST API on the MacBook); 6.3 pending.
- **7**: all `[~]` AUTHORED — 7.1 procedures, 7.2 hooks (wired), 7.3 session-hygiene skill, 7.4 surface-check, 7.5 on-correction. Open: live-verify; remote `http`/`mcp_tool` hooks; Cowork-runs-hooks check; per-surface skill/instruction enablement (Part 10).
- **8–11**: not started. (8 git hygiene is partly pre-satisfied by the Stop push-gate + SessionStart gate.)

## Owner / next-session items (carried from 008, still open)
- **4.2 redeploy** (propagate new tool descriptions): Render → op-mcp → Manual Deploy `15e197d`+,
  then Cloudflare MCP server re-sync. (Functionally already works.)
- **6.2/6.3**: MacBook — open `claude-archive` as an Obsidian vault + install Local REST API.
- **Actions secret**: decide on `DB_Storage` + `appfolio-marketing-project` (never scoped).
- **Next-session verifies**: 2.4 (global lane in another repo), 3.4 (path-scoped non-leak), 5.6, and
  the Part-7 hook live-verify above.

## Gotchas
- Hooks load at session start — editing hooks/settings needs a **restart** to take effect.
- `.claude/settings.json` is a tracked file but still gated: hook changes need **explicit** owner
  approval (the classifier enforces this; a clarifying question is not consent).
- Stop push-gate is **Option 2** (blocking). If it ever annoys, soften `session-stop-push-gate.sh`
  to a non-blocking reminder (warn instead of `decision: block`).
- `connectors/op-mcp/` `node_modules`+`dist` gitignored (`npm install` before build).
- `~/.claude/CLAUDE.md` lives outside the repo (capture in the 9.5 install checklist).
- settings.json backup: `~/.claude/settings.json.bak-20260603-144320`.

## Next buildable, in order
1. **Live-verify the Part-7 hooks** (next fresh session — see the ⚠️ block). Flip 5.3/5.4 → [x].
2. **Part 8** (git hygiene): 8.1 default-on-main (already practiced), 8.2 SessionStart gate addresses
   unmerged work first (the gate now does the surfacing — verify + check the box), 8.3 merge-with-
   discretion skill (only if/when a branch exists, owner-approved).
3. **Part 9** (anti-staleness wiring + template; 9.3 CI freshness, 9.5 README install checklist).
4. **Part 10** (wire surfaces: enable session-hygiene + surface-check on claude.ai/Cowork; closes
   2.4/3.4/5.6/7.3/7.4 enablement). 5. **Part 11** (agentic OS).
- Remote `http`/`mcp_tool` hooks + the Cowork-runs-hooks check stay open inside 7.2 — pick up
  opportunistically (the Cowork check needs the Cowork surface).

## Resume prompt
"Resume claude-kit. Working dir ~/code/claude-kit. Read PLAN.md, PROGRESS.md, and
handoffs/009-part7-hooks-skills.md first — tracker + docs current. Part 7 is AUTHORED and the three
Code hooks are WIRED into .claude/settings.json (owner-approved). FIRST: live-verify the hooks this
fresh session — confirm the SESSION-START GATE block printed at startup; test the Stop push-gate
(commit without pushing → it should block); confirm SESSION-END backup at end. Flip PLAN 5.3/5.4 → [x]
once seen. Then continue strict IN-ORDER to Part 8 (git hygiene; the SessionStart gate already surfaces
unmerged/unpushed work — verify 8.2). Apply keep-tracker-current (flip box + PROGRESS line + push every
state change; no doc hardcodes a mutable fact). Get explicit owner approval before any ~/.claude /
settings.json hook change or secret distribution. Act autonomously; handoff at each Part boundary.
Pause occasionally to check for input."
