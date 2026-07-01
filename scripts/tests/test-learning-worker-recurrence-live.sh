#!/usr/bin/env bash
# test-learning-worker-recurrence-live.sh - LIVE-path regression test for the recurrence gate.
#
# Guards the A1 invariant (the highest-stakes bug on the autonomous loop): a recurring error-class is
# marked "drafted" (and held out of distillation) ONLY when its `gh issue create` actually SUCCEEDED.
# On a gh FAILURE the class must NOT be marked (so it retries next run) and must NOT be filtered (so it
# still flows to prose distillation THIS run) - better a prose fact than a lesson orphaned into a gate
# that was never filed. And in EVERY case nothing lands on main (the cardinal safety invariant).
#
# RED (the defect this locks down): the pre-fix worker appended the drafted SIG to the marker and set
# the distill filter UNCONDITIONALLY after the gh loop - so a gh failure still marked the class drafted
# (idempotency then suppresses re-draft forever) AND held its capture out of distillation. The lesson
# could then never become an issue OR prose; only the raw archive row survived.
#
# Harness: a throwaway git repo (bare origin + working clone) holding the REAL scripts/, with PATH
# shims for the two external commands the live path calls - a flippable `gh` (GH_MODE=fail|succeed) and
# a no-op `claude` (so `command -v claude` passes) - and a no-op distill python (LEARNING_DISTILL_PYTHON)
# so no .md is edited. NO network; the only git remote is the local bare origin. This runs the actual
# learning-worker.sh live path end to end.
set -uo pipefail
export LC_ALL=C

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_SCRIPTS="$(cd "$here/.." && pwd)"          # the real scripts/ dir under test
pass=0; fail=0

check() { # $1=got $2=want $3=label
  if [ "$1" = "$2" ]; then pass=$((pass+1)); echo "ok   $3"
  else echo "FAIL $3 (got [$1] want [$2])" >&2; fail=$((fail+1)); fi
}
contains() { case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }

# --- build a throwaway repo: bare origin + working clone with the real scripts ----------------------
root="$(mktemp -d)"; trap 'rm -rf "$root"' EXIT
origin="$root/origin.git"
work="$root/work"
export GIT_CONFIG_GLOBAL="$root/.gitconfig"    # isolate from the user's real git identity/hooks
# -b main: pin the bare HEAD so clones are deterministic across host git defaults (see the
# vault-live harness for the CI failure this prevents).
git init -q --bare -b main "$origin"
git clone -q "$origin" "$work" 2>/dev/null   # 2>/dev/null: silence the benign empty-repo clone notice
git -C "$work" config user.email test@example.com
git -C "$work" config user.name  test
git -C "$work" config commit.gpgsign false

# Seed the origin/main the worker resets to: the real scripts + stub externals, plus rules/ so the
# post-distill scope check has a realistic tree. The stub distill python edits NOTHING.
mkdir -p "$work/scripts" "$work/rules" "$work/scheduled-tasks"
cp "$SRC_SCRIPTS/learning-worker.sh"     "$work/scripts/"
cp "$SRC_SCRIPTS/learning-recurrence.sh" "$work/scripts/"
cp "$SRC_SCRIPTS/learning-gate.sh"       "$work/scripts/"
# lib/ is sourced by learning-gate.sh (frontmatter parser); copy it if present so the gate can run.
[ -d "$SRC_SCRIPTS/lib" ] && cp -R "$SRC_SCRIPTS/lib" "$work/scripts/"
# ops-alert.sh is called best-effort; a no-op keeps the alert layer from touching anything real.
printf '#!/usr/bin/env bash\nexit 0\n' > "$work/scripts/ops-alert.sh"
# learning_distill.py must exist (the worker execs it), but we point LEARNING_DISTILL_PYTHON at a no-op
# python below, so its contents never run. A placeholder file is enough.
printf '# stub - never executed (LEARNING_DISTILL_PYTHON is a no-op)\n' > "$work/scripts/learning_distill.py"
chmod +x "$work/scripts/"*.sh
printf 'placeholder\n' > "$work/rules/placeholder.md"
git -C "$work" add -A
git -C "$work" commit -q -m "seed"
git -C "$work" push -q origin HEAD:main
git -C "$work" branch -q -M main 2>/dev/null || true

# --- PATH shims: flippable gh + no-op claude + no-op distill python ----------------------------------
shim_dir="$root/bin"; mkdir -p "$shim_dir"
# gh: honors GH_MODE - 'fail' exits non-zero WITHOUT filing; 'succeed' records the call and exits 0.
cat > "$shim_dir/gh" <<'EOF'
#!/usr/bin/env bash
if [ "${GH_MODE:-fail}" = "succeed" ]; then
  echo "gh $*" >> "${GH_CALL_LOG:?}"
  exit 0
