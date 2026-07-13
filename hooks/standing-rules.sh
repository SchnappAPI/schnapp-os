#!/usr/bin/env bash
# standing-rules.sh: UserPromptSubmit hook injecting a one-line salience reminder of the
# owner's standing reply rules into EVERY message, on every project (wired machine-wide in
# ~/.claude/settings.json, user scope, not the repo .claude/settings.json). The rules
# THEMSELVES live in rules/global/working-style.md, which is already always-loaded via
# ~/.claude/CLAUDE.md @imports - this hook only re-surfaces them for recency, so it stays
# one line (the full restatement cost ~275 tokens per message for content already in context).
# Always exit 0: an advisory injection must never block the prompt.
set -uo pipefail

cat <<'EOF'
Standing rules in effect, every message (rules/global/working-style.md governs): no sycophancy, terse answer-first replies, no capitulation under pushback, read for intent before acting.
EOF
exit 0
