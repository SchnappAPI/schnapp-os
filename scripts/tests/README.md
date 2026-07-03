# scripts/tests/ - self-tests for guards and the learning loop

One `test-*.sh` per guarded behavior; each runs standalone (`bash scripts/tests/test-X.sh`,
exit 0 = pass) and as its own step in
[.github/workflows/freshness.yml](../../.github/workflows/freshness.yml) - add a step there when
adding a test. Tests never touch live state: queue/vault/state paths are injected via env
(`LEARNING_QUEUE`, dirs under `mktemp -d`). `secret-fixtures.txt` feeds the secret-scanner tests
with inert lookalike tokens.

Run the lot: `for t in scripts/tests/test-*.sh; do bash "$t" || echo "FAIL $t"; done`

Before pushing anything that touches hooks/ or scripts/: run the suite. A 2026-07-03 CI red came
from skipping exactly this.
