---
name: mac-connector-tooling
metadata:
  node_type: memory
  scope: global
  source: "handoffs/016 (observed 2026-06-16)"
  updated: 2026-06-16
  supersedes: ""
  originSessionId: claude-ai-web-2026-06-16-stale-review
---

Schnapp Mac connector tool semantics (non-obvious; bit us once — observed 2026-06-16).

- **`write_file` OVERWRITES / truncates** the target — it has no append mode. Writing only new
  content to an existing file destroys the rest (it truncated PROGRESS.md mid-session; restored
  from git). To APPEND, use `shell_exec` with a heredoc: `cat >> path <<'EOF' ... EOF`. To edit
  in place, prefer a `python3` read-modify-write via `shell_exec` (exact-anchor replace), not
  `write_file`. Reserve `write_file` for brand-new files or deliberate full rewrites.
- **`shell_exec` strips the 1Password identity** (`op` cannot read secrets in it). Route any
  credential-bearing command through **`op_run`** (injects specific `op://` refs, scrubs values).
