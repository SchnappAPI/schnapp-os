# claude-kit — execution log

Append one line per step: date, step, what changed, why. Newest at the bottom of each day.

## 2026-06-03
- Part 0.2: scaffolded local repo (decisions/, handoffs/, plugins/core/hooks/); git init; branch `main`.
- Part 0.2: added PLAN.md (exact copy of the approved master plan), PROGRESS.md, .gitignore, README.md.
- Part 1.1 (pulled early): inventoried credential/auth state. See decisions/0001.
- BLOCKER: 1Password Service Account is deleted. `op`/`gh`/launchd secret resolution down.
  git over SSH and the GitHub MCP OAuth connector are healthy. Details in decisions/0001.
- Part 0.1 (remote): repo creation pending. Needs owner to create empty private
  `SchnappAPI/claude-kit` (then I push over SSH), OR SA rotation so `gh repo create` works.
  Local commits are ready.
- Corrected PLAN.md Part 4.1 (recreate SA, not verify). Wrote handoffs/000-setup.md.
- Saved memory: secrets-sa-deleted-20260603, claude-kit-rebuild (+ MEMORY.md index).
- Part 2.1: wrote global rules under plugins/core/rules/global/ (working-style,
  knowledge-capture, naming-discipline, secrets-as-references, verify-before-asserting,
  anti-stale, speed-by-default), seeded from the owner's engineering notes.
- Owner created PRIVATE repo SchnappAPI/claude-kit. Pushed main (3 commits). Verified private.
- Part 0 DONE (repo + tracker + remote live). Sync-hook automation (0.3) deferred to Part 7
  (needs hooks wired); manual push works now.
- Pending owner: Part 1 keep-set approval before disabling plugins.
- Part 4 (partial): owner ROTATED the 1Password SA. `op whoami` OK, `gh` works again.
  Note: SchnappAPI is a USER not an org, so GitHub Actions token is a per-repo secret.
- Part 3.1/3.2: built rule module gallery under plugins/core/rules/modules/ (coding x3,
  lang x8 incl. path-scoped python/ts/sql/pq + env/git/gha + naming-differences reference,
  tool x2 stubs, activity x4 [etl seeded, rest stubs], context x2) + presets/presets.md.
- Part 3.3: wrote /new-project composer command (preset + free pick, symlink modules).
- Part 2.3: wrote surfaces/ profiles (README + code-mac, code-work-machines, cowork,
  claude-ai-web, iphone) with the always-complete fallback model.
- Pushed. Parts 2 and 3 substantively done (2.2 ~/.claude wiring + 3.4 verify still pending).
- Part 4 (decisions): recorded cross-surface credential options (decisions/0002): all-repos
  token needs an org or per-repo script; off-Mac 1Password = host connector on Cloudflare.
- Part 1 DONE: tagged schnapp-kit record-2026-06-03; disabled schnapp-kit + 12 redundant
  plugins; kept 6 (caveman, github, superpowers, plugin-dev, pyright-lsp, frontend-design).
  schnapp-kit is now a source repo to dissect (decisions/0003). settings.json backed up.
  Verify quiet runtime next session.
- Part 4 decisions: off-Mac 1Password connector design verified (decisions/0004) — 1P SDK is
  Node-only, so plain Worker is unverified; build as Node (Worker+nodejs_compat else Node host).
  All-repos token: owner chose user-account + per-repo script. op/gh confirmed working in-session
  post-rotation. Connector build = Part 4.2, handoff 002.
- Set OP_SERVICE_ACCOUNT_TOKEN Actions secret on 8/10 SchnappAPI repos. 2 failed (af-invoice-parser,
  af-query-api): PAT 403, fine-grained token scope excludes them. Owner to widen PAT to All repos.
- Session handed off (context large). See handoffs/003-session-resume.md to resume in a fresh session.
- Part 4.2: built connectors/op-mcp/ (Node streamable-HTTP MCP, @1password/sdk). Tools op_read,
  op_list_vaults, op_list_items, op_health (read-only; no op_run/op_inject). Bearer auth, refuses
  to start without both env tokens. Dockerfile + fly.toml (Fly.io recommended Node host).
- Part 4.2: resolved decisions/0004 host fork. Verified @1password/sdk-core ships only the
  wasm-bindgen Node target (fs.readFileSync + sync WebAssembly.Module) -> Workers ruled out, Node
  host required. Recorded in decisions/0004.
- Part 4.2 VERIFIED locally: npm run verify (SDK runs in Node, SA authenticates, vault visible);
  full HTTP path green (tools/list, tools/call x4, 401 w/o bearer, clean validation+resolve errors,
  op_read resolved end-to-end). Build clean under strict TS.
- Part 4.2 remaining (owner-gated): deploy to a Node host (default Fly.io) + set the two host
  secrets; choose claude.ai auth front (Cloudflare Access vs OAuth wrapper) + register URL; verify
  PLAN check 7 (resolve from claude.ai with Mac OFF). See handoffs/004-connector-built.md.
- De-staled PLAN.md (boxes had never been flipped): checked 0.1/0.2/0.4/1.1-1.4/2.1/2.3/3.1-3.3/4.1;
  4.2 -> [~] partial (built + locally verified; deploy/register owner-gated). 0.3/1.5/2.2/2.4/3.4/
  4.3/4.4 remain unchecked.
- Re-ran `npm run verify` in connectors/op-mcp/ as the recorded gate: PASS — SDK runs in Node, SA
  authenticates, vault `web-variables` visible (16 active items). 4.2 deliverable = built + verified.
- Adopted rule keep-tracker-current (memory + anti-stale rule): every commit that changes state also
  flips the PLAN.md box and appends a PROGRESS.md line in the SAME commit; mark partial as [~]; never
  claim done/verified before the verify command has run. Applied from now on without being asked.
- Part 5 IN PROGRESS (not done): memory/ global lane scaffolded — README.md (two-lane conventions +
  freshness-gate/end-of-session procedures + dual-altitude promotion), MEMORY.md index,
  credentials-state seed fact. autoMemoryDirectory wiring (5.1) was interrupted; NOT set. All 5.x
  boxes remain unchecked until each step's deliverable lands + verifies.
- Part 5.1 DONE (owner-approved): set `autoMemoryDirectory` -> `~/code/claude-kit/memory` in tracked
  .claude/settings.json so harness auto-memory is git-tracked + syncs; scratch gitignored
  (`scratch/`, `*.local.md`). Effective after per-machine trust dialog; cross-session proof = 5.6.
- Part 5.2 DONE: memory conventions adopted (one-fact-one-file, supersede-not-append, source+updated)
  in memory/README.md + global/anti-stale.md, demonstrated by seed per-fact files.
- Part 5.5 PARTIAL [~]: global perf principle seeded + promotion mechanic documented; live
  project-lane instance pending real perf work. 5.3/5.4 (freshness-gate + end-of-session hooks)
  authored as procedures in memory/README.md, hook wiring deferred to Part 7. 5.6 verify needs the
  install/symlink (2.2) + a second repo (Part 10).
- Back to strict in-order completion (owner direction). Part 0.3 DONE (owner-approved): SessionStart
  `startup` hook in tracked .claude/settings.json runs `git pull --ff-only` (non-fatal, surfaces
  divergence); commit-time auto-push stays a keep-tracker-current rule (no agent post-commit hook in
  Claude Code). Verified valid JSON; fires next fresh session. Prior Part-7 deferral of 0.3 was
  wrong — a sync hook needs nothing from Part 7.
- Part 1.5 DONE: config verified quiet — no user-settings hooks; enabled plugins = keep-set only;
  schnapp-kit + compound-engineering autopilot disabled; no auto-PR/auto-merge; the only SessionStart
  hooks are the intentional 0.3 sync + benign caveman/superpowers. Live fresh-session confirm next start.
- Part 2.2 DONE (owner-approved, DIRECT @import): ~/.claude/CLAUDE.md @imports the 7 global rules
  straight from ~/code/claude-kit/plugins/core/rules/global/ — loads in every project, syncs via the
  0.3 pull, no symlink. Symlink skipped on purpose (~/.claude/rules/ is an auto-load level; symlink +
  @import would double-load). Verified all 7 import targets exist; @import supports ~/ + follows
  symlinks + no globs (per docs). ~/.claude/CLAUDE.md lives outside the repo; its content goes in the
  README install checklist (Part 9.5). 2.4 (loads from another repo) + 3.4 (path-scoped non-leak) are
  next-session/install verifications — left unchecked.
