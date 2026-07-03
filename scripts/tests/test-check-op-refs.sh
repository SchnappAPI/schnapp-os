#!/usr/bin/env bash
# test-check-op-refs.sh - proves check-op-refs.sh flags an op:// item missing from
# credentials-map.md, skips placeholder examples (<ITEM>) and pattern artifacts (a regex/glob/
# shell-var where the item would be, e.g. a script embedding the extraction regex itself - the
# 2026-07-03 self-match false positive), stays WARN-only by default, and fails under --strict.
set -uo pipefail
export LC_ALL=C
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tool="$here/../check-op-refs.sh"
pass=0; fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

git -C "$tmp" init -q -b main
# build the ref prefix by concatenation so THIS tracked test source never contains a literal
# op:// ref for the repo-wide scan to extract (fixture items exist only in the temp repo)
pfx='op:/''/web-variables'
cat > "$tmp/credentials-map.md" <<MD
| GOOD_ITEM | ${pfx}/GOOD_ITEM/credential | example |
MD
cat > "$tmp/ok.md" <<MD
Resolve with ${pfx}/GOOD_ITEM/credential at runtime.
Docs show the shape as ${pfx}/<ITEM>/<field> (placeholder).
MD
# a script that embeds the extraction pattern itself (the self-match class)
cat > "$tmp/scan.sh" <<SH
grep -hoE '${pfx}/[^/" ]+/' .
echo "${pfx}/\$ITEM/credential"
SH
git -C "$tmp" add -A -f >/dev/null 2>&1

run() { CLAUDE_KIT_REPO="$tmp" bash "$tool" "$@" >"$tmp/out" 2>"$tmp/err"; echo $?; }

# 1. documented item + placeholder + pattern artifacts -> exit 0, clean
rc="$(run)"
if [ "$rc" = 0 ] && grep -q "ok: every op:// item" "$tmp/out"; then pass=$((pass+1)); echo "ok   documented refs pass clean"; else echo "FAIL clean tree (rc=$rc)"; cat "$tmp/out" "$tmp/err"; fail=$((fail+1)); fi

# 2. pattern/placeholder artifacts never flagged as items
if grep -qE "\[\^|\\\$ITEM|<ITEM>" "$tmp/err"; then echo "FAIL a pattern artifact was flagged as an item" >&2; cat "$tmp/err"; fail=$((fail+1)); else pass=$((pass+1)); echo "ok   placeholder + regex/var artifacts skipped"; fi

# 3. undocumented item -> named on stderr, WARN-only (exit 0) by default
echo "uses ${pfx}/RENAMED_ITEM/credential" > "$tmp/stale.md"
git -C "$tmp" add -A -f >/dev/null 2>&1
rc="$(run)"
if [ "$rc" = 0 ] && grep -q "STALE op:// ref: item 'RENAMED_ITEM'" "$tmp/err"; then pass=$((pass+1)); echo "ok   stale ref named, WARN-only by default"; else echo "FAIL stale ref default (rc=$rc)" >&2; cat "$tmp/out" "$tmp/err"; fail=$((fail+1)); fi

# 4. --strict -> exit 1 on the same stale ref
rc="$(run --strict)"
if [ "$rc" = 1 ]; then pass=$((pass+1)); echo "ok   --strict fails on stale ref"; else echo "FAIL --strict (rc=$rc)" >&2; fail=$((fail+1)); fi

echo "---"; echo "check-op-refs: $pass passed, $fail failed"
[ "$fail" = 0 ]
