# hooks/ - Claude Code lifecycle hooks

Shell hooks, one file per concern. WIRING lives in two places (the hook file alone tells you
nothing about when it fires):

- **Project scope** [.claude/settings.json](../.claude/settings.json) (its `$comment` documents
  each): session-start-gate (SessionStart: sync/freshness/memory/learning gate),
  post-compact-reinject (SessionStart matcher `compact`), no-force-push-guard (PreToolUse),
  secret-scan-on-write + shellcheck-on-write + em-dash-on-write + length-advisory (PostToolUse
  write guards), auto-dispatch (PostToolUse: runs every [auto/](auto/) autonomous hook - the
  ADR 0037 tier-3 lane, contract in [auto/README.md](auto/README.md)), session-stop-push-gate
  (Stop), session-end-backup (SessionEnd).
- **User scope** `~/.claude/settings.json` (machine-wide, fires in EVERY repo; written by
  [shell/install.sh](../shell/README.md), ADR 0033): standing-rules.sh (reply rules),
  capture-nudge.sh (correction capture -> learning queue), global-session-gate.sh
  (startup|resume|clear: parallel pull of both live clones, drift auto-heal via the installer,
  vault-backlog surfacing), global-vault-push.sh (SessionEnd vault commit+push),
  idea-sweep.sh (SessionEnd: model-extracts tabled ideas from the ended transcript into the
  schnapp-console idea inbox; backgrounded, no-op if the console is down), and the guard
  wrappers global-force-push-guard.sh + global-secret-scan.sh. The secret-scan wrapper has two
  legs: PostToolUse Write/Edit (delegates to the canonical scanner; self-skips inside
  schnapp-os, where the project wiring covers it for web parity) and PreToolUse Bash (scans
  the command TEXT so heredoc/echo-written secrets block BEFORE execution; never self-skips -
  no project wiring anywhere covers Bash writes). Keep standing-rules
  in sync with [rules/global/working-style.md](../rules/global/working-style.md).

Conventions: deterministic, fast, non-blocking unless the hook IS a gate (exit 2 blocks);
UserPromptSubmit hooks must always exit 0. Hooks reload at session start. Test changes via
[scripts/tests/](../scripts/tests/). Hookless surfaces (claude.ai web, iPhone, Cowork) get the
must-happen steps via the `session-hygiene` skill instead.
