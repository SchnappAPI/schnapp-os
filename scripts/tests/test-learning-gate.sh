#!/usr/bin/env bash
set -uo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/learning-gate.sh"
pass=0; fail=0
check(){ if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got '$1' want '$2')"; fail=$((fail+1)); fi; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
R="$tmp/rules/global/working-style.md"
git -C "$tmp" init -q -b main
git -C "$tmp" config user.email t@t; git -C "$tmp" config user.name t
mkdir -p "$tmp/rules/global" "$tmp/memory" "$tmp/docs"
base_body='- existing rule one about being concise and clear in all communications always here.'
write_rule(){ printf -- '---\nscope: global\nupdated: %s\n---\n# Working style\n\n%s\n' "$1" "$2" > "$R"; }
write_rule 2026-06-01 "$base_body"
git -C "$tmp" add -A; git -C "$tmp" commit -qm base

reset(){ git -C "$tmp" checkout -q main; git -C "$tmp" branch -qD se 2>/dev/null || true; git -C "$tmp" checkout -q -b se; }
# shellcheck disable=SC2119,SC2120  # optional $1 = scope pattern list; most calls use the default
gate(){ ( cd "$tmp" && bash "$SCRIPT" main "$@" ); }

# 1. clean in-scope rule add + updated bumped -> APPROVE
reset
write_rule 2026-06-27 "$base_body"$'\n''- a brand new rule about recording failures before retrying a known-bad approach here.'
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
write_rule 2026-06-27 "$big"; git -C "$tmp" commit -qam "se big"
out="$(cd "$tmp" && LEARNING_GATE_MAX_ADDED=40 bash "$SCRIPT" main 2>&1)"; check "$?" 1 "too large -> HOLD"
check "$(printf '%s' "$out" | grep -c 'too large')" 1 "names size"

# 4. rule changed without bumping frontmatter updated: -> HOLD
reset
write_rule 2026-06-01 "$base_body"$'\n''- another new rule added without touching the updated date field at all here now.'
git -C "$tmp" commit -qam "se no bump"
out="$(gate 2>&1)"; check "$?" 1 "no updated bump -> HOLD"
check "$(printf '%s' "$out" | grep -c 'bumping frontmatter')" 1 "names provenance"

# 5. duplicate of an existing rule line -> HOLD
reset
write_rule 2026-06-27 "$base_body"$'\n'"$base_body"; git -C "$tmp" commit -qam "se dup"
out="$(gate 2>&1)"; check "$?" 1 "duplicate content -> HOLD"
check "$(printf '%s' "$out" | grep -c 'duplicate content')" 1 "names duplication"

# 6. BYPASS: symlink (even named .md) -> HOLD
reset
ln -s "../../.github/workflows/freshness.yml" "$tmp/rules/global/evil.md"
git -C "$tmp" add -A; git -C "$tmp" commit -qm "se symlink"
out="$(gate 2>&1)"; check "$?" 1 "symlink -> HOLD"
check "$(printf '%s' "$out" | grep -c 'symlink not allowed')" 1 "names symlink"

# 7. BYPASS: non-.md file inside an allowed dir -> HOLD
reset
printf '#!/bin/sh\necho hi\n' > "$tmp/rules/global/evil.sh"
git -C "$tmp" add -A; git -C "$tmp" commit -qm "se script"
out="$(gate 2>&1)"; check "$?" 1 "non-.md in allowed dir -> HOLD"
check "$(printf '%s' "$out" | grep -c 'non-.md')" 1 "names non-md"

# 8. BYPASS: provenance spoof - body line starting 'updated:' while frontmatter date unchanged -> HOLD
reset
write_rule 2026-06-01 'updated: see the note below about the rule we are adding to this file now.'$'\n'"$base_body"$'\n''- a sneaky new rule landed with a stale frontmatter date via a body spoof line here.'
git -C "$tmp" commit -qam "se spoof"
out="$(gate 2>&1)"; check "$?" 1 "provenance spoof -> HOLD"
check "$(printf '%s' "$out" | grep -c 'bumping frontmatter')" 1 "spoof caught by parser"

# 9. nested-metadata memory file with updated bumped -> APPROVE under the vault scope arg
#    (parser handles nested frontmatter; memory/*.md is a legal scope only when passed explicitly)
reset
M="$tmp/memory/fact.md"
printf -- '---\nname: fact\nmetadata:\n  source: t\n  updated: 2026-06-01\n---\n- a durable fact about the sql port being on its standard value here right now.\n' > "$M"
git -C "$tmp" add -A; git -C "$tmp" commit -qm "se memory base on branch"
# (commit base of the memory file first on main so the change is a real edit)
git -C "$tmp" checkout -q main; git -C "$tmp" merge -q se; git -C "$tmp" branch -qD se; git -C "$tmp" checkout -q -b se
printf -- '---\nname: fact\nmetadata:\n  source: t\n  updated: 2026-06-27\n---\n- a durable fact about the sql port being on its standard value here right now.\n- and a second distinct durable fact about the weekly backup cadence schedule here.\n' > "$M"
git -C "$tmp" commit -qam "se memory bump"
gate 'memory/*.md' >/dev/null 2>&1; check "$?" 0 "nested-metadata memory bump -> APPROVE"

