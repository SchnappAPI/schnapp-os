#!/usr/bin/env bash
# scan-secrets.sh - single-source literal-secret scanner.
#
# One pattern set, two consumers (anti-stale: never duplicate the patterns):
#   (1) CI - .github/workflows/freshness.yml runs it over tracked files; any BLOCK = fail.
#   (2) Skill - .claude/skills/cleanse-secrets wraps it for report + retro-scrub.
#
# Catches the exact value classes that leaked 2026-06-17 (vault memory/credential-leak-2026-06-17.md):
# the 1Password SA token (ops_…), Anthropic api/oauth keys (sk-ant-…), GitHub PATs, the openssl
# bearers, private keys, DB/connection URLs. The reused opensource-sanitizer lib alone MISSES
# ops_ and sk-ant-* - the master-token classes - so those are added here as first-class BLOCK rules.
#
# Output: one finding per line  ->  file:line  SEV  label  <masked>   (values are NEVER printed
# in full; masked to prefix + length). Exit 1 if any BLOCK finding (with --strict, WARN too).
#
# Usage:
#   scan-secrets.sh [--strict] [--exclude GLOB]... [PATH...]
#     no PATH    -> scans this repo's git-tracked files (the CI default)
#     PATH dir   -> scans every file under it (cross-repo: e.g. the schnapp-vault export scrub)
#     PATH file  -> scans that file
#     --strict   -> WARN findings also fail (exit 1)
#     --exclude  -> skip files whose path matches GLOB (repeatable)
#
# References, not values: op:// URIs are pointers, so heuristic (WARN) rules skip op:// lines and
# .env.template; the high-precision BLOCK token formats always fire (a real token is a real token).
set -uo pipefail
export LC_ALL=C

strict=0
print_block_re=0
excludes=()
paths=()
while [ $# -gt 0 ]; do
  case "$1" in
    --strict) strict=1; shift ;;
    --block-re) print_block_re=1; shift ;;
    --exclude) excludes+=("$2"); shift 2 ;;
    --exclude=*) excludes+=("${1#--exclude=}"); shift ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) paths+=("$1"); shift ;;
  esac
done

# --- build the file list ------------------------------------------------------
files=()
if [ "$print_block_re" -eq 1 ]; then
  : # no file list needed; the registry itself is the output (printed below, after it is defined)
elif [ "${#paths[@]}" -eq 0 ]; then
  while IFS= read -r f; do files+=("$f"); done < <(git ls-files 2>/dev/null)
else
  for p in "${paths[@]}"; do
    if [ -d "$p" ]; then
      while IFS= read -r f; do files+=("$f"); done < <(find "$p" -type f -not -path '*/.git/*' 2>/dev/null)
    elif [ -e "$p" ]; then
      files+=("$p")
    fi
  done
fi

# apply --exclude globs
if [ "${#excludes[@]}" -gt 0 ] && [ "${#files[@]}" -gt 0 ]; then
  kept=()
  for f in "${files[@]}"; do
    skip=0
    for g in "${excludes[@]}"; do
      # shellcheck disable=SC2053,SC2254  # $g is an exclude GLOB; unquoted match is intentional
      case "$f" in $g) skip=1; break ;; esac
    done
    [ "$skip" -eq 0 ] && kept+=("$f")
  done
  files=("${kept[@]}")
fi

if [ "$print_block_re" -eq 0 ] && [ "${#files[@]}" -eq 0 ]; then echo "scan-secrets: no files to scan"; exit 0; fi

# --- pattern registry ---------------------------------------------------------
# Each rule: SEV|LABEL|GREPFLAGS|ERE   (GREPFLAGS adds -i for case-insensitive heuristics).
# BLOCK = high-precision token formats (any match is a leaked value). WARN = heuristics.
rules=(
  # ---- BLOCK: exact token formats -------------------------------------------
  "BLOCK|onepassword-sa-token||ops_[A-Za-z0-9_-]{40,}"
  "BLOCK|anthropic-key||sk-ant-[A-Za-z0-9-]*[A-Za-z0-9_-]{24,}"
  "BLOCK|github-pat-fine||github_pat_[A-Za-z0-9_]{30,}"
  "BLOCK|github-token||gh[pousr]_[A-Za-z0-9]{36,}"
  "BLOCK|private-key||-----BEGIN ([A-Z]+ )?PRIVATE KEY-----"
  "BLOCK|aws-access-key||AKIA[0-9A-Z]{16}"
  "BLOCK|google-oauth||GOCSPX-[A-Za-z0-9_-]{20,}"
  "BLOCK|slack-webhook||https://hooks\.slack\.com/services/T[A-Z0-9]+/B[A-Z0-9]+/[A-Za-z0-9]+"
  "BLOCK|sendgrid-key||SG\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{40,}"
  "BLOCK|jwt||eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]+"
  "BLOCK|db-url-creds||(postgres|postgresql|mysql|mongodb|redis|mssql|sqlserver)://[^:@/ \"']+:[^@/ \"']+@"
  # ---- WARN: heuristics (manual review; --strict to enforce) -----------------
  "WARN|hex-bearer-64||[a-f0-9]{64}"
  "WARN|assignment-secret|-i|(password|passwd|secret|api[_-]?key|auth[_-]?token|bearer|client[_-]?secret)[\"' ]?[:=][ ]*[\"']?[^\\s\"'<>op][^\\s\"'<>]{7,}"
  "WARN|private-ip||(192\.168\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3})"
)

# --block-re: print each BLOCK regex, parenthesized, one per line, and exit. Consumers
# (hooks/global-secret-scan.sh Bash-leg fast path joins them with '|'; the wrapper test
# iterates them) always read THIS registry - no pattern copies anywhere (anti-stale).
if [ "$print_block_re" -eq 1 ]; then
  for rule in "${rules[@]}"; do
    IFS='|' read -r sev _label _flags ere <<<"$rule"
    [ "$sev" = "BLOCK" ] || continue
    printf '(%s)\n' "$ere"
  done
  exit 0
fi

mask() { # $1=match -> prefix + char count, never the full value
  local m="$1" n=${#1}
  printf '%s…[%dc]' "${m:0:4}" "$n"
}

block_hits=0
warn_hits=0

for rule in "${rules[@]}"; do
  IFS='|' read -r sev label flags ere <<<"$rule"
  # heuristics ignore op:// pointer lines and .env.template (references, not values)
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    file="${hit%%:*}"; rest="${hit#*:}"; line="${rest%%:*}"; match="${rest#*:}"
    if [ "$sev" = "WARN" ]; then
      case "$file" in *.env.template) continue ;; esac
      case "$match" in op://*) continue ;; esac
      warn_hits=$((warn_hits+1))
    else
      block_hits=$((block_hits+1))
    fi
    printf '%s:%s  %s  %s  %s\n' "$file" "$line" "$sev" "$label" "$(mask "$match")"
  done < <(printf '%s\0' "${files[@]}" | xargs -0 grep -I -HnoE ${flags:+$flags} -e "$ere" 2>/dev/null)
done

echo "scan-secrets: ${block_hits} BLOCK, ${warn_hits} WARN across ${#files[@]} files" >&2
if [ "$block_hits" -gt 0 ]; then exit 1; fi
if [ "$strict" -eq 1 ] && [ "$warn_hits" -gt 0 ]; then exit 1; fi
exit 0
