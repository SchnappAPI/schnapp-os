#!/usr/bin/env bash
# test-write-hook-json-extract.sh - proves the three PostToolUse write-guards
# (secret-scan-on-write.sh, shellcheck-on-write.sh, em-dash-on-write.sh) extract file_path
# through BOTH JSON parser paths (jq-first, python3 fallback) and keep their no-op envelope.
#
# RED (the gap this closes): all three guards were python3-only, so on a jq-only surface the
# leak guard, shell lint, and em-dash gate all silently no-opped together, while the purely
# advisory length hook was the only one with a fallback. The positive path is proven end to
# end via the em-dash hook (deterministic checker, no external linter needed); cross-hook
# consistency is enforced by diffing the extraction block byte-for-byte across all three.
set -uo pipefail
export LC_ALL=C
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
hooks_dir="$here/../../hooks"
pass=0; fail=0

payload(){ # $1 tool_name, $2 file_path -> hook-event JSON
  jq -cn --arg t "$1" --arg f "$2" '{tool_name:$t, tool_input:{file_path:$f}}'
}

# PATH farms simulating a genuinely absent parser (see test-no-force-push-guard.sh).
# The em-dash hook delegates to scripts/check-writing-style.sh, which needs git + textutils.
mkmask(){
  local d="$1" omit="$2" t p
  mkdir -p "$d"
  for t in bash sh cat grep sed awk tr wc sort head tail cut dirname basename find xargs \
           git env mktemp rm mkdir jq python3; do
    [ "$t" = "$omit" ] && continue
    p="$(command -v "$t" 2>/dev/null)" || continue
    ln -sf "$p" "$d/$t"
  done
}
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkmask "$tmp/no-py" python3
mkmask "$tmp/no-jq" jq

dash_file="$tmp/dashy.md"
printf 'a line with an em dash \xe2\x80\x94 right here\n' > "$dash_file"
clean_file="$tmp/clean.md"
printf 'plain text, no dash\n' > "$clean_file"

check(){ # $1 got, $2 want, $3 name
  if [ "$1" = "$2" ]; then echo "ok   $3"; pass=$((pass+1))
  else echo "FAIL $3 (got '$1' want '$2')" >&2; fail=$((fail+1)); fi
}

emdash="$hooks_dir/em-dash-on-write.sh"

# 1) positive extraction, all three parser situations (em-dash hook must flag = exit 2)
payload Write "$dash_file" | bash "$emdash" >/dev/null 2>&1;                 check "$?" 2 "em-dash flags via default path"
payload Write "$dash_file" | PATH="$tmp/no-py" bash "$emdash" >/dev/null 2>&1; check "$?" 2 "em-dash flags via jq-only path"
payload Write "$dash_file" | PATH="$tmp/no-jq" bash "$emdash" >/dev/null 2>&1; check "$?" 2 "em-dash flags via python3-only path"

# 2) clean file passes silently on both parser paths
payload Write "$clean_file" | PATH="$tmp/no-py" bash "$emdash" >/dev/null 2>&1; check "$?" 0 "clean file passes (jq-only)"
payload Write "$clean_file" | PATH="$tmp/no-jq" bash "$emdash" >/dev/null 2>&1; check "$?" 0 "clean file passes (python3-only)"

# 3) no-op envelope holds for ALL three hooks on both parser paths:
#    non-write tool, missing file_path, malformed JSON -> always exit 0, silent
for h in secret-scan-on-write.sh shellcheck-on-write.sh em-dash-on-write.sh; do
  hp="$hooks_dir/$h"
  for mask in "$tmp/no-py" "$tmp/no-jq"; do
    m="$(basename "$mask")"
    payload Read "$dash_file" | PATH="$mask" bash "$hp" >/dev/null 2>&1; check "$?" 0 "$h: non-write tool no-ops ($m)"
    printf '{"tool_name":"Write","tool_input":{}}' | PATH="$mask" bash "$hp" >/dev/null 2>&1; check "$?" 0 "$h: missing file_path no-ops ($m)"
    printf 'not json' | PATH="$mask" bash "$hp" >/dev/null 2>&1; check "$?" 0 "$h: malformed JSON no-ops ($m)"
  done
done

# 4) the extraction block is byte-identical across the three hooks (single pattern, no drift)
extract_block(){ sed -n '/^if command -v jq/,/^fi$/p' "$1"; }
b1="$(extract_block "$hooks_dir/secret-scan-on-write.sh")"
b2="$(extract_block "$hooks_dir/shellcheck-on-write.sh")"
b3="$(extract_block "$hooks_dir/em-dash-on-write.sh")"
if [ -n "$b1" ] && [ "$b1" = "$b2" ] && [ "$b2" = "$b3" ]; then
  echo "ok   extraction block byte-identical across the three hooks"; pass=$((pass+1))
else
  echo "FAIL extraction blocks differ (or block not found) across the three hooks" >&2; fail=$((fail+1))
fi

echo "pass=$pass fail=$fail"
[ "$fail" = 0 ] || { echo "== test-write-hook-json-extract: FAIL ==" >&2; exit 1; }
echo "== test-write-hook-json-extract: PASS =="
