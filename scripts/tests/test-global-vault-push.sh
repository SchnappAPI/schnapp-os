#!/usr/bin/env bash
# Tests hooks/global-vault-push.sh: SessionEnd wrapper over vault-autocommit.sh - dirty vault
# commits + pushes immediately (debounce off), clean vault no-ops, missing vault degrades,
# always exit 0. Engine behavior itself is covered by test-vault-autocommit.sh.
set -uo pipefail
HOOK="$(cd "$(dirname "$0")/../../hooks" && pwd)/global-vault-push.sh"
OS_REAL="$(cd "$(dirname "$0")/../.." && pwd)"
pass=0; fail=0
check() { if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got '$1' want '$2')"; fail=$((fail+1)); fi; }
checkgrep() { if printf '%s' "$1" | grep -q "$2"; then pass=$((pass+1)); else echo "FAIL: $3 (no '$2' in output)"; echo "$1" | sed 's/^/    /'; fail=$((fail+1)); fi; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
GIT="git -c user.name=t -c user.email=t@t"
git init -q --bare "$tmp/vault.git"
git clone -q "$tmp/vault.git" "$tmp/vault" 2>/dev/null
( cd "$tmp/vault" && git checkout -q -b main && echo x > f && git add f && $GIT commit -qm init && git push -qu origin main )

# 1. Dirty vault: committed + pushed at session end
echo "fact" > "$tmp/vault/new-fact.md"
out="$(SCHNAPP_OS_DIR="$OS_REAL" VAULT_DIR="$tmp/vault" bash "$HOOK" 2>&1)"; rc=$?
check "$rc" 0 "exit 0 on push"
checkgrep "$out" "pushed:" "reports the push"
check "$(git -C "$tmp/vault.git" log --oneline main | wc -l | tr -d ' ')" 2 "origin received the commit"
check "$(git -C "$tmp/vault" status --porcelain | wc -l | tr -d ' ')" 0 "tree clean after push"

# 2. Clean vault: no-op
out="$(SCHNAPP_OS_DIR="$OS_REAL" VAULT_DIR="$tmp/vault" bash "$HOOK" 2>&1)"; rc=$?
check "$rc" 0 "exit 0 on clean tree"
checkgrep "$out" "clean, nothing to push" "clean tree reported"

# 3. Missing vault: degrade, exit 0. Sandbox ALL fallbacks (HOME + sibling-of-OS_DIR), or the
#    hook's resolution chain walks to the machine's real vault - it did on first test run.
mkdir -p "$tmp/fakeos"
out="$(HOME="$tmp" SCHNAPP_OS_DIR="$tmp/fakeos" VAULT_DIR="$tmp/absent" bash "$HOOK" 2>&1)"; rc=$?
check "$rc" 0 "exit 0 with no vault"
checkgrep "$out" "skipped: no vault clone" "missing vault reported"

echo "test-global-vault-push: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