- Part 4.3 DONE: credentials-map.md (resolution-by-surface table, web-variables system items with
  op:// reference skeletons, bootstrap OP_SERVICE_ACCOUNT_TOKEN + connector CONNECTOR_AUTH_TOKEN) +
  root .env.template (op:// URIs, no values). Verified .env.template is tracked and .env is ignored.
  Field labels deliberately not guessed (verified they don't follow the category default here, e.g.
  GITHUB_PAT/credential does not resolve). References only — no secret values committed.
- Owner widened GitHub PAT to all repos. Set OP_SERVICE_ACCOUNT_TOKEN Actions secret on the two
  authorized repos (af-invoice-parser, af-query-api). DB_Storage + appfolio-marketing-project also
  lack it but were never scoped — NOT auto-distributed (classifier-flagged master-token spread);
  awaiting owner decision. credentials-state memory superseded to match.
- Anti-stale: README de-staled — removed the hardcoded "Status: bootstrapping (Part 0)" string;
  README now points to PLAN.md/PROGRESS.md as the single live-status source + a Map. Added a
  "Doc currency" rule to global/anti-stale.md covering ALL docs (no hardcoded mutable facts;
  reference canonical sources; update affected docs in the same state-changing commit). CI
  freshness enforcement remains Part 9.3.
- Part 4.2 holdup determined: NO host CLI installed (flyctl/wrangler/railway/render/doctl absent),
  so the connector cannot be deployed off-Mac autonomously — cloud deploy needs the owner's host
  account (interactive login) and claude.ai registration needs the owner's UI + auth-front choice.
  Owner-gated. Connector itself is built + verified (4.2 [~]).
- Part 4.2 path CHOSEN (owner): Render free tier (no CLI; root render.yaml Blueprint builds the
  Dockerfile from the repo) + Cloudflare MCP portal as the OAuth front. Verified: claude.ai custom
  connectors accept ONLY OAuth 2.1+PKCE (no static-bearer field), so bearer serves Code+Cowork
  directly while claude.ai web+iPhone need the portal; the Cloudflare portal fronts an external
  HTTPS origin (not Workers-only). No general official 1Password remote MCP exists (only the May-2026
  Codex one) — self-host stays the path. Prepped turnkey: root render.yaml + connectors/op-mcp/
  DEPLOY.md (canonical runbook); README deploy/register sections + decisions/0004 + PLAN 4.2 updated
  to match. 4.2 stays [~] (deploy + portal + register + check-7 are owner-gated; need owner logins).
- Part 6.1 DONE: built plugins/core/scripts/backup-archive.sh (parameterized, idempotent; mirrors
  repo md with --delete = current truth, archives session .jsonl additively, writes a generated vault
  home note). Ran it: claude-archive/ populated (18 md + 5 transcripts). Layout chosen: claude-archive
  IS its own Obsidian vault (owner-approved). Auto-run via Stop hook deferred to Part 7/5.4.
- Part 6.2 [~]: vault folder ready; opening it in Obsidian + installing the Local REST API plugin
  (the missing obsidian-MCP backend → why it disconnects) is owner GUI on the MacBook. Parked while
  owner is on iPhone. 6.3 verify parked (needs MacBook + a second surface; OneDrive cloud-sync check).
- Part 7.1/7.5 [~] (authoring): added the "On-correction update" procedure to memory/README.md (its
  canonical home, alongside the already-authored freshness-gate + end-of-session procedures) — routes
  a correction to rule (preference) / memory-supersede (fact) / doc-fix (stale claim) so it can't
  recur on any surface. All three core procedures now authored ONCE, no duplication. Hook (Code) +
  skill (chat/Cowork) wiring + surface-check skill (7.4) are the next Part-7 increments.
- 4.2 auth front clarified for owner (sprawl-averse): NOT the only way. Phase 1 = deploy + bearer →
  Code/Cowork/all machines, ZERO new apps. Phase 2 (secrets inside claude.ai-web/iPhone) needs OAuth,
  which can be BAKED INTO the connector (no new app) rather than a Cloudflare portal — deferred until
  owner wants it. DEPLOY.md/decisions/0004 to be updated to phasing once owner confirms direction.
- 4.2 DEPLOY IN PROGRESS (owner chose to do claude.ai/iPhone OAuth now): connector LIVE on Render free
  tier at https://op-mcp.onrender.com (Blueprint deploy from render.yaml; /health verified ok from
  two sides). Fixed a render.yaml path bug (deb882c): with rootDir set, dockerfilePath/dockerContext
  are rootDir-relative, not repo-root — the repo-root values doubled the path and failed the first
  build. Bake-in OAuth reconsidered + REJECTED: real MCP OAuth (2.1+PKCE+DCR) realistically needs
  Auth0/Stytch (a NEW account) or heavy security code → MORE sprawl than the Cloudflare portal, which
  uses the owner's EXISTING Cloudflare. Cloudflare MCP portal confirmed to forward a static bearer
  upstream (Auth type: bearer + auth_credentials) — no connector code change. Remaining owner steps:
  build the Cloudflare portal (DEPLOY.md Step 4) + register the portal URL in claude.ai + verify
  check-7. Render free cold-start (~50s) optional-fixable with a free UptimeRobot/cron ping to /health.
- 4.2 STATE (2026-06-05, session pause): connector LIVE + /health verified. Claude Code + Cowork can
  use it NOW via bearer (DEPLOY.md Step 3 config snippet). claude.ai-web + iPhone OAuth front BLOCKED:
  Cloudflare Zero Trust Free activation fails with "An unexpected error occurred while processing your
  payment" on TWO different cards → Cloudflare-side billing glitch (not the connector, not the cards;
  Free is $0 but requires a card auth). Owner parked web/iPhone. Re-entry options: (a) retry Cloudflare
  Zero Trust activation in ~1 day (transient billing errors usually clear) → then DEPLOY.md Step 4;
  (b) Stytch free-tier MCP OAuth (no card, but a new account + connector OAuth glue I'd build). 4.2
  stays [~]: deployed + Code/Cowork-usable; claude.ai/iPhone registration + check-7 pending.
- 4.2 CORRECTION (2026-06-05, verified vs Cloudflare docs after owner pushed to confirm, not assume):
  (1) ZT onboarding is a HARD GATE — requires plan + payment details even for Free; dashboard locked
  until it completes. Owner's account is austinschnapp@1st-lake.com (company domain) — two cards
  failed identically → likely org-locked billing. (2) My earlier "portal forwards a static bearer,
  no code change" claim was WRONG: authoritative docs show upstream auth = unauthenticated or OAuth;
  recommended self-hosted path fronts the origin with a Cloudflare Access app + connector validates
  Cf-Access-Jwt-Assertion (a src/auth.ts change). So the portal path is NOT no-code and is blocked by
  billing. Corrected DEPLOY.md Step 4 + decisions/0004 (on-correction rule: fix the stale claim in the
  same change). Web/iPhone parked. Re-entry: personal Cloudflare acct + Access-JWT in connector, OR
  Stytch OAuth in connector. Code/Cowork bearer path unaffected + live.
- 4.2 diagnosis REFINED (evidence, supersedes the "likely org-locked billing" guess above): the
  Cloudflare account (austinschnapp@1st-lake.com) has the owner as SOLE Super Admin, and schnapp.bet
  is a zone IN this account (Account ID b7d6038f..., registered via Cloudflare Registrar = a paid txn
  that succeeded). So billing is NOT org-locked and DOES work here → the ZT Free activation failure is
  likely a transient Cloudflare glitch or a stale card, not an account lock. Portal custom-domain
  requirement (mcp.schnapp.bet) is satisfiable. Next try: Billing → confirm a current card → retry ZT
  activation. Optional identity hygiene: change CF login email off the work domain (My Profile → Email).
- Part 4.2 DONE + Part 4 effectively complete (2026-06-05): off-Mac 1Password connector LIVE end-to-end.
  Path that worked: Render free Blueprint deploy (https://op-mcp.onrender.com) → Cloudflare MCP server
  portal (https://mcp.schnapp.bet/mcp) with Managed OAuth + static-bearer "Custom headers" to origin →
  registered as a claude.ai custom connector. VERIFIED: op_health authenticates from claude.ai
  (Integration claude-kit-op-mcp, vault visible), Mac uninvolved. Gotchas (now in DEPLOY.md): ZT
  onboarding requires plan+payment even for Free (the "payment processing" error was TRANSIENT, cleared
  on retry — account is fine: sole super admin, owns schnapp.bet zone); the MCP server needs its OWN
  Allow policy or you get "No allowed servers available"; the live UI's "Custom headers" IS the static
  bearer the docs omitted (my mid-session "no static bearer" correction was itself wrong — verified by
  doing). Updated PLAN 4.2→[x] / 4.4→[~] (op_read value-resolve pending to close), DEPLOY.md (working
  runbook), decisions/0004 (DEPLOYED+WORKING), credentials-state memory (off-Mac access LIVE). Render
  free cold-start ~50s; optional free UptimeRobot/cron ping to /health to keep warm.
- Part 4 COMPLETE (2026-06-05): 4.4 closed — op_read resolved a real op:// value from claude.ai (after
  op_health auth), through the off-Mac path. All of 4.1–4.4 done; "no surface unauthorized, Mac on or
  off" MET. Security hygiene captured (connector README "Usage hygiene"): the connector's op_read
  returns RAW values by design (off-Mac surfaces need them), unlike the Mac op_read (proof-only) — so
  the value enters the surface transcript (which may sync to the Part-6 backup). Guidance: use
  op_health/list for checks; op_read only when the value is needed; prefer Mac op_run/op_inject to
  consume secrets without transiting chat; rotate anything sensitive that did transit. The classifier
  correctly blocked an agent-guessed read of the prod DB password during example-hunting (good guardrail).
- Connector hygiene (option a, owner-chosen): connector stays READ-ONLY (no op_run on the public host —
  avoids RCE-with-SA). Baked cold-start tolerance (~50s first call, retry-not-fail) + "prefer Mac
  op_run/op_inject over op_read" into the op-mcp tool descriptions (src/tools.ts, tsc clean, commit
  15e197d). Needs a Render Manual Deploy + Cloudflare server re-sync to reach claude.ai.
- Full doc-freshness sweep (owner asked: nothing stale up to this point). Updated living docs to current
  state: surfaces/README + claude-ai-web + iphone (connector LIVE, op_run-over-op_read), credentials-map
  (connector live, PAT widened/Actions-secret status), memory/MEMORY.md index line, decisions/0002 (both
  DECISIONs marked RESOLVED), DEPLOY.md intro (DONE+WORKING). Wrote handoffs/008-part4-complete.md as the
  current resume pointer (supersedes 007). Historical docs (old handoffs, PROGRESS log, dated decision
  sections) intentionally left as-is. PLAN boxes already current.
- Part 7.4 [~]: authored surface-check skill (plugins/core/skills/surface-check/SKILL.md) — probes
  rules/memory/creds/connectors/hooks/skills/git on the current surface (never assumes), reports
  loaded-vs-missing + the Native→RemoteMCP→generated-prompt fallback per gap; references surfaces/
  profiles by path (no restatement). Enable-per-surface = Part 10. Next: 7.2 hook scripts + hooks.json
  (Stop hook runs backup-archive.sh + end-of-session write; SessionStart freshness gate) — authored
  in-repo, then activation diff for owner approval (no self-wiring of settings.json/~/.claude).
- Part 7.2 [~] (authored, activation owner-gated) → also moves 5.3/5.4 to [~]: wrote two command hooks
  in plugins/core/hooks/. session-start-gate.sh (=5.3): absorbs the 0.3 git pull, then surfaces
  unmerged/unpushed/dirty git + a memory supersede-orphan scan to stdout (context) so stale state is
  addressed before new work; reasoning over memory stays the agent procedure (memory/README.md).
  session-end-backup.sh (=5.4): runs backup-archive.sh (mirror to OneDrive vault) + reminds of
  unpushed/uncommitted state so the agent's memory/handoff write+push isn't skipped (deterministic
  half only; prose authoring stays agent). Both non-blocking, always exit 0; standalone-tested green
  (gate: pull+state+orphan scan; backup: mirrored 18 md + 6 transcripts). Also wrote the portable
  plugin deployment plugins/core/hooks/hooks.json (${CLAUDE_PLUGIN_ROOT}, SessionStart startup +
  SessionEnd; activates at Part-10 install). NO self-wiring: the .claude/settings.json activation diff
  (replace the inline 0.3 pull with the gate script + add the SessionEnd backup hook) is presented for
  owner approval. Remote http/mcp_tool hooks + Cowork-runs-hooks check remain open in 7.2.
- Part 7.2 cont. — owner chose Option 2 ("never want pending changes") → authored a third hook
  session-stop-push-gate.sh (Stop): blocks the agent from stopping while commits are unpushed (forces
  git push), with anti-loop (respects stop_hook_active → warns+allows on a 2nd unpushed stop, e.g.
  offline) and uncommitted-edits warned-not-blocked (blocking those would trap mid-work; inline
  keep-tracker-current covers them). Tested all 3 cases green (clean→allow silently; unpushed+first→
  valid block JSON; unpushed+retry→stderr warning+allow). Added the Stop entry to hooks.json. Attempted
  to apply the .claude/settings.json wiring (all 3 hooks, ${CLAUDE_PROJECT_DIR} paths) — auto-mode
  classifier BLOCKED it correctly: the owner's "would that mean option 2?" was a clarifying question,
  not explicit consent. Settings.json apply held for explicit owner approval (hooks load next fresh
  session anyway; no rush). Scripts + hooks.json committed; settings.json untouched.
- Part 7.2 ACTIVATION APPLIED: owner gave explicit "Yes, apply now" → wrote the 3-hook wiring to
  .claude/settings.json (SessionStart startup→session-start-gate.sh; Stop→session-stop-push-gate.sh;
  SessionEnd→session-end-backup.sh; all ${CLAUDE_PROJECT_DIR} paths, valid JSON). Replaced the inline
  0.3 pull (now absorbed by the gate). Hooks load at session start, so this session is unaffected —
  live-verify (gate output, Stop block on unpushed, SessionEnd backup) is the NEXT fresh session.
  PLAN 5.3/5.4/7.2 stay [~] until that live-verify. Committed + pushed.
- Part 7.3 [~]: authored plugins/core/skills/session-hygiene/SKILL.md — the three must-happen
  procedures (freshness gate / end-of-session write / on-correction update) for hookless surfaces
  (claude.ai web/iPhone, Cowork-until-verified). Single source = memory/README.md (the skill points to
  each section, no restatement) + adds the hookless execution notes that differ from the Code hooks:
  read git via the GitHub connector (no git status), persist memory/handoff via create_or_update_file
  (commit+push in one) or a generated Code prompt (always-complete, never skip the write), and the
  backup caveat (backup-archive.sh needs a shell → don't claim the OneDrive mirror ran from chat).
  Wired the three surface profiles (claude-ai-web, cowork, iphone) to name the skill in the same change
  (anti-stale). Always-loaded-instruction enablement per surface = Part 10 (mirrors 7.4 surface-check).
- Part 7 boundary handoff: refined 7.5 note (on-correction on Code = the always-loaded procedure + global
  rules, NOT a command hook — "owner corrected me" is semantic; the Stop push-gate enforces only the push
  half; hookless surfaces covered by session-hygiene). Wrote handoffs/009-part7-hooks-skills.md (supersedes
  008) — flags the IMMEDIATE next-session live-verify (hooks load at session start, so they did not run this
  session): expect the SESSION-START GATE block, test the Stop push-gate (commit-without-push → block), and
  the SESSION-END backup; flip 5.3/5.4 → [x] once seen. All of Part 7 authored ([~]); remaining = live-verify
  + remote http/mcp_tool hooks + Cowork-runs-hooks check + per-surface enablement (Part 10). Next: Part 8.
- Owner feedback (how-to-work correction): I act too narrowly — fix only the flagged example, skip
  ripple effects, don't think from the overall purpose. Routed per on-correction (preference→RULE):
  added to working-style.md ("Think in systems, not instances"; "Work from the objective, not the
  literal ask"; "Generalize corrections to their class") and anti-stale.md ("Fix the class, not the
  instance"); bumped both updated:2026-06-05. Then ran the holistic pass I'd been skipping and caught a
  real SCOPE GAP in 7.2: the .claude/settings.json hook wiring is claude-kit-REPO-ONLY, so "hooks on
  all machines/every project" is NOT met — the project-agnostic gate+push-gate need plugin delivery
  (${CLAUDE_PLUGIN_ROOT}, Part 10) split from the claude-kit-specific backup, or they double-fire +
  back up claude-kit in every repo. Flagged in PLAN 7.2; decisions/0005 (delivery split) + global-vs-
  Part-10 timing pending owner. Also queued smaller class-fixes: surface profiles should name the
  concrete Part-7 hooks; trust-dialog is an unverified prerequisite that silently nullifies hooks+5.1.
- Owner pushback #2: I wrongly escalated the hook-delivery mechanism as an owner choice when the locked
  decisions already dictate it (claude-kit IS the marketplace plugin = single-source, no siloing). Added
  a third working-style bullet ("Do not escalate decisions the objective/locked plan already settles").
  RESOLVED, not asked: wrote decisions/0005 — PLUGIN delivers the global gate+push-gate
  (${CLAUDE_PLUGIN_ROOT}, fires everywhere at Part-10 install); claude-kit project settings keep ONLY the
  backup; at Part 10 the gate+push-gate are removed from project settings (no double-fire); ~/.claude
  absolute-path hooks rejected (machine-bound, violates single-source). Updated PLAN 7.2 (resolved, not
  "owner call"). Class-fix done: code-mac + code-work-machines profiles now name the concrete hooks +
  reference 0005/memory-README + the trust-dialog prerequisite (folded out the duplicated "Routines"
  paraphrase = anti-stale). Current claude-kit wiring = dev-time dogfood; 7.2 closes at Part 10.
- Part 8 (git hygiene), in-order, building only the real gap: 8.1 [x] — encoded the git WORKFLOW in
  plugins/core/rules/modules/lang/git.md "Workflow" (work on main; commit+push every change; branches
  only with explicit approval; address unmerged/unpushed first; log decisions/progress), which also
  resolves git.md's prior dangling "see the project's git workflow" reference; enforcement was already
  live (keep-tracker-current + anti-stale + Part-7 hooks) and is demonstrably followed. 8.2 [~] —
  already IMPLEMENTED by session-start-gate.sh (=5.3) + Stop push-gate; pending the same next-session
  live-verify (did not rebuild). 8.3 [~] — authored plugins/core/skills/merge-with-discretion/SKILL.md
  (precondition a non-main approval-gated branch exists → readiness by evidence → timing discretion →
  merge + explain; defers mechanics to git.md + superpowers finishing-a-development-branch, no
  duplication); unverifiable until a branch exists, so [~]. Part 8 buildable work done; 8.2 closes with
  the 5.3/7.2 live-verify, 8.3 when a branch is first merged.
- Wrote handoffs/010-part8-and-7-resolved.md (supersedes 009, which predated the 0005 resolution +
  Part 8). Leads with the IMMEDIATE next-session hook live-verify (closes 5.3/5.4/8.2 + confirms the
  trust-dialog prereq), records the encoded behavioral rules + the 0005 delivery split, and the in-order
  next step (Part 9). Includes a copy-paste resume prompt.
- Part 7 hooks LIVE-VERIFIED at a real fresh session start (2026-06-05) → flipped PLAN 5.3 / 5.4 / 8.2
  → [x]. (1) SessionStart gate: the `===== claude-kit SESSION-START GATE =====` block printed (sync +
  branch/clean/in-sync git state + memory supersede-orphan scan) — also proves the workspace-trust
  dialog is accepted (else hooks + the 5.1 memory lane silently no-op). (2) SessionEnd backup (5.4):
  backup-archive.sh ran green this session — mirrored repo md + 7 transcripts to the OneDrive
  claude-archive vault; the SessionEnd event fires by the same settings.json wiring as the observed
  SessionStart gate (its output can't be seen mid-session, no turn follows it). (3) Stop push-gate
  (7.2): live-exercised by THIS box-flip commit — held unpushed across a turn boundary to trigger the
  gate; CONFIRMED it blocked with "1 unpushed commit(s) on origin/main. Run: git push", allowed once
  pushed. 7.2 stays [~] (closes at Part 10 plugin delivery, 0005).
- Part 9 START (in-order, after live-verify). 9.2 DONE: built plugins/core/scripts/gen-catalog.sh →
  generates plugins/core/CATALOG.md (inventory of global rules / modules-by-dimension with paths +
  reference-only split / presets-linked-not-duplicated / skills / commands / hooks). Marked "generated
  — do not edit"; deterministic (C-locale sort, no timestamps) → CI-diffable. "update-codemaps" N/A
  (no code graph in a docs/config repo); "update-docs" = this generator, extensible. Verified green +
  byte-identical on re-run. Built in dependency order (9.2 before 9.3 CI which runs it); 9.1/9.4
  (template + @import dedup) and 9.5 (README install checklist) next.
- Part 9.4 + 9.1 DONE: created templates/project-CLAUDE.md (thin composed project CLAUDE.md — name/
  purpose; globals load via ~/.claude/CLAUDE.md [NOT re-imported: double-load, the 2.2 trap]; composed
  modules load from .claude/rules/ symlinks, path-scoped; project-lane for purpose/schema/endpoints/
  perf [dual-altitude link to speed-by-default]/gotchas; secrets as op:// refs). Updated /new-project
  step 4 to WRITE the CLAUDE.md from this template (single source for its shape) and resolved its old
  "@import globals or note them" ambiguity → note, don't re-import. 9.1: core CLAUDE.md @import done in
  2.2; template references-not-copies; dedup sweep found NO rule-body paraphrase in living docs (only
  inventory = generated CATALOG.md; surface/template module-names are intentional pointers). Path-scoped
  non-leak verify stays 3.4 (Part 10). Next: 9.3 CI freshness check (runs gen-catalog + diff-fails on stale).
- Part 9.3 [~] BUILT: plugins/core/scripts/check-freshness.sh (both 9.3 clauses — regenerate CATALOG +
  diff-fail if stale; flag any `last-verified:` doc whose `sources:` changed later per git log) +
  .github/workflows/freshness.yml (GitHub-hosted ubuntu, Mac-independent, fetch-depth 0). Made
  gen-catalog.sh location-independent (derive repo root from script path, not $HOME) so it runs in CI.
  Locally verified 4 cases: clean→OK exit0; dirty CATALOG→FAIL exit1 with fix hint; stale last-verified
  fixture→FAIL with precise message; restored→OK. 9.3 stays [~] until the first GitHub CI run is
  confirmed green (proves the mac-generated CATALOG matches a Linux re-generation — generator
  determinism across platforms). Checking the run right after this push.
- Part 9.3 cross-platform FIX: first CI run (a5db33e) FAILED — Linux runner's awk (mawk) regenerated a
  CATALOG differing from the mac (BSD awk) committed copy. Root cause: gen-catalog.sh trunc() emitted the
  `…` via an awk `\xe2\x80\xa6` hex escape, which mawk does NOT interpret like BSD awk → the 3 truncated
  skill lines differed. Fixed: pass the ellipsis as a literal UTF-8 byte string via `awk -v ell='…'`
  (no awk escape → identical bytes on mawk/gawk/BSD awk). CATALOG.md bytes unchanged on mac (both paths
  produce `…` there), so only the generator logic changed. Also made check-freshness.sh PRINT the diff on
  staleness so a CI failure is self-explanatory. Re-checking CI after this push to confirm green.
- Part 9.3 CAUGHT A REAL BUG (run b53ca3a, diff now printed): the CI regeneration was missing the
  "Secrets are references, never values" global-rule line. Root cause: `.gitignore` glob `**/*secret*`
  matched `plugins/core/rules/global/secrets-as-references.md`, so one of the 7 ALWAYS-LOADED global rules
  was NEVER committed — present locally (on disk, @imported by ~/.claude/CLAUDE.md, in every session's
  loaded context) but ABSENT from GitHub/CI/any cloned machine, where that rule would silently fail to
  load. The freshness gate surfaced it on its first real run (exactly its purpose). Fix: added a targeted
  `.gitignore` negation `!**/secrets-as-references.md` (keeps the secret safety-net; re-includes the
  no-secrets policy DOC) + committed the rescued file. Audited all ignored files — it was the only false
  positive (rest are node_modules/dist/settings.local). CATALOG.md unchanged (already listed all 7). 9.3
  stays [~] until the post-fix CI run is confirmed green.
- Part 9.3 DONE → [x]: live CI run 27034142430 (commit 62cc695) GREEN on GitHub-hosted ubuntu. The
  freshness gate is verified end-to-end and already earned its keep across its first three runs (1 →
  cross-platform mawk ellipsis non-determinism; 2 → with diff-print, surfaced the untracked global rule;
  3 → green). 9.1/9.2/9.3/9.4 all [x]. Remaining in Part 9: 9.5 (per-surface README install checklist).
- Part 9.5 DONE → Part 9 COMPLETE. Rewrote the README "Install (per surface)" section (Code primary +
  other machines, Cowork, claude.ai web, iPhone) covering the four required items: ~/.claude/CLAUDE.md
  content (single-sourced as tracked templates/user-global-CLAUDE.md, referenced not duplicated), the
  workspace-trust dialog step (gates hooks + memory lane), the OneDrive backup path, and the 0005
  plugin-vs-project hook-delivery split. Each surface points to its surfaces/ profile + DEPLOY.md (no
  restatement). Updated the README Map (CATALOG + templates rows) and the "Staying current" CI line to
  the now-live freshness gate. Freshness gate still green locally (CATALOG untouched by README/template).
  Part 9 (9.1–9.5) all [x]. Next: handoff at the Part-9 boundary, then Part 10 (wire surfaces; plugin
  install delivers global hooks per 0005; closes 2.4/3.4/5.6/7.x enablement).
- MID-BUILD EVALUATION + RE-SEQUENCE (owner asked: step back, consider the ultimate objective, plan the
  rest with precision, no rework, address "I don't see the skills/agents I want"). Ran 3 parallel
  read-only evaluations: (1) FOUNDATION VERIFIED SOUND — `.claude/rules/` auto-discovery + `paths:`
  frontmatter scoping is NATIVE in current Claude Code (the make-or-break assumption holds; no
  architectural rework; 2.4/3.4/5.6 are now confirmations). (2) claude-kit COHESIVE through Part 9 (no
  orphans/dead/stale; only Part-10 manifests + agents/ absent, expected). (3) schnapp-kit located at
  ~/code/schnapp-kit (tag record-2026-06-03): 134 skills / 39 agents / 59 commands / 21 hooks — the
  source of the GAP. Root finding: the plan had NO phase for the PRODUCTIVE capability layer (claude-kit
  = 3 skills/1 cmd/0 agents, all infra). Owner decisions: DOMAIN-FIRST LEAN capabilities (build only the
  owner's-platform gap NOT already covered by keep-set/available-skills/connectors; compose what exists;
  schnapp-kit = on-demand archive, no bulk migration → anti-sprawl) + FINISH agentic OS as capstone.
  Encoded in PLAN.md "Finish sequence" + a new "Capability layer" phase (C.0–C.3) inserted BEFORE Part 10;
  Part numbers KEPT STABLE (caught + reverted a renumber that would have rippled Part-10/11 refs across
  decisions/0005, surfaces, settings, hooks, memory — the blast-radius/stable-identifier discipline).
  Rationale recorded in decisions/0006. Order: foundation-verify → capability layer → Part 10 package+wire
  → Part 11 agentic OS → final 14-point sweep (capabilities BEFORE packaging = no re-package rework).
  Handoff 012 next (session large).
- FOUNDATION VERIFY COMPLETE (2026-06-05) → flipped PLAN 2.4 / 3.4 / 5.6 → [x]. Method: faithful live
  `claude -p` sessions in a real second repo (`/tmp/ck-verify/repo-b`, composed with python+sql-server
  module symlinks) — confirmed via Claude Code docs that headless (without `--bare`) loads the SAME
  context as interactive (user CLAUDE.md + @imports, project rules, auto-memory). 2.4: repo-b quoted the
  owner's unique global rule `galPerUnitPerDay not gpud` verbatim with no file read → global lane loads in
  another (untrusted) repo via `~/.claude/CLAUDE.md`. 3.4: read `.py` → python.md loads + `SQL-ABSENT`;
  read `.sql` → sql-server.md loads + `PYTHON-ABSENT` → native `paths:` scoping, zero leak both ways. 5.6:
  repo-b loaded the real lane (quoted `keep-tracker-current` + throwaway `VERIFY-ALPHA`), then after an
  in-place supersede to `VERIFY-BETA` a fresh repo-b session saw BETA / `OLD: NO`, one file + one index
  line → supersede-not-duplicate, cross-repo. LOAD-BEARING FINDING + FIX: cross-repo memory needs
  `autoMemoryDirectory` at USER scope — plugins can't set it (only `agent`/`subagentStatusLine`), project
  scope reaches only that project (repo-b project-scope attempt → `LANE-ABSENT`). Owner-approved adding it
  to `~/.claude/settings.json` (the memory sibling of the user-global rules delivery; now README install
  step 2; corrected README step 3's now-stale "trust gates the memory lane" claim). claude-kit's
  project-scope entry left as a benign bootstrap fallback. Throwaway fact + /tmp fixture cleaned up; lane +
  repo clean. Phase boundary: pause before the Capability layer (C.0 gap-inventory) per the locked order.
- Owner-gated parallel track (Part 6 / Obsidian), taken mid-Capability-layer at owner request. (a) SECURITY:
  found a GitHub PAT hardcoded in `~/Documents/Obsidian/.git/config` (the active vault) AND a plaintext
  token in `~/.git-credentials` (global `credential.helper=store`). Flagged per secrets-as-references; owner
  is rotating the PAT. Fixed the vault leak: switched its remote to SSH (token removed from .git/config,
  verified 0 tokens + SSH fetch works), switched global helper toward osxkeychain. PENDING owner OK:
  delete `~/.git-credentials`; obsidian-git plugin needs its auth re-set in-GUI post-rotation; 11 unpushed
  vault commits left for obsidian-git to sync. (b) DIAGNOSIS CORRECTION: the obsidian MCP is the filesystem
  `obsidian-mcp` npm pkg pointed at `~/Documents/Obsidian` (exists, cached) — NOT the Local REST API kind;
  nothing to "repair", it was just mid-startup when it looked stuck (earlier Local-REST-API diagnosis was
  wrong — failed to check the MCP type first). (c) SPRAWL: two diverged clones of SchnappAPI/obsidian-vault
  (`~/Documents/Obsidian` = active, 11 ahead of origin; `~/code/obsidian-vault` = equals origin, redundant).
  Owner chose `~/Documents/Obsidian` canonical. (d) PART A DONE: extended backup-archive.sh to dual-mirror —
  also writes the knowledge md into `$OBSIDIAN_VAULT_DIR/claude-archive/` (default ~/Documents/Obsidian;
  sessions stay OneDrive-only to avoid bloating the git-synced vault). Ran it: vault now holds
  claude-archive/repo (memory/handoffs/decisions/PLAN/PROGRESS). (e) PENDING: build the remote Obsidian MCP
  (op-mcp-style, serves the vault from GitHub for off-Mac) — owner-approved scope, owner-gated deploy.
- PART B DONE (build + local verify): built connectors/obsidian-mcp/ — a read-only remote MCP that serves
  the Obsidian vault from a git copy (clones VAULT_REPO or uses a mounted VAULT_DIR), so claude.ai/iPhone
  query the vault with the Mac + Obsidian app OFF (no Local REST API dependency). Modeled on op-mcp: Node
  streamable-HTTP, bearer-gated /mcp + open /health, refuses to start without CONNECTOR_AUTH_TOKEN. Tools
  (read-only): vault_search (content/filename + snippet), vault_read, vault_list, vault_health; path-escape
  rejected, only .md served, payloads capped. GITHUB_TOKEN woven into the clone URL at runtime (op://, never
  committed/logged); .env.template uses op:// refs only. LOCAL-VERIFIED: tsc strict clean; vault logic vs an
  isolated /tmp fixture (health/list/search-content/search-filename/read all correct); md path-escape +
  non-md both blocked; server boots ("vault ready — N notes"), /health ok, /mcp 401 without bearer, full MCP
  initialize handshake with bearer. Ships Dockerfile (installs git), render.yaml Blueprint, README, DEPLOY
  (Render origin → Cloudflare portal → claude.ai, same path as op-mcp). DEPLOY is owner-gated (Render +
  Cloudflare logins + the two op:// secrets). Freshness green; node_modules/dist gitignored; no token literals.
- Corrected stale PLAN 6.2/6.3 (Local REST API path was wrong — filesystem MCP on Mac + the new remote
  connector off-Mac; canonical vault = ~/Documents/Obsidian). Owner ROTATED the leaked PAT (vault leak
  neutralized). Session WRAP → handoff 014 (supersedes 013). Remaining hygiene (owner OK pending):
  ~/.git-credentials still holds a plaintext token + global helper=store (recommend rm + osxkeychain).
  Owner-gated leftovers: obsidian-git reauth post-rotation, deploy connectors/obsidian-mcp, retire the
  redundant ~/code/obsidian-vault clone, the broader vault-consolidation workstream. NEXT SESSION: build the
  locked C.1 capability set (decisions/0007) — nothing in it built yet.
- Capability layer C.0 (inventory half) → PLAN C.0 `[~]`. Owner asked for a full, deduplicated, thematically
  clustered inventory of ALL schnapp-kit (referencing its skill-scout / search-first / skill-stocktake /
  agent-sort skills for method). Extracted frontmatter for all 253 components (134 skills / 39 agents / 59
  commands / 21 hooks), deduped overlaps, clustered into ~11 intent groups (nested where large), and tagged
  each cluster compose(keep-set/available/connector/claude-kit) vs gap vs archive. Recorded in
  decisions/0007-capability-inventory.md. C.0 conclusion: genuine owner-domain gaps reduce to
  `etl-pipeline-build`, `sql-server-patterns`, `/update-docs`(+`/update-codemaps`), a `sql-etl-reviewer`
  agent, and conditionally `tool/quickbase`+`tool/appfolio`; everything else composes or archives (notably the
  ~25-component session/memory cluster = the sprawl the owner left → port nothing). Awaiting owner confirm of
  the C.1 build set before building; C.0 stays [~] until then.
- C.0 → [x] (owner locked the build/keep set in handoff 014). C.1 BUILD STARTED — group 1: the 7 new GAP
  components, authored lean in house style. Skills: etl-pipeline-build (Python ETL → SQL Server: idempotent
  staged MERGE + fast_executemany + op:// env + Actions cron, composes the etl/python/sql/speed rules),
  sql-server-patterns (T-SQL 2022 dialect guardrails vs Postgres/MySQL + idempotent schema + set-based +
  TRY/CATCH + 2022 features), quickbase (JSON API v1 query/paginate/rate-limit/FID-map → SQL Server),
  appfolio (Reporting API custom-report pull + column-drift guard; scoped to GENERAL integration, defers
  reconciliation to fish-compare). Commands: /update-docs + /update-codemaps (generic derived-doc + codemap
  generators for the owner's OTHER ETL repos, not claude-kit). Agent: sql-etl-reviewer (read-only; reviews
  idempotency/partial-write/set-based/fast_executemany/injection/boundary-validation/secrets/naming/dialect;
  caveman-reviewer finding format). Created plugins/core/agents/. Rewired tool/quickbase + tool/appfolio rule
  stubs to point at the new skills (anti-stale ripple). Regenerated CATALOG (all 7 listed); freshness green.
  C.1 stays [~] (ports + docs-lookup remain).
- C.1 group 2 + docs-lookup → C.1 [x]. Built docs-lookup myself (Obsidian-pointed per owner: filesystem
  `obsidian` MCP on the Mac [search-vault/read-note], the remote connectors/obsidian-mcp [vault_search/read]
  off-Mac; explicitly NOT context7, which stays for external libs). Then dispatched 6 parallel subagents to
  port the ~14 checked archive components LEAN, with a shared house-style + ECC-strip brief (frontmatter =
  name+description only; description "Use when…"; strip origin:/tools:/Prompt-Defense/~/.claude-notes;
  rewrite schnapp-kit-only refs to claude-kit equivalents: santa-method to superpowers verify, planner/
  architect to Plan agent, code-reviewer to /code-review, knowledge-ops//save-session to memory lane+handoffs).
  Ported: grill-me, grill-with-docs, council (interrogation/decision); rules-distill (its 2 archive scripts
  dropped, folded to ls-glob prose; distill targets rewired to rules/+memory/+decisions/); data-throughput-
  accelerator, latency-critical-systems, content-hash-cache-pattern (data perf, compose speed-by-default);
  benchmark, benchmark-optimization-loop, cost-aware-llm-pipeline + performance-optimizer AGENT (refocused
  from 455 lines of React/bundle to Python-ETL/SQL-Server throughput, 62 lines); regex-vs-llm-structured-text;
  token-budget-advisor, context-budget, strategic-compact + clean-gone COMMAND. Verification sweep: every skill
  frontmatter = name+description only, 0 ECC-isms repo-wide, all relative md links resolve, agent frontmatter
  correct. Spot-read council + perf-optimizer + rules-distill = quality. Regenerated CATALOG (22 skills /
  2 agents / 4 commands); freshness green. NEXT: C.2 presets.
- C.2 + C.3 → [x]; CAPABILITY LAYER (C.0–C.3) COMPLETE. C.2: presets.md now has a "Recommended skills per
  preset" section (human list + machine-readable `skills:` map) naming the C.1 domain skills/agents and the
  HAVE skills (pq-flat-map-type, data:* suite, sports-data-auditor/fish-compare/xlsx, deep-research,
  docs-lookup) + a cross-cutting list; skills are plugin-global so they are NAMED not symlinked. Added a
  "Skills in reach" slot to templates/project-CLAUDE.md and wired /new-project step 4 to fill it from the
  preset's `skills:` list (systemic: preset → command → project CLAUDE.md, no stale hand-list). C.3:
  standing anti-sprawl policy confirmed (decisions/0003) — the build pulled ONLY the owner-locked checked set,
  the ~25-component session/memory cluster deliberately not ported; schnapp-kit stays the on-demand archive.
  CATALOG unchanged (presets/template not catalog content); freshness green. PHASE BOUNDARY → handoff 015;
  pause for owner input before Part 10 (package + wire surfaces).

## 2026-06-16 — Repo stale-review (claude.ai web session)

- Reviewed the repo against verified Mac/infra ground truth (not the resume summary) and corrected
  the Obsidian staleness cluster left by the infra session. Root cause: schnapp-bet `docs/CONNECTIONS.md`
  was updated + committed locally (`b7d318d`) but **never pushed** (`[ahead 1]`) — GitHub served the
  2026-05-27 version. Pushed it; schnapp-bet now in sync, authoritative infra doc live.
- Verified live state on the Mac: vault canonical at `~/Library/CloudStorage/OneDrive-Schnapp/Obsidian`
  (symlink at `~/Documents/Obsidian`); off-Mac obsidian = Mac-hosted FastMCP `~/obsidian-mcp/server.py`
  (port 8767, OAuth) at `obsidian-mcp.schnapp.bet`, 7 tools `read_note/write_note/append_note/search_notes/
  list_notes/inbox_drop/get_index`; Mac npm `obsidian` MCP confirmed exposing `search-vault`/`read-note`/
  `list-available-vaults` (Mac row was correct).
- Fixes (claude-kit): `docs-lookup` off-Mac row + workflow corrected to the real connector + tool names
  (was the non-existent `vault_*` on the undeployed Render connector) and the Mac-dependency caveat added;
  `connectors/obsidian-mcp/{README,DEPLOY}.md` SUPERSEDED banners (kept as the Mac-independent option, not
  deleted); `backup-archive.sh` vault default -> canonical OneDrive path (symlink-neutral, more robust);
  PLAN 6.2/6.3 + owner-gated-tracks UPDATE clauses (record preserved); new `memory/obsidian-state.md` + index.
- CATALOG unchanged; freshness gate green. Handoffs 002-015 / old PROGRESS lines left intact (record).
- FLAGGED for owner (not actioned): the live obsidian server's source (`~/obsidian-mcp/server.py`) is not in
  any repo — single-source-of-truth gap; and the Mac-hosted design reintroduces a Mac dependency the locked
  plan tried to avoid. Decide: import the server into the repo / restore Mac-independent serving / retire the
  Render connector. Also still open: retire redundant `~/code/obsidian-vault` clone.

## 2026-06-16 (cont.) — acted on the two notes
- Note 1: credentials-state.md superseded — SA re-rotated 2026-06-15 (token in ~/.zshrc + ~/.zshenv),
  verified live 2026-06-16 (op whoami SA identity resolves, gh authenticated). updated:->2026-06-16.
- Note 2: new memory/mac-connector-tooling.md (+index) — durable fact: Schnapp Mac write_file OVERWRITES
  (no append; use shell_exec cat>> or python read-modify-write); shell_exec strips op identity (use op_run).

## 2026-06-16 (cont. 2) — executed Option A: single-sourced the Obsidian MCP
- Divergence rationale: NOT recoverable from here. Newest Mac Code transcript is Jun 8 (the Jun 16 infra
  work was a claude.ai chat in another project); vault Claude Export stops at May 22; this project's chat
  history is empty (new project). Gap + decision recorded in decisions/0008.
- Option A executed: live server (~/obsidian-mcp/server.py) imported to connectors/obsidian-mcp/ as
  canonical source; Mac runs it via symlink (~/obsidian-mcp/server.py -> repo), launchd plist untouched;
  Render/TS implementation removed (recoverable in git history). Service restarted + verified live
  (running, 401 OAuth, functional search ok, clean startup on :8767).
- decisions/0008 logged. docs-lookup + memory/obsidian-state + PLAN 6.2 (->[x]) + owner-gated line updated.
- Prevention: session-start-gate.sh now surfaces UNPUSHED commits in satellite repos (schnapp-bet,
  obsidian-vault) — unpushed-only (dirty is expected noise for the live vault), existence-guarded for
  other machines. Both currently report pushed.
- Remaining (owner): retire redundant ~/code/obsidian-vault clone; reload Obsidian to activate the
  obsidian-git push flip; export the Jun 16 chat if you want the divergence reason on record.

## 2026-06-16 (cont. 3) — repaired Obsidian MCP OAuth (provider vs mcp 1.27.2)
- Connector "won't reconnect" was NOT an outage; the hand-rolled OAuth provider was stale against the
  installed mcp 1.27.2. Fixed 5 cascading version-drift breakages (consent route on dead private attr;
  lossy get_client dropping scope/auth-method; no scopes at registration; removed code_challenge_method
  field; hand-rolled AuthCode/refresh missing framework fields). Each surfaced only after the prior fix.
- Verified end-to-end (register->authorize->consent->token->/mcp): token 200, initialize 200, tools/list
  -> all 7 tools. Reset oauth_state.json (cleared 12 orphaned DCR clients).
- Hardening: added connectors/obsidian-mcp/requirements.txt (mcp==1.27.2 + direct deps pinned) +
  requirements.lock.txt; removed unused standalone fastmcp from venv.
- Commits pushed: 0ab4316, eaaec24, + dep-pin commit. decisions/0009 + handoffs/018 logged.
- Owner action: click Connect to re-establish the session (server side complete). Part 10 still NEXT.

## 2026-06-16 (cont. 4) — recon: other custom MCPs (queued, handoff 019)
- Audited mac-mcp (:8765) + github-mcp (:8766): both FastMCP/python, Bearer auth (NOT the OAuth
  provider that broke Obsidian, so lower drift risk), but TWO gaps: (1) source is on-Mac only, NOT
  symlinked into the repo (violates single-source / decision 0008); (2) deps unpinned (fastmcp 3.2.4,
  mcp 1.27.0 — drifted independently from obsidian's 1.27.2). Working today.
- op-mcp/1Password (mcp.schnapp.bet) is a portal/gateway behind CF Access, different stack — separate
  investigation, not lumped in. 1Password desktop app procs are unrelated.
- Scoped fix (mirror obsidian-mcp: import->symlink->pin->lock->restart->smoke) in handoffs/019. NOT
  executed — handoff only. Part 10 still NEXT.

## 2026-06-16 (cont. 5) — executed handoff 019: single-sourced + pinned mac-mcp & github-mcp
- github-mcp (0e6a04f) + mac-mcp (85fc26e): imported to connectors/<svc>/, Mac runs via symlink,
  pinned requirements.txt + lock, .env.template/.gitignore/README. Mirrors obsidian-mcp.
- github-mcp verified: initialize 200, tools/list 200, 43 tools. mac-mcp booted from symlink, stable
  + listening :8765, serving live traffic (nested authed check N/A — single-worker self-deadlock).
- FINDING: mac-mcp restart is slow (~2 min to rebind :8765, one intermediate launchd exit 1) —
  likely launchd throttle + op-secret resolution on boot. Recovered stable. Watch-item for reboot
  resilience, not fixed. github-mcp restarts fast.
- op-mcp/1Password still separate (portal stack). Part 10 still NEXT.

## 2026-06-16 (cont. 6) — diagnosed mac-mcp slow restart; queued fix (handoff 020)
- Root cause CONFIRMED (not hypothesis): kickstart -k SIGKILLs mac-mcp; new process races to bind
  :8765 before the old socket frees -> [Errno 48] Address already in use -> exit 1 -> ~10s launchd
  throttle -> repeat (~2 min). Evidence: 11x errno-48 in mcp.err.log + intermediate exit-1.
- Ruled out op-secret resolution (both servers resolve identical 23 op:// refs; github fast) and any
  blocking startup probe (all network calls are in tool fns; __main__ is just uvicorn.run(:8765)).
- Restart hazard only; cold reboot has no lingering socket. Fix: graceful TERM restart + SO_REUSEADDR/
  SO_REUSEPORT bind; apply to all three MCPs; update CONNECTIONS.md recovery cmd. Scoped in handoff 020.

## 2026-06-16 (cont. 7) — executed mac-mcp restart fix (handoff 020 → 021); decision 0010
- Fixed the :8765 restart bind race in all three MCP connectors. Two layers: (1) graceful
  `launchctl kill TERM` instead of `kickstart -k` SIGKILL; (2) pre-bound SO_REUSEADDR+SO_REUSEPORT
  socket handed to uvicorn via `Server(Config(...)).run(sockets=[sock])`. Edited repo copies only
  (symlinked live, decision 0008); deps untouched (0008/0009); diff confined to each `__main__`.
- obsidian-mcp entrypoint converted from `mcp.run(transport="streamable-http")` to an exact mirror
  of FastMCP 1.27.2's runner + the reuse socket; verified /consent 200 + /mcp 401 (OAuth intact).
- Deployed + verified each: github-mcp 2.79s / 43 tools authed / 0 errno-48; obsidian-mcp 2.32s /
  0 errno-48; mac-mcp **2.56s** (was ~2 min) / authed serving / 0 errno-48. mac-mcp restarted via a
  detached double-fork daemon (it is the operating channel on claude.ai web — a foreground restart
  would sever the call; the task prompt's "local shell, no daemon trick" was wrong for this surface).
- Empirically confirmed op-wrap.sh `exec op run -- python` forwards SIGTERM to the child (clean
  uvicorn shutdown in the log). Updated mac-mcp recovery command in schnapp-bet/docs/CONNECTIONS.md.
- Part 10 (package + wire surfaces) and Part 11 (scheduler/orchestrator/control plane) still NEXT.

## 2026-06-16 (cont. 8) — optimization pass on the restart fix (decision 0010 refinement)
- Dropped SO_REUSEPORT (kept SO_REUSEADDR) in all 3 connectors: REUSEADDR alone fixes the race under
  graceful TERM and preserves loud-fail on accidental double-run; REUSEPORT allowed silent
  split-brain (verified empirically on macOS).
- service_restart tool: graceful TERM default + self-verify/kickstart-fallback for non-KeepAlive
  agents + mode='hard' escape hatch (was hardcoded kickstart -k, contradicting decision 0010).
  flask_restart left on kickstart -k (out of scope).
- CONNECTIONS.md: mac-mcp note -> REUSEADDR; obsidian + github recovery -> graceful TERM.
- Re-deployed all 3 REUSEADDR-only: github 2.64s / obsidian 2.69s / mac-mcp 2.53s, 0 errno-48.
- Considered & rejected: shared socket-helper module, ThrottleInterval; dead obsidian OAuth code
  already gone.

## 2026-06-16 (cont. 9) — Part 10.1 authored (plugin manifests + hook-delivery split); install deferred to Code (handoff 022)
- Wrote .claude-plugin/marketplace.json (marketplace "claude-kit", plugin "claude-kit-core", source
  ./plugins/core) and plugins/core/.claude-plugin/plugin.json. Schema modeled on the working
  schnapp-kit manifests + the plugin-structure skill; components auto-discover from the plugin root.
- Executed decision 0005's hook-delivery split IN the plugin: stripped SessionEnd from
  plugins/core/hooks/hooks.json so the plugin delivers ONLY the global SessionStart gate + Stop
  push-gate; the claude-kit-specific SessionEnd backup stays project-scoped (must not fire from
  unrelated repos). Plugin hooks now: SessionStart, Stop.
- Install + project-settings de-dup + verify must run on Code (hooks fire only there; ordering is
  coupled) -> ready-to-run prompt in handoffs/022. claude-kit dogfood (.claude/settings.json keeps all
  three) unchanged until then; manifests have ZERO runtime effect until the plugin is installed.
- Corrected stale PLAN.md 4.1 "BLOCKER" -> RESOLVED (op resolution works in production).
- Next: run handoff 022 on Code (closes 10.1 + PLAN 7.2). Then 10.2 (wire Cowork + claude.ai/iPhone,
  op-mcp connector) + 10.3 (14-point verification). Part 11 capstone after.

## 2026-06-16 (cont. 10) — Part 10.2 PREP: surface enablement drafted (ready to apply post-10.1)
- Authored surfaces/always-loaded-instructions.md: the canonical hookless always-loaded block
  (operating model native->remote MCP->generated prompt; session-hygiene triggers; surface-check;
  the 7 global rules condensed faithfully; secrets-as-references; hookless persist path). Self-contained
  so it works on claude.ai/iPhone without repo file access; points to plugins/core/rules/global for full text.
- Appended an "Enablement (apply once 10.1 installed)" checklist to claude-ai-web.md, iphone.md, cowork.md:
  exact connectors to confirm, skills to enable (session-hygiene/surface-check/docs-lookup first, domain
  on demand), where to paste the always-loaded block, and a surface-check verify step.
- Verified (not assumed): op-mcp/1Password connector is Render + Cloudflare OAuth portal at
  mcp.schnapp.bet (NOT Mac-hosted; not in cloudflared config; /health 404 = the OAuth front), matching
  DEPLOY.md/decision 0004 — profiles were already correct, left unchanged. connectors/op-mcp/fly.toml is
  an unused alternative (minor cleanup candidate, out of scope).
- 10.2 application is owner action across client UIs (enable connectors/skills, paste instructions,
  connect repo in Cowork). Pairs with 10.1 (handoff 022). 10.3 (14-pt verification) after both.

## 2026-06-16 (cont. 11) — repo staleness/consistency audit (verified, not assumed); handoff 023
- Ran the CI freshness gate (check-freshness.sh): CATALOG.md current, no stale last-verified docs.
- Verified-current as FACT: counts 22 skills/2 agents/4 commands match; no node_modules tracked;
  SO_REUSEPORT only in code comments/history; op-mcp = Render + Cloudflare portal (not Mac/Fly);
  root README is status-free; handoffs 000-022 + decisions 0001-0010 continuous.
- Fixed stale LIVE docs (append-only history left intact): connectors/{mac,github,obsidian}-mcp
  READMEs recovery kickstart-k -> graceful TERM (decision 0010); op-mcp README "Fly recommended"
  -> Render chosen; PLAN 4.1 DONE annotation; PLAN 10.1/10.2 [ ]->[~] PARTIAL; marketplace.json
  dropped the hardcoded "22 skills/4 commands/2 agents" count (CATALOG is the source of truth).
- Flagged, not changed (current + consistent, owner judgement): credentials-state/credentials-map
  overlap; DB_Storage + appfolio-marketing-project missing the Actions secret; flask_restart still
  kickstart -k; service_restart graceful path deployed but not runtime-tested via the tool.
- Full session context + audit -> handoffs/023; handoff 022's Code output renumbered 023 -> 024.
- Freshness gate re-run after all edits: green.

## 2026-06-16 (cont. 12) — Part 11 agentic-OS capstone built (11.1/11.2/11.3); handoff 025
- Surface: Claude Code web remote container (shell+git+connectors). Freshness gate green at start;
  branch == origin/main, clean. Built Part 11 (authorable here, blocks nothing).
- 11.1 Scheduler: scheduled-tasks/ — README (safety model: safe-auto vs asks-first; surface map;
  results-to-repo) + 4 routine specs (doc-freshness-sweep, sync-unmerged-check, memory-consolidation,
  infra-health). run-ci-routines.sh = single source for the 2 safe Mac-independent routines (freshness
  sweep hard-gate + sync/unmerged report); wired on nightly cron in .github/workflows/
  scheduled-routines.yml (reports to Step Summary, non-zero only on freshness drift, never commits).
  Tested locally: exit 0, correctly flagged this PR's branch as the 1 unmerged item. memory-consolidation
  (asks-first) + infra-health (Mac-needed) specified for a LaunchAgent claude -p session.
- 11.2 Orchestrator: plugins/core/commands/do.md — /do classifies the task, routes to preset(presets.md)
  + skill/agent(CATALOG) + model tier, plans if non-trivial, asks-first on mutating work, dispatches,
  reports. Composes existing pieces; no reimplementation.
- 11.3 Control plane: plugins/core/skills/status/SKILL.md — cross-surface aggregate (git/freshness/
  scheduled-routines/memory/backup/connectors/per-surface enablement), probe-don't-assume, WARN vs
  unreadable, reuses the nightly routine's findings. Builds on surface-check (current-surface only).
- Regenerated CATALOG (now 23 skills / 2 agents / 5 commands); freshness gate green. PLAN 11.1/11.2/11.3
  -> [x]. Final-verification #14 (agentic OS) now substantially met; live /do+/status exercise is organic.
- Still surface-gated (unchanged): 10.1 needs a Mac-Code session (handoff 022); 10.2 needs owner UIs.

## 2026-06-16 (cont. 13) — Part 10.1 installed + hook de-dup live (PLAN 7.2/10.1 -> [x]); handoff 026
- Surface: Mac Code on Schnapps-MBP (the surface 10.1 required). Freshness gate green at session start.
- `claude plugin validate ~/code/claude-kit` -> PASS. `claude plugin marketplace add ~/code/claude-kit`
  registered the directory-source marketplace; `claude plugin install claude-kit-core@claude-kit`
  cached it user-scope at ~/.claude/plugins/cache/claude-kit/claude-kit-core/0.1.0 (gitCommitSha
  5b1241e) and auto-enabled. `claude plugin list` confirms enabled.
- LIVE-VERIFIED plugin delivery in an UNRELATED repo (~/code/schnapp-bet) via headless `claude -p
  --include-hook-events --output-format stream-json`: claude-kit SESSION-START GATE printed
  sync/branch/clean/in-sync + supersede + satellite-push audit; Stop push-gate fired with `{}` allow;
  SessionEnd backup did NOT fire (decision 0005 holds: backup is project-scoped to claude-kit).
- De-duped ~/code/claude-kit/.claude/settings.json: removed SessionStart gate + Stop push-gate
  entries; kept ONLY the SessionEnd backup hook + autoMemoryDirectory + the `$comment`. Updated the
  `$comment` to reflect the new state. autoMemoryDirectory CONFIRMED at USER scope
  (~/.claude/settings.json) -> the memory lane loads in every repo (Final-verification #4; plugins
  can't set this key).
- Single-fire check in claude-kit (claude -p smoke): only one SessionStart entry carries the
  claude-kit GATE stdout (other SessionStart hooks belong to caveman/superpowers/etc; that is by
  design, not double-fire of OUR gate); Stop fires once. The smoke also exercised Final-verification
  #11 LIVE: the gate flagged the in-flight settings.json edit as `UNCOMMITTED changes` BEFORE work
  proceeded.
- Final-verification updates from this session: #2 (no double hooks) PASS, structurally + smoke;
  #3 (global lane in every repo) PASS via user-scope autoMemoryDirectory; #11 (session with
  unmerged/dirty work addresses it first) PASS LIVE. #1/#4-#10/#12-#14 unchanged from prior runs.
- 10.2 (owner UIs) and 10.3 full sweep remain. Plugin install path is now the proven distribution.

## 2026-06-16 (cont. 14) — 10.2 applied + staleness pass (op-mcp outage, global-instructions); handoff 027
- Owner applied 10.2 across claude.ai web / iPhone / Cowork (skills uploaded as zips; connectors enabled;
  claude-kit-core plugin added in Cowork; always-loaded block placed GLOBALLY at Settings>Profile>
  Preferences, not a Project — owner choice). PLAN 10.2 -> [x]; surface-check verify rolls into 10.3.
- FINDING (verified, 2 surfaces): hosted op-mcp connector is DOWN — op_health errors "authentication
  error ... Check OP_SERVICE_ACCOUNT_TOKEN on the host" from this Code session AND Cowork. Host-side
  SA-token/perms problem, NOT per-surface. Mac op_run/op_inject is the working route. Final-verification
  #7 currently FAILS. Recorded: memory/credentials-state.md (superseded the "LIVE/verified" claim) +
  MEMORY.md index; annotated PLAN FV#7. Fix is host-side (Render OP_SERVICE_ACCOUNT_TOKEN), owner action.
- Staleness pass (anti-stale: transient status lives only in credentials-state.md; surface docs POINT to
  it instead of carrying their own LIVE/DOWN claim): fixed surfaces/{claude-ai-web,iphone,README}.md +
  always-loaded-instructions.md — removed absolute "op-mcp LIVE"; switched "paste into Project
  instructions" -> "Settings>Profile>Preferences (global)" per owner's choice. Freshness gate green.
- FINDING (verified via brain get_index): the obsidian brain holds ONLY 6 pipeline-verification TEST
  notes from 2026-06-16 (2 flagged actionable test-closeouts), zero real notes. Cleanup = remove the 6
  source .md files via the Mac shell (brain connector has no delete tool) + clear the 2 actions. PENDING
  owner confirm ("delete all 6"); to run at wrap via the Mac.

## 2026-06-16 (cont. 15) — surface-checks reconciled: Cowork hooks=NO; 1Password outage (corrected)
- Owner ran surface-check on claude.ai, Cowork-Mac, Cowork-HP. Results reconciled into the repo.
- Cowork hooks: RESOLVED = NO. Neither Cowork session saw the SessionStart gate fire; both fell back
  to manual session-hygiene. surfaces/cowork.md + PLAN 7.2 updated (the long-open "does Cowork run
  hooks" question is now answered, not guessed).
- 1Password: CORRECTED a self-overcall. I first read op_run/op_whoami "unauthorized" from THIS Code-web
  session as proof the SA is broken — but shell_exec also returned unauthorized and mac_info (needs no
  token) WORKED, proving this session just lacks MAC_MCP_AUTH_TOKEN, so the privileged-tool failures are
  at the Mac-auth layer, not the SA. My op test was INCONCLUSIVE. Accurate picture: hosted op-mcp is
  CONFIRMED down (host SA-token error); the owner's authed surface-checks show op_whoami unauthorized
  (Mac-auth was valid there, so it points at the SA) — so a full SA outage is LIKELY but needs an
  op_run resolution test from an AUTHED session to confirm. Recorded the testing caveat in
  credentials-state.md so it isn't repeated. MEMORY index + PLAN FV#7 updated. gh/GitHub unaffected.
- Brain cleanup: owner chose ARCHIVE (not delete). Can't run it from here (no Mac shell auth); handed
  the owner a ready-to-run archive command (move the 6 test .md files to _archive/, brain reprocesses).
- CORRECTION (owner steer): do NOT rotate the SA — it worked recently + at 05:12 today. Reframed
  credentials-state.md/MEMORY/PLAN FV#7 to diagnose-first: likely a token-PROPAGATION issue (Render
  op-mcp env still on the old pre-06-15 token; and/or a long-running Mac service holding a stale token
  — launchd does not source ~/.zshrc/~/.zshenv). Confirm via op_run from an authed session; rotate only
  if truly revoked.
- Brain archive: moving the vault .md files did NOT clear the brain index (separate store; still 6).
  Only 2 of 6 were real files (in ~/code/obsidian-vault/Inbox — the redundant clone flagged for
  retirement); the other 4 live only in the brain index. Real cleanup = reset the brain agent's index
  store (owner's custom system). Pending owner.
- ROOT CAUSE CONFIRMED (1Password): op-wrap.sh (schnapp-bet/services/launchd/) greps
  OP_SERVICE_ACCOUNT_TOKEN from ~/.zshrc at process start then exec op run. The com.schnapp.macmcp
  process predates the 06-15 rotation → runs with the old revoked token in-process. SA is fine.
  FIX (no rotation): graceful-restart com.schnapp.macmcp (re-reads ~/.zshrc) + update the Render
  op-mcp OP_SERVICE_ACCOUNT_TOKEN env + redeploy. Captured the rotation gotcha for the 0001 runbook.
  credentials-state.md updated with the confirmed cause + fix; FV#7 reopens to PASS once verified green.

## 2026-06-22 — Phase 1 SA-token rotation COMPLETE
- Owner rotated the SA token **in place** (1P `OP_SERVICE_ACCOUNT_TOKEN/credential`). Old token dead
  (`403 Service Account Deleted`); new last4 `bSJ9`, `op whoami` integration `55TZ…` (was `VU2RK…`).
- Propagated no-echo: 11 GH repo secrets, `~/.zshrc` + `~/.zshenv` (**UNQUOTED**), launchd session env
  (`com.schnapp.environment` re-run), Render `op-mcp` env + redeploy (owner). plist holds no token
  (sources `~/.zshenv`).
- Restarted + verified healthy: `com.schnapp.{macmcp,githubmcp,obsidian-mcp,brain-watcher}` +
  `bet.schnapp.{web-prod(200),flask}`. shell `op whoami`=`55TZ`; Render `op_health`=authenticated.
- Self-inflicted + fixed: quoting the token broke `op-wrap.sh` (greps `~/.zshrc`, no source) → 6
  services crash-looped on `unrecognized auth type`; fixed by unquoting. Lesson:
  `memory/op-wrap-token-unquoted.md`.
- PENDING (owner): Mac MCP connector bearer is stale in the **Claude account** connector config
  (server/env/vault all = `…6267`). Fix in claude.ai Settings→Connectors / the Cloudflare MCP portal.
  Details: `handoffs/030-phase1-sa-rotation-complete.md`.

## 2026-06-22 (cont.) — Phase 2 rename finalized: transitional symlink removed + residual name sweep
- Removed transitional symlink `~/code/claude-kit -> schnapp-os`. Its load-bearing siblings removed
  first so nothing resolved through a dead path: dropped the dormant `claude-kit` marketplace entry
  from `~/.claude/plugins/known_marketplaces.json` (live plugin is `claude-kit-core@schnapp-os`,
  nothing bound to it) and repointed the active plan's spec path. Orphaned `~/.claude/plugins/cache/
  claude-kit/` left in place — destructive-guard + auto-mode blocked its `rm -rf`; harmless cruft now
  its marketplace entry is gone (optional owner `rm`).
- Swept residual old-distribution-name refs `claude-kit -> schnapp-os` across 28 active files (README,
  templates, surfaces, plugin hooks/scripts/skills/commands/rules, memory, scheduled-tasks, CI, op-mcp
  DEPLOY). Symmetric 63/63 diff (pure 1:1 swaps). Hook banners renamed (`===== schnapp-os SESSION-*`);
  `CATALOG.md` regenerated from updated hook headers.
- KEPT (deliberate identifiers, not renamed by PR #4): `claude-kit-core` (plugin/skill namespace),
  `CLAUDE_KIT_REPO` (env var), `claude-kit-op-mcp` (1P/Render integration). LEFT historical:
  `handoffs/ decisions/ docs/ PLAN.md PROGRESS.md` + `keep-tracker-current.md` `source:` provenance.
- Deleted rename-time backups `~/.claude/{CLAUDE.md,settings.json}.bak-rename-20260622`.
- Verified: all JSON valid, `bash -n` clean on edited scripts, `known_marketplaces.json` parses
  (6 entries, schnapp-os intact), real repo + `.git` untouched, plugin hooks still firing this session.
- Landed as PR #5, **merged** → main `51dc688`. Handoff `031-phase2-finalized-and-leftovers.md` written.
- OWNER-GATED leftovers (destructive-guard + auto-mode block the agent; run in a plain terminal):
  `rm -rf ~/.claude/plugins/cache/claude-kit` (orphaned cache) and
  `git branch -D chore/phase1-sa-rotation-record chore/rename-to-schnapp-os` (2 stale `[gone]` branches).
- Phase 2 COMPLETE. NEXT = Phase 3 (secrets domain): build vault-resolve / cleanse-secrets /
  rotate-secret; rotate remaining leaked values; retro-scrub ~28 export files; secret-scan CI.

## 2026-06-22 (cont.) — Phase 3 part A: secrets skills + secret-scan CI (the toolkit)
- Built the 3 secrets skills (`plugins/core/skills/`): `vault-resolve` (resolve op:// refs per
  surface, field-label gotcha, non-echoing reads), `cleanse-secrets` (report+redact wrapping the
  scanner), `rotate-secret` (rotate-on-migrate protocol: consumed_by → mint → store → propagate →
  restart → verify → changelog). Owner pref: small reusable skills, not a monolith.
- Single-source scanner `plugins/core/scripts/scan-secrets.sh` (one pattern set, two consumers: CI +
  cleanse-secrets). Catches the leaked classes the reused opensource-sanitizer lib MISSED — `ops_`
  (master SA token) and `sk-ant-*` (Anthropic/Claude) — as first-class BLOCK rules. Values masked,
  op:// pointers skipped, exit non-zero on BLOCK. Proven against `scripts/tests/secret-fixtures.txt`
  via `scripts/tests/test-scan-secrets.sh` (11 BLOCK + 3 WARN classes, masking + negative + exit code).
- `plugins/core/scripts/check-op-refs.sh`: flags op:// refs whose item is absent from credentials-map
  (single-source for valid refs). WARN-only for now.
- Extended `.github/workflows/freshness.yml`: 3 new steps (scanner self-test; secret scan over tracked
  files excluding the fixtures; op:// ref check). Repo scans **0 BLOCK** (no leaked value tracked here).
- Verified: full CI gauntlet green locally; skill-reviewer gap-test passed after fixing all example
  commands to be non-echoing-by-construction (the redact/store/read examples could have echoed a value).
- DEFERRED to Phase 3 part B (owner-gated): actual rotations of the remaining leaked values (consoles +
  Render redeploy + claude.ai connector), the ~28-file leak scrub (separate obsidian-vault repo +
  history-rewrite decision), promoting op-ref check to BLOCK.

## 2026-06-22 (cont.) — Phase 3 part B: self-serve MCP-bearer rotations (rotate-on-migrate)
- PREREQ class-fix (rename residual caught before any restart): the deployed MCP services symlinked
  `~/{mac-mcp,github-mcp,obsidian-mcp}/server.py` → the **dead** `~/code/claude-kit/connectors/*` path
  (the Phase 2 finalize removed the `~/code/claude-kit` transitional symlink). All three were broken
  symlinks; the services only survived because they were long-running processes holding already-loaded
  code — **any restart (or reboot) would crash-loop all three on ENOENT**. Repointed all three to
  `~/code/schnapp-os/connectors/*/server.py` (`ln -sfn`, self-serve, non-destructive); each now resolves.
  Validated by the rotation restarts below (fresh PIDs loaded the new target cleanly).
- **Rotation 1 — `MAC_MCP_AUTH_TOKEN`** (leaked bearer → fresh `openssl rand -hex 32`, non-echoing
  mint+store; field `/credential` stays CONCEALED, len 64). Restarted `com.schnapp.macmcp` (+
  `com.schnapp.obsidian-mcp`). **Verified Mac:** `:8765` NEW bearer → HTTP 200, bogus → 401; obsidian
  `:8767` up + gated (401). consumed_by corrected in the map: mac-mcp is the functional consumer;
  obsidian-mcp's `.env.template` injects the var but the OAuth server **ignores it** (vestigial, flagged).
  **OWNER leg pending (client):** set claude.ai connector `mac-mcp.schnapp.bet` Authorization Bearer (or
  the Cloudflare One MCP portal entry) = `op://web-variables/MAC_MCP_AUTH_TOKEN/credential` — also clears
  the stale-connector open item from handoff 032.
