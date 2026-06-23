# Schnapp-OS: Research and Decisions

A preserved record of the research, reference implementations, best practices, and reasoning behind building a cross-platform, remote-MCP Claude agentic operating system. Carry this into the Claude Code session that continues work on Schnapp-OS.

Date captured: 2026-06-23

---

## 0. How to use this document

This is a reference and decision record, not a task list. It exists so the next session does not start from scratch and so no load-bearing reasoning is lost. The companion handoff (Section 8) is the actionable part. Everything before it is the "why."

Read order for the next session: Section 8 (handoff) first, then Section 7 (decisions) to understand the order of operations, then dip into Sections 1 to 6 as reference when building.

---

## 1. The core thesis: what an agentic OS is

An agentic OS is the operating-system abstraction applied to agents. A normal OS manages processes, memory, I/O, scheduling, and permissions. An agentic OS manages the same things with different nouns: agents are processes, context and knowledge are memory, tools and connectors are device drivers, triggers are the scheduler, approval gates are permissions, and the repo is the filesystem.

Everything the OS "should have" falls out of that mapping, so the component list is not arbitrary:

- Kernel / control plane: policy, routing, permissions.
- Memory: tiered (working, durable, archival), single source of truth, supersede on change.
- Skills registry: modular, progressive disclosure, actually wired in.
- Orchestration: solo agent to sub-agents to pipelines, with quality gates.
- Tool / MCP layer: connectors, probe before claiming a capability exists.
- Scheduler: event triggers and time triggers.
- Observability and evals.
- Governance of self-modification: versioning, review, rollback.
- Secrets as references, never values.

### The architecture, as a stack

```
   [ Continuous learning loop ]   [ Freshness loop ]      <- cross-cutting governors
                     |                    |
              [ Kernel / control plane: policy, routing, permissions ]
                     |
   [ Skills registry ]  [ Orchestration ]  [ Tool / MCP layer ]
                     |
              [ Memory (tiered): working, durable, supersede on change ]
                     |
              [ Durable substrate: git repos, canonical docs, backup ]
```

### The two loops are the whole point

The layers are the easy 20 percent. The two loops are the hard 80 percent, and they are what separate an OS from a pile of config. A loop that depends on a human remembering to run it is not a system, it is a wish. Make both loops fire whether or not anyone is paying attention.

- Freshness loop (nothing is ever stale): at the start of every session, reconcile stored belief against ground truth (live git state, the real file on disk, a live connector probe). Ground truth always wins over stored belief. Single source of truth per fact (reference, never paraphrase). Memory supersedes, never appends. Fix the class, not the instance.
- Learning loop (continuously learns): capture what happened (especially corrections and novel solutions), distill the reusable principle, route it to one canonical home, validate that it actually fires, then promote a low-confidence note to a tested skill. The validate-and-promote step is the one everyone skips, and skipping it is why "learning" systems accumulate contradictory cruft instead of improving.

### Efficiency = three economies

- Context economy: load only what is relevant, progressive disclosure, page knowledge in and out.
- Compute economy: cheap tasks to cheap models, cache expensive reads, parallelize independent I/O, set-based operations.
- Human economy: act by default, pause only for the irreversible or costly. Human attention is the scarcest resource.

---

## 2. Three reference implementations (use as the comparison set)

Each nails one layer and leaves the rest to you. There is no single turnkey repo that bundles everything.

### A. AIOS (Rutgers / agiresearch) — the OS thesis and reference architecture

- Open-source "LLM Agent Operating System." Isolates resources and LLM services from agent applications into an AIOS kernel. The kernel provides scheduling, context management, memory management, storage management, tool management, and access control.
- The access manager is the security boundary: which tools, which data, which endpoints each agent may touch.
- Key insight: this kernel structure is not aspirational. It is what every production-grade agent runtime ends up implementing whether or not the authors call it a kernel.
- Reports roughly 2.1x faster execution via an OS-style scheduler optimizing how queries dispatch to the LLM.
- Built for serving many concurrent agents efficiently, NOT for continuous learning. Read it for the mental model and the kernel decomposition, do not deploy it directly as your OS.
- Related: AgentOS, UFO2 (Windows desktop agent OS), LiteCUA. Broader "Agent OS" movement includes IBM and Microsoft (Windows AI Foundry, Entra Agent ID).
- Sources: arxiv.org/abs/2403.16971 ; github.com/agiresearch/AIOS (SDK is the Cerebrum repo).

