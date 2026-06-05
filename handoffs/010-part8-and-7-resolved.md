# Handoff 010 — Parts 7 + 8 buildable-done; scope gap resolved (supersedes 009). Tracker + docs current.

Date: 2026-06-05.

## ⚠️ DO THIS FIRST — live-verify (one fresh session closes 4 boxes)
The Part-7 hooks were wired into `.claude/settings.json` AFTER this/last session started, so they have
not run yet (hooks load at session start). 5.3, 5.4, 8.2, and 7.2's dogfood-verify all close on the
same thing — the hooks firing at a real start. **This also verifies the trust-dialog prerequisite**
(if the per-machine workspace-trust dialog is unaccepted, the hooks AND `autoMemoryDirectory` (5.1)
silently do nothing). Steps:
1. At startup, confirm the **`===== claude-kit SESSION-START GATE =====`** block prints (sync + git
   state + memory supersede-orphan scan), NOT the old one-line "Already up to date."
2. **Stop push-gate:** make any commit, do NOT push, end your turn → it should BLOCK and say
   `git push`. Push → next stop goes clean. (Offline-safe: blocks once, then warns+allows.)
3. **SessionEnd:** end the session → `backup-archive.sh` runs (OneDrive mirror) + unpushed reminder.
Seen → flip PLAN **5.3 / 5.4 / 8.2 → [x]** and 7.2's live-verify line, commit, push.

## What changed since 009
- **Behavioral correction encoded as rules** (owner: I act too narrowly, don't think from the
  objective, ask things the plan already settles). Now in `working-style.md` (think in systems / work
  from the objective / generalize corrections / don't escalate settled decisions) + `anti-stale.md`
  (fix the class, not the instance). These load every session — honor them.
- **7.2 scope gap found + RESOLVED** — `decisions/0005`. The `.claude/settings.json` wiring is
  claude-kit-repo-ONLY, so "hooks on all machines" is NOT met by it. Dictated by the locked
  single-source/no-siloing decisions (not an owner choice): the **PLUGIN** delivers the global
  gate+push-gate (`${CLAUDE_PLUGIN_ROOT}`, fires everywhere at Part-10 install); **claude-kit project
  settings keep ONLY the backup**; at Part 10 the gate+push-gate are **removed from project settings**
  to avoid double-fire; `~/.claude` absolute-path hooks rejected. Current project wiring = dev-time
  dogfood; **7.2 closes at Part 10**, not now.
- **Part 8 buildable-done:** 8.1 `[x]` — git workflow encoded in
  `plugins/core/rules/modules/lang/git.md` "Workflow" (work on main; commit+push every change;
  branches need explicit approval; address unmerged first), resolving git.md's old dangling "project
  git workflow" ref. 8.2 `[~]` — already implemented by the SessionStart gate (live-verify above, not
  rebuilt). 8.3 `[~]` — `plugins/core/skills/merge-with-discretion/SKILL.md` authored (readiness +
  timing judgment over the standard finishing mechanics; defers to git.md + superpowers
  `finishing-a-development-branch`); unverifiable until a branch exists.
- Surface profiles (`code-mac`, `code-work-machines`) now name the concrete Part-7 hooks + the
  trust-dialog prerequisite (dropped a duplicated "Routines" paraphrase).
- Commits this session: `a085012`→`b9eac11` (gate+backup → Stop gate → settings wiring → session-hygiene
  → handoff 009 → rules+7.2-flag → 0005 → Part 8). All pushed; tree clean.

## State by Part
- **0,1,4** DONE. **2**: 2.4 verify pending. **3**: 3.4 verify pending.
- **5**: 5.1/5.2 done; **5.3/5.4** `[~]` (hooks wired → live-verify above); 5.5 `[~]`; 5.6 pending (Part 10).
- **6**: 6.1 done; 6.2 `[~]` (MacBook: open `claude-archive` in Obsidian + Local REST API); 6.3 pending.
- **7**: all `[~]` AUTHORED + wired; scope resolved (0005). Open: live-verify; remote `http`/`mcp_tool`
  hooks; Cowork-runs-hooks check; per-surface enablement + plugin global delivery (Part 10).
