---
name: agentic-os-reference
description: Use when a session needs the domain theory behind this system - "how do skills/hooks/agents actually load", "what is a hook and when does it fire", "what does exit 2 mean in a hook", "why is my skill not triggering", "what's the difference between user/project/plugin scope", "how does MCP work here", "why op:// bearers in .mcp.json", "what is context rot / why one-screen rules", "how does the memory lane differ from auto-memory", "why supersede not append", "how does the learning loop land edits", or when onboarding a fresh session/machine/engineer to the Claude-agentic component model as applied in schnapp-os. Concepts and mechanics, not procedures.
---

# agentic-os-reference

The domain-theory pack: how Claude-based agentic systems work AS APPLIED in this repo. Every
concept points at a real file here as the worked example. Read this to understand the machine;
use the sibling os-* skills to operate it (see "When NOT to use").

Paths below are this machine's clones: `/Users/schnapp/code/schnapp-os` and
`/Users/schnapp/code/schnapp-vault`. On another machine, substitute its clone paths (installer:
`shell/install.sh` wires them).

## Glossary (each term defined once)

| Term | Meaning here |
|---|---|
| **Surface** | A place Claude runs: Claude Code on a Mac, claude.ai web, iPhone app, Cowork. Split hooked (Code) vs hookless (the rest). |
| **Skill** | A markdown instruction pack in `skills/<name>/SKILL.md`. Loaded on demand when its description matches the task. |
| **Agent** | A subagent definition in `agents/*.md` (4 as of 2026-07-17: 3 read-only reviewers with Read/Grep/Bash, plus performance-optimizer, which carries Write/Edit/Bash). Runs in an isolated context, returns a report. |
| **Command** | A user-invoked `/name` in `commands/*.md` (e.g. `/do`, `/critique-os`). |
| **Hook** | A shell script fired by the Claude Code harness at a lifecycle event. Scripts in `hooks/`, wiring in settings files. |
| **Harness** | The Claude Code program itself: the thing that runs hooks, loads settings, and executes tools. |
| **MCP** | Model Context Protocol: how Claude reaches external tools (a server exposes tools; the client discovers and calls them). |
| **Connector** | An MCP server this system owns, under `connectors/` (mac-mcp, op-mcp, memory-mcp, obsidian-mcp); the github leg is GitHub's official hosted server, not owned code. |
| **Memory lane** | The cross-surface fact store: one file per fact in `~/code/schnapp-vault/memory/`, indexed by `MEMORY.md`. |
| **Learning loop** | Capture corrections -> nightly distiller proposes edits -> deterministic gate auto-lands or holds them. |
| **Context rot** | In-session quality decay as the window fills with noise. Why always-loaded content is kept minimal. |

## 1. Component model and load mechanics

Four component kinds, one registrar: repo root `skills/`, `agents/`, `commands/`, `hooks/`.
`.claude/` is wiring-only. Never create `.claude/skills/` - it double-loads (handoff 058).
Inventory is generated into `CATALOG.md` by `scripts/gen-catalog.sh`; regenerate in the same
commit as any component change or CI fails.

**How loading actually works (the context-cost model):**

- A skill's YAML frontmatter has exactly two keys: `name` and `description`. The
  **description is the trigger**: it is always in context (cheap, one paragraph), and the model
  matches the current request against it. The **body loads only when invoked** (expensive,
  the whole file). So: descriptions are written trigger-rich with concrete symptom phrases
  (read `skills/status/SKILL.md` frontmatter as the house example), and bodies stay one to two
  screens.
- Rules differ: `rules/global/*.md` are **always loaded** in every session on this machine, via
  `~/.claude/CLAUDE.md` `@import`s. Every line there is paid for in every session forever. That
  is why the writing-style rule demands one screen and why `hooks/length-advisory.sh` warns on
  long rule files.
- Path-scoped modules (`rules/modules/`) load only when pulled in by a project. Nothing at the
  schnapp-os root force-loads them.
