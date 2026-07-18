#!/usr/bin/env bash
# sync-plugins.sh - make this machine/surface's Claude Code plugin set match
# shell/plugins-manifest.txt (generated on the Mac by scripts/gen-plugins-manifest.sh).
# Idempotent; additive only (never uninstalls extras - subtract by hand where wanted).
# Never bricks a bootstrap: always exits 0. Called from shell/install.sh; safe standalone:
#   bash /path/to/schnapp-os/shell/sync-plugins.sh
set -uo pipefail

MANIFEST="$(cd "$(dirname "$0")" && pwd)/plugins-manifest.txt"
[ -f "$MANIFEST" ] || { echo "[sync-plugins] no manifest, skipping"; exit 0; }
command -v claude >/dev/null 2>&1 || { echo "[sync-plugins] claude CLI absent, skipping"; exit 0; }

KNOWN_MARKETS="$HOME/.claude/plugins/known_marketplaces.json"
SETTINGS="$HOME/.claude/settings.json"

have_market() {
  [ -f "$KNOWN_MARKETS" ] && python3 -c "
import json,sys; sys.exit(0 if '$1' in json.load(open('$KNOWN_MARKETS')) else 1)" 2>/dev/null
}

plugin_enabled() {
  [ -f "$SETTINGS" ] && python3 -c "
import json,sys
s=json.load(open('$SETTINGS')).get('enabledPlugins') or {}
sys.exit(0 if s.get('$1') else 1)" 2>/dev/null
}

added=0
while read -r kind a b; do
  case "$kind" in
    marketplace)
      if ! have_market "$a"; then
        echo "[sync-plugins] adding marketplace $a ($b)"
        claude plugin marketplace add "$b" --scope user >/dev/null 2>&1 \
          || echo "[sync-plugins] WARN: marketplace add failed: $a"
      fi ;;
    plugin)
      if ! plugin_enabled "$a"; then
        echo "[sync-plugins] installing $a"
        if claude plugin install "$a" --scope user >/dev/null 2>&1 \
           || claude plugin enable "$a" >/dev/null 2>&1; then
          added=$((added + 1))
        else
          echo "[sync-plugins] WARN: install failed: $a (marketplace unreachable? allowlist?)"
        fi
      fi ;;
  esac
done < <(grep -v '^#' "$MANIFEST" | grep -v '^[[:space:]]*$')

echo "[sync-plugins] done ($added installed/enabled; restart session to load new plugins)"
exit 0
