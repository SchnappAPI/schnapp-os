#!/usr/bin/env bash
# test-assemble-context.sh - proves assemble-context.sh projects paths: correctly and lints an
# @import block. Guards the tool that makes the modules' paths: frontmatter honest (ADR 0030): a
# path maps to exactly the modules whose globs match, and the contamination/missing-target lint
# fails closed. Wired into freshness.yml.
set -uo pipefail
export LC_ALL=C
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tool="$here/../assemble-context.sh"
pass=0; fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# matched section of the projection for a path (captured; no live pipe from the tool, so a
# grep -q early-exit downstream cannot SIGPIPE the tool and trip pipefail).
matched_section() { # $1=path
  local out; out="$("$tool" "$1" 2>/dev/null)"
  printf '%s\n' "$out" | sed -n '/Path-scoped/,/On-demand/p'
}
has_match() { # $1=path $2=module $3=label
  if grep -q "^- $2\$" <<<"$(matched_section "$1")"; then
    pass=$((pass+1)); echo "ok   $3"
  else echo "FAIL $3 ($2 not matched for $1)" >&2; fail=$((fail+1)); fi
}
no_match() { # $1=path $2=module $3=label
  if grep -q "^- $2\$" <<<"$(matched_section "$1")"; then
    echo "FAIL $3 ($2 wrongly matched for $1)" >&2; fail=$((fail+1))
  else pass=$((pass+1)); echo "ok   $3"; fi
}
rc_is() { # $1=expected $2=label ; $3.. = argv
  local want="$1" label="$2"; shift 2
  "$@" >/dev/null 2>&1; local got=$?
  if [ "$got" = "$want" ]; then pass=$((pass+1)); echo "ok   $label"
  else echo "FAIL $label (rc got $got want $want)" >&2; fail=$((fail+1)); fi
}

# --- projection: glob matching ---
has_match "src/a/b.py"                 "lang/python"          "py -> lang/python (nested)"
has_match "x.py"                       "lang/python"          "py -> lang/python (root)"
no_match  "x.pyc"                      "lang/python"          "pyc does NOT match *.py"
has_match "app/main.ts"                "lang/typescript"      "ts -> lang/typescript"
has_match ".github/workflows/ci.yml"   "lang/github-actions"  "workflow yml -> github-actions"
has_match ".github/workflows/ci.yaml"  "lang/github-actions"  "workflow yaml -> github-actions (brace)"
has_match ".github/workflows/ci.yml"   "lang/env-vars"        "workflow -> env-vars too"
has_match "svc/.env.local"             "lang/env-vars"        ".env.local -> env-vars"
no_match  "README.md"                  "lang/python"          "md matches no lang module"
no_match  "notes.txt"                  "lang/typescript"      "txt matches no lang module"

# --- projection: always-load + on-demand always present ---
proj_out="$("$tool" src/x.py 2>/dev/null)"
if printf '%s\n' "$proj_out" | grep -q '^- global/working-style$'; then
  pass=$((pass+1)); echo "ok   global rules always listed"
else echo "FAIL global rules always listed" >&2; fail=$((fail+1)); fi

# --- lint ---
printf '@r/rules/modules/context/work.md\n@r/rules/modules/context/personal.md\n' > "$tmp/bad.md"
rc_is 1 "lint: work+personal contamination -> exit 1" "$tool" --lint "$tmp/bad.md"
printf '@r/rules/global/does-not-exist.md\n' > "$tmp/miss.md"
rc_is 1 "lint: missing @import target -> exit 1" "$tool" --lint "$tmp/miss.md"
printf '@r/rules/global/working-style.md\n@r/rules/modules/context/work.md\n' > "$tmp/ok.md"
rc_is 0 "lint: work alone + real target -> exit 0" "$tool" --lint "$tmp/ok.md"

echo "---"; echo "assemble-context: $pass passed, $fail failed"
[ "$fail" = 0 ]