fi
echo "gh-shim: simulated failure" >&2
exit 1
EOF
# claude: presence-only (the worker just needs `command -v claude` to succeed). Never actually invoked.
printf '#!/usr/bin/env bash\nexit 0\n' > "$shim_dir/claude"
# no-op distill "python": accepts the distill-script path arg, edits nothing, exits 0. It records the
# distill INPUT it was handed (the worker exports LEARNING_QUEUE=the filtered queue) so the test can
# prove a filed class's captures are held out - and an unfiled (gh-failed) class's captures are NOT.
cat > "$shim_dir/noop-python" <<'EOF'
#!/usr/bin/env bash
[ -n "${DISTILL_INPUT_LOG:-}" ] && [ -n "${LEARNING_QUEUE:-}" ] && [ -f "$LEARNING_QUEUE" ] \
  && cat "$LEARNING_QUEUE" > "$DISTILL_INPUT_LOG"
exit 0
EOF
chmod +x "$shim_dir/gh" "$shim_dir/claude" "$shim_dir/noop-python"

WORKER="$work/scripts/learning-worker.sh"

# --- vault fixture: the live path preps a worker-owned vault clone BEFORE distillation (ADR 0028) ----
# These cases write no facts (noop distill), so the vault leg stays a no-op; the fixture only keeps
# clone prep off the network (every remote local). Fact-leg behavior: test-learning-worker-vault-live.sh.
vault_origin="$root/vault-origin.git"
vseed="$root/vault-seed"
git init -q --bare -b main "$vault_origin"
git clone -q "$vault_origin" "$vseed" 2>/dev/null
git -C "$vseed" config user.email test@example.com
git -C "$vseed" config user.name  test
git -C "$vseed" config commit.gpgsign false
mkdir -p "$vseed/memory"
printf '# MEMORY index\n' > "$vseed/memory/MEMORY.md"
git -C "$vseed" add -A
git -C "$vseed" commit -q -m "vault seed"
git -C "$vseed" push -q origin HEAD:main
vclone="$root/vclone"

# Seed a repeat class: archive has 1 port-class capture, queue has 1 more matching + 1 unrelated single.
# The port class recurs (count 2, present this run) → the worker drafts a gate for it.
seed_queue() { # $1 = queue file, $2 = archive file
  printf '2026-06-01T00:00:00Z\tcorrection\tthe SQL Server port is 1433 not 1533\n' >  "$2"
  printf '2026-06-02T00:00:00Z\tcorrection\tthe SQL Server port is 5432 not 5433\n' >  "$1"
  printf '2026-06-02T00:01:00Z\tcorrection\talways quote op refs that contain spaces\n' >> "$1"
}
PORTSIG="$(bash "$SRC_SCRIPTS/learning-recurrence.sh" signature 'the SQL Server port is 1433 not 1533')"

# Snapshot both refs so we can prove nothing landed on main.
head_before_fail="$(git -C "$work" rev-parse HEAD)"
main_before_fail="$(git -C "$work" rev-parse origin/main)"

# ============ CASE A - gh FAILS: not marked, not filtered, all archived, nothing landed ============
qA="$root/qA.tsv"; aA="$root/qA.archive.tsv"; mA="$root/qA.gate-drafted.tsv"
distinA="$root/distill-in-A.tsv"; : > "$distinA"
seed_queue "$qA" "$aA"; : > "$mA"
outA="$(cd "$work" && PATH="$shim_dir:$PATH" GH_MODE=fail DISTILL_INPUT_LOG="$distinA" \
  LEARNING_QUEUE="$qA" LEARNING_ARCHIVE="$aA" LEARNING_GATE_DRAFTED="$mA" \
  LEARNING_DISTILL_PYTHON="$shim_dir/noop-python" \
  LEARNING_VAULT_DIR="$vclone" LEARNING_VAULT_REMOTE="$vault_origin" LEARNING_VAULT_LIVE="$root/vault-live-unused" \
  bash "$WORKER" 2>&1)"
rcA=$?
check "$rcA" 0 "gh-FAIL: worker exits 0 (best-effort, never fails the worker)"
# The marker must NOT contain the class signature - so the class re-drafts on a later run.
if [ -s "$mA" ] && grep -qxF "$PORTSIG" "$mA"; then
  echo "FAIL gh-FAIL: class was marked drafted despite gh failure (would suppress retry forever)" >&2; fail=$((fail+1))
else
  pass=$((pass+1)); echo "ok   gh-FAIL: class NOT marked drafted (will retry next run)"
fi
# The failure notice is printed (operator signal), and the success message is NOT.
if contains "$outA" "could not open gate-proposal issue"; then pass=$((pass+1)); echo "ok   gh-FAIL: prints the could-not-file notice"
else echo "FAIL gh-FAIL: missing the could-not-file notice" >&2; fail=$((fail+1)); fi
if contains "$outA" "DRAFTED a gate proposal issue"; then
  echo "FAIL gh-FAIL: wrongly claimed a gate issue was drafted" >&2; fail=$((fail+1))