- Agents load like skills (description always visible, body on dispatch) but run in a **separate
  context window**: their raw file reads never enter the parent session, only their report does.

**Consequence to internalize:** the system's tiers are ordered by context cost.
Always-load (rules, CLAUDE.md) < trigger descriptions (skills/agents) < on-demand bodies <
subagent-isolated work. Put knowledge in the cheapest tier that still gets it used.
The `context-budget` skill audits what the loaded set costs.

## 2. Scopes and precedence

Three scopes deliver components and hooks. Verified wiring as of 2026-07-17:

| Scope | File | Fires where | What it carries here |
|---|---|---|---|
| **User** (machine-wide) | `~/.claude/settings.json` + `~/.claude/CLAUDE.md` | every repo on the machine | global rules @imports; ANY-REPO hooks (standing-rules, capture-nudge, global-session-gate, global-vault-push, idea-sweep, session-digest, guard wrappers). Written by `shell/install.sh` (ADR 0033). |
| **Project** | `<repo>/.claude/settings.json`, `<repo>/CLAUDE.md`, `<repo>/.mcp.json` | that repo only | schnapp-os's own gate set (see section 3) and the three project MCP servers. |
| **Plugin** | marketplace-installed bundles | wherever enabled | third-party only. Delivering schnapp-os itself as a plugin was rejected twice: plugin snapshots pin a commit and go stale (ADRs 0011, 0033). |

Both user and project hooks fire; the guard wrappers (`hooks/global-force-push-guard.sh`,
`hooks/global-secret-scan.sh`) self-skip inside schnapp-os by git remote identity so the
project wiring never double-fires. Exception documented in `hooks/README.md`: the secret-scan
wrapper's PreToolUse Bash leg never self-skips, because nothing else scans Bash command text.

Key inversion to remember: **this repo IS the source of the user scope.** Edit rules in
`rules/global/`, never in `~/.claude/`. `~/.claude/CLAUDE.md` only @imports them.

## 3. Hook events and the exit-code contract

A hook receives a JSON event on **stdin** (fields like `tool_name`, `tool_input`; see
`hooks/no-force-push-guard.sh` for a parsed example) and speaks through its **exit code**:

- **exit 0**: allow / no-op. Stdout from SessionStart and UserPromptSubmit hooks is injected
  into the session context (that is how `standing-rules.sh` delivers its reminder and how
  `post-compact-reinject.sh` restores invariants after compaction).
- **exit 2**: hard block. On PreToolUse the tool call never runs; stderr is shown to the model.
  PreToolUse fires before the permission-mode check, so an exit-2 guard holds even under
  `--dangerously-skip-permissions` (per the rationale in `hooks/no-force-push-guard.sh`).
- UserPromptSubmit hooks must always exit 0: exit 2 there suppresses the user's prompt
  (convention in `hooks/README.md`).
- Hooks reload at session start only; restart the session to pick up wiring changes.

Events actually wired in this repo (`.claude/settings.json`, verified 2026-07-17):

| Event | Matcher | Hook | Purpose |
|---|---|---|---|
| PreToolUse | `Bash` | no-force-push-guard.sh | block force-push (exit 2) |
| PostToolUse | `Write\|Edit\|MultiEdit` | secret-scan-on-write.sh, shellcheck-on-write.sh, em-dash-on-write.sh, length-advisory.sh | leak/lint/style gates (exit 2) + soft length WARN (always 0) |
| SessionStart | `startup` | session-start-gate.sh | sync + freshness + drift gate |
| SessionStart | `compact` | post-compact-reinject.sh | re-inject invariants post-compaction |
| Stop | `*` | session-stop-push-gate.sh | block stopping with unpushed commits |
| SessionEnd | `*` | session-end-backup.sh | backup |

User-scope events (every repo, from `~/.claude/settings.json`): UserPromptSubmit
(standing-rules, capture-nudge), SessionStart `startup|resume|clear` (global-session-gate pulls
both live clones), SessionEnd (global-vault-push, idea-sweep, session-digest), plus the two
guard wrappers. Full map: `hooks/README.md`.

