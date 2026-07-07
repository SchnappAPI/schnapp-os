#!/usr/bin/env bash
# gen-claude-ai-skills.sh - generate surfaces/claude-ai-skills.md, the checklist of skills to
# enable on claude.ai (Settings > Capabilities).
#
# claude.ai skills do NOT auto-sync from this repo and there is no API to register them (a
# platform boundary, not a wiring gap): each must be added by hand in the account settings. This
# checklist is the one thing we CAN keep honest - it is a PROJECTION of .claude/skills/, so the
# list of what to add never drifts from the actual skill set. The click-through stays manual.
#
# Tier comes from each SKILL.md's own frontmatter: `claude-ai-tier: core` = add on every account;
# anything else (or absent) = on-demand. Co-located with the skill so there is no second hand-list.
#
# Deterministic (C-locale sort, no timestamps) so the CI freshness diff is stable. Re-run after
# adding/removing a skill or changing a tier; CI (check-freshness.sh) fails the push if stale.
set -euo pipefail
export LC_ALL=C

REPO="${CLAUDE_KIT_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
OUT="${1:-$REPO/surfaces/claude-ai-skills.md}"

[ -d "$REPO/.claude/skills" ] || { echo "FATAL: .claude/skills not found under: $REPO" >&2; exit 1; }

fm() { # file key -> single-line frontmatter value (empty if absent)
  awk -v k="$2" '
    NR==1 && $0=="---" { f=1; next }
    f && $0=="---" { exit }
    f && index($0, k":")==1 { v=substr($0, length(k)+2); sub(/^[ \t]+/,"",v); print v; exit }
  ' "$1"
}
trunc() { awk -v n=140 -v ell='…' '{ if (length($0)<=n) print; else { s=substr($0,1,n); sub(/[^ ]*$/,"",s); print s ell } }'; }

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

{
  echo "# claude.ai skills to enable (generated - do not edit)"
  echo
  echo "Skills do not auto-sync to claude.ai and there is no API to register them, so each must be"
  echo "added by hand in **Settings > Capabilities**. This checklist is generated from"
  echo "\`.claude/skills/\` by [\`scripts/gen-claude-ai-skills.sh\`](../scripts/gen-claude-ai-skills.sh),"
  echo "so the list never drifts from the actual skill set. Tier is each skill's own"
  echo "\`claude-ai-tier:\` frontmatter (\`core\` = add on every account; otherwise on-demand)."
  echo "Do not hand-edit; re-run the generator. CI fails the push if this file is stale."
  echo

  for tier in core on-demand; do
    if [ "$tier" = "core" ]; then
      echo "## Core (add on every account)"
    else
      echo "## On-demand (add per need)"
    fi
    echo
    any=0
    for d in "$REPO"/.claude/skills/*/; do
      [ -f "$d/SKILL.md" ] || continue
      nm="$(fm "$d/SKILL.md" name)"; [ -z "$nm" ] && nm="$(basename "$d")"
      t="$(fm "$d/SKILL.md" claude-ai-tier)"; [ "$t" = "core" ] || t="on-demand"
      [ "$t" = "$tier" ] || continue
      desc="$(fm "$d/SKILL.md" description | trunc)"
      echo "- [ ] **$nm**: $desc"
      any=1
    done
    [ "$any" = "0" ] && echo "_(none)_"
    echo
  done
} > "$TMP"

mv "$TMP" "$OUT"
trap - EXIT
echo "gen-claude-ai-skills: wrote $OUT"
