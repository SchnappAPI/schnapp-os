#!/usr/bin/env bash
# test-check-writing-style.sh - self-test for the writing-style em-dash gate.
# Covers: live file with an em dash FAILS; clean file passes; frozen path passes;
# a line quoting the vault index-line format ('.md) <em dash>') passes; a frozen file
# reached by an absolute path from ANOTHER checkout (worktree-session hook) is exempt,
# while a live file reached the same way still fails.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SUT="$REPO/scripts/check-writing-style.sh"
EM="$(printf '\xe2\x80\x94')"
pass=0; failn=0
ok()  { pass=$((pass+1)); }
bad() { failn=$((failn+1)); echo "FAIL: $1" >&2; }

tmp="$(mktemp -d "$REPO/.tmp-ws-test-XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
rel="${tmp#"$REPO"/}"

# 1. live file with an em dash -> exit 1, names the file
printf 'bad %s dash\n' "$EM" > "$tmp/live.md"
if bash "$SUT" "$rel/live.md" >/dev/null 2>&1; then bad "em-dash file passed"; else ok; fi

# 2. clean live file -> exit 0
printf 'clean - hyphen only\n' > "$tmp/clean.md"
if bash "$SUT" "$rel/clean.md" >/dev/null 2>&1; then ok; else bad "clean file failed"; fi

# 3. frozen path -> exempt even with an em dash
mkdir -p "$REPO/decisions/.tmp-ws-test" 2>/dev/null || true
frozen="$REPO/decisions/.tmp-ws-test/frozen.md"
printf 'frozen %s dash\n' "$EM" > "$frozen"
if bash "$SUT" "decisions/.tmp-ws-test/frozen.md" >/dev/null 2>&1; then ok; else bad "frozen path not exempt"; fi
rm -rf "$REPO/decisions/.tmp-ws-test"

# 4. vault index-line format quote -> skipped
printf -- "- [Title](slug.md) %s hook\n" "$EM" > "$tmp/fmt.md"
if bash "$SUT" "$rel/fmt.md" >/dev/null 2>&1; then ok; else bad "vault format line flagged"; fi

# 5. frozen TRACKED file by absolute path from another checkout -> exempt (the 2026-07-01
#    worktree-hook false-flag: prefix-strip no-ops, frozen match must use the file's own
#    repo-relative path)
other="$(mktemp -d)"
if CLAUDE_KIT_REPO="$other" bash "$SUT" "$REPO/PROGRESS.md" >/dev/null 2>&1; then ok; else bad "cross-checkout frozen path not exempt"; fi

# 6. live em-dash file by absolute path from another checkout -> still fails (untracked
#    fallback must not over-exempt)
if CLAUDE_KIT_REPO="$other" bash "$SUT" "$tmp/live.md" >/dev/null 2>&1; then bad "cross-checkout live file passed"; else ok; fi
rm -rf "$other"

echo "check-writing-style self-test: $pass passed, $failn failed"
[ "$failn" -eq 0 ]
