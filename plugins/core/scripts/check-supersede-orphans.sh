#!/usr/bin/env bash
# check-supersede-orphans.sh — detect memory facts whose `supersedes:` names a fact
# file that STILL EXISTS (the old fact was appended-around, not replaced — the exact
# "supersede, do not append" violation memory/README.md warns about).
#
# RED (the bug this closes): the prior inline scan in session-start-gate.sh matched
# `supersedes:` only at column 0, but every on-disk fact nests it INDENTED under a
# `metadata:` block (e.g. memory/credentials-state.md), so the scan matched ZERO real
# files and supersession was effectively unchecked. This detector is frontmatter-aware
# and indentation-tolerant, and is unit-tested (tests/test-supersede-orphans.sh) so the
# regression cannot return silently.
#
# Pure detector: prints one human-readable record per orphan to stdout, nothing if clean,
# and ALWAYS exits 0. Presentation + exit policy stay the caller's job (session-start-gate.sh).
#
# Usage: check-supersede-orphans.sh [MEMORY_DIR]   (default: $CLAUDE_PROJECT_DIR/memory)
set -uo pipefail

MEM="${1:-${CLAUDE_PROJECT_DIR:-$PWD}/memory}"
[ -d "$MEM" ] || exit 0

for f in "$MEM"/*.md; do
  [ -e "$f" ] || continue
  case "$(basename "$f")" in MEMORY.md|README.md) continue;; esac

  # Read `supersedes:` from the YAML frontmatter ONLY (the first ---...--- block), at any
  # indentation — so a key nested under `metadata:` is found, and a `---` rule or the word
  # "supersedes:" in the body can never false-match.
  sup="$(awk '
    NR==1 && /^---[ \t]*$/ { infm=1; next }
    infm && /^---[ \t]*$/  { exit }
    infm && /^[ \t]*supersedes:[ \t]*/ {
      sub(/^[ \t]*supersedes:[ \t]*/, ""); print; exit
    }
  ' "$f")"

  # Normalize: strip surrounding quotes, [[wikilink]] brackets, and outer whitespace
  # (keep internal spaces so prose descriptions stay detectable as non-slugs below).
  sup="${sup%\"}"; sup="${sup#\"}"
  sup="${sup%\'}"; sup="${sup#\'}"
  sup="${sup#"[["}"; sup="${sup%"]]"}"
  sup="${sup#"${sup%%[![:space:]]*}"}"   # ltrim
  sup="${sup%"${sup##*[![:space:]]}"}"   # rtrim

  [ -z "$sup" ] && continue
  # Only a slug-like value can name a fact file. A prose supersedes-note (e.g.
  # "2026-06-17 outage-resolved note") contains spaces/punctuation and is NOT an orphan.
  case "$sup" in
    *[!A-Za-z0-9._-]*) continue ;;
  esac

  [ -f "$MEM/$sup.md" ] && printf "%s supersedes '%s' but %s.md still exists\n" \
    "$(basename "$f")" "$sup" "$sup"
done
exit 0
