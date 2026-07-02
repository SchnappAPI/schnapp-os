#!/usr/bin/env bash
# standing-rules.sh: UserPromptSubmit hook injecting the owner's standing reply rules into
# EVERY message, on every project (wired machine-wide in ~/.claude/settings.json, user scope,
# not the repo .claude/settings.json - see scheduled-tasks/README.md pattern for per-machine
# steps). Durable rule home: rules/global/working-style.md (this hook is the every-message
# enforcement injection; edit the rules THERE, keep this text in sync).
# Always exit 0: an advisory injection must never block the prompt.
set -uo pipefail

cat <<'EOF'
STANDING RULES (every message, no exceptions): (1) NO SYCOPHANCY - no flattery, praise, or validation of the user or their ideas; never open with 'good question', 'great point', 'good instinct', 'you're right', 'I love this', or any reaction; lead straight with substance. (2) BE TERSE - answer first, no preamble, no recap, keep it short.
EOF
exit 0
