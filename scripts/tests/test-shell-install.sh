#!/usr/bin/env bash
# Tests shell/install.sh: first run writes all three layers into a sandbox ~/.claude, second
# run is a no-op, dry-run writes nothing, existing foreign entries are never clobbered.
# Runs against the REAL repo as OS_DIR (read-only); all writes land in a temp CLAUDE_CONFIG_DIR.
set -uo pipefail
OS_REAL="$(cd "$(dirname "$0")/../.." && pwd)"
INSTALL="$OS_REAL/shell/install.sh"
pass=0; fail=0
check() { if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got '$1' want '$2')"; fail=$((fail+1)); fi; }
checkgrep() { if printf '%s' "$1" | grep -q "$2"; then pass=$((pass+1)); else echo "FAIL: $3 (no '$2' in output)"; echo "$1" | sed 's/^/    /'; fail=$((fail+1)); fi; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/vault/memory" "$tmp/claude"
git init -q "$tmp/vault"   # engine checks .git presence only in the hook, installer just warns

run_install() { CLAUDE_CONFIG_DIR="$tmp/claude" VAULT_DIR="$tmp/vault" bash "$INSTALL" "$@" 2>&1; }

# 1. Dry-run on a fresh sandbox: reports, writes nothing
out="$(run_install --dry-run)"; rc=$?
check "$rc" 0 "dry-run exits 0"
check "$(find "$tmp/claude" -mindepth 1 | wc -l | tr -d ' ')" 0 "dry-run wrote nothing"

# 2. First real run: all three layers land
out="$(run_install)"; rc=$?
check "$rc" 0 "install exits 0"
check "$(grep -c '^@' "$tmp/claude/CLAUDE.md")" "$(find "$OS_REAL/rules/global" -name '*.md' | wc -l | tr -d ' ')" "CLAUDE.md imports every global rule"
checkgrep "$(cat "$tmp/claude/CLAUDE.md")" "@$OS_REAL/rules/global/working-style.md" "imports resolve to this clone's absolute path"
py() { python3 -c "import json;d=json.load(open('$tmp/claude/settings.json'));$1"; }
check "$(py 'print(d["autoMemoryDirectory"])')" "$tmp/vault/memory" "autoMemoryDirectory -> sandbox vault lane"
for s in standing-rules capture-nudge global-session-gate global-vault-push global-force-push-guard global-secret-scan; do
  check "$(py "print('$s' in json.dumps(d['hooks']))")" "True" "hook $s wired"
done
check "$(readlink "$tmp/claude/skills/status")" "$OS_REAL/.claude/skills/status" "skill symlink points into the live clone"
check "$([ -L "$tmp/claude/agents/secrets-leak-reviewer.md" ] && echo yes)" "yes" "agent symlinked"
check "$([ -L "$tmp/claude/commands/do.md" ] && echo yes)" "yes" "command symlinked"

# 3. Second run: idempotent no-op
out="$(run_install)"
checkgrep "$out" "CLAUDE.md: unchanged" "CLAUDE.md untouched on re-run"
checkgrep "$out" "settings.json: unchanged" "settings untouched on re-run"
checkgrep "$out" "components: 0 linked" "no re-linking on re-run"

# 4. Foreign entries survive: a real dir with a colliding name is left alone, other settings keys kept
rm "$tmp/claude/skills/status" && mkdir -p "$tmp/claude/skills/status"
python3 -c "import json;p='$tmp/claude/settings.json';d=json.load(open(p));d['statusLine']={'type':'command','command':'x'};json.dump(d,open(p,'w'))"
out="$(run_install)"
checkgrep "$out" "WARN: skills/status exists and is not our symlink" "non-symlink collision warned, not clobbered"
check "$([ -d "$tmp/claude/skills/status" ] && [ ! -L "$tmp/claude/skills/status" ] && echo kept)" "kept" "foreign dir kept"
check "$(py 'print(d["statusLine"]["command"])')" "x" "unrelated settings keys preserved"

echo "test-shell-install: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
