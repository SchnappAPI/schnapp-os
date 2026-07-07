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
  echo "# claude.ai skills inventory (generated - do not edit)"
  echo
  echo "Do NOT paste static skill copies: a pasted \`SKILL.md\` goes stale. With the Schnapp Portal"
  echo "connector on (default), claude.ai reads skills LIVE from \`.claude/skills/<name>/SKILL.md\` on"
  echo "demand, so the substance stays current with zero registration. This is the generated"
  echo "inventory of what is available to read live, from"
  echo "[\`scripts/gen-claude-ai-skills.sh\`](../scripts/gen-claude-ai-skills.sh), so it never drifts."
  echo "Tier is each skill's own \`claude-ai-tier:\` frontmatter. Optional: register a THIN auto-trigger"
  echo "stub (a pointer body that reads the live SKILL.md, never a copy) for a skill you want the"
  echo "platform to surface by description without naming it."
  echo

  for tier in core on-demand; do
    if [ "$tier" = "core" ]; then
      echo "## Core (run proactively; worth a thin auto-trigger stub)"
    else
      echo "## On-demand (read live when a task matches)"
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
