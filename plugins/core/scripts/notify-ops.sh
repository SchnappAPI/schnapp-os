#!/usr/bin/env bash
# notify-ops.sh — best-effort off-Mac page for schnapp-os routines (ntfy).
#
# Sends a message to an ntfy topic when NTFY_URL is set; a silent no-op (exit 0) otherwise,
# so ANY routine can call it unconditionally without guarding. Pure bash + curl, short timeout,
# never blocks or fails the caller — a liveness probe must not die on its own alerting, the same
# reason check-infra-health.sh is dependency-free (no LLM/MCP/auth in the watch path).
#
# Config (the topic is obscurity, never a tracked value): NTFY_URL=https://ntfy.sh/<topic>, read
# from the environment or, if unset, sourced from ${OPS_ENV:-~/.config/schnapp-os/ops.env}. The
# value is deliberately Mac-local, NOT an op:// secret, so paging never depends on 1Password being
# up (documented in .env.template).
#
# Usage: notify-ops.sh "message" ["Title"] ["priority"] ["tags"]
#   priority: max|high|default|low|min   tags: comma-sep ntfy emoji shortcodes
set -uo pipefail

msg="${1:-}"
title="${2:-schnapp-os}"
prio="${3:-default}"
tags="${4:-warning}"

[ -n "$msg" ] || exit 0

# Resolve NTFY_URL: prefer the environment; else the Mac-local ops env file.
OPS_ENV="${OPS_ENV:-$HOME/.config/schnapp-os/ops.env}"
if [ -z "${NTFY_URL:-}" ] && [ -r "$OPS_ENV" ]; then
  # shellcheck disable=SC1090
  . "$OPS_ENV"
fi

# Not configured (no topic yet) -> silent success, so callers stay unconditional.
[ -n "${NTFY_URL:-}" ] || exit 0

curl -fsS -m 8 \
  -H "Title: ${title}" \
  -H "Priority: ${prio}" \
  -H "Tags: ${tags}" \
  --data-raw "$msg" \
  "$NTFY_URL" >/dev/null 2>&1 || true

exit 0
