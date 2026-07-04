#!/usr/bin/env bash
# Tests hooks/global-session-gate.sh: any-repo pull of both clones, quiet-inside-schnapp-os,
# wiring drift detection, missing-clone tolerance. All paths sandboxed via env overrides.
set -uo pipefail
GATE="$(cd "$(dirname "$0")/../../hooks" && pwd)/global-session-gate.sh"
pass=0; fail=0
check() { if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got '$1' want '$2')"; fail=$((fail+1)); fi; }
checkgrep() { if printf '%s' "$1" | grep -q "$2"; then pass=$((pass+1)); else echo "FAIL: $3 (no '$2' in output)"; echo "$1" | sed 's/^/    /'; fail=$((fail+1)); fi; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
GIT="git -c user.name=t -c user.email=t@t"

mkrepo() { # $1=name -> bare origin + working clone at $tmp/$1
  git init -q --bare "$tmp/$1.git"
  git clone -q "$tmp/$1.git" "$tmp/$1" 2>/dev/null
  ( cd "$tmp/$1" && git checkout -q -b main && echo x > f && git add f && $GIT commit -qm init && git push -qu origin main )
}
mkrepo os
mkrepo vault
mkdir -p "$tmp/vault/memory" && echo idx > "$tmp/vault/memory/MEMORY.md"
( cd "$tmp/vault" && git add memory && $GIT commit -qm memory-index && git push -q )   # tracked, like the real lane
mkdir -p "$tmp/foreign" "$tmp/home/.claude"

run_gate() { HOME="$tmp/home" SCHNAPP_OS_DIR="$tmp/os" VAULT_DIR="$tmp/vault" CLAUDE_PROJECT_DIR="${1:-$tmp/foreign}" bash "$GATE" 2>&1; }

# 1. Foreign repo, both fresh: one status line + memory orient, exit 0
out="$(run_gate)"; rc=$?
check "$rc" 0 "exit 0 in foreign repo"
checkgrep "$out" "schnapp-os: fresh | vault: fresh | wiring intact" "both repos fresh, wiring intact"
checkgrep "$out" "memory: read $tmp/vault/memory/MEMORY.md" "memory orient line points at vault index"

# 2. Remote moved ahead: gate pulls and reports UPDATED
( cd "$tmp" && git clone -q os.git os2 && cd os2 && echo y > g && git add g && $GIT commit -qm ahead && git push -q origin HEAD:main )
out="$(run_gate)"
checkgrep "$out" "schnapp-os: UPDATED" "gate ff-pulls a moved remote"
check "$(cd "$tmp/os" && git log --oneline | wc -l | tr -d ' ')" 2 "clone actually advanced"

# 3. Inside schnapp-os: silent when vault is fresh (project gate owns the report)
out="$(run_gate "$tmp/os")"
check "$out" "" "quiet inside schnapp-os with fresh vault"

# 4. Wiring drift: a live component without its ~/.claude symlink is counted
mkdir -p "$tmp/os/.claude/skills/probe-skill"
out="$(run_gate)"
checkgrep "$out" "WIRING DRIFT: 1" "unlinked component detected"
mkdir -p "$tmp/home/.claude/skills"
ln -s "$tmp/os/.claude/skills/probe-skill" "$tmp/home/.claude/skills/probe-skill"
out="$(run_gate)"
checkgrep "$out" "wiring intact" "symlinked component clears the drift"

# 5. Missing clones: degrade to a message, still exit 0
out="$(HOME="$tmp/home" SCHNAPP_OS_DIR="$tmp/nope" VAULT_DIR="$tmp/nope2" CLAUDE_PROJECT_DIR="$tmp/foreign" bash "$GATE" 2>&1)"; rc=$?
check "$rc" 0 "exit 0 with no clones"
checkgrep "$out" "no clone at" "missing clone reported, not fatal"

# 6. Drift auto-heal: with an installer present, the gate runs it instead of instructing
mkdir -p "$tmp/os/.claude/skills/heal-skill" "$tmp/os/shell"
cat > "$tmp/os/shell/install.sh" <<SH
#!/usr/bin/env bash
ln -s "$tmp/os/.claude/skills/heal-skill" "$tmp/home/.claude/skills/heal-skill"
echo "[shell-install] components: 1 linked, 0 already live, 0 pruned, 0 skipped"
SH
out="$(run_gate)"
checkgrep "$out" "installer auto-ran" "drift triggers installer auto-run"
if [ -e "$tmp/home/.claude/skills/heal-skill" ]; then pass=$((pass+1)); else echo "FAIL: auto-heal did not create the symlink"; fail=$((fail+1)); fi

# 7. Vault backlog surfaced: SessionEnd output is invisible, so a stuck lane must show at
#    the next session start
echo stray > "$tmp/vault/stray.md"
out="$(run_gate)"
checkgrep "$out" "vault BACKLOG: 1 uncommitted path(s)" "dirty vault surfaced in foreign repo"
( cd "$tmp/vault" && git add stray.md && $GIT commit -qm stray )
out="$(run_gate)"
checkgrep "$out" "unpushed commit(s)" "unpushed vault commit surfaced"
( cd "$tmp/vault" && git push -q )

echo "test-global-session-gate: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