**Hookless surfaces** (claude.ai web, iPhone, Cowork) get none of this. The must-happen steps
run by hand via the `session-hygiene` skill; treat any non-Code surface as hookless until
verified (`surface-check`).

## 4. MCP as used here

Two transports exist in MCP: **stdio** (client spawns a local process; used by the Obsidian
desktop server) and **remote HTTP** (client connects to a URL; everything else here). On
connect, the client discovers the server's tool list; tools then appear as callable
`mcp__<server>__<tool>` entries.

This system's topology (canonical detail: `connectors/README.md`, `.mcp.json` `$comment`):

- **Mac-independent pair on Render**: op-mcp (1Password resolver) and memory-mcp (vault
  read/write over the GitHub Contents API). Alive when the Mac is asleep.
- **Mac-hosted duo behind cloudflared**: mac-mcp (:8765) and obsidian-mcp (:8767) at
  `*.schnapp.bet`, run by launchd via `op-wrap.sh`. The github leg is GitHub's official MCP
  server (`api.githubcopilot.com/mcp/`) reached via the portal's github-mcp slot with
  portal-side headers - no Mac service (ADR 0036).
- **Auth, two styles by surface**:
  - Claude Code / Cowork read `.mcp.json`: static bearer headers written as
    `${ENV_VAR}` references, expanded at connect time. Never literal values
    (`rules/global/secrets-as-references.md`).
  - claude.ai web / iPhone cannot use `.mcp.json` (connector UI is OAuth-only): they reach the
    bearer servers through one Cloudflare OAuth portal, "Schnapp Portal" at `mcp.schnapp.bet`.
- **The silent-absence gotcha**: in a cloud environment, a missing entry in the network
  allowlist makes the proxy 403 the CONNECT and the server's tools simply never appear. Tool
  absence means allowlist first, not a broken server (memory: `environment-access`;
  canonical list: `docs/environment-and-access.md`).

## 5. Context-window economics

The window is finite and quality decays before it fills (context rot: repeated decisions,
generic output, forgotten constraints). Canonical rule:
`rules/global/context-discipline.md`. The design consequences visible in this repo:

- Always-load layer is ruthlessly small; one-screen rule files
  (`rules/global/writing-style.md`).
- Everything else is on-demand: skill bodies, path-scoped modules, docs.
- Broad searches and many-file reads go to subagents so raw dumps stay out of the main window.
- Compaction is survivable because `post-compact-reinject.sh` reprints the invariants.
- Measuring headroom and trimming is the `context-budget` skill.

## 6. Memory architecture

Two memory systems touch the same directory; know which is which.

- **The file-based lane (canonical)**: `~/code/schnapp-vault/memory/`, one fact per file,
  flat frontmatter schema (`name/description/type/area/source/created/updated/superseded`)
  defined once in the vault's `agents.md`. Git is the truth; every surface reads it (Code via
  clone, hookless surfaces via memory-mcp/portal). **Supersede, do not append**: a changed
  fact is overwritten in place with `updated:` bumped, never left beside a contradicting copy.
  Rationale: a retrieved contradiction is worse than no memory (`rules/global/anti-stale.md`).
- **Harness auto-memory**: Claude Code's built-in memory, pointed at that same directory by
  `autoMemoryDirectory` in `.claude/settings.json` (and user scope) so it commits and syncs.
  Side effect (ADR 0029): the harness re-serializes Edit/Write-tool writes in that directory
  into its own nested schema within ~2s. Contained by the vault's pre-commit flattener; for a
  byte-exact write use a shell redirect, not Edit/Write.
- Procedures (end-of-session write, on-correction routing, handoff packet):
  `docs/memory-lane.md`. Query entry point: the `notes-lookup` skill.

## 7. Subagent orchestration

Dispatch a subagent when the work is context-heavy (broad search, many files) or needs an
isolated adversarial pass (the `agents/` reviewers). Only the report returns to the parent.

