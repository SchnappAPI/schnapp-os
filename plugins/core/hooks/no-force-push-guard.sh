#!/usr/bin/env bash
# no-force-push-guard.sh — PreToolUse HARD guard against force-push (decisions/0011 #9).
#
# Workflow is main-only. A force-push (--force / -f / --force-with-lease / a `+refspec`) can
# irrecoverably rewrite protected history — exactly the operation used for the history cleanse,
# and exactly the one you never want an agent to run by accident. PreToolUse fires BEFORE the
# permission-mode check, so exit 2 here blocks the command even under --dangerously-skip-permissions
# (the only reliable hard-policy gate; research doc §4). Replaces the removed, buggy schnapp-kit
# no-commit-to-main hook (which wrongly forced feature branches and false-matched read-only git).
#
# Fast + deterministic: one python json parse, scoped regex (only the push command's own args, so a
# trailing `&& rm -f x` does not false-trip). Allows every non-force push. Never blocks anything else.
set -uo pipefail
INPUT="$(cat)"

verdict="$(printf '%s' "$INPUT" | python3 -c '
import sys, json, re
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if d.get("tool_name") != "Bash":
    sys.exit(0)
cmd = d.get("tool_input", {}).get("command", "") or ""
# Inspect each "git ... push <args>" segment, args bounded to before the next ; && || | newline.
for m in re.finditer(r"git\s+[^;&|\n]*?\bpush\b([^;&|\n]*)", cmd):
    args = m.group(1)
    if re.search(r"(--force\b|--force-with-lease\b|(?:^|\s)-\w*f\w*|(?:^|\s)\+\w)", args):
        print("FORCE")
        break
' 2>/dev/null)"

if [ "$verdict" = "FORCE" ]; then
  echo "BLOCKED: force-push is disabled by the schnapp-os guard (decisions/0011 #9, main-only)." >&2
  echo "Force-push can irrecoverably rewrite protected history. If you truly need it (e.g. a deliberate" >&2
  echo "history cleanse), run it yourself in a terminal outside the agent." >&2
  exit 2
fi
exit 0