### B. Letta (formerly MemGPT) — the memory and continuous-learning loop

- LLM-as-operating-system paradigm: the model manages its own memory, context, and reasoning loops, like an OS manages RAM and disk.
- Three-tier memory: core (always in context) to recall (searchable history) to archival (vector storage).
- Self-editing memory: the agent writes to its own prompt via tool calls, unlike passive RAG. Virtual context via summarization and paging creates the illusion of unbounded context.
- Sleep-time agents: background agents that manage and compact memory asynchronously. This is a clean model for the distill-and-route step of the learning loop.
- Open source, model-agnostic, git-backed (Letta Code). From UC Berkeley Sky Computing Lab, creators of MemGPT.
- Free DeepLearning.AI course builds a self-editing MemGPT-style agent from scratch (fastest way to internalize the mechanism).
- Mem0 is the lighter alternative: a memory layer you bolt onto an existing framework, vs Letta which is a full runtime where agents live.
- Use as the reference implementation for the memory tier plus the learning loop.
- Sources: letta.com ; the MemGPT paper ; DeepLearning.AI "LLMs as Operating Systems: Agent Memory."

### C. Claude Code ecosystem — the practical clone-and-run starting point

The loops fit most naturally in an agent harness, so this is the surface to actually build on.

- ChrisWiles/claude-code-showcase: full `.claude/` layout — CLAUDE.md, settings.json (hooks/permissions), agents/, commands/, .mcp.json. Hooks auto-format, run tests, block edits on main.
- luongnv89/claude-howto: copy-paste templates for memory, skills, subagents, hooks, MCP.
- hesreallyhim/awesome-claude-code and rohitg00/awesome-claude-code-toolkit: curated lists. Notable entries: a "markdown-first multi-agent OS for Claude Code" (file-based dispatch, institutional memory, human approval gate, scheduling) and a "cognitive architecture" (persistent memory plus self-reflection via plain-text conventions).
- claude-mem: a working memory loop on Claude Code — lifecycle hooks enqueue observations, an async worker compresses them to SQLite, and a SessionStart hook injects recent context into the next session. Closely mirrors the learning loop. Sources: docs.claude-mem.ai.
- Native Claude Code features that already implement parts of the loops: CLAUDE.md (persistent memory loaded at session start); subagent `memory` field plus MEMORY.md self-curation; PreToolUse hooks (policy enforcement that cannot be bypassed).

### What each contributes, mapped to the architecture

- AIOS = the kernel and subsystem decomposition (the whole diagram, conceptually).
- Letta = the memory tier and the self-editing/distill mechanics of the learning loop.
- Claude Code templates = the loops, the skills registry, and the tool layer, on the real surface. The anti-staleness discipline (single source of truth, supersede, freshness reconcile) is convention you wire yourself, mostly through hooks and CLAUDE.md.

---

## 3. Building it on Claude: primitive mapping

| Architecture box | Claude primitive |
| --- | --- |
| Durable substrate | git repo + `.claude/` directory |
| Kernel / control plane | CLAUDE.md (rules, policy, loaded every session) + settings.json (permissions) |
| Memory: core | CLAUDE.md (always in context) |
| Memory: durable | subagent memory directory + self-curated MEMORY.md |
| Memory: archival | external store (SQLite or vector via a memory plugin; or Letta / Mem0) |
| Single source of truth | canonical docs in the repo, referenced not paraphrased |
| Skills registry | SKILL.md files with progressive disclosure, bundled as plugins |
| Orchestration | subagents (own context, tools, memory) + slash commands; Agent SDK if headless |
| Tool / device layer | MCP connectors in `.mcp.json` (including self-hosted) |
| Scheduler | hooks (event) + cron/launchd (time) + slash commands (on-demand) |
| Permissions / security | settings.json deny rules + PreToolUse hooks + secrets as references |

---

## 4. The two loops, as concrete Claude hooks

### Hook facts (current as of mid-2026, v2.1.141+)

