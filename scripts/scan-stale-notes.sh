#!/usr/bin/env bash
# scan-stale-notes.sh - stale credential-incident-note scanner.
#
# The class this guards (owner-directed 2026-07-15): a point-in-time incident claim
# ("X was exposed in chat and needs rotation") left in a LIVE doc after resolution causes
# false alarms on every re-read. The rule (anti-stale.md "credential-incident notes"):
# an open incident lives ONLY in the vault ledger memory/credentials-state.md; incident
# NARRATIVE belongs only in append-only history (handoffs/, decisions/, archives). Any
# incident phrasing anywhere else is a defect - delete the line, never annotate it.
#
# Scans tracked *.md files (or PATH args) for incident phrases outside the sanctioned
# homes. Output: file:line  STALE  <matched phrase>. Exit 1 on any finding.
#
# Usage: scan-stale-notes.sh [--exclude GLOB]... [PATH...]
#   no PATH -> this repo's git-tracked *.md files; PATH dir/file -> scanned recursively.
set -uo pipefail
export LC_ALL=C

excludes=()
paths=()
while [ $# -gt 0 ]; do
  case "$1" in
    --exclude) excludes+=("$2"); shift 2 ;;
    --exclude=*) excludes+=("${1#--exclude=}"); shift ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) paths+=("$1"); shift ;;
  esac
done

# Sanctioned homes + doctrine files (rule text that DESCRIBES incidents is not an incident).
default_excludes=(
  '*decisions/*' '*handoffs/*' '*PROGRESS.md' '*docs/archive/*' '*LEARNED.md'
  '*Build-Journal/*' '*sessions/*' '*reviews/*' '*claude-archive/*' '*Claude Export/*'
  '*bootstrap-archive/*' '*memory/credentials-state.md' '*memory/credential-leak-*.md'
  '*rules/*'
  '*skills/rotate-secret/*' '*skills/cleanse-secrets/*' '*skills/vault-resolve/*'
  '*agents/secrets-leak-reviewer.md' '*agents/secrets-hygiene-reviewer.md'
  '*scripts/tests/*' '*credentials-map.md'
)

files=()
if [ "${#paths[@]}" -eq 0 ]; then
  while IFS= read -r f; do files+=("$f"); done < <(git ls-files '*.md' 2>/dev/null)
else
  for p in "${paths[@]}"; do
    if [ -d "$p" ]; then
      while IFS= read -r f; do files+=("$f"); done < <(find "$p" -type f -name '*.md' -not -path '*/.git/*' 2>/dev/null)
    elif [ -e "$p" ]; then
      files+=("$p")
    fi
  done
fi

kept=()
for f in "${files[@]}"; do
  skip=0
  for g in "${default_excludes[@]}" ${excludes[@]+"${excludes[@]}"}; do
    # shellcheck disable=SC2053,SC2254  # exclude GLOBs; unquoted match is intentional
    case "$f" in $g) skip=1; break ;; esac
  done
  [ "$skip" -eq 0 ] && kept+=("$f")
done
files=(${kept[@]+"${kept[@]}"})
if [ "${#files[@]}" -eq 0 ]; then echo "scan-stale-notes: no files to scan"; exit 0; fi

# Single phrase registry (ERE, case-insensitive). Add here, never in a doc.
re='needs? rotation|must be rotated|(was|were|been) (exposed|leaked|compromised)|exposed in (chat|a chat|the chat|this session|a session|the transcript|a transcript)|treat .{0,40} as compromised|(key|token|secret|credential|password) (was |were |has been |have been )?(leaked|exposed|compromised)|\[MISSING - NEEDS ROTATION\]'

hits=0
while IFS= read -r hit; do
  [ -n "$hit" ] || continue
  file="${hit%%:*}"; rest="${hit#*:}"; line="${rest%%:*}"; match="${rest#*:}"
  printf '%s:%s  STALE  %s\n' "$file" "$line" "$match"
  hits=$((hits+1))
done < <(printf '%s\0' "${files[@]}" | xargs -0 grep -HinoE -e "$re" 2>/dev/null)

echo "scan-stale-notes: ${hits} finding(s) across ${#files[@]} files" >&2
[ "$hits" -gt 0 ] && exit 1
exit 0
