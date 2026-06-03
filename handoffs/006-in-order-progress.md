# Handoff 006 — master resume (supersedes 003/005). Tracker is current.

Date: 2026-06-03. PLAN.md boxes now reflect reality (de-staled this session) and stay
current per the **keep-tracker-current** rule: every state-changing commit flips the box +
PROGRESS line in the same commit AND pushes immediately so GitHub mirrors local.

## Completed (checked in PLAN.md, all pushed)
- **Part 0** DONE — repo, tracker, SSH remote, **0.3** SessionStart `git pull --ff-only` sync
  hook (tracked `.claude/settings.json`, fires next fresh session), 0.4.
- **Part 1** DONE — schnapp-kit frozen + disabled, fleet 19→6, **1.5** runtime verified quiet
  (no auto-PR/auto-merge; only intentional sync hook + benign caveman/superpowers SessionStart).
- **Part 2** DONE — global rules; surfaces/ profiles; **2.2** `~/.claude/CLAUDE.md` @imports the
  7 global rules directly from the repo (owner-approved direct-@import, no symlink → no double-load).
- **Part 3** — 3.1/3.2/3.3 done (gallery, presets, /new-project composer).
- **Part 4** — 4.1 SA rotated; **4.2 `[~]`** op-mcp connector BUILT + `npm run verify` PASS
  (deploy/register owner-gated); **4.3** credentials-map.md + root .env.template (refs only).
- **Part 5** — 5.1 autoMemoryDirectory→repo (owner-approved); 5.2 conventions; **5.5 `[~]`**
  (global perf principle + promotion mechanic done; live project instance pending).

## Remaining — three buckets

### A. Next-session / install verifications (cannot run mid-session)
- **2.4** global lane loads from another repo (the new `~/.claude/CLAUDE.md` @imports apply at
  next session start; open a different repo and confirm the 7 rules load).
- **3.4** path-scoped lang rules don't leak (compose a project via /new-project, confirm Python
  rules absent when editing `.sql` and vice versa).
- **5.6** cross-repo lesson + supersede (needs 2.4 working + a 2nd repo).
- Live confirmations of 0.3 (pull fires), 1.5 (fresh session quiet), 2.2 (rules load), 5.1
  (auto-memory writes to repo dir after the trust dialog).

### B. Owner-gated
- **4.2** deploy op-mcp to a Node host (default Fly.io; see connectors/op-mcp/fly.toml + README),
  set `OP_SERVICE_ACCOUNT_TOKEN` + `CONNECTOR_AUTH_TOKEN`, choose claude.ai auth front (Cloudflare
  Access vs OAuth wrapper), register the URL. Then **4.4** verify resolve from claude.ai, Mac OFF.
- Widen the GitHub fine-grained PAT to All repos; set the Actions secret on `af-invoice-parser`
  and `af-query-api` (other 8 done).
- Accept the workspace-trust dialog on this Mac so the 0.3 hook + autoMemoryDirectory take effect.

### C. Buildable next (autonomous, in order)
- **Part 6** — 6.1 done (OneDrive `claude-archive/`); 6.2 point Obsidian vault at it + fix the
  Obsidian connection (obsidian MCP is connected); 6.3 verify a non-Mac backup lands.
- **Part 7** — 7.1 procedures (freshness-gate + end-of-session already authored in memory/README.md);
  7.2 implement as hooks (self-config — needs per-hook owner approval, like 0.3); 7.3 same as skills
  for chat/Cowork; 7.4 `surface-check` skill; 7.5 on-correction auto-update. This also wires the
  deferred **5.3/5.4**.
- Then **8** git hygiene, **9** anti-stale wiring + template, **10** marketplace/install + run the
  full verification list (closes 2.4/3.4/4.4/5.6), **11** agentic OS.

## Working norms (owner)
Direct/terse, no fluff, no em dashes, lead with recommendation. Never guess — verify files/tools
before asserting. Strict in-order completion; do NOT skip. caveman mode active (normal prose for
code/commits/security). Self-config (`~/.claude`, settings.json hooks) requires explicit owner
approval — the auto-mode classifier gates it; present the exact change and ask.

## Gotchas
- ~/.claude/CLAUDE.md lives outside the repo; capture its content in the README install checklist
  (Part 9.5) so it is reproducible on other machines.
- connectors/op-mcp/ node_modules + dist are gitignored; `npm install` before `npm run verify`.
- settings.json backup: `~/.claude/settings.json.bak-20260603-144320`.

## Resume prompt
"Resume claude-kit. Working dir ~/code/claude-kit. Read PLAN.md, PROGRESS.md, and
handoffs/006-in-order-progress.md. Tracker is current. Continue strict in-order: the next
unchecked buildable work is Part 6 then Part 7 (2.4/3.4/5.6 are next-session verifications; 4.2/4.4
owner-gated). Apply keep-tracker-current (flip box + PROGRESS line + push every state change). Get
owner approval before any ~/.claude or settings.json hook change. Act autonomously; handoff at each
part boundary."