- Roughly 27 distinct lifecycle events. Most relevant: SessionStart, Setup, SessionEnd, UserPromptSubmit, Stop, PreToolUse, PostToolUse, SubagentStart, SubagentStop, PreCompact.
- Handler types: command, http, prompt, agent (plus mcp_tool). `async: true` runs a hook in the background without blocking. HTTP hooks send events to a remote server.
- SessionStart and UserPromptSubmit: anything written to stdout is added to Claude's context. SessionStart matchers: startup, resume, clear, compact.
- PreToolUse fires before the permission-mode check, so a hook returning deny (or exit 2) blocks the action even under `--dangerously-skip-permissions`. This is the only reliable hard-policy gate.
- Stop fires whenever Claude finishes responding. It can return exit 2 / decision block to force continuation, gated on a real condition that clears with exit 0.
- SessionEnd is cleanup, fires on clear, cannot block termination.
- Sources: code.claude.com/docs/en/hooks-guide ; code.claude.com/docs/en/sub-agents ; github.com/anthropics/claude-code (plugin-dev hook-development skill).

### Freshness loop

- A SessionStart hook runs the git catch-up and reconciliation and writes the reconciled state (uncommitted, unpushed, stale) to stdout, so it lands in context before any work begins.
- A second SessionStart hook with a `compact` matcher re-injects conventions after compaction so the system does not forget mid-session.
- PreToolUse hooks block stale or destructive operations (force-push to main, destructive deletes, writing secret values), unbypassable.

### Learning loop

- Capture at the boundaries: Stop, SessionEnd, and UserPromptSubmit.
- Because hooks must return fast (about 1 second), the hook enqueues an observation and an async worker does the slow compression and routing (the claude-mem pattern: enqueue in milliseconds, worker writes summaries to SQLite, next SessionStart injects recent context).
- Routing: a correction becomes an edit to a rules file; a durable fact supersedes a memory entry; a repeated procedure graduates into a new SKILL.md. Promotion (note to tested skill) is gated by the eval harness.
- A Stop hook can refuse to end the session until memory is written and committed.

### Session lifecycle

```
[ SessionStart hook ] --> [ Work loop ] --> [ Stop / SessionEnd hook ]
   freshness gate:          skills, MCP        end write: memory,
   catch up, reconcile      tools, subagents,  handoff, commit
                            PreToolUse guard
        ^                                              |
        |______________ writes feed next session ______|
```

---

## 5. Remote MCP server (cross-platform access)

This is the layer that makes the OS reachable from every Claude surface (web, mobile, Claude Code, API) instead of tied to one machine. It is how OS operations (read/write memory, trigger the freshness reconcile, run the learning-loop route, dispatch a job, resolve a credential) become callable tools shared across surfaces.

### Topology

```
[ Claude surfaces ]      [ Remote MCP servers ]      [ Shared OS state ]
  web / mobile     -->     memory             -->      git repo
  Claude Code      OAuth   control-plane               memory store
  API / agents             integrations                canonical docs
```

### Facts (current)

- Transport: Streamable HTTP is the standard (single `/mcp` endpoint). SSE is deprecated. MCP-Protocol-Version header is mandatory after init; servers validate Origin; disable proxy buffering on the MCP path.
- How Claude connects:
  - claude.ai / desktop: Settings, Connectors, Add custom connector, paste URL, OAuth flow.
  - Claude Code: `claude mcp add --transport http <name> <url>` (type field accepts `streamable-http` as alias for `http`).
  - API: pass the server with type `url` and an authorization token. Only tool calls are supported; must be public HTTP, not stdio.