# 10. BYPASS: binary .md -> HOLD (cannot size-check), even inside an allowed scope
reset
printf '\x00\x01\x02BINARYBLOB\x00' > "$tmp/memory/blob.md"
git -C "$tmp" add -A; git -C "$tmp" commit -qm "se binary"
out="$(gate 'memory/*.md' 2>&1)"; check "$?" 1 "binary .md -> HOLD"
check "$(printf '%s' "$out" | grep -c 'binary')" 1 "names binary"

# 11. DEFAULT SCOPE IS rules/ ONLY: memory/*.md in this repo -> HOLD (the lane moved to the vault;
#     a repo-local memory write must never auto-land - ADR 0028)
reset
printf -- '---\nname: fact\nmetadata:\n  source: t\n  updated: 2026-06-28\n---\n- a durable fact about the sql port being on its standard value here right now.\n- and a second distinct durable fact about the weekly backup cadence schedule here.\n- a third distinct durable fact about the nightly job window starting after midnight.\n' > "$M"
git -C "$tmp" commit -qam "se memory default scope"
out="$(gate 2>&1)"; check "$?" 1 "memory/*.md under default scope -> HOLD"
check "$(printf '%s' "$out" | grep -c 'out-of-scope')" 1 "names memory file as out-of-scope"

# 12. same change under the explicit vault scope -> APPROVE (scope arg admits it)
gate 'memory/*.md' >/dev/null 2>&1; check "$?" 0 "memory/*.md under 'memory/*.md' scope -> APPROVE"

# 13. scope arg is exclusive: rules/*.md change under 'memory/*.md' scope -> HOLD
reset
write_rule 2026-06-28 "$base_body"$'\n''- one more brand new rule about naming the failure before retrying it again here.'
git -C "$tmp" commit -qam "se rules under vault scope"
out="$(gate 'memory/*.md' 2>&1)"; check "$?" 1 "rules/*.md under 'memory/*.md' scope -> HOLD"
check "$(printf '%s' "$out" | grep -c 'out-of-scope')" 1 "names rules file as out-of-scope"

# 14. index file WITHOUT frontmatter (MEMORY.md): edit needs no updated: bump -> APPROVE
reset
I="$tmp/memory/MEMORY.md"
printf -- '# MEMORY index\n- [Fact](fact.md) - the sql port fact one-line hook lives right here.\n' > "$I"
git -C "$tmp" add -A; git -C "$tmp" commit -qm "se index base on branch"
git -C "$tmp" checkout -q main; git -C "$tmp" merge -q se; git -C "$tmp" branch -qD se; git -C "$tmp" checkout -q -b se
printf -- '# MEMORY index\n- [Fact](fact.md) - the sql port fact one-line hook lives right here.\n- [Cadence](cadence.md) - the weekly backup cadence fact one-line hook lives here.\n' > "$I"
git -C "$tmp" commit -qam "se index line"
gate 'memory/*.md' >/dev/null 2>&1; check "$?" 0 "no-frontmatter index edit -> APPROVE (provenance skipped)"

# 15. BYPASS: REMOVING updated: from a file that had one -> HOLD (supersede hygiene, not a bump)
reset
printf -- '---\nname: fact\nmetadata:\n  source: t\n---\n- a durable fact about the sql port being on its standard value here right now.\n- and a second distinct durable fact about the weekly backup cadence schedule here.\n- a fourth distinct durable fact about the archive rotation threshold being six hundred.\n' > "$M"
git -C "$tmp" commit -qam "se drop updated"
out="$(gate 'memory/*.md' 2>&1)"; check "$?" 1 "dropping updated: -> HOLD"
check "$(printf '%s' "$out" | grep -c 'supersede hygiene')" 1 "names provenance on updated: removal"

# 16. empty scope arg -> graceful HOLD (fail-closed, no bash 3.2 set -u unbound-array crash)
reset
write_rule 2026-06-29 "$base_body"$'\n''- yet another brand new rule about stating uncertainty before asserting a fact here.'
git -C "$tmp" commit -qam "se empty scope"
out="$(gate '' 2>&1)"; check "$?" 1 "empty scope -> HOLD"
check "$(printf '%s' "$out" | grep -c 'out-of-scope')" 1 "empty scope names the file out-of-scope (no crash)"

# 17. empty diff -> HOLD
reset
out="$(gate 2>&1)"; check "$?" 1 "no changes -> HOLD"

# 18. read-only: no working-tree changes left behind
check "$(git -C "$tmp" status --porcelain | grep -c .)" 0 "gate left no working-tree changes"

echo "pass=$pass fail=$fail"; [ "$fail" = 0 ]
