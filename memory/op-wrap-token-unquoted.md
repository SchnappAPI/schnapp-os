---
name: op-wrap-token-unquoted
description: "launchd op-wrap.sh greps the SA token out of ~/.zshrc and strips the prefix literally (no sourcing) — so the token line MUST be unquoted, or every service crash-loops on \"unrecognized auth type\"."
metadata: 
  node_type: memory
  scope: global
  type: project
  source: "session f25f3f99 (SA token rotation / launchd crash diagnosis 2026-06-22)"
  updated: 2026-06-30
  originSessionId: f25f3f99-54d9-4eda-9ce7-e06604900a56
---

`~/code/schnapp-bet/services/launchd/op-wrap.sh` is the bootstrap wrapper for every launchd-managed
service (macmcp, githubmcp, obsidian-mcp, brain-watcher, bet.schnapp web-prod/flask). It does **not**
source `~/.zshrc`; it reads the SA token by `grep '^export OP_SERVICE_ACCOUNT_TOKEN=' ~/.zshrc` then
literal prefix-strip: `export OP_SERVICE_ACCOUNT_TOKEN="${LINE#export OP_SERVICE_ACCOUNT_TOKEN=}"`.

So the token in `~/.zshrc` (and `~/.zshenv`, for symmetry) MUST be written **unquoted**:
`export OP_SERVICE_ACCOUNT_TOKEN=ops_…`. Quoting it (`='ops_…'`) leaks the literal quote characters
into the value → `op run` gets a token starting with `'` → every service dies at op-client init with
`failed to DeserializeServiceAccountAuthToken, unrecognized auth type` and crash-loops (exit 1).

The trap: shell-sourcing readers (zsh, the `com.schnapp.environment` agent's `. ~/.zshenv`) strip the
quotes correctly, so `op whoami` and `launchctl getenv` show a clean valid token while the services
silently fail — the cause looks like a bad token when it is a bad *format*.

**Why:** a non-sourcing grep/strip parser cannot remove shell quotes.
**How to apply:** before changing the format of any file, enumerate every reader, not just the shell —
a value consumed by a grep/strip/regex parser must match that parser's expected shape. Generalize the
"fix the class" habit: one stale assumption about how a file is read broke six services at once.
Links: [[credentials-state]], [[verify-before-asserting]], [[anti-stale]].
