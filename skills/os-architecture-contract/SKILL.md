---
name: os-architecture-contract
description: Use when you need to know WHY schnapp-os is shaped the way it is before changing it - "why is this a symlink not a plugin", "can I add a skill under .claude/skills", "where do rules/memory/secrets canonically live", "what invariants must my change preserve", "why two repos", "why is the portal in front", "is this weakness known", or any architectural change, refactor, or new-component proposal that could violate a load-bearing decision. The design contract: the invariants, the reasoning behind them, and the known-weak points stated plainly.
---

# os-architecture-contract

The design contract for schnapp-os. Read this BEFORE proposing any structural change: every
invariant below is load-bearing, was paid for by a real incident, and has an ADR or doc that owns
it. This skill is the map of WHY; the change procedure itself is `os-change-control`.

Jargon, defined once:
- **ADR**: append-only decision record in `decisions/NNNN-*.md`. Reversals are NEW ADRs, never edits.
- **Surface**: a place Claude runs (Claude Code on a Mac, claude.ai web, iPhone, Cowork).
- **Hooked vs hookless**: Claude Code gets lifecycle hooks (SessionStart gates, secret scans,
  push gates); claude.ai/iPhone/Cowork get none and need a different consistency mechanism.
- **The vault**: sibling repo `~/code/schnapp-vault` (GitHub `SchnappAPI/schnapp-vault`), home of
  the cross-surface memory lane and the Obsidian second brain.
- **The portal**: the Cloudflare-managed OAuth MCP front at `mcp.schnapp.bet` ("Schnapp Portal")
  that claude.ai/iPhone use to reach the static-bearer connectors.

Paths below are this machine's clones (`/Users/schnapp/code/schnapp-os`,
`/Users/schnapp/code/schnapp-vault`); other machines use their own `~/code` clones.

## The two enemies

Everything in the architecture defends against two failure modes named in
[docs/framework.md](../../docs/framework.md):

1. **Silent drift**: a fact quietly going stale while a copy lives on elsewhere. Defense:
   single source of truth, supersede-not-append, generated docs, freshness CI, current-state-only docs.
2. **Silent stop**: automation quietly dying (the SQL backup was dead ~55 days before anyone
   noticed). Defense: infra-health probe + ntfy paging, GitHub-hosted mac-liveness dead-man's
   watcher, render-health keep-warm.

Test every proposed change against both: does it create a second copy of a fact, and can it die
without anyone being told?

## Load-bearing decisions and why

