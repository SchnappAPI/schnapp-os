# 0028 - Learning loop routes durable facts to the vault lane (worker-owned clone)

Date: 2026-07-01. Status: DECIDED + SHIPPED. Builds on
[0016](0016-no-branches-precommit-gate.md) (pre-commit gate, no branches),
[0021](0021-learning-loop-agent-sdk.md) (file-scoped Agent SDK distill),
[0023](0023-two-repo-vault-split-flat-memory-schema.md) (global memory lane -> schnapp-vault),
[0026](0026-enforcement-ladder-recurrence-escalation.md) (gates never auto-land).

## Context

Streamline Phase 1 removed schnapp-os's `memory/` (the global lane moved to the vault per 0023),
but the nightly learning loop still targeted it: `learning_distill.py`'s prompt said "supersede in
memory/" and `learning-gate.sh`'s auto-land scope was `rules/*.md|memory/*.md`. The first nightly
run with a durable-fact capture would have recreated `memory/` in the WRONG repo and auto-landed
it, diverging from the lane every surface actually reads (memory-mcp, autoMemoryDirectory, the
vault checkout). Found 2026-07-01 in the em-dash sweep; routed to a dedicated session because a
freshly-reviewed autonomous pipeline gets a designed, tested change, not a hot patch.

## Decision

Durable facts land in the VAULT via a worker-owned automation clone. Rules keep the existing path.

1. **Distill edits a clone, never the live tree.** `learning_distill.py` gets the clone as a second
   writable root (SDK `add_dirs`, env `LEARNING_VAULT_DIR`, default
   `~/.cache/schnapp-os/learning-vault`). The prompt routes: behavioral -> `rules/global/` here;
   durable fact -> supersede in `<clone>/memory/` per the vault's `agents.md` flat schema (new fact
   also gets a `MEMORY.md` index line). Missing clone -> fail fast (exit 4, queue preserved).
2. **The worker preps and lands per tree.** `learning-worker.sh` clones-or-syncs the clone
   (fetch + reset + clean) BEFORE recurrence/distillation; prep failure aborts before any side
   effect. After distillation: the rules leg gates with scope `rules/*.md` and pushes this repo's
   main (unchanged flow); the fact leg commits the clone diff, gates INSIDE the clone with scope
   `memory/*.md` PLUS a flat-lane depth check (any path not a DIRECT child of `memory/` is held:
   the scope glob crosses `/`, so depth is enforced separately) PLUS the clone's own
   `scripts/check-frontmatter.sh` (the same check the vault's CI enforces, made recursive in the
   vault so no depth escapes it; pre-push it can never land red), then pushes the vault's main. A
   held proposal on either leg is reverted and filed as a review issue in schnapp-os (one review
   queue).
3. **Gate scope is an argument.** `learning-gate.sh [base] [scope]`, default `rules/*.md`. A
   repo-local `memory/` write in schnapp-os is out-of-scope -> HOLD -> issue. Provenance tightened
   while in there: a base file with no frontmatter `updated:` (an index like `MEMORY.md`) is
   exempt; REMOVING `updated:` now HOLDs (it previously passed as "changed").
4. **The owner's live vault tree is untouchable.** Never reset, never stashed. After a landed fact
   the worker fast-forwards it best-effort, only when clean; otherwise the next session-start sync
   picks the fact up from the vault's main.

## Rejected

- **Queue hand-off to a vault-side consumer**: breaks supersede-in-place (the LLM must edit the
  existing fact file with its current content in context), adds an async component whose backlog
  can silently grow.
- **Writing via memory-mcp**: reintroduces network into the LLM step that 0021 deliberately
  restricted to file tools, and there is no local byte-level gate before such a write.
- **Editing the live vault tree directly**: Obsidian can dirty it at any moment; the worker's
  clean-tree/reset discipline only works on a tree the worker owns. Proven live while shipping
  this ADR: an in-session Edit into the live lane was re-serialized within seconds by the harness
  auto-memory layer back into its nested house schema before it could be committed (vault commit
  dc13cb2 captured the interception; cd892a1 landed the intended bytes via a plain shell write).
  The live tree has more writers than the owner. The clone is not under any autoMemoryDirectory,
  so the distill session's edits there are plain file writes.

## Follow-up (routed to its own session, 2026-07-01)

The interception above exposed a standing two-writer conflict on the live lane: the harness
auto-memory feature writes NESTED `metadata:` frontmatter into `~/code/schnapp-vault/memory/`,
while the vault's contract (its `agents.md` + `check-frontmatter.sh` CI) requires the FLAT 8-key
block and rejects the nested form. One file was migrated flat here (it was blocking vault CI and
this ADR's fact leg); the contract decision is chipped as a dedicated task, not settled by this ADR.

## Invariants kept

- Gates NEVER auto-land (0026): recurrence still only drafts issues; the auto-land path admits
  only rule `.md` here and schema-valid fact `.md` in the vault clone.
- No branches; everything that lands goes to a `main` (0016).
- The LLM never touches git; the worker does all prep/gate/commit/push deterministically (0021).

## Verification

TDD, all wired into `.github/workflows/freshness.yml`:
`scripts/tests/test-learning-gate.sh` (30: scope arg, default rules-only HOLD for `memory/`,
index-file provenance exemption, `updated:`-removal HOLD, empty-scope fail-closed HOLD),
`scripts/tests/test-learning-distill.sh` (6, new: prompt routing, `add_dirs` wiring, fail-fast),
`scripts/tests/test-learning-worker-vault-live.sh` (37, new gh-shim live harness: clean fact lands
on vault main only with live-tree ff-pull; out-of-scope, bad-schema, subdirectory, and repo-local
`memory/` writes all HOLD with an issue; clone-prep failure and a clone dir inside the repo abort
with the queue preserved),
`scripts/tests/test-learning-worker-recurrence-live.sh` (16, vault fixtures added).

Adversarial review (Fable subagent) before push found one Critical, verified end-to-end: a
schema-less fact in a `memory/` SUBDIRECTORY auto-landed on a simulated vault main, because the
scope case-glob crosses `/` and the vault checker scanned only direct children. Closed three ways:
the worker's flat-lane depth check (above), the vault checker made recursive (vault commit
81df3b8), and a regression case in the live harness. Its Minor (empty scope) turned out worse than
reported: `${2:-}` substituted the rules default for an explicitly empty scope (fail open);
now `${2-}` keeps empty empty and `in_scope` matches nothing (fail closed, gate test 16). Also
taken from its residual list: LEARNING_VAULT_DIR inside the repo aborts, clone prep self-heals
with `checkout -f`, live-tree ff-pull additionally requires the live tree to be ON main.
