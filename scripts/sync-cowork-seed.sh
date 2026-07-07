#!/bin/bash
# Regenerate the Cowork per-session seed CLAUDE.md from the canonical hookless instructions,
# so editing surfaces/always-loaded-instructions.md is the only step and the seed never drifts
# by hand. Seed content = that file's "## CORE" section through EOF (CORE + Cowork block),
# verbatim, with a generated header. Best-effort + idempotent: only writes on change, backs up
# once per change, never fails a caller (SessionStart runs it). ADR: seed sync was manual before.
#
# Seed path is machine-local desktop-app state; override with SCHNAPP_COWORK_SEED. Default is the
# recorded seed (memory note cowork-claude-md-seed). Only the seed template is touched, never a
# live session's own CLAUDE.md.

set -uo pipefail
REPO="${SCHNAPP_OS_DIR:-/Users/schnapp/code/schnapp-os}"
SRC="$REPO/surfaces/always-loaded-instructions.md"
SEED="${SCHNAPP_COWORK_SEED:-$HOME/Library/Application Support/Claude/local-agent-mode-sessions/34c09ba2-4e40-4da3-ae66-67273d88dcbd/87027e43-ab9c-4d5c-b08a-474d90e043fc/memory/CLAUDE.md}"

[ -f "$SRC" ] || exit 0

# build the seed text: header + everything from the first "## CORE" line to EOF
new="$(SRC="$SRC" python3 - <<'PY' 2>/dev/null
import os
src = open(os.environ["SRC"], encoding="utf-8").read().splitlines()
start = next((i for i, l in enumerate(src) if l.startswith("## CORE")), None)
if start is None:
    raise SystemExit(1)
body = "\n".join(src[start:]).rstrip()
header = ("# schnapp-os Cowork seed (GENERATED from surfaces/always-loaded-instructions.md - "
          "do not edit here)\n"
          "# Edit the source in the repo; Claude Code SessionStart resyncs this file.\n")
print(header + "\n" + body)
PY
)"
[ -z "$new" ] && exit 0

# no seed file yet (app reinstalled / different UUID): do not create a stray, just report
[ -f "$SEED" ] || { echo "cowork-seed: seed not found at '$SEED' (set SCHNAPP_COWORK_SEED)"; exit 0; }

# only write on change; back up the prior seed once per change
if ! printf '%s\n' "$new" | cmp -s - "$SEED"; then
  cp "$SEED" "$SEED.bak.$(date +%Y-%m-%d)" 2>/dev/null || true
  printf '%s\n' "$new" > "$SEED" && echo "cowork-seed: resynced from always-loaded-instructions.md"
fi
exit 0
