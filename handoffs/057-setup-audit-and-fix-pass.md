# Handoff 057: Full setup audit (5 subagents) + fix pass, and the 07-04..07-12 catch-up

Date: 2026-07-13. Surface: Claude Code web (cloud env, branch session). Prior: [056](056-portable-shell-redteam.md).

## Goal
Owner asked: read skills, memory, and past sessions; grade the whole setup with subagents through
the transcripts; report what to fix now, what to merge, what to delete, and the single
highest-payoff change. Then (follow-up "What next?") execute the fixes.

## Catch-up: what happened between 056 (07-03) and this session
No handoff was written for ~8 sessions / 24 commits (itself the audit's top recurring failure).
From git/PROGRESS: surfaces restructure to live-read (07-04), cowork seed automation
(sync-cowork-seed.sh, 07-06), five cross-device seam fixes + session-digest hook + schnapp-console
merge (07-07), intent-check redesign after owner grill-me review (07-07), vault-autocommit
HEAD.lock mutex fix (07-07), check-secret-bytes op-read fix + credentials-map APPFOLIO_API item
(07-11), working-style single-operator merge rule (07-12).

## Facts established (audit scores, evidence in the session report)
- Overall 7/10. Layers: follow-through on the 2026-06-25 AUDIT.md 8.5/10 (top-5 gaps all fixed
  within ~8 days, live-verified); skills 7/10; rules/hooks 7/10; memory 7/10; learns-from-sessions
  6/10.
- The binding constraint is no longer machinery: ~95% of recorded sessions are meta-work; the six
  domain/pattern skills had zero recorded uses in 5 weeks; deterministic failure classes get gated
  and stop (em-dash class: rule -> CI gate -> zero recurrence) while judgment classes (tracker
  currency, ask-vs-act, verify-first) recur after every rule sharpening.
- Skill double-registration root cause: shell/install.sh symlinks .claude/{skills,commands} to
  user scope; a schnapp-os session then also loads them at project scope; no harness dedup. Costs
  ~11KB duplicated trigger text per schnapp-os session.
- Web-surface defects found live: guard self-skip compared paths so both global guards double-fired
  (working checkout /home/user vs shell clone /root/code); vault not cloned in the env so the
  entire memory lane (autoMemoryDirectory, vault-push, session-digest) was silently dead;
  session-stop-push-gate enforces pushing the claude/* branches that ADR 0016/0017 ban.
- One live-doc lie: scheduled-tasks/memory-consolidation.md described a consolidation review the
  com.schnapp.memory-consolidation LaunchAgent does not run (it runs learning-worker.sh).
- Memory lane: 23 facts, 100% schema-compliant, index exact, Obsidian mirror in sync, no secret
  values; but supersede-not-append drifting (credential pair duplicated ledgers, promoted facts
  never retired, 2 verified-stale facts).

## Decisions + reasoning
- THE one highest-payoff change (owner-level, not executed here): meta-work freeze; force one week
  of real object work through the tools (settlement-audit on live grades, appfolio/quickbase on a
  real 1st Lake pull). The system's ROI is zero while it only runs on itself. The never-used domain
  skills get that week to earn their slot, then prune.
- Merged rather than kept-separate: performance <- benchmark + data-throughput-accelerator +
  latency-critical-systems (one domain, three restatements of speed-by-default);
  grill-me <- grill-with-docs (pure delta, no independent trigger). Kept separate on verified
  boundaries: status/surface-check/session-hygiene; secrets lifecycle; learn-route/rules-distill/
  session-to-skill; council vs intent-check.
- Demoted, not deleted: content-hash-cache-pattern and regex-vs-llm-structured-text are patterns,
  not procedures -> rules/modules/coding/. speed-by-default is Python/SQL-specific -> demoted from
  the always-on global lane to rules/modules/coding/ (~180 tokens/session, every repo).
- standing-rules.sh cut to a one-line salience reminder: the full text re-paid ~275 tokens/message
  for rules already always-loaded via ~/.claude/CLAUDE.md; working-style.md is now the single home.
  If judgment-rule adherence visibly degrades, revert is one commit.
- Registrar move (fix for double-registration) DEFERRED to its own session: it is a cross-surface
  move (install.sh symlink source, gen scripts, Mac re-install, claude.ai/Cowork live-read paths)
  and the history shows move-fallout is this repo's most fragile class. Mechanism decided: move
  canonical skills/commands out of the auto-loaded .claude/ dirs (e.g. skills-src/), install.sh
  symlinks from there, project scope carries nothing; verify with a temp-HOME install.sh run +
  check-links + a claude.ai skill-load spot check after merge.
- This session ran on a claude/* branch with PR because the cloud environment pins it; the repo
  policy (ADR 0016/0017 main-only) stands. Resolution is the owner's env-config knob (below).

## Actions + outcomes
- Batch 1 (commits a607bce + 509afcf; the first's file list was truncated by an aborted git add,
  second carries the files): standing-rules one-liner; guard self-skip keyed on git remote identity
  not path (block/skip verified both ways); session-start-gate tracker-currency drift warnings
  (handoffs/ >5 commits, PROGRESS.md >3) + GIT_TERMINAL_PROMPT=0; speed-by-default demotion with
  full live-reference sweep; memory-consolidation.md retitled SPEC-not-yet-scheduled + README
  routine table reconciled; the four 2026-06-27 loops plan docs (59 unflipped boxes on shipped
  work) closed with retroactive banners; README Map gains AUDIT.md + render.yaml rows;
  templates/project-CLAUDE.md stops hand-listing the rule set (was a stale 7-of-9 list).
- Batch 2 (this commit): performance skill merge (+3 deletions), grill-me absorbs grill-with-docs,
  2 pattern-skill demotions to modules, settlement-audit slimmed 259->63 lines with SQL moved to
  queries/*.sql and function-name (not line-number) anchors into grade_props.py, rotate-secret
  sheds its mutable remediation ledger (points at credentials-map + vault credentials-state),
  broken-link class fixed (council, grill-me, context-budget, etl-pipeline-build,
  sql-server-patterns), dangling refs repaired (live-session-cache, fish-compare), external plugin
  deps (superpowers:brainstorming, skill-creator) marked conditional with inline fallbacks.
  CATALOG.md + surfaces/claude-ai-skills.md regenerated. Gates: check-links 394 OK, freshness OK,
  writing-style OK, scan-secrets 0 BLOCK, affected hook tests PASS.
- Memory supersede pass applied via memory MCP (vault repo not cloned in this env): credential pair
  collapsed (credentials-state canonical), obsidian-state notes-lookup fix, mac-connector-tooling
  bullet rewritten to current state, cowork-claude-md-seed updated:-bump + dedupe,
  cowork-vault-write-verified deleted (durable line folded into surfaces-live-read-default),
  owner-working-preferences trimmed to unpromoted points, keep-tracker-current shrunk to a pointer.
- Audit-only findings NOT acted on (recorded here so they are not lost): mac-mcp/github-mcp tool
  bloat with zero per-tool instrumentation (AUDIT.md G1/G3, untouched since June); weekly deep
  review cron + wiki-grows-from-questions still absent (last pure Group-B gaps); orphan modules
  (lang/power-query-m, lang/github-actions, coding/design-defaults) left in place because external
  project @imports cannot be verified from this surface.

## Status + next steps
- Next session, first: the registrar move (mechanism above). Second: the meta-freeze object-work
  week. Also owed: handoff-057-era PROGRESS discipline is now warned-on by the session-start gate;
  watch that the warning actually fires and gets acted on.
- Unfinished-loop cleanup owed from the audit: substrate P2 (GitHub official-MCP swap) and P3
  (Obsidian bearer swap) are still greenlight-ready-never-executed (13+ days); either execute or
  write the ADR that kills them.

## Defect found during the memory pass (fix next session, server-side)
connectors/memory-mcp `memory_write` corrupts frontmatter on every write: resets `created:` to
today, replaces `description:` with an auto-summary (sometimes with unquoted inner colons =
invalid YAML), drifts `type:`, and appends non-schema `scope:`/`supersedes:` keys. Separately, a
mid-write GitHub 502 left MEMORY.md with a duplicated index line that a same-slug re-write does
not heal. All 22 facts were repaired this session by direct commits to the vault, but ANY future
memory_write re-introduces the corruption until the server is fixed. Fix belongs in
connectors/memory-mcp (write path: preserve existing frontmatter keys verbatim, only bump
`updated:`; index update must be replace-by-slug and idempotent).

## Open questions / edge cases (owner-only)
- Web env branch policy: apply the ADR 0017 knob (set this environment's working branch to main in
  the claude.ai env settings) OR amend 0017 to accept claude/* + merge-on-green. Until then every
  web session violates the written policy and the stop-gate enforces the violation.
- Grant the web environment access to SchnappAPI/schnapp-vault (env repo access setting) so the
  memory lane is alive on this surface; today it is MCP-only here.
- Mac leg after merge: pull + re-run shell/install.sh so ~/.claude/CLAUDE.md drops the
  speed-by-default import and picks up the new hook text (attempted via mac-mcp this session if
  reachable; otherwise run locally).
- claude.ai surface: spot-check that the live-read skill pointers survived the six skill deletions
  (surfaces/claude-ai-skills.md regenerated; the claude.ai-side project config may pin old names).

## Copy-paste primer (new session)
Setup audit graded the system 7/10 and applied the fix pass: skills merged/slimmed (30 -> 24 units),
standing-rules hook one-lined, guards identity-keyed, speed-by-default demoted to a module, memory
supersede pass applied via MCP, loops plan docs closed, trackers current. Resume point: this
handoff; next actions are the .claude/skills registrar move (single-registrar, spec in Decisions)
and the owner's meta-freeze object-work week. Read PROGRESS.md 2026-07-13 for the commit trail.
