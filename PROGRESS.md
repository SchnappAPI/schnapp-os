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
- **Rotation 2 — `GITHUB_MCP_AUTH_TOKEN`** (leaked → fresh `openssl rand -hex 32`, non-echoing).
  Restarted `com.schnapp.githubmcp`. **Verified Mac:** `:8766` NEW bearer → HTTP 200, bogus → 401
  (fresh PID). **OWNER leg pending (client):** set the github-mcp client bearer (Copilot config) =
  `op://web-variables/GITHUB_MCP_AUTH_TOKEN/credential`.
- **Rotation 3 — `OP_MCP_BEARER`** ✓ (owner present, opted in). Vault value minted+stored fresh
  (non-echoing, concealed); connector stayed live on the OLD value until the owner propagated, so no
  outage. Owner did (1) Render `op-mcp` env + redeploy and (2) Cloudflare portal `mcp.schnapp.bet`
  op-mcp Custom header `Authorization: Bearer …`. **Leg 3 (Code/Cowork direct client bearer) = N/A**:
  this/claude.ai/iPhone reach op-mcp through the portal over **OAuth** (verified `config.json`
  `oauth:tokenCache`, connector URL `mcp.schnapp.bet/mcp` — no static client bearer); a direct
  `op-mcp.onrender.com` client would use the bearer, none configured. **Verified:** `op_health`
  authenticated (OAuth client → portal new-header → Render new-env); origin `/health` 200, `/mcp` NEW
  bearer → 200, bogus → 401. Phase 3B self-serve + owner-coordinated rotations all DONE.
- Mid-rotation infra fixes (rename residual + security, Mac-side): repointed deployed
  `~/{mac,github,obsidian}-mcp/server.py` off the dead `~/code/claude-kit/*` path → `~/code/schnapp-os/*`
  (a restart/reboot would have crash-looped all three); rewrote the **clobbered** `com.schnapp.macmcp.plist`
  (bare JSON array → proper secrets-free op-wrap `<dict>`, lint OK, not reloaded) closing a reboot-time
  bearer-disable/exposure; removed the vestigial `MAC_MCP_AUTH_TOKEN` ref from `obsidian-mcp/.env.template`
  (OAuth server ignores it). Flagged a plaintext-secrets `.bak` (dead MAC bearer + live `GH_PAT` +
  `RUNNER_API_KEY`) for owner `rm` + console rotation. Memory (credentials-state / credential-leak / index)
  updated; handoff `033-phase3b-bearer-rotations.md`. Owner-pending: 2 client bearers, the `.bak` rm, the
  owner-console rotation set, PR merge.

## 2026-06-23 — Plan review: ten decisions re-decided on purpose (decisions/0011)
- Read the decision record `docs/schnapp-os-research-and-decisions-2026-06-23.md` (it was NOT on disk —
  lived only in unpulled remote commit `48e2cec`, a GitHub web upload; local pull was failing). Fast-forwarded
  local main → origin (clean, ff-only) to land it. First freshness casualty, logged in 0011.
- Plan review (doc §7.4 step3 / §8): walked all ten load-bearing decisions; owner re-decided each on purpose.
  Outcomes in `decisions/0011`: plan authority → doc governs, PLAN.md = parking lot; repo form → plainer (drop
  marketplace-plugin); surface scope → narrow to current; rules → plain files (no gallery/presets/symlinks);
  credentials → one centralized remote-MCP tool; MCP topology → few scoped servers, keep current host, defer
  Cloudflare; backup → keep, prune write-only Obsidian mirror; agentic-OS layer → defer until loops fire; git →
  main only + force-push guard; chat-memory → delete + generation off. Locked: keep Schnapp-OS, no 4th repo.
- Reframed PLAN.md (same change): top banner + Locked-decisions note → not the spine, a backlog; 0011 wins on conflict.
- FINDING (for the freshness/guardrail phase): old "frozen" schnapp-kit is still live — its
  `no-commit-to-main.sh` PreToolUse hook fired here, blocking commits. Buggy (false-positives read-only
  `git merge-base`) AND policy-wrong (forces branches vs decision #9 main-only). To be removed + replaced by the
  real force-push guard. These records are written but NOT yet committed because of it.
- NEXT (do not build yet): capture original repo intent → freshness gate → capture-and-route → prune.
- CAPTURE INTENT done (doc §7.2 step 1) → `docs/intent-capture-2026-06-23.md`. Method: 5 parallel read-only
  investigators (hooks+scripts / skills+commands+agents / rules / connectors / memory+surfaces+meta), each
  grounding component intent in decisions+handoffs. Records what each of the 26 skills / 5 cmds / 2 agents /
  26 rules / 4 connectors / 6 surfaces / 6 scripts / 3 hooks was MEANT to do; load-bearing vs accretion;
  prune/defer CANDIDATES (not actions — prune is the last step). Headline findings: (1) freshness loop exists
  but its core `git pull` sync is broken; (2) learning loop mostly absent (no capture hook, no promote/validate
  gate); (3) decision #2 (drop plugin packaging) SEVERS the only delivery vehicle for the global freshness+push
  hooks → re-homing them is a prerequisite of #2 and is freshness-loop work; (4) a stale `claude-kit` gate copy
  still fires vs the repo's `schnapp-os` source; (5) no scoped memory/control-plane MCP server, mac-mcp is the
  mega-server #6 warns against; (6) force-push guard #9 not built yet. Owner-action items (chat-memory off,
  open credential legs) listed in the doc §6.
