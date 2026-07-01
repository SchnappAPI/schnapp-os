# 0029 - Vault memory lane: flat schema stays canonical, harness nested writer contained

Date: 2026-07-01. Status: DECIDED + SHIPPED. Builds on
[0023](0023-two-repo-vault-split-flat-memory-schema.md) (vault split, flat 8-key schema),
[0026](0026-enforcement-ladder-recurrence-escalation.md) (enforcement ladder),
[0028](0028-learning-loop-vault-fact-routing.md) (whose Follow-up routed this task).

## Context

Two writers shared `~/code/schnapp-vault/memory/` with different schemas. The vault contract
(its `agents.md`, single definition site) requires the FLAT 8-key frontmatter block, enforced
recursively by `scripts/check-frontmatter.sh` in vault CI on every push touching `memory/**`.
The Claude Code harness auto-memory feature (`autoMemoryDirectory`, user scope, points at the
lane) re-serializes fact files into a NESTED house form: name/description top-level, every
other key under `metadata:`, plus bookkeeping (`node_type`, `originSessionId`). Any session
memory write turned vault CI red and silently reverted flat migrations (first seen shipping
0028: vault dc13cb2 captured an interception; cd892a1 landed flat via shell write).

Measured by experiment before deciding (session 8efd82dd, 2026-07-01, Claude Code 2.1.112):

- Both Write and Edit tool writes into the lane are re-serialized, in about 2 seconds.
- The rewrite is key-preserving: all 8 flat keys survive under `metadata:`; only bookkeeping
  is added. A deterministic reverse mapping is total.
- Files at rest are never touched: no directory-wide heal at session start.
- Plain shell writes bypass the layer and stick.
- Docs and changelog: the nested format is undocumented, not configurable, and has no
  re-serialization disable knob; `autoMemoryDirectory` itself is configurable at all scopes.
  Killing the feature (`autoMemoryEnabled: false`) would also kill session recall.

## Decision

Flat stays canonical. The nested form is a transient serialization artifact, normalized
deterministically at the commit choke point, never adopted. `autoMemoryDirectory` stays
pointed at the lane so session recall keeps working. All vault-side, shipped in vault commit
`6c97b11`:

1. **`scripts/flatten-frontmatter.sh`** (TDD, 11 cases): nested to flat. Keys lifted verbatim
   in canonical order; `node_type`/`originSessionId` dropped (`originSessionId` seeds
   `source:` only when source is absent); mechanical defaults for missing keys (area, dates,
   superseded); semantic keys (description, type) never invented; flat files pass through
   byte-identical; fail-closed (exit 1, file untouched) on unmappable shapes.
2. **`scripts/git-hooks/pre-commit`** (TDD, 5 live scratch-repo cases): flattens staged
   direct-child `memory/*.md` facts, re-stages, validates each with `check-frontmatter.sh`,
   blocks subdirectory facts. Bootstrap once per machine:
   `git config core.hooksPath scripts/git-hooks` (done on this Mac). The committed lane is
   always flat regardless of what the harness did to the worktree.
3. **CI backstop unchanged in role**: `vault-freshness.yml` keeps the recursive checker on
   `memory/` and now also self-tests all three script specs; trigger paths widened to
   `scripts/**`. A machine without the hook bootstrap fails visibly in CI, never silently.
4. **`agents.md`**: new "Second writer: harness auto-memory" section documents the writer, the
   containment, and the shell-redirect escape hatch for byte-exact writes. The schema section
   is unchanged.

Proven live end-to-end on the real lane: an Edit-tool touch re-nested a probe file in ~2s; the
flattener restored flat bytes, checker-clean, body edit preserved; the deleting shell `rm`
stuck and `MEMORY.md` was not auto-modified.

## Rejected

- **(a) Adopt the nested form as canonical**: anchors the vault contract and CI to an
  undocumented, version-coupled internal serialization that can change with any Claude Code
  release; breaks memory-mcp's verified flat-schema serving; re-tools the just-shipped 0028
  fact leg (clone checker, distill prompt); imports per-session bookkeeping churn
  (`originSessionId` changes on every touching session) into fact diffs.
- **(b) Move `autoMemoryDirectory` off the lane** with a sync/translation step: the only
  reader that needs the setting is session recall itself (`MEMORY.md` injected at session
  start). Moving it either kills recall or requires mirroring the lane into a second directory,
  a standing duplication with drift risk (anti-stale). Interception is per-write and
  key-preserving, so commit-time normalization fully contains it without giving up recall.
- **Disabling auto-memory**: loses cross-session recall, the feature the lane exists to feed.

## Invariants kept

- One schema, one definition site: the vault's `agents.md`; the checker and flattener both
  point at it. schnapp-os restates nothing (this ADR records the decision, not the schema).
- CI stays green continuously: nested bytes cannot reach the remote through a hooked machine,
  and an unhooked machine fails loudly, not silently.
- No silent reverts of owner edits: content survives the harness round trip (key-preserving),
  and the hook restores the canonical shape at commit.
- Learning loop untouched: its worker-owned clone is outside any `autoMemoryDirectory` (0028).

## Verification

Vault `6c97b11`: `scripts/tests/test-flatten-frontmatter.sh` (11), `test-pre-commit-hook.sh`
(5, scratch-repo live), `run-tests.sh` (9, checker regression), shellcheck clean, all wired
into `vault-freshness.yml`; lane checker-clean; live interception round trip above. The
headless probe of a scratch `autoMemoryDirectory` via nested `claude -p` was attempted and
abandoned (child session cannot reach the parent's host-managed OAuth: 401 twice); directory
configurability is documented behavior and was not load-bearing for the decision.
