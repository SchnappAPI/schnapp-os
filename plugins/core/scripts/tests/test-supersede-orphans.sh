#!/usr/bin/env bash
# test-supersede-orphans.sh — proves check-supersede-orphans.sh detects supersede-orphans
# across the on-disk frontmatter shapes, and does NOT false-flag.
#
# RED (the gap this closes): the old inline scan matched `supersedes:` only at column 0, so
# the INDENTED key used by every real fact file (nested under `metadata:`, e.g.
# memory/credentials-state.md) was never read — supersession was a silent no-op. The critical
# assertion below is `nested-orphan` (an indented supersedes pointing at an existing file): the
# old code missed it; the fix must catch it.
set -uo pipefail
export LC_ALL=C
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/../../../.." && pwd)"
detector="$here/../check-supersede-orphans.sh"
fail=0

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# --- orphans (the old fact file still exists → must be flagged) ---
cat >"$tmp/superseded-slug.md" <<'EOF'
---
name: superseded-slug
---
the old fact, not removed
EOF
cat >"$tmp/nested-orphan.md" <<'EOF'
---
name: nested-orphan
metadata:
  node_type: memory
  scope: global
  source: test
  updated: 2026-06-25
  supersedes: superseded-slug
---
indented supersedes (the exact shape the old column-0 scan missed)
EOF

cat >"$tmp/legacy-slug.md" <<'EOF'
---
name: legacy-slug
---
EOF
cat >"$tmp/flat-orphan.md" <<'EOF'
---
name: flat-orphan
scope: global
supersedes: legacy-slug
---
flat column-0 supersedes (must still work)
EOF

cat >"$tmp/bracket-slug.md" <<'EOF'
---
name: bracket-slug
---
EOF
cat >"$tmp/wikilink-orphan.md" <<'EOF'
---
name: wikilink-orphan
metadata:
  supersedes: "[[bracket-slug]]"
---
quoted [[wikilink]] supersedes
EOF

# --- non-orphans (must NOT be flagged) ---
cat >"$tmp/nested-prose.md" <<'EOF'
---
name: nested-prose
metadata:
  supersedes: "2026-06-17 outage-resolved note; pre-3B framing"
---
prose supersedes describes a non-file note → not an orphan
EOF
cat >"$tmp/clean-empty.md" <<'EOF'
---
name: clean-empty
metadata:
  supersedes: ""
---
EOF
cat >"$tmp/resolved.md" <<'EOF'
---
name: resolved
metadata:
  supersedes: already-gone
---
correctly superseded: the named file was removed (already-gone.md absent)
EOF

# --- the index + readme must be ignored even if they carry a supersedes that names a real file ---
cat >"$tmp/MEMORY.md" <<'EOF'
---
supersedes: superseded-slug
---
index file — never scanned
EOF
cat >"$tmp/README.md" <<'EOF'
spec doc — never scanned
EOF

# --- the REAL on-disk file: exercises the actual nested `metadata:` schema; its prose
#     supersedes must NOT be flagged (and it must not crash the reader). ---
if [ -f "$repo/memory/credentials-state.md" ]; then
  cp "$repo/memory/credentials-state.md" "$tmp/credentials-state.md"
fi

out="$(bash "$detector" "$tmp")"
rc=$?

assert_has()  { if echo "$out" | grep -q "$1"; then echo "ok   flagged   $2"; else echo "MISS flagged   $2" >&2; fail=1; fi; }
assert_lacks(){ if echo "$out" | grep -q "$1"; then echo "FAIL flagged   $2" >&2; fail=1; else echo "ok   skipped   $2"; fi; }

# CRITICAL regression: an indented supersedes pointing at an existing file is caught.
assert_has  "nested-orphan.md supersedes 'superseded-slug'"  "nested (indented) orphan — the regression case"
assert_has  "flat-orphan.md supersedes 'legacy-slug'"        "flat (column-0) orphan"
assert_has  "wikilink-orphan.md supersedes 'bracket-slug'"   "[[wikilink]]/quoted orphan"

assert_lacks "nested-prose"      "prose supersedes (not a file ref)"
assert_lacks "clean-empty"       "empty supersedes"
assert_lacks "resolved"          "supersedes a removed file (correctly superseded)"
assert_lacks "MEMORY.md"         "index file ignored"
assert_lacks "credentials-state" "real on-disk nested-prose file not false-flagged"

# exactly three orphans, nothing extra
n="$(printf '%s\n' "$out" | grep -c 'still exists' || true)"
if [ "$n" = "3" ]; then echo "ok   count     exactly 3 orphans"; else echo "FAIL count $n (expected 3)" >&2; fail=1; fi

# detector is a signal, never a gate: always exit 0
if [ "$rc" = "0" ]; then echo "ok   exit0     detector exits 0"; else echo "FAIL detector exited $rc" >&2; fail=1; fi

if [ "$fail" -ne 0 ]; then echo "== test-supersede-orphans: FAIL ==" >&2; exit 1; fi
echo "== test-supersede-orphans: PASS =="
