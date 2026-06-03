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
