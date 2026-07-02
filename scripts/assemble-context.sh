#!/usr/bin/env bash
# assemble-context.sh - make the rule modules' `paths:` frontmatter honest.
#
# Nothing in schnapp-os auto-injects modules by path: a project @imports them manually and the
# `paths:` field is documentation only (it feeds CATALOG's Scope column). ADR 0011 #4 keeps that
# explicit for auditability; ADR 0030 declined path-triggered auto-injection. This tool is the safe
# alternative: it REPORTS what a path would pull and LINTS an @import block, so `paths:` means
# something and stays testable, without a fragile auto-load hook.
#
# Modes (both read-only):
#   assemble-context.sh <file-path>        projection: global rules (always) + modules whose
#                                          paths: glob matches <file-path>. Always exit 0.
#   assemble-context.sh --lint <claude.md> lint an @import block: exit 1 if it @imports a rule file
#                                          that does not exist, or both context/work AND
#                                          context/personal (the cross-area contamination pair).
set -uo pipefail
export LC_ALL=C
REPO="${CLAUDE_KIT_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# glob (gitignore-ish: ** and {a,b}) -> anchored extended regex.
glob_to_re() {
  printf '%s' "$1" | sed -E \
    -e 's/\./\\./g' \
    -e 's/,/|/g' -e 's/\{/(/g' -e 's/\}/)/g' \
    -e 's#\*\*/#@@GS@@#g' -e 's/\*\*/@@GG@@/g' \
    -e 's/\*/[^\/]*/g' -e 's/\?/[^\/]/g' \
    -e 's#@@GS@@#(.*/)?#g' -e 's/@@GG@@/.*/g'
}

# emit each glob listed under a module file's `paths:` frontmatter key (empty if none).
module_paths() {
  awk '
    /^---[[:space:]]*$/ { d++; if (d==2) exit; next }
    d==1 && /^paths:/ { p=1; next }
    d==1 && p && /^[[:space:]]*-[[:space:]]/ {
      line=$0; sub(/^[[:space:]]*-[[:space:]]*/, "", line);
      gsub(/^["'\'']|["'\'']$/, "", line); print line; next }
    d==1 && p && /^[^[:space:]]/ { p=0 }
  ' "$1"
}

matches_path() { # $1=path $2=module-file ; 0 if any glob matches
  local p="$1" f="$2" g re
  while IFS= read -r g; do
    [ -z "$g" ] && continue
    re="$(glob_to_re "$g")"
    printf '%s\n' "$p" | grep -qE "^${re}$" && return 0
  done < <(module_paths "$f")
  return 1
}

project() {
  local path="$1"
  echo "# Context for: $path"
  echo
  echo "## Always (global rules, load every session)"
  for f in "$REPO"/rules/global/*.md; do echo "- global/$(basename "$f" .md)"; done
  echo
  echo "## Path-scoped modules whose paths: match"
  local any=0
  for f in "$REPO"/rules/modules/*/*.md; do
    [ -f "$f" ] || continue
    module_paths "$f" | grep -q . || continue      # only modules that declare paths:
    if matches_path "$path" "$f"; then
      echo "- $(fm_module "$f")"; any=1
    fi
  done
  [ "$any" = 0 ] && echo "- (none - this path triggers no path-scoped module)"
  echo
  echo "## On-demand modules (no paths:; load only via explicit @import)"
  for f in "$REPO"/rules/modules/*/*.md; do
    [ -f "$f" ] || continue
    module_paths "$f" | grep -q . && continue
    echo "- $(fm_module "$f")"
  done
}

fm_module() { grep -m1 '^module:' "$1" | sed -E 's/^module:[[:space:]]*//'; }

lint() {
  local file="$1" rc=0 imports work=0 personal=0
  [ -f "$file" ] || { echo "FATAL: no such file: $file" >&2; exit 2; }
  # @import lines that target a repo rule file (…/rules/…)
  imports="$(grep -oE '@[^[:space:]]*rules/[^[:space:]]+\.md' "$file" | sed 's/^@//' || true)"
  while IFS= read -r imp; do
    [ -z "$imp" ] && continue
    local rel="${imp##*rules/}"; local target="$REPO/rules/$rel"
    if [ ! -f "$target" ]; then echo "MISSING: @import rules/$rel -> no such file" >&2; rc=1; fi
    case "$rel" in */context/work.md) work=1;; */context/personal.md) personal=1;; esac
  done <<< "$imports"
  if [ "$work" = 1 ] && [ "$personal" = 1 ]; then
    echo "CONTAMINATION: imports both context/work and context/personal (never load two areas at once)" >&2
    rc=1
  fi
  [ "$rc" = 0 ] && echo "assemble-context lint OK: $file"
  return "$rc"
}

case "${1:-}" in
  ""|-h|--help) sed -n '2,20p' "$0"; exit 0 ;;
  --lint) lint "${2:?usage: --lint <claude.md>}" ;;
  *) project "$1" ;;
esac