else pass=$((pass+1)); echo "ok   gh-FAIL: did not claim a draft succeeded"; fi
# The unfiled class's capture MUST flow to distillation this run (prose fallback, not orphaned).
if [ -s "$distinA" ] && grep -qF 'the SQL Server port is 5432 not 5433' "$distinA"; then
  pass=$((pass+1)); echo "ok   gh-FAIL: the unfiled class's capture flows to distillation (prose fallback)"
else echo "FAIL gh-FAIL: the unfiled class's capture was wrongly held out of distillation" >&2; fail=$((fail+1)); fi
# All captures archived (never silently lose a capture) - the full original queue, unfiltered:
# 1 pre-seeded archive row + the 2 queue rows this run = 3.
check "$([ -f "$aA" ] && wc -l < "$aA" | tr -d ' ' || echo 0)" "3" "gh-FAIL: all captures archived (1 seed + 2 queue)"
check "$([ -s "$qA" ] && echo nonempty || echo empty)" "empty" "gh-FAIL: queue drained after archiving"
# NOTHING landed on main: local HEAD and remote main byte-identical to before.
check "$(git -C "$work" rev-parse HEAD)"        "$head_before_fail" "gh-FAIL: local HEAD unchanged (nothing committed/landed)"
check "$(git -C "$work" rev-parse origin/main)" "$main_before_fail" "gh-FAIL: origin/main unchanged (nothing pushed)"

# ============ CASE B - gh SUCCEEDS (same class recurs): marked, filtered, still nothing landed ======
# Fresh marker (empty) so the class is eligible again; the CASE-A archive now holds the earlier port
# captures, so the class still recurs. A brand-new queue supplies this run's matching capture.
head_before_ok="$(git -C "$work" rev-parse HEAD)"
main_before_ok="$(git -C "$work" rev-parse origin/main)"
qB="$root/qB.tsv"; aB="$root/qB.archive.tsv"; mB="$root/qB.gate-drafted.tsv"
distinB="$root/distill-in-B.tsv"; : > "$distinB"
gh_log="$root/gh-calls.log"; : > "$gh_log"
printf '2026-07-01T00:00:00Z\tcorrection\tthe SQL Server port is 1433 not 1533\n' >  "$aB"
printf '2026-07-02T00:00:00Z\tcorrection\tthe SQL Server port is 6000 not 6001\n' >  "$qB"
: > "$mB"
outB="$(cd "$work" && PATH="$shim_dir:$PATH" GH_MODE=succeed GH_CALL_LOG="$gh_log" DISTILL_INPUT_LOG="$distinB" \
  LEARNING_QUEUE="$qB" LEARNING_ARCHIVE="$aB" LEARNING_GATE_DRAFTED="$mB" \
  LEARNING_DISTILL_PYTHON="$shim_dir/noop-python" \
  LEARNING_VAULT_DIR="$vclone" LEARNING_VAULT_REMOTE="$vault_origin" LEARNING_VAULT_LIVE="$root/vault-live-unused" \
  bash "$WORKER" 2>&1)"
rcB=$?
check "$rcB" 0 "gh-SUCCEED: worker exits 0"
# gh was actually invoked to file the issue.
if [ -s "$gh_log" ] && grep -q 'issue create' "$gh_log"; then pass=$((pass+1)); echo "ok   gh-SUCCEED: gh issue create was invoked"
else echo "FAIL gh-SUCCEED: gh issue create was never invoked" >&2; fail=$((fail+1)); fi
# The class IS now marked drafted (idempotency: it won't re-draft next run).
if [ -s "$mB" ] && grep -qxF "$PORTSIG" "$mB"; then pass=$((pass+1)); echo "ok   gh-SUCCEED: class marked drafted (won't re-draft)"
else echo "FAIL gh-SUCCEED: filed class was NOT marked drafted" >&2; fail=$((fail+1)); fi
if contains "$outB" "DRAFTED a gate proposal issue"; then pass=$((pass+1)); echo "ok   gh-SUCCEED: prints the drafted-issue confirmation"
else echo "FAIL gh-SUCCEED: missing the drafted-issue confirmation" >&2; fail=$((fail+1)); fi
# The filed class's capture is HELD OUT of distillation (no redundant prose for an escalated class).
if grep -qF 'the SQL Server port is 6000 not 6001' "$distinB"; then
  echo "FAIL gh-SUCCEED: filed class's capture leaked into distillation (not held out)" >&2; fail=$((fail+1))
else pass=$((pass+1)); echo "ok   gh-SUCCEED: filed class's capture held out of distillation"; fi
# STILL nothing landed on main.
check "$(git -C "$work" rev-parse HEAD)"        "$head_before_ok" "gh-SUCCEED: local HEAD unchanged (nothing landed)"
check "$(git -C "$work" rev-parse origin/main)" "$main_before_ok" "gh-SUCCEED: origin/main unchanged (nothing pushed)"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