- **8**: 8.1 `[x]`; 8.2 `[~]` (live-verify); 8.3 `[~]` (until a branch exists).
- **9,10,11**: not started. (9 = anti-stale wiring + CI freshness + template + README install checklist.)

## Owner / next-session items
- **4.2 redeploy** (propagate tool descriptions): Render → op-mcp → Manual Deploy `15e197d`+, then
  Cloudflare MCP server re-sync. (Functionally already works.)
- **6.2/6.3:** MacBook — open `claude-archive` as an Obsidian vault + install Local REST API.
- **Actions secret:** decide on `DB_Storage` + `appfolio-marketing-project` (never scoped).
- **Next-session verifies:** the hook live-verify (above), 2.4 (global lane in another repo), 3.4
  (path-scoped non-leak), 5.6 (cross-repo lesson + supersede).

## Gotchas
- Hooks load at session start — editing hooks/settings needs a **restart** to take effect.
- `.claude/settings.json` is tracked but still gated: hook changes need **explicit** owner approval
  (a clarifying question is not consent; the auto-mode classifier enforces this).
- Stop push-gate is blocking (Option 2). To soften: warn instead of `decision: block` in
  `session-stop-push-gate.sh`.
- `${CLAUDE_PLUGIN_ROOT}` is the only portable global-hook delivery (Part 10); do NOT add absolute
  `~/.claude` hook paths (machine-bound; violates single-source — see 0005).
- `connectors/op-mcp/` `node_modules`+`dist` gitignored (`npm install` before build).
- `~/.claude/CLAUDE.md` lives outside the repo (capture in the 9.5 install checklist).
- settings.json backup: `~/.claude/settings.json.bak-20260603-144320`.

## Next buildable, in order
1. **Live-verify the hooks** (fresh session, above). Flip 5.3/5.4/8.2 → [x].
2. **Part 9** (anti-staleness wiring): 9.1 `@import` dedup in core/template CLAUDE.md; 9.2 generators
   (gen-catalog/update-codemaps/update-docs) marked generated; 9.3 CI freshness check (fail push on a
   stale generated doc / source newer than last-verified); 9.4 finalize `templates/project-CLAUDE.md`
   + `/new-project` output; 9.5 per-surface README install checklist (must include: `~/.claude/CLAUDE.md`
   content, the trust-dialog step, OneDrive path, the 0005 delivery split).
3. **Part 10** (wire surfaces; plugin install → global hooks per 0005; closes 2.4/3.4/5.6/7.x enablement).
4. **Part 11** (agentic OS).

## Resume prompt
"Resume claude-kit. Working dir ~/code/claude-kit. Read PLAN.md, PROGRESS.md, and
handoffs/010-part8-and-7-resolved.md first — tracker + docs are current. Parts 0–8 are buildable-done
(7.2 scope resolved in decisions/0005; Part 8 done bar live-verify). DO THIS FIRST: live-verify the
Part-7 hooks this fresh session — confirm the SESSION-START GATE block printed at startup (if not, the
workspace-trust dialog may be unaccepted, which also disables the memory lane); test the Stop push-gate
(commit without pushing → it must block and say git push); confirm the SESSION-END backup at end. Flip
PLAN 5.3/5.4/8.2 → [x] once seen, commit + push. Then continue strict IN-ORDER to Part 9 (anti-staleness
wiring: @import dedup, generators, 9.3 CI freshness, 9.4 template, 9.5 README install checklist).
Behavioral rules now loaded and binding: think in systems and trace every change's ripple across docs/
trackers/surfaces; work from the objective, not the literal ask; fix the class not the instance; do NOT
escalate decisions the locked plan already settles — resolve from the plan, act, record. Apply
keep-tracker-current (flip box + PROGRESS line + push every state change; no doc hardcodes a mutable
fact). Get explicit owner approval before any ~/.claude / settings.json hook change or secret
distribution. Act autonomously; handoff at each Part boundary. Pause occasionally to check for input."