| Decision | Why | Owner |
|---|---|---|
| One fact, one canonical file; everything else references by path | Duplication is what goes stale | [rules/global/anti-stale.md](../../rules/global/anti-stale.md), [docs/framework.md](../../docs/framework.md) |
| This repo IS the machine-wide global lane: `~/.claude/CLAUDE.md` only `@import`s `rules/global/*` | Editing `~/.claude/` directly would fork the rules per machine | [CLAUDE.md](../../CLAUDE.md), [templates/user-global-CLAUDE.md](../../templates/user-global-CLAUDE.md) |
| Portable shell (symlinks + `@import` + absolute-path user-scope hooks), NOT a plugin | Plugin install ALWAYS snapshots to a cache; a live-source edit does not propagate. Proven by live test twice; the stale-plugin-pin failure class was DELETED by flattening the plugin away | ADRs [0033](../../decisions/0033-portable-shell-user-scope-wiring.md), [0024](../../decisions/0024-flatten-plugin-native-claude.md) |
| Single registrar: components live at repo root `skills/` `agents/` `commands/`; `.claude/` is wiring-only; **`.claude/skills/` is BANNED** | Anything under `.claude/{skills,commands}` auto-loads at project scope while the shell's user-scope symlinks load the same components everywhere: every session listed every skill twice (~11KB duplicated trigger text) | [handoffs/058](../../handoffs/058-single-registrar-component-move.md), commit `6f74078` |
| Two-repo split on the ATOMICITY line: system stays in schnapp-os, cross-surface knowledge in the vault | You cannot make one atomic commit across two repos, and atomicity is what prevents staleness, so the seam follows it. Vault is git-native and OUT of OneDrive (two sync engines corrupt `.git/`) | ADR [0023](../../decisions/0023-two-repo-vault-split-flat-memory-schema.md) |
| Flat 8-key memory schema, defined ONCE in the vault's `agents.md`, CI-enforced; the harness's nested rewrite is contained at commit time, never adopted | Three schema homes caused drift and a dead supersede-check; the Claude Code harness re-serializes Edit/Write in the lane to a nested form in ~2s, so a pre-commit flattener keeps the committed lane always flat | ADRs [0023](../../decisions/0023-two-repo-vault-split-flat-memory-schema.md), [0029](../../decisions/0029-vault-flat-schema-harness-writer-containment.md) |
| Connector topology: Render pair Mac-independent, Mac trio tunneled, portal in front | Memory and secrets must survive the Mac being off (op-mcp + memory-mcp on Render); Mac powers (shell, SQL, services) are inherently Mac-hosted (mac-mcp :8765, github-mcp :8766, obsidian-mcp :8767 behind cloudflared at `*.schnapp.bet`); claude.ai's connector UI is OAuth-only, so the four static-bearer servers sit behind one Cloudflare OAuth portal (obsidian-mcp speaks native OAuth, no portal needed) | [connectors/README.md](../../connectors/README.md), ADR [0020](../../decisions/0020-portal-front-mac-github-mcp.md) |
| Hookless surfaces: bootstrap floor + live read, no synced distilled copy | claude.ai/Cowork read `rules/global/` LIVE via the portal GitHub connector (probe-confirmed 2026-07-07); the pasted CORE is only a fallback floor for connector-down, plus the clause pointing at the live rules. An auto-synthesis daemon was killed: a 5% line diff can flip a negation | [surfaces/always-loaded-instructions.md](../../surfaces/always-loaded-instructions.md) |
| Enforcement ladder, escalation on RECURRENCE (>=2), never severity; judgment rules never get gates | History shows lessons that became a code/hook fix stopped recurring; prose-only lessons kept recurring. But a gate around a judgment rule is theatre that trains route-arounds. Ladder: advisory rule -> memory fact -> Code hook -> surface-independent CI gate (the only rung hookless surfaces cannot route around) | ADR [0026](../../decisions/0026-enforcement-ladder-recurrence-escalation.md) |
| Subtract over add; loops before features; plain over elaborate | The maximalist 11-Part plan was deliberately re-decided into ten subtractions; every added component expands the decision space every session pays for | ADR [0011](../../decisions/0011-plan-review-ten-redecisions.md) |
| Main only, no branches/PRs for directed work; commit and push without asking | Session-per-branch sprawl (14 stray branches once swept); single operator | ADRs [0016](../../decisions/0016-no-branches-precommit-gate.md), [0017](../../decisions/0017-web-sessions-target-main.md) |
| Secrets are `op://` references, never values, everywhere | The 2026-06-17 full plaintext leak of the vault's secrets | [rules/global/secrets-as-references.md](../../rules/global/secrets-as-references.md) |

Rollback nuance, stated precisely: DECISIONS are never reversed by edit or `git revert` (write a
new ADR). A bad RULE/SKILL edit that has already propagated machine-wide IS recovered by
`git revert` of the offending commit + push (the next SessionStart pull re-propagates the good
state). Both are in [docs/framework.md](../../docs/framework.md) section E.

## Invariants: what must hold, and how each breaks

