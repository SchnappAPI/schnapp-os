#!/usr/bin/env bash
# diagnose-all.sh - one-shot read-only scoreboard over every schnapp-os diagnostic.
#
# Runs each hard gate exactly as CI invokes it (freshness.yml / ci-lint.yml), then the
# informational sweeps, and prints one PASS/FAIL/INFO line per check plus a verdict.
# READ-ONLY: never regenerates, edits, restarts, or commits anything. Exit 1 if any HARD
# gate failed (same set that would fail a push), 0 otherwise; informational checks never
# affect the exit code.
#
# Usage:
#   diagnose-all.sh              # gates + informational sweeps
#   diagnose-all.sh --with-tests # also run the scripts/tests/test-*.sh suite (slower)
#   diagnose-all.sh -v           # print each check's full output, not just the scoreboard
#
# INFO-check output always prints (it IS the signal); -v additionally prints PASS output.
# Config: CLAUDE_KIT_REPO overrides the repo root (default: derived from this script's
# location, so it runs from any cwd and on any machine's clone); VAULT_DIR overrides the
# vault clone (default: ~/code/schnapp-vault).
set -uo pipefail
export LC_ALL=C

REPO="${CLAUDE_KIT_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
cd "$REPO" || { echo "FATAL: repo not found: $REPO" >&2; exit 2; }
[ -f scripts/check-freshness.sh ] || { echo "FATAL: $REPO is not a schnapp-os clone" >&2; exit 2; }

with_tests=0; verbose=0
for a in "$@"; do
  case "$a" in
    --with-tests) with_tests=1 ;;
    -v|--verbose) verbose=1 ;;
    -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $a" >&2; exit 2 ;;
  esac
done

hard_fail=0
rows=""

run() { # run <HARD|INFO> <label> <cmd...>
  local kind="$1" label="$2"; shift 2
  local out rc verdict
  out="$("$@" 2>&1)"; rc=$?
  if [ "$kind" = HARD ]; then
    if [ "$rc" -eq 0 ]; then verdict="PASS"; else verdict="FAIL"; hard_fail=1; fi
  else
    # Informational checks always exit 0 by contract; flag output-bearing runs for reading.
    if [ "$rc" -ne 0 ]; then verdict="ERROR"; else verdict="INFO"; fi
  fi
  rows+="$(printf '%-5s %-6s %s' "$verdict" "$kind" "$label")"$'\n'
  # INFO output always prints: informational checks exit 0 by contract, so their OUTPUT is
  # the only signal. Everything else prints on failure or under -v.
  if [ "$verbose" -eq 1 ] || [ "$verdict" = FAIL ] || [ "$verdict" = ERROR ] || { [ "$kind" = INFO ] && [ -n "$out" ]; }; then
    printf -- '----- %s (%s, exit %s) -----\n%s\n\n' "$label" "$kind" "$rc" "$out"
  fi
}

# --- hard gates, invoked exactly as CI does (see .github/workflows/freshness.yml) ---
run HARD "check-freshness (generated docs + last-verified)" bash scripts/check-freshness.sh
run HARD "scan-secrets (CI form: --exclude scripts/tests/*)" bash scripts/scan-secrets.sh --exclude 'scripts/tests/*'
run HARD "scan-stale-notes (credential-incident phrases)"    bash scripts/scan-stale-notes.sh
run HARD "check-links (relative md links)"                   bash scripts/check-links.sh
run HARD "check-writing-style (em-dash lint)"                bash scripts/check-writing-style.sh

# --- informational sweeps (exit 0 by contract; the OUTPUT is the signal and always prints) ---
# check-op-refs is INFO, not HARD: CI runs it WARN-only (exit 0), so it cannot fail a push
# and must not count toward this script's "exit 1 = a push would fail" contract.
run INFO "check-op-refs (WARN-only in CI; --strict to enforce)" bash scripts/check-op-refs.sh
run INFO "check-open-questions (newest handoff's open items)" bash scripts/check-open-questions.sh handoffs
VAULT_MEMORY="${VAULT_DIR:-$HOME/code/schnapp-vault}/memory"
run INFO "check-supersede-orphans (vault memory lane)" \
    bash scripts/check-supersede-orphans.sh "$VAULT_MEMORY"
run INFO "check-stale-facts (vault memory lane, 7/30/90d)" \
    bash scripts/check-stale-facts.sh "$VAULT_MEMORY"
if [ "$(uname)" = Darwin ] && command -v launchctl >/dev/null 2>&1; then
  run INFO "check-infra-health (Mac; exits nonzero on RED by design)" bash scripts/check-infra-health.sh
else
  rows+="$(printf '%-5s %-6s %s' "SKIP" "INFO" "check-infra-health (Mac-only: launchctl absent)")"$'\n'
fi

# --- optional: the per-guard self-test suite ---
if [ "$with_tests" -eq 1 ]; then
  for t in scripts/tests/test-*.sh; do
    run HARD "$(basename "$t")" bash "$t"
  done
fi

echo "===== diagnose-all scoreboard ($(date -u +%FT%TZ)) ====="
printf '%s' "$rows"
if [ "$hard_fail" -eq 1 ]; then
  echo "VERDICT: FAIL (a hard gate above would fail the push; fix before committing)"
  exit 1
fi
echo "VERDICT: PASS (all hard gates green; read INFO lines for surfaced items)"
