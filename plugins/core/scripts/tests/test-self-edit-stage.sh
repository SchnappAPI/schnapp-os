#!/usr/bin/env bash
set -uo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/self-edit-stage.sh"
pass=0; fail=0
check(){ if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got '$1' want '$2')"; fail=$((fail+1)); fi; }

# throwaway repo fixture, no remote
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
git -C "$tmp" init -q -b main
git -C "$tmp" config user.email t@t; git -C "$tmp" config user.name t
echo "base" > "$tmp/fact.md"; git -C "$tmp" add -A; git -C "$tmp" commit -qm base
main_before="$(git -C "$tmp" rev-parse main)"

# make a proposed self-edit in the working tree, then stage it
echo "superseded value" > "$tmp/fact.md"
( cd "$tmp" && SELF_EDIT_DATE=2026-06-27 SELF_EDIT_REMOTE=nope bash "$SCRIPT" supersede-fact "correction: new value; source: owner; supersedes old" ) >/dev/null 2>&1
rc=$?
check "$rc" 0 "stager exits 0 with no remote"

# branch created with the expected name
git -C "$tmp" rev-parse --verify -q "self-edit/2026-06-27-supersede-fact" >/dev/null; check "$?" 0 "review branch created"

# the change is committed ON the branch, with the rationale in the message
body="$(git -C "$tmp" log -1 --format=%B "self-edit/2026-06-27-supersede-fact")"
check "$(printf '%s' "$body" | grep -c 'supersede-fact')" 1 "subject names the slug"
check "$(printf '%s' "$body" | grep -c 'correction: new value')" 1 "rationale in commit body"
branch_content="$(git -C "$tmp" show "self-edit/2026-06-27-supersede-fact:fact.md")"
check "$branch_content" "superseded value" "branch carries the proposed edit"

# main is UNTOUCHED (no new commit, original content)
check "$(git -C "$tmp" rev-parse main)" "$main_before" "main has no new commit"
check "$(git -C "$tmp" show main:fact.md)" "base" "main content unchanged"

# original branch restored, working tree clean
check "$(git -C "$tmp" rev-parse --abbrev-ref HEAD)" "main" "original branch restored"
check "$(git -C "$tmp" status --porcelain)" "" "working tree clean after staging"

# no-op guard: nothing to stage -> exit 2
( cd "$tmp" && bash "$SCRIPT" empty-slug "x" ) >/dev/null 2>&1; check "$?" 2 "no changes -> exit 2"

# missing slug -> exit 2
echo "y" > "$tmp/fact.md"
( cd "$tmp" && bash "$SCRIPT" ) >/dev/null 2>&1; check "$?" 2 "missing slug -> exit 2"

echo "pass=$pass fail=$fail"; [ "$fail" = 0 ]
