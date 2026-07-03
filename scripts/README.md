# scripts/ - checks, generators, learning loop, ops

Every script carries a header comment stating its contract (read that, not this list, for
behavior). Groups:

**Freshness / gates** (run in CI via [.github/workflows/](../.github/workflows/), some also in
session hooks): `check-freshness.sh` (generated-doc + `last-verified:` drift, the hard gate),
`check-links.sh`, `check-writing-style.sh`, `check-stale-facts.sh`, `check-supersede-orphans.sh`,
`check-open-questions.sh`, `check-op-refs.sh`, `scan-secrets.sh`, `check-secret-bytes.sh`.

**Generators** (output is committed, never hand-edited): `gen-catalog.sh` ->
[CATALOG.md](../CATALOG.md), `gen-handoff-index.sh` -> [handoffs/README.md](../handoffs/README.md).

**Learning loop** (the self-improvement pipeline; ADRs 0016/0021/0026/0028):
`learning-worker.sh` (orchestrator, runs from the memory-consolidation LaunchAgent),
`learning_distill.py` (Agent SDK distiller), `learning-gate.sh` (deterministic approve/hold),
`learning-recurrence.sh` (error-class recurrence -> gate-proposal issue), `learning-eval.sh`
(read-only effectiveness report).

**Ops / infra**: `check-infra-health.sh`, `ops-alert.sh`, `notify-ops.sh`, `backup-archive.sh`,
`vault-autocommit.sh`, `assemble-context.sh`, `lib-frontmatter.sh` (shared parser).

**Tests**: [tests/](tests/) - one self-test per guard/loop script, each a CI step in
`freshness.yml`.
