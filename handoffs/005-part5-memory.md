# Handoff 005 — Part 5 (memory) boundary; tracker de-staled

Date: 2026-06-03.

## State (PLAN.md now matches reality — boxes are current)
- **Part 4.2** `[~]`: op-mcp connector BUILT + locally verified (`npm run verify` PASS).
  Deploy + claude.ai registration owner-gated (handoff 004, decisions/0004 RESOLVED).
- **Part 5**: 5.1 ✓ (autoMemoryDirectory -> `~/code/claude-kit/memory`, tracked settings.json,
  owner-approved; scratch gitignored). 5.2 ✓ (memory conventions). 5.5 `[~]` (global principle
  seeded + mechanic documented). 5.3/5.4 procedures authored in memory/README.md, hook wiring
  deferred to **Part 7**. 5.6 verify needs install/symlink (2.2) + a 2nd repo (**Part 10**).
- Adopted **keep-tracker-current** rule (global/anti-stale.md + memory): every state-changing
  commit flips the PLAN box + PROGRESS line in the SAME commit and is **pushed immediately** so
  GitHub mirrors local. Partial = `[~]`. Never claim verified before the verify ran.

## What changed this session
- `connectors/op-mcp/` (new): Node streamable-HTTP MCP, read-only tools, bearer auth. Built + verified.
- `memory/` (new): README (conventions + freshness-gate/end-of-session procedures + dual-altitude),
  MEMORY.md index, credentials-state + keep-tracker-current seed facts.
- `.claude/settings.json` (new): autoMemoryDirectory.
- PLAN.md de-staled (all real progress checked); decisions/0004 RESOLVED; PROGRESS.md current.
- Commits: 2831ee6 (connector), 0ceca76 (de-stale + rule), 42faf77 (Part 5.1/5.2). All pushed.

## Next, in order (per handoff 003)
1. **Part 2.2** — `~/.claude/CLAUDE.md` `@import`s the global rules + symlink `~/.claude/rules/global`
   to the repo. NOTE: this is GLOBAL harness config (affects all projects) + self-modification;
   needs owner approval (the classifier gates ~/.claude writes). Confirm before doing.
2. **Part 6** — OneDrive backup wiring + Obsidian mirror (6.1 done).
3. **Part 7** — hooks (incl. the 5.3/5.4 freshness-gate + end-of-session procedures already authored)
   + skills + surface-check + on-correction auto-update.
4. **Part 8** git hygiene, **9** anti-stale wiring + template, **10** marketplace/install + verify
   (closes 5.6, 3.4, 2.4, 4.4), **11** agentic OS.

## Owner-gated / pending
- Deploy op-mcp to a Node host + claude.ai auth front + register URL; verify PLAN check 7 (Mac off).
- Widen GitHub fine-grained PAT to All repos; set the Actions secret on af-invoice-parser, af-query-api.
- Approve ~/.claude global changes for Part 2.2.

## Resume prompt
"Resume claude-kit. Working dir ~/code/claude-kit. Read PLAN.md, PROGRESS.md, and the latest
handoffs. PLAN boxes are current. Continue from Part 2.2 (needs owner OK for ~/.claude changes),
then Parts 6, 7, 8, 9, 10, 11 in order. Apply the keep-tracker-current rule: every state-changing
commit flips the PLAN box + PROGRESS line and pushes immediately. Act autonomously; handoff at each
part boundary."
