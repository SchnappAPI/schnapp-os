# Memory lane: procedures (schnapp-os system behavior)

Canonical home for the memory SYSTEM PROCEDURES: the freshness gate, the
end-of-session write, on-correction routing, and dual-altitude promotion. The hooks
([`hooks/`](../hooks/)) and the
[`session-hygiene`](../.claude/skills/session-hygiene/SKILL.md) skill reference this
file; do not restate its content elsewhere.

This file owns the PROCEDURES only. The memory SCHEMA (frontmatter, supersede rule) is
owned by the vault, not here. See [Schema](#schema).

## Two lanes

| Lane | Where | Holds | Synced by |
|---|---|---|---|
| **Global** | the vault `~/code/schnapp-vault/memory/` (repo `SchnappAPI/schnapp-vault`, private) | Cross-everything facts, reusable principles, who-the-user-is, durable preferences | git (vault repo); off-Mac via `memory-mcp` |
| **Project** | each project's `<project>/memory/` (set via `autoMemoryDirectory`) | Facts specific to that repo: which table, which endpoint, this project's quirks | git (that project's repo) |

Both lanes are git-tracked, so a lesson written on one machine or surface is present on
the next after a pull. This is the fix for "lessons siloed per repo" and "memory siloed
per machine": the harness's default auto-memory dir is machine-local; pointing
`autoMemoryDirectory` at a repo path makes it travel.

schnapp-os no longer owns the global lane. The global memory lane moved to the vault; a
separate repo holds cross-surface knowledge (its contract is the vault's `agents.md`), and
`memory-mcp` serves it to hookless surfaces.

### `autoMemoryDirectory` (verified semantics)
- Accepts an **absolute** or `~/`-prefixed path only (no relative, no `${VAR}`).
- Default (unset) = `~/.claude/projects/<project>/memory/`. Machine-local, NOT synced.
- Set in project `.claude/settings.json` it is honored only **after the workspace trust
  dialog is accepted** on that machine (same gate as hooks).
- The harness writes `MEMORY.md` (index; first ~200 lines / 25KB loaded at session start)
  plus topic files (loaded on demand).
- schnapp-os points it at `~/code/schnapp-vault/memory` (the global lane). The same value
  is set at USER scope in `~/.claude/settings.json` so the lane is active in every repo on
  the machine. A machine that clones the vault elsewhere overrides the path in its own
  `.claude/settings.local.json`.

## Schema

Do NOT restate the schema here. The vault's `agents.md` "Memory frontmatter schema"
(repo `SchnappAPI/schnapp-vault`, at `~/code/schnapp-vault/agents.md`) is the single
definition site: the flat top-level frontmatter block, the required keys, and the supersede
rule (overwrite in place and bump `updated:`; `superseded: true` only to retire a whole file
toward a `[[successor]]`). It is CI-enforced in the vault. Every memory write follows that
block; nothing here duplicates it. (Cross-repo, so it is referenced by path, not a link.)

Anti-stale discipline that applies to both lanes:
1. **One fact, one file.** Each per-fact file holds a single fact; `MEMORY.md` is a thin
   index (one line per fact). See [anti-stale](../rules/global/anti-stale.md).
2. **Supersede, do not append.** When a fact changes, replace the file's body; never leave
   a contradicting copy.
3. **No secrets.** References only (`op://...`), never secret values. See
   [secrets-as-references](../rules/global/secrets-as-references.md).

## Dual-altitude promotion (nothing moved, nothing lost)

When a lesson has BOTH a general principle and a specific instance, write it in **both**
lanes and link them. Never move:
- The **general principle** goes to the matching global rule (e.g. perf →
  [speed-by-default](../rules/global/speed-by-default.md), already seeded with:
  read-once, module-level cache, ThreadPoolExecutor, set-based SQL/CTE, bulk insert,
  `fast_executemany=True`).
- The **specific instance** (which table, which endpoint, which repo) goes to that project's
  lane and links back to the global principle by path.

This keeps the reusable lesson available everywhere while preserving the concrete detail
where it happened. Promotion is additive, so nothing is lost.

## Freshness gate (SessionStart)

At session start, before new work:
1. Load `MEMORY.md`; for each referenced fact compare `updated:` and the supersede flag.
2. **Skip / quarantine** any fact that is superseded or older than a fact that contradicts
   it. A superseded fact is never presented as current.
3. Verify any fact that names a file/function/flag/table still exists before acting on it
   (see [verify-before-asserting](../rules/global/verify-before-asserting.md)).
4. Surface **unmerged or unpushed work first** (git gate) before starting new work.

Implemented on Code as the SessionStart hook
[`session-start-gate.sh`](../hooks/session-start-gate.sh) (scans the vault's
memory for supersede-orphans and stale facts via the dir-arg check scripts). This section
is the authored procedure; the reasoning over memory stays the agent's job. On hookless
surfaces, run it via [`session-hygiene`](../.claude/skills/session-hygiene/SKILL.md).

## End-of-session write (Stop / SessionEnd)

On stop / session end, deterministically:
1. Write any fresh durable facts to the correct lane (supersede, don't append).
2. Update `MEMORY.md` index lines for changed facts.
3. Write/refresh the handoff (`handoffs/NNN-*.md`) and append a `PROGRESS.md` line.
4. Commit + push.

Implemented on Code as the Stop/SessionEnd hooks
([`session-stop-push-gate.sh`](../hooks/session-stop-push-gate.sh),
[`session-end-backup.sh`](../hooks/session-end-backup.sh)). The hook automates
only the deterministic half; authoring memory/handoff prose stays the agent's procedure. On
hookless surfaces, run it via `session-hygiene`.

## Handoff packet (cross-surface resume)

The named unit of cross-surface state (streamline spec section 7): whoever stops writes the
packet and pushes; whoever starts reads it. Both halves are the two procedures above, so this
section adds no new work, only the cross-surface contract:

- **Write on stop** = the [end-of-session write](#end-of-session-write-stop--sessionend):
  1. **Working-memory**: fresh durable facts into the vault `memory/` lane (schema + supersede
     rule: the vault's `agents.md`) plus their `MEMORY.md` index lines.
  2. **Newest handoff**: `handoffs/NNN-*.md` (next number = the new resume point) plus the
     regenerated `handoffs/README.md`, the `PROGRESS.md` line, and the plan-doc box flip.
  3. **Indexes current, both repos pushed** (`schnapp-os` + `schnapp-vault`). The vault root
     `index.md` changes only when the vault layout changed.
- **Read on start** = the [freshness gate](#freshness-gate-sessionstart): newest `handoffs/NNN`
  (via `handoffs/README.md`, marked "resume point"), then `MEMORY.md` and the facts the task
  needs, then surface unpushed/unmerged state before new work.

Transport differs; the packet does not. Code = local git + the hooks (automatic). Hookless
surfaces (Cowork, claude.ai) = the GitHub connector, run by hand via
[`session-hygiene`](../.claude/skills/session-hygiene/SKILL.md), which owns the connector
mechanics. Decision + rationale: [decisions/0027](../decisions/0027-cowork-handoff-packet-over-git.md).

## On-correction update (any surface)

When the owner corrects a mistake, or a wrong assumption surfaces, capture the fix
immediately so it is never repeated. Route by what kind of thing was corrected:
1. **Behavioral preference / how-to-work** → a rule, not memory. Update the matching file in
   [`rules/global/`](../rules/global/) (e.g. working-style). Rules load every
   session; memory is recall. See
   [knowledge-capture](../rules/global/knowledge-capture.md).
2. **Durable fact** (a value, a name, who/what/where) → memory, **supersede** the old fact
   (don't append a contradiction); set `source: correction` + today's `updated:`. Global lane
   (the vault) if cross-everything, project lane if repo-specific; link with `[[slug]]`.
3. **Doc-relevant** (a doc stated the wrong thing) → fix the doc in the same change; never
   leave the stale claim (see [anti-stale](../rules/global/anti-stale.md) "Doc
   currency").

Goal: the correction changes the always-loaded layer (rule) or the recall layer (memory) so
the same mistake cannot recur on any surface. Classification + routing detail lives in the
[`learn-route`](../.claude/skills/learn-route/SKILL.md) skill, which points back here.

## Verification
- Cross-repo: a global-lane fact written to the vault appears in a fresh session on another
  surface (via `memory-mcp` off-Mac, or the vault checkout on Code).
- Supersede: change a fact, confirm the old body is replaced (not duplicated) and the
  freshness gate skips the superseded version.
