# Memory — two lanes, cross-surface, never stale

The canonical spec for how memory works in claude-kit. Rules reference this file;
do not restate its content elsewhere. (PLAN.md Part 5.)

## Two lanes

| Lane | Where | Holds | Synced by |
|---|---|---|---|
| **Global** | `claude-kit/memory/` (this dir) | Cross-everything facts, reusable principles, who-the-user-is, durable preferences | git (claude-kit repo) |
| **Project** | each project's `<project>/memory/` (set via `autoMemoryDirectory`) | Facts specific to that repo: which table, which endpoint, this project's quirks | git (that project's repo) |

Both lanes are **git-tracked**, so a lesson written on one machine or surface is
present on the next after a pull. This is the fix for "lessons siloed per repo"
and "memory siloed per machine" — the harness's default auto-memory dir is
machine-local; pointing `autoMemoryDirectory` at a repo path makes it travel.

### `autoMemoryDirectory` (verified semantics)
- Accepts an **absolute** or `~/`-prefixed path only (no relative, no `${VAR}`).
- Default (unset) = `~/.claude/projects/<project>/memory/` — machine-local, NOT synced.
- Set in project `.claude/settings.json` it is honored only **after the workspace
  trust dialog is accepted** on that machine (same gate as hooks).
- The harness writes `MEMORY.md` (index; first ~200 lines / 25KB loaded at session
  start) plus topic files (loaded on demand).
- claude-kit points it at `~/code/claude-kit/memory`. A machine that clones the repo
  elsewhere overrides the path in its own `.claude/settings.local.json`.

## Discipline (the anti-stale rules)

1. **One fact, one file.** Each per-fact file holds a single fact; `MEMORY.md` is a
   thin index (one line per fact). See [anti-stale](../plugins/core/rules/global/anti-stale.md).
2. **Supersede, do not append.** When a fact changes, replace the file's body; never
   leave a contradicting copy. Delete files that turn out to be wrong.
3. **Every memory carries `source:` and `updated:`** in frontmatter (ISO date). These
   drive the freshness gate.
4. **No secrets.** References only (`op://...`), never secret values.
   See [secrets-as-references](../plugins/core/rules/global/secrets-as-references.md).

### Per-fact file frontmatter
```markdown
---
name: <kebab-slug>
scope: global | project
source: <where this came from — a session, a correction, a decision doc>
updated: 2026-06-03
supersedes: <slug or "">   # optional, when replacing an earlier fact
---
<the fact, terse. Link related facts with [[other-slug]].>
```

## Dual-altitude promotion (nothing moved, nothing lost)

When a lesson has BOTH a general principle and a specific instance, write it in
**both** lanes and link them — never move:
- The **general principle** goes to the matching global rule (e.g. perf →
  [speed-by-default](../plugins/core/rules/global/speed-by-default.md), already seeded
  with: read-once, module-level cache, ThreadPoolExecutor, set-based SQL/CTE, bulk
  insert, `fast_executemany=True`).
- The **specific instance** (which table, which endpoint, which repo) goes to that
  project's lane and links back to the global principle by path.

This keeps the reusable lesson available everywhere while preserving the concrete
detail where it happened. Promotion is additive, so nothing is lost.

## Freshness gate (SessionStart) — procedure, wired in Part 7

At session start, before new work:
1. Load `MEMORY.md`; for each referenced fact compare `updated:` and `supersedes:`.
2. **Skip / quarantine** any fact that is superseded or older than a fact that
   contradicts it. A superseded fact is never presented as current.
3. Verify any fact that names a file/function/flag/table still exists before acting
   on it (see [verify-before-asserting](../plugins/core/rules/global/verify-before-asserting.md)).
4. Surface **unmerged or unpushed work first** (Part 8 git gate) before starting new work.

Implemented as a SessionStart hook in Part 7 (hook wiring is deferred there); this
section is the authored procedure (Part 7.1 "author the core procedures once").

## End-of-session write (Stop / SessionEnd) — procedure, wired in Part 7

On stop / session end, deterministically:
1. Write any fresh durable facts to the correct lane (supersede, don't append).
2. Update `MEMORY.md` index lines for changed facts.
3. Write/refresh the handoff (`handoffs/NNN-*.md`) and append a `PROGRESS.md` line.
4. Commit + push.

Implemented as a Stop/SessionEnd hook in Part 7.

## Verification (5.6)
- Cross-repo: a global-lane fact written here appears in a fresh session in another
  repo — verifiable once the global lane is installed/symlinked (Part 2.2 + Part 10).
- Supersede: change a fact, confirm the old body is replaced (not duplicated) and the
  freshness gate skips the superseded version.
