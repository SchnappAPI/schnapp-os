---
name: malformed-stored-secret-401
metadata: 
  node_type: memory
  scope: global
  source: "schnapp-os learning-worker auth debug, 2026-06-29 (ADR 0019)"
  updated: 2026-06-29
  supersedes: ""
  type: reference
  originSessionId: 9779c264-7052-43c7-a854-a37d03a35a90
---

A stored credential carrying surrounding whitespace or wrapping quotes (e.g. a 1Password item saved as
`␣'sk-ant-oat…'` instead of the bare token) is read and sent **verbatim**, so a perfectly valid secret
authenticates as corrupted and the API returns `401 Invalid bearer token` (or `Invalid signature` / a
generic auth error). It is indistinguishable at a glance from an expired/wrong/unsupported token, so the
stored value is the last thing suspected. This exact bug caused a multi-day misdiagnosis: a valid Claude
**subscription** OAuth token (`CLAUDE_CODE_OAUTH_TOKEN`) was blamed on "CLI v2.1.112"; once the leading
space + quotes were stripped it authenticated headless on that same CLI. See [[credentials-state]] and ADR 0019.

**Why:** normal output (logs, `op read`, `echo`) renders wrapping whitespace/quotes invisibly, and the 401
names no cause, so debugging chases the tool or the version instead of the value.

**How to apply:** when a stored secret mysteriously 401s, verify its RAW BYTES before blaming the tool, the
CLI version, or rotating it: `op read "<ref>" | head -c4 | xxd -p` — a clean token starts with its own
characters (e.g. `73`='s'); a leading space+quote shows `2027`. Strip surrounding whitespace/quotes and
store the bare value with no trailing newline (`op item edit` stores exactly what you pass). Applies to any
secret consumed verbatim: API keys, bearers, OAuth tokens, connection strings.