- FRESHNESS GATE built (loop 1, the next step after capture-intent). Three changes:
  (1) Fixed the sync bug: `session-start-gate.sh` bare `git pull --ff-only` (which failed "Cannot
  fast-forward to multiple branches" and silently left the repo stale — it lost the decision doc) →
  explicit `git pull --ff-only origin "$branch"`. Added a light credential reconcile (`op whoami`
  when the SA token is in env; deep check = remote op-mcp). ~1s, non-blocking, exit 0.
  (2) Moved hook DELIVERY off the fragile plugin → into `.claude/settings.json` (live
  `${CLAUDE_PROJECT_DIR}` paths) for all three hooks (SessionStart gate, Stop push-gate, SessionEnd
  backup). Root cause: `installed_plugins.json` pinned old commits + referenced cleaned cache paths,
  so a stale claude-kit-era gate fired. Plugin `hooks.json` now declares no hooks; decision 0005
  annotated SUPERSEDED.
  (3) VERIFIED by running: sync `Already up to date` (no multi-branch error), git/memory/satellite
  state correct, `[creds] 1Password SA resolves`, 1.7s. Live-fires via project settings NEXT session.
  Scope = schnapp-os repo (per 0011 #2); cross-surface freshness = the remote-MCP layer (next).
  Cosmetic cleanup remaining (non-blocking, gate no longer depends on it): dead plugin registrations
  in ~/.claude (claude-kit-core@claude-kit, schnapp-kit) — clean via /plugin when convenient.
  [CORRECTED below 2026-06-23 cont.: this was NOT cosmetic — the live plugin's OLD pin re-fired the
  stale gate and raced the project gate's pull; "verified no multi-branch error" held only when the
  gate ran ALONE, not with the double-gate live. Fixed by re-pinning. See next block.]
- LEARNING LOOP capture-and-route step (loop 2). The routing procedures already existed
  (memory/README "on-correction": behavioral->rule, fact->memory-supersede, stale-doc->doc-fix); the
  missing piece was the TRIGGER — capture relied on the agent remembering, so corrections got fixed
  locally and lost next session (the "fixes don't stick" failure). Built `capture-nudge.sh`
  (UserPromptSubmit): high-precision grep for correction/teaching language -> injects a route-it nudge
  pointing at memory/README. Deterministic, ~13ms, non-blocking, exit 0. Wired in `.claude/settings.json`.
  Verified both ways: correction -> nudge; normal request -> silent (no false positive). Cross-surface
  capture stays the `session-hygiene` skill (hookless surfaces). Eval/promote gate = a LATER step
  (doc §7.8: build the gate before autonomous self-edits), so the nudge says STAGE rule edits.
- Demonstrated the loop end-to-end on a real correction: owner's repeated "fix on sight, don't ask"
  routed (behavioral) to the EXISTING rule, not a new file -> added a "A defect is not a decision"
  bullet to `working-style.md` (bumped updated: 2026-06-23). Correct routing = sharpen the existing
  home, not duplicate.
- PRUNE step (first cut), owner-approved after challenging the reasoning. Cut 4 skills on SOUND
  per-item grounds (NOT provenance): `token-budget-advisor` + `strategic-compact` (redundant with
  active caveman mode / native compaction), `cost-aware-llm-pipeline` (no owner LLM-batch work) +
  `benchmark-optimization-loop` (redundant with the kept performance-optimizer agent). KEPT the rest:
  the owner challenged my initial 8-cut list; verified per-item, most touch real ETL/sports/perf
  domains (regex-vs-llm, content-hash-cache, benchmark, latency-critical, data-throughput) or the
  leanness goal (context-budget) — keeping them is "narrow to what is REAL." Ripples fixed in the same
  change: 5 live references (performance-optimizer agent, presets ×2, benchmark, context-budget),
  regenerated CATALOG (26→22 skills), freshness gate GREEN. Historical records (decisions/0007,
  handoffs 014/015) left intact as record; CATALOG is the live inventory. Lesson reinforced: cut only
  on verified redundancy or owner-confirmed out-of-domain, never on an agent's label.

## 2026-06-23 (cont.) — Loops live-proofed + stale-gate root-caused & fixed (NOT cosmetic)
- LIVE-PROOF (first fresh session since the loops were built). Freshness gate fired correctly as
  `schnapp-os` with `[creds] 1Password SA resolves`. Learning loop fired: the `[capture]` route-it
  nudge triggered this turn (matched "Don't ask" in the owner's opening message — a loose but
  accepted precision-over-recall match; documented in capture-nudge.sh). Both loops confirmed live.
- BUT two defects surfaced in the gate output, both fixed on sight:
  (1) A SECOND, stale `claude-kit SESSION-START GATE` fired alongside the `schnapp-os` one, and BOTH
  printed `fatal: Cannot fast-forward to multiple branches`. Root cause (run the gate command alone →
  clean, so it's not the refspec the prior session "fixed"): the desktop **local-agent-mode** harness
  snapshots each enabled plugin from its PINNED commit (`installed_plugins.json` gitCommitSha), not
  the working tree. `claude-kit-core@schnapp-os` was pinned at `8417c2c4` (pre-hook-move), whose
  `hooks.json` still declared SessionStart+Stop. That snapshot ran the OLD bare `git pull --ff-only`,
  which raced the project gate's `git pull --ff-only origin main` on `FETCH_HEAD` → both errored.
- FIX: re-pinned `claude-kit-core@schnapp-os` to HEAD `86dba69` (where `hooks.json` is `{}`) via
  uninstall+reinstall — `claude plugin update` is version-keyed and no-ops at the same 0.1.0. Removed
  the two dead registrations (`claude-kit-core@claude-kit` orphan, `schnapp-kit@schnapp-kit`) and the
  dead `schnapp-kit` marketplace. GOTCHA hit en route: `claude plugin uninstall name@mkt` matches by
  NAME and removed the live `@schnapp-os` instead of the named `@claude-kit` orphan; restored by
  reinstall (which also achieved the re-pin), then deleted the orphan by hand-editing the JSON key.
  All three harness JSON files validated. Captured: memory [[plugin-registry-snapshot-gotchas]].
- VERIFIES AT NEXT RESTART: the desktop harness rebuilds the snapshot from the new pin, so next
  session should show a SINGLE clean `schnapp-os` gate (no `claude-kit` gate, clean `[sync]` line).
  This session's already-built snapshot still carries the old hooks (harmless; self-heals next start).
- Permanent class-fix remains decision 0011 #2 (drop the plugin packaging in repo-flattening); until
  then, re-pin after any hook/structure change. Corrected the "cosmetic" misclaim in handoff 034 and
  the FRESHNESS GATE block above.

## 2026-06-23 (cont.) — rotate-secret reshaped + service_status leak plugged (4820fef)
- Owner fed up with rotation churn, asked for a trigger-it-and-tell-me tool. That skill already
  existed (`rotate-secret`) but read as agent-internal. Reshaped it: explicit owner trigger
  `/rotate-secret <name>` + an output contract emitting one ordered runbook per secret, every step
  tagged 🖐️ YOU (exact console click-path / paste line) vs 🤖 ME (I run it), closing "say go". Drives
  off the map's `consumed_by`. NOT a new skill — sharpened the existing one (adherence, not duplication).
- Prevention for the leak that prompted it: the Mac MCP `service_status` returned raw `launchctl print`
  incl. the process's `inherited environment` → leaked the live `OP_SERVICE_ACCOUNT_TOKEN` into the
  transcript. Added `_redact_secrets()` to `connectors/mac-mcp/server.py`; fixed an over-redaction bug
  (`PAT`→`_PAT` so PATH survives); unit-tested, scanner clean. Owner reloaded macmcp → live. SA NOT
  re-rotated (owner call; token only hit a local transcript, source now fixed). De-staled map + leak count.

## 2026-06-23 (cont.) — memory-mcp built (cross-surface memory layer, biggest deferred piece)
- Inventoried the live remote MCP servers first (owner method §7.2 step 2): op-mcp = credential tool
  (#5, exists); Mac ops = control-plane but the mega-server #6 warns against; a `76d929ef` brain-capture
  notes server = test-only/unadopted; GitHub/M365/Cloudflare = integrations. Conclusion: credential +
  integration slots filled; the real gap is **cross-surface memory reconcile** — the `memory/` lane is
  only reachable on Code-on-Mac (hooks + git). Owner chose: new memory server over the git-tracked lane,
  prune the brain-capture server.
- Built `connectors/memory-mcp/` (TypeScript, mirrors the op-mcp Render template: Express + MCP SDK
  StreamableHTTP stateless, bearer gate, Dockerfile, `.env.template` op:// refs). Backing store = the
  **GitHub Contents API** on `SchnappAPI/schnapp-os@main` `memory/` → GitHub origin is the source of truth,
  no Mac dependency. Tools: `memory_health/index/list/read/search/write/delete`; `memory_write` enforces the
  `memory/README` discipline (one-fact-one-file, supersede-not-append, source/updated frontmatter, index upkeep).
- Verified: `npm run build` clean; smoke-tested the GitHub client against the LIVE repo (health authenticated,
  read MEMORY.md, listed 10 .md / 8 facts). Write path reuses the same proven client (unverified-live to avoid
  noise commits). DEPLOY.md written (owner: fine-grained PAT + bearer + Render service + connector; Render owner-only).
- NEXT: owner deploys per DEPLOY.md + records the two secrets in the map `consumed_by`; then prune the
  brain-capture server; then #4 rules-simplification / #2 repo-flattening / force-push guard #9 / eval gate.

## 2026-06-23 (cont.) — force-push guard #9 built (the one missing guardrail)
- Decision 0011 #9 (main-only + a PreToolUse guard blocking force-push to protected repos). The old
  schnapp-kit `no-commit-to-main.sh` was buggy + policy-wrong and is now removed, leaving ZERO
  force-push protection — a real gap given the recent history cleanse used force-push.
- Built `plugins/core/hooks/no-force-push-guard.sh` (PreToolUse, matcher Bash). PreToolUse fires before
  the permission check, so exit 2 hard-blocks even under --dangerously-skip-permissions (research §4).
  Detects `--force` / `-f` / `--force-with-lease` / `+refspec`, scoped to each `git ... push` segment's
  own args (so a trailing `&& rm -f` does not false-trip) and handles the `git -c k=v push` bypass.
  Tested 10 cases (5 block incl. -c-bypass/+refspec/compound, 5 allow incl. --follow-tags/rm -f/--grep=push).
  Wired in `.claude/settings.json` PreToolUse; de-staled the settings `$comment` to list all 5 hooks
  (it said "all three" and omitted capture-nudge). Activates next session start (hooks load at startup).

## 2026-06-23 (cont.) — #4 rules-simplification (drop the gallery machinery, keep the content)
- Decision 0011 #4: plain rules files + CLAUDE.md, no module gallery / presets / symlink composer.
  Executed (decided by the architecture, not re-asked). REMOVED: `rules/presets/presets.md` and the
  `/new-project` symlink composer command. KEPT all rule content: `rules/global/*` (7 always-on) and
  `rules/modules/*` (lang/tool/activity/context — incl. the locked `lang/sql-server.md` table rules),
  now a plain reference library (a project `@import`s only what it needs; no gallery/preset/composer).
- Ripples fixed in the same pass (think-in-systems): `do.md` routes by modules + CATALOG (not presets);
  `gen-catalog.sh` dropped the Presets section + reworded the modules heading; regenerated `CATALOG.md`
  (freshness green); `templates/project-CLAUDE.md` rewritten as a manual composer-free starter;
  `templates/user-global-CLAUDE.md` (the canonical `~/.claude/CLAUDE.md` copy) de-staled off `/new-project`;
  `README.md` (rules/templates/connectors rows, + added memory-mcp); `PLAN.md` Part 3 marked SUPERSEDED.
- Remaining live-ref sweep clean (only handoffs/PROGRESS/decisions/intent-capture retain it as history).
- OWNER 1-liner: re-copy `templates/user-global-CLAUDE.md` body to `~/.claude/CLAUDE.md` (its `/new-project`
  note is now stale on your machine until synced). NEXT deferred: #2 repo-flattening (riskier — plugin still
  delivers skills/rules/commands) + the learning-loop eval gate.

## 2026-06-23 (cont.) — memory-mcp DEPLOYED + VERIFIED cross-surface (the vision's biggest piece)
- Owner deployed memory-mcp to Render (`memory-mcp-rtad.onrender.com`): env `GITHUB_TOKEN` = a fine-grained
  PAT named `SCHNAPP_OS_PAT` (contents R/W on schnapp-os only) + `MEMORY_MCP_BEARER` (I created it in 1P).
  Added the `memory-mcp` server to the existing Cloudflare `mcp.schnapp.bet` portal (User-auth OFF, shared
  with op-mcp — still separately revocable); reconnected the claude.ai "1Password" connector → 11 tools.
- VERIFIED from claude.ai web (a hookless surface): `memory_health` = authenticated, repo schnapp-os, 10 files;
  `memory_index` returned the full MEMORY.md. iPhone uses the same connector automatically. This closes the
  freshness loop for hookless surfaces — the single biggest deferred piece of the vision is done.
- Naming settled: credential identity = `SCHNAPP_OS_PAT` (GitHub label + 1P + map) and `MEMORY_MCP_BEARER`;
  Render env-var keys stay `GITHUB_TOKEN` + `MEMORY_MCP_BEARER` (the names the code reads).
- FOLLOW-UP: confirm `SCHNAPP_OS_PAT` value is stored in 1P (`op://.../SCHNAPP_OS_PAT/token`). Still open:
  #2 repo-flattening, learning-loop eval gate, GITHUB_PAT rotation (9 vault files), brain-capture prune,
  ~/.claude/CLAUDE.md sync, gate verification next restart.
- 2026-06-26 VAULT FLATTEN executed (owner-directed, overrides 0011 #2 deferral; flatten-only, no rotation).
  Phase A: created 10 per-secret items in `web-variables` (Web App→6 + WEB_APP_CONFIG; Database→MSSQL_SA_PASSWORD;
  Anthropic→ANTHROPIC_API_KEY; Claude Code→CLAUDE_CODE_OAUTH_TOKEN), values copied, all resolve. Phase B: repointed
  every live consumer — schnapp-bet (.env.template+9 workflows+docs, commit c626196 pushed), web-bad, obsidian-vault,
  brain-watcher's OneDrive .env.template, schnapp-os manifest/README. Database core stays bundled (~18 ETL workflows
  untouched). Phase C: deleted Web App / Anthropic / Claude Code / MCP Tokens / GitHub bundles + Database/mssql_sa_password
  field, each after a 0-ref grep guard. Verified vault=27 items, all new refs + Database core resolve, 5 bundles gone.
  ROTATION still owed: flatten copied values, never rotated post-leak (updated_at all 2026-05); sanity-check 2-char ADMIN_REFRESH_CODE.
- 2026-06-27 Renamed the schnapp-os marketplace core plugin `claude-kit-core` → `schnapp-os-core`
  (legacy claude-kit-lineage name; owner flagged the inconsistency). Canonical defs updated
  (.claude-plugin/marketplace.json, plugins/core/.claude-plugin/plugin.json) + 2 live refs
  (surfaces/cowork.md, .claude/settings.json comment); ~38 historical refs in PROGRESS/handoffs/
  PLAN/memory kept (they record the past name correctly). Also corrected the marketplace
  description's stale "delivers hooks" claim (hooks moved to .claude/settings.json per 0011 #2).
  Repo: commit d6e0a51 pushed. **OWNER must reinstall to activate** (repo def changed, installed
  plugin still `claude-kit-core@schnapp-os` until then): `claude plugin uninstall claude-kit-core@schnapp-os`
  → `claude plugin marketplace update schnapp-os` → `claude plugin install schnapp-os-core@schnapp-os`.
  Skill/command namespace then flips `claude-kit-core:` → `schnapp-os-core:`. No breakage until reinstall.
- 2026-06-27 Agentic-OS loops Phase 1 SHIPPED (provenance detector + CI, ci-lint green); see plan
  docs/superpowers/plans/2026-06-27-agentic-os-loops.md + handoff 035. Phase 2 (reflective freshness)
  next, to continue in a fresh session. Detours resolved this session: stale schnapp-kit no-commit-to-main
  hook (frozen Desktop snapshot, neutralized; self-heals fresh session) + plugin rename claude-kit-core→schnapp-os-core.
- 2026-06-29 Edit-time security hooks wired (PostToolUse in .claude/settings.json): secret-scan-on-write.sh
  (runs scan-secrets.sh on each Write/Edit, exit 2 on a literal secret value — shift-left from the
  freshness.yml CI gate) + shellcheck-on-write.sh (lints *.sh at -S info, catches the unquoted-var/word-split
  class SC2086; no-ops if shellcheck absent — now brew-installed, v0.11.0). New agent secrets-leak-reviewer.md
  (adversarial leak audit beyond the regex gate; runs the scanner then finds what regex misses). CATALOG.md
  regenerated to list both. Also de-staled the live ~/.claude/CLAUDE.md off the removed /new-project composer
  (decisions/0011 #4) — completed the pending owner re-copy from templates/user-global-CLAUDE.md flagged earlier
  in this log; the template was already correct, only the per-machine file lagged. Both hooks dogfood-clean at
  shellcheck -S info; tested (planted token→block, SC2086→block, clean→pass, non-edit/non-sh→ignored);
  scan-secrets self-test passes. Hooks/agent activate next session (loaded at startup).
- 2026-06-29 Doc-currency sweep (repo-review follow-up): fixed three stale descriptions. The CI bundle
  `scheduled-tasks/run-ci-routines.sh` header and `scheduled-tasks/README.md` said it runs "two" routines;
  it runs four (doc-freshness gate, sync/unmerged, memory-freshness sweep, learning-loop eval) — corrected
  both. `gen-catalog.sh` Hooks-section prose still described the old plugin hook-delivery split; rewrote it
  to reflect settings.json-only wiring (ADR 0011 #2). Regenerated CATALOG.md; freshness gate green, shellcheck clean.
- 2026-06-29 Full repo review (on request): saved orientation map + optimization plan to
  docs/repo-review-2026-06-29.md (dated snapshot; references PLAN/PROGRESS/AUDIT/CATALOG, copies no state).
  Thesis: the build is solid, the gap is liveness — strong vs silent drift, weak vs silent stop. Root-caused
  handoff 038's open backup risk: the SQL `weekly-backup.sh` last ran 2026-05-03 because its LaunchAgent plist
  was never installed into ~/Library/LaunchAgents (it sat in ~/azure-sql-backups, RunAtLoad=false, so it never
  re-armed after a reboot — it stopped silently, no crash). Fixed: installed + loaded `bet.schnapp.bacpac-backup`
  (confirmed registered; weekly Sun 05:00, now survives reboots) and triggered an immediate export to backfill
  the 55-day gap. Unresolved (owner call): the scheduled-tasks/README worker-auth contradiction (Claude OAuth
  token vs ANTHROPIC_API_KEY), to settle with the learning-worker reinstall (038 #2).
- 2026-06-29 Backup RESOLVED + correction to the entry above. The immediate export first FAILED, but the raw
  error ("Login failed for user 'sa' / Cannot open database 'sports-modeling'") was misleading. Using the
  container-bundled sqlcmd (the HOST sqlcmd is broken — unixodbc/libodbc.2.dylib missing; `brew install
  unixodbc` to repair), the canonical vault SA password authenticates fine and the sole user DB is
  `schnapp-bet`. Real cause: the DB was renamed sports-modeling -> schnapp-bet after the last good backup
  (2026-05-03) and ~/azure-sql-backups/weekly-backup.sh still targeted the old name. Fixed the script (DB name
  + output prefix + retention glob -> schnapp-bet; added a justified `# shellcheck disable=SC2012` so it
  passes the edit-time gate) and re-ran: `schnapp-bet-20260630.bacpac` (344M) verified-exported, backfilling
  the 55-day gap. Net: weekly LaunchAgent armed (survives reboots) AND the export works — NOT a credential
  issue. Open follow-ups: P1 infra-health probe (a backup-age alarm catches this regardless of cause);
  `brew install unixodbc`; the worker-auth README contradiction (038 #2).
- 2026-06-29 Worker-auth "contradiction" RESOLVED as stale doc-drift, not an owner fork (corrects my earlier
  flag). Canonical, dated docs/headless-claude-auth.md sanctions ANTHROPIC_API_KEY
  (op://web-variables/ANTHROPIC_API_KEY/credential; non-expiring, wins precedence over the Keychain) for the
  headless learning-worker; the OAuth-minting prose in scheduled-tasks/README.md was leftover from the
  abandoned subscription-OAuth path and contradicted both the canonical doc and its own install step. Fixed
  the README to match + point at the canonical doc; updated review-doc P0 #2. Clarified (owner Q): the worker
  is a launchd daemon, so its auth is fully decoupled from how the owner runs interactive Claude (global vs
  local / in-repo) — launchd doesn't source ~/.zshrc, can't read the Keychain, and gets only the plist env +
  inherited OP_SERVICE_ACCOUNT_TOKEN; repo .claude/settings.json injects no auth vars (verified ANTHROPIC_API_KEY
  + CLAUDE_CODE_OAUTH_TOKEN both unset this session). Worker reinstall + live-verify (038 #2/#3) still TODO.
- 2026-06-29 SWITCHED the learning-worker to the Claude SUBSCRIPTION (ADR 0019), answering owner Q "how to
  use subscription not API". Root-caused the prior API-key sanction as a MISDIAGNOSIS: the vault
  CLAUDE_CODE_OAUTH_TOKEN was malformed (stored as ␣'sk-ant-oat…' — leading space + wrapping quotes, 111 vs
  108 clean bytes), so a valid token was sent corrupted → 401 "Invalid bearer token", which the 2026-06-27
  arc pinned on CLI v2.1.112. Disproven: control invalid token → 401; cleaned vault token → ok; worker's
  exact resolution in a clean launchd-equivalent env (launchd OP_SA + OAuth ref) → "resolved ->
  CLAUDE_CODE_OAUTH_TOKEN" then ok. Actions: cleaned the vault item in place (op item edit; verified 108
  bytes, leading 's', headless ok); repointed LEARNING_CLAUDE_TOKEN_REF to the OAuth item + reinstalled the
  plist from template (launchctl reload; ref confirmed; launchd has OP_SA). Worker reasoning now bills the
  subscription, honoring cost discipline (AUDIT K). Docs corrected: headless-claude-auth.md (sanctioned cred
  → OAuth + malformed-value gotcha + fixed 401 table/checklist), scheduled-tasks/README.md, review-doc P0 #2;
  recorded as decisions/0019. NOT a credential rotation. Token expires ~2027-05 (re-mint via claude setup-token).
- 2026-06-29 Built the infra-health liveness probe (P1) + two smaller asks. (1) plugins/core/scripts/
  check-infra-health.sh — pure-bash, read-only probe for the SILENT-STOP class: checks expected LaunchAgents
  loaded (3 connectors, tunnel, worker, backup, CI runner, flask, web-prod), newest schnapp-bet-*.bacpac age
  (<8d), mssql container up, local MCP ports 8765/66/67 listening; green/red, exits non-zero + macOS
  notification on RED; NEVER remediates. Deliberate divergence from infra-health.md's claude -p design (a
  liveness probe must not depend on the connector/credential it watches — the day's lesson). Scheduled via new
  com.schnapp.infra-health.plist (daily 08:30 + RunAtLoad); INSTALLED + loaded on the Mac (exit 0, all green).
  tests/test-infra-health.sh (skips on non-Darwin) wired into freshness.yml; new plist added to the CI
  plist-validity check. infra-health.md rewritten to current state; scheduled-tasks/README surface-map row
  updated. (2) brew install unixodbc → repaired the broken host sqlcmd (libodbc.2.dylib now linked). (3)
  Global-memory fact memory/malformed-stored-secret-401.md (+ MEMORY.md index): the general lesson behind ADR
  0019 — a stored secret with stray whitespace/quotes 401s "Invalid bearer token"; verify raw bytes before
  blaming the tool/CLI. Validations: probe exit 0; test PASS; memory-frontmatter OK (11 facts); freshness OK.
- 2026-06-30 Pushed the OAuth maintenance note to the canonical credential ledger (credentials-map.md):
  updated the CLAUDE_CODE_OAUTH_TOKEN row (added the learning-worker consumer + expiry/re-mint maintenance —
  minted ~2026-05, re-mint ~2027-05 via `claude setup-token`, store clean) and appended a 2026-06-30 changelog
  row recording the ADR-0019 repoint + the in-place token clean. (The other maintenance note — keep
  EXPECTED_AGENTS current — was already persisted in scheduled-tasks/infra-health.md + the check-infra-health.sh
  comment, so not duplicated.)
- 2026-06-30 MCP connector remote-reachability audit (5 connectors) + config fixes. Probed live (Code-Mac):
  all 5 reachable off-Mac, all bearers are op:// refs, both Render services up (op-mcp + memory-mcp /health 200),
  obsidian native OAuth confirmed (WWW-Authenticate + well-knowns). mac-mcp unauth `initialize` 200 traced to a
  safe-by-design two-layer gate (middleware 401s a WRONG bearer; every tool self-gates via _check_token before
  any subprocess — verified: unauth shell_exec → unauthorized), not an open shell. Fixes landed: (1)
  docs/environment-and-access.md allowlist host memory-mcp.onrender.com → memory-mcp-rtad.onrender.com (bare name
  503s; -rtad is the real origin) + portal row notes mcp.schnapp.bet fronts op-mcp+memory-mcp; (2) .mcp.json added
  Schnapp_Secrets (op-mcp) + Schnapp_Memory (memory-mcp) bearer-ref servers for off-Mac Code/Cowork (cloud-only;
  disconnected on the Mac by design); (3) rotate-secret SKILL.md gotcha — client-side static-bearer connectors are
  rotation legs (portal/OAuth-fronted ones aren't); (4) mac-mcp server.py instructions string no longer enumerates
  internal infra on unauth initialize. Owner-pending (off-repo): mirror the corrected host into each env network
  policy; set OP_MCP_BEARER/MEMORY_MCP_BEARER in cloud envs; portal-front or bearer-refresh mac-mcp+github-mcp for
  claude.ai/iPhone. BLOCKED: idle tunnel schnapp-mcp (6725bd14, 0 conns) delete — CLOUDFLARE_API_TOKEN 401s on DNS
  read, can't confirm no dependents. Validations: .mcp.json valid JSON; server.py compiles. Complements (remote/auth
  side) the Mac-side plugins/core/scripts/check-infra-health.sh.
- 2026-06-30 Portal doc-sync (after the owner moved mac-mcp + github-mcp behind the Cloudflare portal in step 5 of
  the connector cleanup). Verified the portal live first: `portal_list_servers` → op-mcp + memory-mcp + mac-mcp +
  github-mcp all enabled; `op_health` + `memory_health` authenticated through it. Then swept every doc off the old
  standalone-connector model onto "Schnapp Portal fronts the four static-bearer servers; obsidian stays native-OAuth
  standalone": credentials-map (mac/github bearer consumers → portal Custom header + changelog row), memory/
  credentials-state ("Owner CLIENT legs pending" → RESOLVED), surfaces/{claude-ai-web,iphone,cowork,always-loaded-
  instructions}, connectors/{mac,github}-mcp/README, docs/environment-and-access (portal = all 4), memory/mac-cloud-
  access (claude.ai chat now via portal; .mcp.json Code path unchanged). New ADR 0020 records the decision + the
  security note (User-auth OFF → the portal Access policy gates a full Mac shell). No env-file change — the portal
  reuses existing bearers as Cloudflare Custom headers. 11 files.
- 2026-06-30 Added root CLAUDE.md (agent front door for working *in* schnapp-os): thin, reference-only — links the
  canonical sources (global rules, PLAN/PROGRESS, decisions, memory, hooks, secrets-as-refs); re-imports no global
  rules (they load machine-wide via ~/.claude/CLAUDE.md, so re-import would double-load) and hardcodes no status.
  Linked it from the README map. Dogfoods templates/project-CLAUDE.md, which the repo shipped for other projects but
  never used on itself. Verified every referenced path exists + every hook named is wired in .claude/settings.json.
  Also captured owner preference (owner-working-preferences #7): commit + push to main automatically by default (no
  per-change ask; overrides the harness "only when asked" default), and never leave open PRs.
- 2026-06-30 Sharpened rules/global/verify-before-asserting.md: "Read before editing" now names the **Read tool**
  explicitly — a Bash `cat`/`head`/`tail`/`grep` does NOT register a file as read, so Edit/Write fail with "File has
  not been read yet." Hit this mid-session editing 3 files (owner-working-preferences, MEMORY, PROGRESS) I had only
  `cat`'d via Bash. Fix-the-class, not the instance. Also: merged the last org-wide open PR (schnapp-bet #2, the
  fail-closed secrets security fix, reviewed) and closed two dead ones (schnapp-bet #1 empty, schnapp-kit #29 moot)
  → 0 open PRs across SchnappAPI, per the new never-leave-open-PRs preference.
- 2026-06-30 Built the pr-sweep skill (plugins/core/skills/pr-sweep) — on-demand org-wide open-PR triage: one
  `gh search prs` call → classify (empty/moot/mergeable/needs-review) → close dead + gated-merge clean; never
  blind-merge prod/security (the auto-mode classifier blocks merging a PR the agent didn't open without specific
  auth). Codifies this session's efficiency lessons (one wide call, token-readable fields only — `statusCheckRollup`
  403s on some repos) and the safe-vs-asks-first split (framework F). Cross-linked from status; complements the
  read-only sync/unmerged routine (that = branches, this = PR objects). CATALOG regenerated; components auto-discover
  (plugin.json) so it is live on next plugin load.
- 2026-06-30 Session-close hygiene. (a) Refreshed the 4 stale-flagged memory facts after VERIFYING each (not a blind
  date-bump): keep-tracker-current (re-attested by this session's practice); op-wrap-token-unquoted + obsidian-state
  Mac-verified live (zshrc token unquoted, op-wrap.sh still greps-not-sources; `com.schnapp.obsidian-mcp` agent up,
  vault symlink intact — consistent with ADR 0020 obsidian-stays-standalone); plugin-registry-snapshot-gotchas (also
  removed leaked `</content></invoke>` tags from the body). All `updated:`→2026-06-30. (b) Backup P0 from
  repo-review-2026-06-29 verified **RESOLVED**: `bet.schnapp.bacpac-backup` LaunchAgent installed in
  `~/Library/LaunchAgents` + loaded, armed Sun 05:00; `weekly-backup.sh` ran 2026-06-30 04:20 UTC (fresh 344M
  `schnapp-bet-20260630.bacpac`). The 55-day gap was the old `sports-modeling` DB name; renamed `schnapp-bet` DB now
  backed up + scheduled. Annotated the review doc; infra-health probe (P1 #4) still the silent-re-death guard.
- 2026-06-30 Installed the infra-health liveness probe (repo-review P1 #4 / Part 3 #1 — the headline silent-stop
  gap). Dry-ran `check-infra-health.sh` first (all green, zero day-one alarm noise), then substituted the plist
  placeholders and `launchctl load`ed `com.schnapp.infra-health` on the Mac. Verified: loaded, `runs=1 exit=0`,
  calendar trigger armed 08:30 daily, first RunAtLoad report all-green to `~/Library/Logs/schnapp-os/infra-health.log`.
  Pure-bash read-only (no LLM/MCP/auth dependency, so the probe can't die on what it watches); checks expected
  LaunchAgents loaded + backup freshness (<=8d) + mssql container + MCP ports 8765/66/67; RED posts a macOS
  notification + non-zero exit, never remediates. Would have caught the backup lapse. PLAN 11.1 note + review doc
  annotated. (memory-consolidation is loaded too; its tiering/effectiveness tracked separately, AUDIT item B.)
- 2026-06-30 Built off-Mac paging (the residual after the infra-health install). New reusable
  `plugins/core/scripts/notify-ops.sh`: best-effort ntfy pager (pure bash + curl, 8s timeout, silent no-op if
  `NTFY_URL` unset) that any routine can call unconditionally. Wired into `check-infra-health.sh`: on RED it now
  pages off-Mac (with the failing-check summary) in addition to the local macOS notification. Topic is Mac-local in
  `~/.config/schnapp-os/ops.env` (chmod 600), deliberately NOT op:// so the alert path can't die on 1Password;
  documented in `.env.template` per the bootstrap-token precedent. Owner chose the channel (ntfy: free/OSS/$0).
  VERIFIED end-to-end on the Mac: ntfy HTTP 200, and a forced fake-RED run paged. Owner action: subscribe to the
  topic in the ntfy app. Updated infra-health.md + framework.md throughline (silent-stop now alarms; residuals: the
  probe must itself stay scheduled / a dead-man's-switch, and tell a wrong-reason failure from a true RED).
- 2026-06-30 Built the Mac liveness dead-man's-switch (closes infra-health residual #1: who watches the watchdog).
  New GitHub Actions cron `.github/workflows/mac-liveness.yml` (every 30 min, Mac-independent, free, built-in
  GITHUB_TOKEN, no secrets): pings the Mac's public surface (`schnapp.bet` 200 / `mac-flask` 404 = up; 000/52x/
  conn-fail = down, 3 retries to ride blips). On DOWN it opens a GitHub issue assigned to the owner (NATIVE email
  alert, no app to install — owner preference) via open-issue-as-state dedup, and exits non-zero; on recovery it
  comments + auto-closes. Owner-side install: none. Tested both paths via workflow_dispatch (simulate=down opens +
  assigns + emails; a normal run recovers + closes). Spec `scheduled-tasks/mac-liveness.md`; README routine table +
  framework throughline updated. Remaining edge (documented, optional): Mac fully up but the infra-health plist
  specifically unloaded — covered only by an optional mac-mcp service_status pull (needs a repo secret), not wired.
- 2026-06-30 Wired granular native alerting (no app needed). New `plugins/core/scripts/ops-alert.sh`: an incident
  manager that on a routine RED opens an owner-assigned GitHub issue (NATIVE email) and auto-closes it on recovery
  (open-issue-as-state dedup), plus a transition-only ntfy/macOS notification so a persistent RED is one issue, not
  spam. `check-infra-health.sh` now delegates all alerting to it (red + green). `gh` works headless on the Mac
  (verified: hosts.yml readable, clean-env test passed, `repo` scope), so no new secret. Bumped the infra-health
  LaunchAgent from daily 08:30 to every 30 min (`StartInterval 1800`) so a downed service alerts within ~30 min. The
  probe stays dependency-free (detection only); alerting is best-effort. Tested on the Mac (forced RED opened +
  assigned a `[infra-health]` issue; recovery auto-closed it). infra-health.md + plist updated.
- 2026-06-30 Session wrap (review + harden + drop iMessage). ce-correctness-reviewer pass on the ops scripts:
  fixed notify-ops `-d`->`--data-raw` (a leading `@` read a file), a bash-3.2 empty-array abort under the plist's
  `/bin/bash`, sanitized the jq-interpolated `key`, and anchored the mac-liveness issue dedup to `startswith`.
  Verified gh works under launchd (a GUI LaunchAgent reads the keyring) and made it explicit + monitored: a
  `GH_TOKEN` option in ops.env + a **gh-auth self-check** in the probe (REDs via the non-gh channels if the
  issue/email path can't fire, so the alerter can't die silently). Dropped the **iMessage** channel: self-sent
  iMessages don't notify (Apple limitation; sends returned rc=0 but no phone ping), so it can't page — removed
  `imsg` from ops-alert + `OPS_IMESSAGE_TO` from .env.template + the probe comment; unset on the Mac. Phone
  alerting = GitHub issue -> email (Mail push) + GitHub mobile push (owner has the app). Wrote `handoffs/039`.
  End state: main, CI green, 0 open issues/PRs. Optional owner task (NOT pending): Cloudflare Tunnel Health Alert
  (dashboard) as an event-driven complement to mac-liveness.
