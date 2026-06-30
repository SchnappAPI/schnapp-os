# 0019 — Learning-worker authenticates via the Claude subscription (OAuth), not the metered API key

Date: 2026-06-29. Status: DECIDED (supersedes the `ANTHROPIC_API_KEY` sanction in `docs/headless-claude-auth.md`).

## Context
The nightly learning-worker runs headless `claude -p` under launchd. `docs/headless-claude-auth.md`
(2026-06-27) sanctioned `ANTHROPIC_API_KEY` because the subscription OAuth token
(`CLAUDE_CODE_OAUTH_TOKEN`) returned `401 Invalid bearer token` on CLI v2.1.112, attributed to a
CLI/subscription-format limitation. But the metered API key contradicts the cost-discipline principle:
heartbeat/automation reasoning should reuse the Claude subscription, not billed API tokens (AUDIT group K).

## Finding (2026-06-29)
The OAuth path was never broken on v2.1.112. The stored vault value was **malformed**: saved as
`␣'sk-ant-oat…'` — a leading space plus wrapping single-quotes (111 bytes raw vs 108 clean). The worker
sends the resolved value verbatim, so a valid token was transmitted corrupted and rejected, producing the
same `401 Invalid bearer token` a deliberately-invalid control token produces. Evidence:
- control (invalid OAuth token), clean env → `401 Invalid bearer token`;
- cleaned vault token, clean env → `ok`;
- the worker's exact resolution replayed in a clean launchd-equivalent env (launchd `OP_SERVICE_ACCOUNT_TOKEN`
  + the OAuth `op://` ref) → `resolved -> CLAUDE_CODE_OAUTH_TOKEN` then `ok`.

## Decision
The learning-worker authenticates with the **subscription OAuth token**
(`op://web-variables/CLAUDE_CODE_OAUTH_TOKEN/credential`). `LEARNING_CLAUDE_TOKEN_REF` points there; the
worker's prefix auto-select exports it as `CLAUDE_CODE_OAUTH_TOKEN`. `ANTHROPIC_API_KEY` stays the
documented fallback but must never co-exist in the worker env (it wins precedence and re-introduces metered
billing). The malformed vault value was corrected in place; the plist was reinstalled from the repo template
with the OAuth ref and reloaded.

## Consequences
- Worker reasoning bills the Claude **subscription** (free under plan), honoring cost discipline.
- The OAuth token expires ~yearly (this one ~2027-05); re-mint via `claude setup-token` and store it with
  **no surrounding whitespace or quotes**.
- General lesson: when a stored credential mysteriously 401s, verify its raw bytes — a wrapping quote/space
  is invisible in normal output and indistinguishable from a bad token. Added to `headless-claude-auth.md`.
- `docs/headless-claude-auth.md` and `scheduled-tasks/README.md` updated to sanction the OAuth token.