- Cloud-broker gotcha: with a custom connector, the connection is brokered through Anthropic's cloud, so the server must be reachable from Anthropic's public IPs. A private/VPN-only server will not connect. Fix: expose publicly with OAuth, or front with Cloudflare Access, or use the mcp-remote bridge for local clients.
- Auth: OAuth 2.1 with PKCE is the spec standard (the server acts as OAuth provider, supports Dynamic Client Registration); bearer tokens acceptable for internal use.
- Build: FastMCP in Python (set `transport="streamable-http"`); the TypeScript SDK uses an HTTP adapter. Cloudflare Workers is the lowest-friction host: createMcpHandler / McpAgent handle Streamable HTTP, workers-oauth-provider gives spec-compliant OAuth for free, Durable Objects hold per-session state, generous free tier. Test with the MCP Inspector or Cloudflare AI Playground.
- Design for an OS: do not build one mega-server wrapping the whole API. Build few goal-shaped tools; tool-selection accuracy degrades past about 25 to 30 tools and sharply past 50. Deploy several scoped servers (memory, control-plane, integrations), each narrowly permissioned and separately revocable. For a huge API surface use the Code Mode pattern (expose `search()` and `execute()` instead of thousands of tools).
- Sources: platform.claude.com/docs/en/agents-and-tools/mcp-connector ; modelcontextprotocol.io/docs/develop/connect-remote-servers ; developers.cloudflare.com/agents/guides/remote-mcp-server ; blog.cloudflare.com/remote-model-context-protocol-servers-mcp.

---

## 6. 1Password and credential management

The principle is unchanged from the rest of the system: secrets are references, never values.

- 1Password is the source of truth for secrets. Store `op://` references in tracked files; never a secret value in any tracked file, hook, or transcript.
- The remote MCP server holds a 1Password service-account token server-side and resolves `op://` references at call time. The actual credential is fetched at the moment of use and never lands anywhere it persists. The server exposes only tools, so the agent calls a tool and never sees the credential. That is the security win of the remote-server pattern.
- Prefer resolving secrets into the environment of a command (so the value stays off the transcript) over reading a value back into context. Read a value into context only as a last resort.
- The credential redo that triggered this whole effort is therefore not a separate project. It is one of the first scoped tools on the remote MCP server.
- In-session verification: confirm which token lives where, and that no resolved `op://` value is written anywhere it persists.

---

## 7. Decisions made this session, with reasoning

### 7.1 Adapt vs rebuild

The decision turns on one question: is the repo's core architecture sound, or fundamentally misaligned with what an OS needs. Code quality you refactor; a wrong foundation you cannot. Default prior: adapting beats rewriting in almost every case, because a rewrite throws away the embedded knowledge in the existing repo and forces rebuilding the boring 80 percent that already works. Rewrite only when adapting the core costs more than replacing it, and even then migrate incrementally (strangler-fig: stand up the new kernel beside the old, port capabilities one at a time, never be without a working system).

### 7.2 The review method (for a purpose-built repo you fear losing detail from)

1. Capture intent before cutting. Reconstruct what each layer, hook, and skill was meant to do. Distinguish deliberate design from accretion. Do this first, or you will delete something load-bearing because it looked like cruft.
2. Inventory against ground truth. File tree, real entry points, inventory by capability not by file, reverse-dependency check (grep for callers), last-commit dates per area. Orphaned components and stale corners are themselves the diagnosis.
3. Score against the reference architecture. Rate each layer and loop on present/partial/absent and sound/shaky. Weight the two loops heaviest.
4. Decision rule and artifact. Produce a gap report (each layer/loop, rating, one-line note, ending in the adapt-or-rebuild call). If adapt, attach a prioritized backlog. Priority order is fixed: loops first, then prune orphans, then evals and governance. Loops before features, always.

Failure smells to grade against: the same fact paraphrased across files (no single source of truth); memory that appends instead of supersedes; corrections handled ad hoc and never routed; self-edits to rules/skills with no eval gate or review; secret values in tracked files; heavy logic inside hooks.

### 7.3 Diagnosis of the actual situation

Three rebuilds (Schnapp-kit too heavy, Claude-kit simplified it then deleted, Schnapp-OS current) have not stuck because BOTH loops are absent. Fixes in one session do not carry to the next (no learning loop). Stale hooks fire on old assumptions (no freshness loop). The work keeps rebuilding the 80 percent and never gets the hard 20 percent working. A fourth rewrite repeats this exactly. Conclusion: Schnapp-OS is the substrate to keep. Do not start a fourth repo. Do not finish Schnapp-OS as currently planned, because the plan's decisions were taken on "recommended" defaults without deliberate review. Reset to ground truth on it first.

### 7.4 Order of operations (do not reorder)