**Verify findings before acting on them.** A subagent's report is a claim, not a fact: it can
hallucinate paths, misread state, or run against a stale snapshot. Two audit claims were
disproved live in one session (handoff 054). Apply `rules/global/verify-before-asserting.md` to
subagent output exactly as to recalled memory: re-check the specific file/command before
editing or asserting.

## 8. The learning loop

The self-improvement pattern, deterministic where it lands changes (ADRs 0021, 0026, 0028):

1. **Capture**: `hooks/capture-nudge.sh` (UserPromptSubmit, every repo) detects
   high-confidence correction phrases in HUMAN prompts and enqueues to a git-ignored
   `.learning-queue.tsv`, injecting a routing nudge. Manual routing: the `learn-route` skill.
2. **Distill**: nightly LaunchAgent `com.schnapp.memory-consolidation` runs
   `scripts/learning-worker.sh`: a bounded headless Agent SDK run (Read/Edit/Write/Grep/Glob
   only, no Bash) that writes proposed edits: rule edits in this repo, fact edits in a
   worker-owned vault clone.
3. **Gate**: `scripts/learning-gate.sh` auto-lands only small clean `.md` diffs in scope
   (`rules/*.md` here, `memory/*.md` in the vault) that pass size, provenance
   (`updated:` bump), and no-duplicate checks. Anything doubtful becomes a GitHub issue for
   the owner. The failure mode is designed to be "holds too much", never "merges junk".
4. **Escalate on recurrence**: `scripts/learning-recurrence.sh` counts error classes; a class
   seen twice or more is drafted as a gate proposal (a deterministic check), not another prose
   rule. Judgment rules never get gates (ADR 0026 ladder).

Why this shape: an LLM proposes, a deterministic script decides. A learning loop without the
eval gate learns confident junk.

## When NOT to use

This skill is theory. For doing, use the sibling:

- Making a change safely (main-only, same-commit tracker, gates): `os-change-control`.
- Something is broken right now: `os-debugging-playbook`; past incidents and root causes:
  `os-failure-archaeology`.
- What the architecture IS and its invariants: `os-architecture-contract`; flags/config
  surface: `os-config-and-flags`; install/build: `os-build-and-env`; day-to-day operation:
  `os-run-and-operate`; probes and tooling: `os-diagnostics-and-tooling`; tests/QA:
  `os-validation-and-qa`; docs conventions: `os-docs-and-writing`; multi-surface rollouts:
  `os-cross-surface-campaign`.
- Existing operational skills, not restated here: `status` (whole-system health),
  `surface-check` (what is loaded here), `session-hygiene` (hookless must-happens),
  `context-budget`, `learn-route`, `notes-lookup`, `vault-resolve`, `rotate-secret`,
  `cleanse-secrets`.

## Provenance and maintenance

Verified 2026-07-17 against the live repo. Re-verify each drift-prone claim:

- Project hook wiring table: `python3 -c "import json;print(json.load(open('/Users/schnapp/code/schnapp-os/.claude/settings.json'))['hooks'])"`
- User-scope hook list: `python3 -c "import json;print(json.load(open('/Users/schnapp/.claude/settings.json'))['hooks'])"`
- Component counts and inventory: `ls /Users/schnapp/code/schnapp-os/skills /Users/schnapp/code/schnapp-os/agents /Users/schnapp/code/schnapp-os/commands` (canonical: `CATALOG.md`, regenerate via `bash /Users/schnapp/code/schnapp-os/scripts/gen-catalog.sh`)
- MCP server list and auth style: `cat /Users/schnapp/code/schnapp-os/.mcp.json`
- Memory schema keys: `sed -n '/Memory frontmatter schema/,/^---$/p' /Users/schnapp/code/schnapp-vault/agents.md`
- Learning-gate criteria: `head -40 /Users/schnapp/code/schnapp-os/scripts/learning-gate.sh`
- Hookless-surface story (portal, live reads): `cat /Users/schnapp/code/schnapp-vault/memory/surfaces-live-read-default.md`
