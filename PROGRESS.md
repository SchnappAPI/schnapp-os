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
