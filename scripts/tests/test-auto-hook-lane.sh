#!/usr/bin/env bash
# test-auto-hook-lane.sh - self-test for the autonomous hook lane (ADR 0037 tier 3).
# Covers: observe mode never blocks + writes the ledger; enforce mode blocks (rc 2) via the
# dispatcher; an erroring hook is ignored; the escalator's age gate (young holds, old would
# escalate) in a fixture repo, dry-run only.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1"; exit 1; }

# --- fixture auto-dir with one always-failing hook (observe) --------------------------------
mkdir -p "$TMP/auto"
cat > "$TMP/auto/no-foo.sh" <<EOF
#!/usr/bin/env bash
# auto-hook: no-foo - test fixture
AUTO_HOOK_MODE=observe
. "$REPO_ROOT/hooks/auto-hook-lib.sh"
auto_hook_verdict "no-foo" "\$AUTO_HOOK_MODE" "foo detected"
EOF
cat > "$TMP/auto/broken.sh" <<'EOF'
#!/usr/bin/env bash
exit 7
EOF

ledger="$TMP/ledger.log"
out="$(echo '{}' | AUTO_HOOK_DIR="$TMP/auto" AUTO_HOOK_LEDGER="$ledger" \
  bash "$REPO_ROOT/hooks/auto-dispatch.sh")" && rc=0 || rc=$?
[ "$rc" -eq 0 ] || fail "observe mode blocked (rc=$rc)"
grep -q $'\tno-foo\twould-block\tfoo detected' "$ledger" || fail "no ledger line written"
echo "$out" | grep -q "broken.sh errored (rc=7, ignored)" || fail "erroring hook not reported-and-ignored"

# --- enforce mode blocks through the dispatcher ---------------------------------------------
sed -i '' 's/^AUTO_HOOK_MODE=observe/AUTO_HOOK_MODE=enforce/' "$TMP/auto/no-foo.sh" 2>/dev/null \
  || sed -i 's/^AUTO_HOOK_MODE=observe/AUTO_HOOK_MODE=enforce/' "$TMP/auto/no-foo.sh"
echo '{}' | AUTO_HOOK_DIR="$TMP/auto" AUTO_HOOK_LEDGER="$ledger" \
  bash "$REPO_ROOT/hooks/auto-dispatch.sh" 2>/dev/null && fail "enforce mode did not block"

# --- escalator age gate (fixture repo, dry-run: no gh, no push) -----------------------------
mkdir -p "$TMP/repo/hooks/auto"
git -C "$TMP/repo" init -q
git -C "$TMP/repo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
printf '#!/usr/bin/env bash\n# old fixture\nAUTO_HOOK_MODE=observe\n' > "$TMP/repo/hooks/auto/old-hook.sh"
git -C "$TMP/repo" add -A
GIT_AUTHOR_DATE="2026-07-01T00:00:00Z" GIT_COMMITTER_DATE="2026-07-01T00:00:00Z" \
  git -C "$TMP/repo" -c user.email=t@t -c user.name=t commit -qm "add old-hook"
printf '#!/usr/bin/env bash\n# new fixture\nAUTO_HOOK_MODE=observe\n' > "$TMP/repo/hooks/auto/new-hook.sh"
git -C "$TMP/repo" add -A
git -C "$TMP/repo" -c user.email=t@t -c user.name=t commit -qm "add new-hook"

out="$(SESSION_MINE_REPO_ROOT="$TMP/repo" bash "$REPO_ROOT/scripts/auto-hook-escalate.sh" --dry-run)"
echo "$out" | grep -q "would escalate: old-hook" || fail "old hook not escalated: $out"
echo "$out" | grep -q "new-hook too young" || fail "new hook escalated early: $out"
grep -q '^AUTO_HOOK_MODE=observe' "$TMP/repo/hooks/auto/old-hook.sh" || fail "dry-run mutated the tree"

echo "PASS test-auto-hook-lane"
