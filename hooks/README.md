# hooks/ - Claude Code lifecycle hooks

Shell hooks, one file per concern. WIRING lives in two places (the hook file alone tells you
nothing about when it fires):

- **Project scope** [.claude/settings.json](../.claude/settings.json) (its `$comment` documents
  each): session-start-gate (SessionStart: sync/freshness/memory/learning gate),
  post-compact-reinject (SessionStart matcher `compact`), no-force-push-guard (PreToolUse),
  secret-scan-on-write + shellcheck-on-write + em-dash-on-write + length-advisory (PostToolUse
  write guards), session-stop-push-gate (Stop), session-end-backup (SessionEnd).
- **User scope** `~/.claude/settings.json` (machine-wide, fires in EVERY repo; written by
  [shell/install.sh](../shell/README.md), ADR 0033): standing-rules.sh (reply rules),
  capture-nudge.sh (correction capture -> learning queue), global-session-gate.sh (pulls both
  live clones + wiring drift check), global-vault-push.sh (SessionEnd vault commit+push), and
  the guard wrappers global-secret-scan.sh + global-force-push-guard.sh (self-skip inside
  schnapp-os; the project wiring stays for web parity). Keep standing-rules
  in sync with [rules/global/working-style.md](../rules/global/working-style.md).

Conventions: deterministic, fast, non-blocking unless the hook IS a gate (exit 2 blocks);
UserPromptSubmit hooks must always exit 0. Hooks reload at session start. Test changes via
[scripts/tests/](../scripts/tests/). Hookless surfaces (claude.ai web, iPhone, Cowork) get the
must-happen steps via the `session-hygiene` skill instead.