1. Rotate exposed secrets. (Done.)
2. Delete chat-memory history and leave generation off (NOT pause). Reasoning below.
3. In Claude Code: plan review first, not task completion. List each decision taken on "recommended" and re-decide it on purpose.
4. Capture intent before cutting (Section 7.2 step 1).
5. Loops before features. Freshness gate first (one SessionStart hook reconciling live git and the 1Password-backed credential store), then the capture-and-route step.
6. Prune everything else in service of the loops. If a hook does not serve a loop or a current task, delete it. The repo being too busy is the same disease as Schnapp-kit; the cure is subtraction, not completion.
7. Credentials as the first scoped MCP capability (Section 6).

### 7.5 Chat-memory feature: delete history, generation off

The 24-hour generation delay plus a fast-moving day makes the chat-memory feature structurally guaranteed to serve stale references. It violates the freshness principle by construction: it stores belief and serves it back after the world has moved. Pause only stops new memory from generating; the stale references already in the store keep being served. Since the problem is stale stored belief, delete the existing store and leave generation off. The real cross-session continuity comes from the remote MCP memory server, which reconciles against live state instead of replaying a day-old snapshot. Disabling the feature removes the thing competing with the goal.

### 7.6 Git history cleanse (completed)

Method used: per-repo orphan-branch reset plus deletion of non-main branches, force-pushed, driven by an explicit hand-built allowlist rather than a blind loop over all repos (a denylist is unsafe when tired; an allowlist you can read is safe). Protected: schnapp-bet and appfolio-quickbase-sync. Note: old commit SHAs survive on GitHub until garbage collection, so this is history hygiene, not secret erasure; the rotation already neutralized the exposure. "Only commit to main moving forward" was NOT yet enforced as a default-branch + new-branch-block rule; install that and a PreToolUse guard against force-push to protected repos when convenient.

### 7.7 Build order (phased, each phase rests on a working one)

1. Substrate: repo + `.claude/` + CLAUDE.md rules. A minimal working kernel.
2. Freshness: one SessionStart hook injecting git status and recent commits.
3. Guardrails: one PreToolUse hook blocking the irreversible.
4. Memory: a memory plugin (or subagent MEMORY.md) + SessionEnd capture hook + async worker.
5. Capabilities: SKILL.md files for recurring workflows + MCP servers in `.mcp.json`.
6. Orchestration: subagents for big tasks + slash commands to chain them.
7. Learning loop proper: the distill-and-route worker + correction routing.
8. Evals and governance: an eval harness that scores whether a new rule/skill helped + git pull-request review for self-edits, with rollback by revert.

### 7.8 Hard parts (where these fail)

- Hooks must return in about a second; heavy work (compression, embedding, evaluation) goes to an async worker, never inside the hook.
- The distill-and-route step is the real engineering. Mechanical parsing for structured captures; reserve an LLM call for the genuinely fuzzy ones.
- A learning loop without the eval gate learns confident junk. Build the gate before letting the system edit its own rules.
- Self-modification needs governance, gained nearly for free by routing every self-edit through git so each change is diffable and revertible.
- Secrets stay references; never hardcode tokens in committed hooks.

---

## 8. Handoff for the next session

Load repo: Schnapp-OS. It is the substrate being kept and reviewed; it is where the loops and the credential access attach. (The git-history cleanse is a finished, separate terminal task, not a reason to load any repo.)

State of play:
- Secrets rotated. Repo histories cleansed (allowlist method; schnapp-bet and appfolio-quickbase-sync preserved).
- Chat memory: delete history, generation off.
- "Commit to main only" not yet enforced as a rule. Optional follow-up.

First move in session: plan review (Section 7.4 step 3), NOT task completion. List every decision taken on "recommended" defaults and re-decide on purpose.

Then, in order: capture intent before cutting (7.2 step 1), get the freshness gate working (one SessionStart hook reconciling live git + 1Password-backed credentials), then capture-and-route, then prune everything that does not serve a loop or a current task.

Guardrail to install early: a PreToolUse hook blocking force-push to protected repos and writes of resolved secret values.

Standing principle for the whole effort: loops before features, capture intent before cutting, subtract rather than complete, secrets as references, ground truth beats stored belief.
