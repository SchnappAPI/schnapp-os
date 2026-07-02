#!/usr/bin/env bash
# test-check-links.sh - proves check-links.sh flags a broken relative link in a live doc, ignores
# external/anchor/NNN-placeholder/cross-repo targets, and does NOT flag broken links inside
# append-only history (decisions/handoffs/archive). Guards the recurring move-breaks-a-link class
# (ADR 0026). Wired into freshness.yml.
set -uo pipefail
export LC_ALL=C
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tool="$here/../check-links.sh"
pass=0; fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

git -C "$tmp" init -q -b main
mkdir -p "$tmp/docs" "$tmp/decisions" "$tmp/handoffs"
# live doc with a mix of links
cat > "$tmp/live.md" <<'MD'
[good](target.md)
[good-sub](docs/note.md)
[external](https://example.com/x)
[anchor](#section)
[crossrepo](op://vault/item/field)
[home](~/code/x.md)
[placeholder](NNN-slug.md)
[good-line](target.md:42)
MD
echo "x" > "$tmp/target.md"
echo "n" > "$tmp/docs/note.md"
# frozen history with a broken link (must NOT be flagged)
echo "[gone](../does-not-exist.md)" > "$tmp/decisions/0001-x.md"
echo "[gone](../also-gone.md)" > "$tmp/handoffs/001-x.md"
git -C "$tmp" add -A -f >/dev/null 2>&1

run() { CLAUDE_KIT_REPO="$tmp" bash "$tool" >/dev/null 2>"$tmp/err"; echo $?; }

# 1. clean tree (all live links resolve) -> exit 0
rc="$(run)"
if [ "$rc" = 0 ]; then pass=$((pass+1)); echo "ok   clean live tree passes"; else echo "FAIL clean tree (rc=$rc)"; cat "$tmp/err"; fail=$((fail+1)); fi

# 2. broken frozen-history link is NOT flagged
if grep -q "does-not-exist\|also-gone" "$tmp/err"; then echo "FAIL frozen-history link was flagged" >&2; fail=$((fail+1)); else pass=$((pass+1)); echo "ok   frozen history (decisions/handoffs) excluded"; fi

# 3. introduce a broken link in a live doc -> exit 1 and named
echo "[broken](nope.md)" > "$tmp/bad.md"; git -C "$tmp" add -A -f >/dev/null 2>&1
rc="$(run)"
if [ "$rc" = 1 ] && grep -q "BROKEN: bad.md -> nope.md" "$tmp/err"; then pass=$((pass+1)); echo "ok   broken live link -> exit 1 + named"; else echo "FAIL broken live link (rc=$rc)" >&2; cat "$tmp/err"; fail=$((fail+1)); fi

# 4. external/anchor/NNN/crossrepo/home never flagged (implicit in case 1, assert explicitly)
if grep -qE "example.com|#section|NNN-slug|op://|~/code" "$tmp/err"; then echo "FAIL a skip-class target was flagged" >&2; fail=$((fail+1)); else pass=$((pass+1)); echo "ok   external/anchor/NNN/crossrepo/home skipped"; fi

echo "---"; echo "check-links: $pass passed, $fail failed"
[ "$fail" = 0 ]
