# 0011 — Plan review: ten decisions re-decided on purpose (loops before features)

Date: 2026-06-23. Status: DECIDED by owner (deliberate re-decision, not a "recommended" default).

## Context
The prior plan (`PLAN.md`, an 11-Part maximalist build) was answered on "recommended" defaults
without the owner reviewing each decision. Per the decision record
[`docs/schnapp-os-research-and-decisions-2026-06-23.md`](../docs/schnapp-os-research-and-decisions-2026-06-23.md)
§7.4 step 3 and §8, the first move this session was a plan review: list every load-bearing
decision and re-decide it on purpose. This ADR records those re-decisions. It supersedes the
conflicting items in PLAN.md "Locked decisions"; PLAN.md is reframed (this same change) as a
parking lot of ideas, not the spine. The governing plan is now the decision doc's order (§7.4 / §7.7).

## Governing principle (applies to all ten and everything after)
Loops before features. Subtract rather than complete. Narrow to what is real. Defer what is not
yet earned. Elaborate vs plain → take plain. Build-now vs defer → defer unless it is one of the two
loops (freshness, learning) or a guardrail.

## The ten re-decisions
1. **Plan authority** — The decision doc governs. PLAN.md is reframed as a parking lot of ideas to
   pull from later, not the spine. Reframed explicitly in PLAN.md in this same change (not silently
   abandoned).
2. **Repo form** — Plainer repo. Drop the marketplace-plugin + `plugins/core/` packaging. This is
   one OS for the owner, not a distributable plugin.
3. **Surface scope** — Narrow to the surfaces actually used now. The remote MCP server extends to
   others later without a rebuild.
4. **Rules system** — Simpler: plain rules files + CLAUDE.md. No module gallery, presets, or symlink
   composer. One fact, one canonical home.
5. **Credentials delivery** — One centralized remote-MCP credential tool. The server holds the
   1Password service-account token and resolves `op://` at call time. No per-surface resolution.
6. **Remote MCP topology + host** — A few scoped servers (memory, control-plane, integrations), not
   one mega-server. Keep current hosting for now; defer any Cloudflare migration as its own later task.
7. **Cloud backup / Obsidian mirror** — Keep a backup (durability serves the substrate). Keep the
   Obsidian mirror only if something actively reads from it; if write-only, prune it. When unsure, prune.
8. **Agentic-OS layer** (scheduler / orchestrator / control-plane) — Defer until the two loops are
   proven to fire. Cannot orchestrate a system whose loops do not work.
9. **Git workflow** — main only, plus a PreToolUse guard blocking force-push to protected repos. No
   straight-to-main autopush without the guard.
10. **Chat-memory feature** — Confirmed: delete history and leave generation off (doc §7.5).

## Locked, off the table
- Adapt vs rebuild is settled: keep Schnapp-OS, no new (fourth) repo. (doc §7.1 / §7.3)

## Order of operations from here (do not reorder; doc §7.4)
Capture original intent before cutting → freshness gate (one SessionStart hook reconciling live git +
the 1Password-backed credential store) → learning-loop capture-and-route → prune anything not serving
a loop or a current task. Do not start building until intent is captured.

## Live findings surfaced while recording this (for the freshness / guardrail phase, not actioned now)
- **The decision doc was itself a freshness casualty.** It existed only in unpulled remote commit
  `48e2cec` ("Add files via upload" — uploaded via GitHub web), never on local disk; local `git pull`
  was failing. Fast-forwarded local main to origin (clean, ff-only) to land it. This is the exact
  stale-belief-vs-ground-truth gap the freshness loop must close, happening to the doc that describes it.
- **The old "frozen" schnapp-kit is still a live guardrail layer.** Its
  `~/.claude/plugins/cache/schnapp-kit/.../hooks/claude/no-commit-to-main.sh` PreToolUse hook fired into
  this repo, blocking commits. It is (a) buggy — matches `git (commit|merge)` in the command string, so
  read-only `git merge-base` false-positives — and (b) policy-wrong — forces feature branches, the
  opposite of decision #9 (main only). It must be removed and replaced by the real force-push guard when
  the freshness/guardrail step runs. This is why these records are written but not yet committed.
