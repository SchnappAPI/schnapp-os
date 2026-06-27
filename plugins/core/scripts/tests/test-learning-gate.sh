#!/usr/bin/env bash
set -uo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/learning-gate.sh"
pass=0; fail=0
check(){ if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got '$1' want '$2')"; fail=$((fail+1)); fi; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
R="$tmp/plugins/core/rules/global/working-style.md"
git -C "$tmp" init -q -b main
git -C "$tmp" config user.email t@t; git -C "$tmp" config user.name t
mkdir -p "$tmp/plugins/core/rules/global" "$tmp/memory" "$tmp/docs"
base_body='- existing rule one about being concise and clear in all communications always.'
write_rule(){ printf -- '---\nscope: global\nupdated: %s\n---\n# Working style\n\n%s\n' "$1" "$2" > "$R"; }
write_rule 2026-06-01 "$base_body"
git -C "$tmp" add -A; git -C "$tmp" commit -qm base

reset(){ git -C "$tmp" checkout -q main; git -C "$tmp" branch -qD se 2>/dev/null || true; git -C "$tmp" checkout -q -b se; }
gate(){ ( cd "$tmp" && bash "$SCRIPT" main ); }

# 1. clean: in-scope rule add + updated bumped -> APPROVE
reset
write_rule 2026-06-27 "$base_body"$'\n''- a brand new rule about recording failures before retrying a known-bad approach.'
git -C "$tmp" commit -qam "se add"
gate >/dev/null 2>&1; check "$?" 0 "clean in-scope add -> APPROVE"

# 2. out-of-scope file -> HOLD
reset
echo "some note" > "$tmp/docs/note.md"; git -C "$tmp" add -A; git -C "$tmp" commit -qm "se doc"
out="$(gate 2>&1)"; check "$?" 1 "out-of-scope -> HOLD"
check "$(printf '%s' "$out" | grep -c 'out-of-scope')" 1 "names out-of-scope file"

# 3. too large -> HOLD
reset
big="$base_body"; for i in $(seq 1 50); do big="$big"$'\n'"- filler rule line number $i with enough length to count as real content."; done
write_rule 2026-06-27 "$big"
git -C "$tmp" commit -qam "se big"
out="$(cd "$tmp" && LEARNING_GATE_MAX_ADDED=40 bash "$SCRIPT" main 2>&1)"; check "$?" 1 "too large -> HOLD"
check "$(printf '%s' "$out" | grep -c 'too large')" 1 "names size"

# 4. rule changed without bumping updated: -> HOLD
reset
write_rule 2026-06-01 "$base_body"$'\n''- another new rule added without touching the updated date field at all here.'
git -C "$tmp" commit -qam "se no bump"
out="$(gate 2>&1)"; check "$?" 1 "no updated bump -> HOLD"
check "$(printf '%s' "$out" | grep -c "bumping 'updated:'")" 1 "names provenance"

# 5. duplicate of an existing rule line -> HOLD
reset
write_rule 2026-06-27 "$base_body"$'\n'"$base_body"
git -C "$tmp" commit -qam "se dup"
out="$(gate 2>&1)"; check "$?" 1 "duplicate content -> HOLD"
check "$(printf '%s' "$out" | grep -c 'duplicate content')" 1 "names duplication"

# 6. always read-only: main fixture file unchanged on disk vs its commit
check "$(git -C "$tmp" status --porcelain | grep -c .)" 0 "gate left no working-tree changes"

echo "pass=$pass fail=$fail"; [ "$fail" = 0 ]
