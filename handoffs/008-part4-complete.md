# Handoff 008 — master resume (supersedes 007). Part 4 COMPLETE. Tracker + all docs current.

Date: 2026-06-05.

## State by Part
- **0, 1** DONE. **2**: 2.1/2.2/2.3 done; **2.4** next-session verify. **3**: done except **3.4** verify.
- **4 COMPLETE (4.1–4.4).** Off-Mac 1Password connector LIVE end-to-end:
  - Render free tier `https://op-mcp.onrender.com` (root `render.yaml` Blueprint; bearer-gated).
  - Cloudflare MCP server portal `https://mcp.schnapp.bet/mcp` (Managed OAuth + static-bearer
    "Custom headers" to origin), registered as a claude.ai custom connector.
  - VERIFIED from claude.ai: `op_health` authenticated + `op_read` resolved a real value (no Mac
    in the path). Code/Cowork use the Render URL + bearer directly. Mac `op_*` tools = backup.
  - **Hygiene (option a):** connector stays READ-ONLY. To *use* a secret, prefer the Mac's
    `op_run`/`op_inject` (value scrubbed, never in chat); `op_read` = Mac-off fallback (returns the
    raw value into the transcript). Baked into the tool descriptions + connector README.
- **5**: 5.1/5.2 done; 5.3/5.4 procedures authored (hook wiring = Part 7); **5.5** `[~]`; **5.6** verify pending.
- **6**: **6.1** done (`plugins/core/scripts/backup-archive.sh`, ran + verified into OneDrive
  `claude-archive/`); **6.2** `[~]` (claude-archive is a ready Obsidian vault; owner GUI on the
  MacBook = open it + install the **Local REST API** plugin — the missing obsidian-MCP backend);
  **6.3** pending (non-Mac backup appears; needs MacBook + OneDrive cloud-sync check).
- **7**: **7.1/7.5** on-correction procedure authored (memory/README.md); **7.4** surface-check skill
  authored (`plugins/core/skills/surface-check/`); **7.2** hooks + **7.3** chat/Cowork skills PENDING.
- **8–11**: not started.

## Owner / next-session items
- **4.2 redeploy (to apply the new tool descriptions):** Render → op-mcp service → **Manual Deploy →
  Deploy latest commit** (`15e197d`), then Cloudflare → AI controls → MCP servers → op-mcp → refresh/
  re-sync so claude.ai sees the updated cold-start + hygiene text. (Functionally already works; this
  just propagates the guidance.)
- **Optional:** rotate the value read into the claude.ai transcript if it was sensitive.
- **6.2/6.3:** on the MacBook, open `claude-archive` as an Obsidian vault + install Local REST API.
- **Actions secret:** decide on `DB_Storage` + `appfolio-marketing-project` (never scoped).
- **Identity (optional):** the Cloudflare account is on the work email `austinschnapp@1st-lake.com`;
  migrate to a personal email later if desired (My Profile → Email). schnapp.bet is a zone in it.
- **Next-session verifies:** 2.4 (global lane loads in another repo), 3.4 (path-scoped non-leak),
  5.6 (cross-repo lesson + supersede), live 0.3/1.5/2.2/5.1.

## Next buildable, in order — and why Part 7 (not "more Part 5")
Part 5's leftovers are NOT separately buildable now: **5.3 (freshness gate) + 5.4 (end-of-session
write)** are HOOKS whose implementation the PLAN parks in Part 7 (procedures already authored in
memory/README.md); **5.5** needs a live perf instance that lands organically with real perf work;
**5.6** needs a second repo (Part 10) + the freshness gate (Part 7). So Part 7 IS the next actionable,
and it CLOSES 5.3/5.4.

**Part 7 (hooks + skills) — start with the hooks so 5.3/5.4 finish first:**
- **7.2** — author hook scripts + `hooks.json` in-repo: a **Stop/SessionEnd hook** = 5.4 (runs
  `plugins/core/scripts/backup-archive.sh` + the end-of-session memory/handoff write) and a
  **SessionStart freshness/git gate** = 5.3. Then present the `settings.json` activation diff for
  owner approval (NO self-wiring of ~/.claude or settings.json).
- **7.3** — chat/Cowork skill versions of the three procedures (memory/README.md is the single source).
- Then Parts 8, 9 (incl. 9.3 CI freshness, 9.5 install checklist), 10 (closes 2.4/3.4/5.6), 11.

## Gotchas
- `connectors/op-mcp/` `node_modules` + `dist` gitignored; `npm install` before build/verify.
- Render Blueprint `render.yaml` lives at repo root; with `rootDir` set, docker paths are
  rootDir-relative (a doubled path fails the build).
- Cloudflare: each MCP **server needs its own Allow policy** (else "No allowed servers available");
  Managed OAuth ON + add `https://claude.ai/api/mcp/auth_callback` (+ claude.com) redirect URIs;
  "Custom headers" auth type = the static bearer.
- `~/.claude/CLAUDE.md` lives outside the repo (capture in the 9.5 install checklist).
- settings.json backup: `~/.claude/settings.json.bak-20260603-144320`.

## Resume prompt
"Resume claude-kit. Working dir ~/code/claude-kit. Read PLAN.md, PROGRESS.md, and
handoffs/008-part4-complete.md first — tracker and all docs are current. Part 4 is COMPLETE
(off-Mac connector live + verified from claude.ai). Continue strict IN-ORDER: next buildable is
Part 7 (hooks + skills; 7.1/7.4/7.5 authored, 7.2/7.3 pending — author hooks in-repo, then present
the settings.json activation diff for approval). Apply keep-tracker-current (flip box + PROGRESS
line + push every state change; no doc hardcodes a mutable fact). Get explicit owner approval before
any ~/.claude / settings.json hook change or secret distribution. Act autonomously; handoff at each
Part boundary. Pause occasionally to check for input."