| Invariant | How it breaks |
|---|---|
| One fact, one home | A doc restates a mutable fact it does not own; two copies drift; the stale one gets read. Symptom: a "current" doc contradicting PROGRESS.md |
| `~/.claude/CLAUDE.md` carries only `@import`s | Someone edits a rule inline in `~/.claude/`; the repo copy and the machine copy fork silently; other machines never see the change |
| No component ever under `.claude/skills/` or `.claude/commands/` | Creating one double-loads it in every schnapp-os session (project scope + user-scope symlink), duplicating trigger text and burning context |
| Shell delivery is live (symlinks, absolute paths), never snapshotted | Any plugin/copy-based delivery goes stale on the pinned snapshot; edits stop propagating; old bundled hooks can keep firing against a moved source |
| Committed vault memory lane is always flat schema | An unhooked machine commits harness-nested files; vault CI goes red; flat migrations silently revert. Fix: `git config core.hooksPath scripts/git-hooks` in the vault clone, once per machine |
| Vault stays out of any cloud-sync engine | Putting the working tree back under OneDrive lets two sync engines race `.git/` until it corrupts |
| Generated docs (CATALOG.md, handoffs/README.md, surfaces/claude-ai-skills.md) are regenerated, never hand-edited | A hand edit is overwritten by the next generator run, or the freshness gate fails the push |
| Every state-changing commit flips its plan box + appends PROGRESS.md in the SAME commit, pushed immediately | Split commits let GitHub lag local; the tracker stops being trustworthy; sessions resume from stale state |
| A secret value never enters a tracked file or transcript | One leak forces a rotation sweep across launchd services (which cache tokens in-process), Render env, and `~/.zshrc` |
| Gates are earned by recurrence, never pre-built | Premature gates ossify judgment, false-positive, and train everyone to ignore red (the freshness gate's own false-STALE era proved this) |
| Automation that can die must be watched from outside itself | A probe that only runs on the machine it watches dies with it; hence the GitHub-hosted mac-liveness watcher |
| Hookless surfaces are treated as hookless until verified | Assuming hooks ran on claude.ai/Cowork skips the must-happen procedures; run the `session-hygiene` skill there instead |

## Known-weak points (stated plainly, as of 2026-07-17)

1. **Portal health is a single point of failure for hookless surfaces.** If the portal 403s or its
   token expires, claude.ai/iPhone/Cowork silently fall back to the pasted bootstrap floor, which
   snapshots and can lag the live rules. No shipped drift monitor exists (the schnapp-console
   Surfaces tab was planned, never recorded shipped).
2. **Web user-scope wiring is unverified.** ADR 0033's one open empirical question: whether the
   claude.ai web container honors `~/.claude` wiring written by `shell/web-setup.sh`. Until the
   owner observes the first web session after pasting it, the web surface's hook story is unknown.
3. **mac-mcp misdelivery is detection-only.** The 2026-07-16 cross-delivery of another call's
   stdout originates in Cloudflare's layer, which cannot be patched from here. ADR 0034's
   self-identifying envelopes (echo + `call_id` + 90s clamp) make a mismatch visible; the CALLER
   must compare the echo to what it sent. The edge's real response deadline was never measured.
4. **Meta-freeze risk.** The vast majority of recorded sessions are meta-work on the system
   itself; several domain skills went unused for weeks. The system can self-improve into a mirror.
   Handoff 057's top-payoff counter (a week of real object work through it, then prune) was
   unexecuted as of the 2026-07-17 briefing.

## When NOT to use this skill

- Executing a change (commit/tracker/push mechanics): `os-change-control`.
- Diagnosing a live fault: `os-debugging-playbook`; past incidents and root causes:
  `os-failure-archaeology`.
- Whole-system inventory or orientation: `agentic-os-reference`; component flags and settings:
  `os-config-and-flags`.
- Install/bootstrap a machine or env: `os-build-and-env`; day-to-day operation: `os-run-and-operate`.
- Probes and tools: `os-diagnostics-and-tooling`; test/CI gates: `os-validation-and-qa`.
- Writing docs/rules in house style: `os-docs-and-writing`.
- Multi-surface rollout of a change: `os-cross-surface-campaign`.
- "What is loaded here" / "what is the state of everything": existing `surface-check` / `status`.

## Provenance and maintenance

Drift-prone claims and their re-verification commands (run from `/Users/schnapp/code/schnapp-os`):

- Components at repo root, `.claude/` wiring-only:
  `ls skills agents commands && ls .claude` (no `skills/` inside `.claude/`).
- Shell symlinks source repo-root components:
  `grep -n "for kind in skills agents commands" shell/install.sh`.
- `~/.claude/CLAUDE.md` is imports-only: `cat ~/.claude/CLAUDE.md`.
- Connector inventory and hosts: `cat connectors/README.md` and CATALOG.md "MCP connectors".
- mac-mcp envelope + 90s clamp: `grep -n "MAX_COMMAND_TIMEOUT_SECONDS" connectors/mac-mcp/server.py`.
- Vault flat-schema containment on this machine:
  `git -C /Users/schnapp/code/schnapp-vault config core.hooksPath` (expect `scripts/git-hooks`).
- Live-read model + paste map: `head -35 surfaces/always-loaded-instructions.md`.
- Weak points 1, 2, 4 are point-in-time (2026-07-17): re-check the newest handoff
  (`ls handoffs/ | tail -1`) and PROGRESS.md before repeating them.
