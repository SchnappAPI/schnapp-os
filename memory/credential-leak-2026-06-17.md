---
name: credential-leak-2026-06-17
description: Plaintext dump of ALL vault secrets is committed + pushed in obsidian-vault Claude Export files (PRIVATE repo). SA token + 3 MCP bearers rotated; flatten 2026-06-26 COPIED (did not rotate) the rest; owner ACCEPTED the residual risk 2026-06-27 (private repo, not public) — no further rotation/scrub. NOT "nothing exposed": values are plaintext in a private pushed repo.
metadata: 
  node_type: memory
  type: project
  source: "session 9f0ff006 (credential reorg 2026-06-17); owner risk-accepted decision 2026-06-27"
  updated: 2026-06-27
  originSessionId: 9f0ff006-412e-4529-aed7-032cd4dbd18a
---

2026-06-17: Found a full plaintext credential leak while doing the credential reorg.
~28 files under `obsidian-vault/Claude Export/Conversations/*.md` (plus
`obsidian-vault/Notes/Credentials CLAUDE.md`) contain **revealed secret VALUES** dumped
from `op item list`/setup chats: the master `OP_SERVICE_ACCOUNT_TOKEN` (`ops_…`), every
GitHub PAT (`github_pat_…`), the Anthropic API key (`sk-ant-api…`), the Claude Code OAuth
token (`sk-ant-oat…`), both MCP bearers, the DB + `sa` passwords, all Web App secrets,
Webshare, and Cloudflare tunnel secrets.

Exposure: the files are git-TRACKED in `SchnappAPI/obsidian-vault` (PRIVATE) and in its
history (commit `1b9ce78`), pushed to GitHub, synced to OneDrive, present in local clones,
and originated as exported Claude.ai conversations. The grep that found it also pulled the
dump into the 2026-06-17 Claude Code session transcript — that session log is sensitive too.

**Why it matters:** the SA token resolves the whole vault, so EVERY secret must be treated
as compromised. Reorg-without-rotation only relocates burned values.

**How to apply / remediation (owner decisions 2026-06-17):**
- Strategy = **rotate-on-migrate**: as each item is split/renamed in the [[credentials-state]]
  reorg, mint a FRESH value instead of copying the old one. Order: `OP_SERVICE_ACCOUNT_TOKEN`
  FIRST (cuts off vault access), then downstream secrets.
- Owner-only rotations: SA token (1P admin mint), `GITHUB_PAT` (github.com), Anthropic key
  (console.anthropic.com), Claude OAuth (`claude setup-token`), Webshare, Cloudflare.
- Self-serviceable: MCP/OP bearers (`openssl rand -hex 32`), web app passcodes/secrets.
- Purge: history-rewrite decision DEFERRED until after rotation (then the leaked history holds
  dead values). Stop exporting credential-bearing chats; never paste vault values into notes.
- NEVER write a secret value into any tracked file ([secrets-as-references] rule).

**Rotation progress (supersedes the 2026-06-17 "nothing rotated yet" status):**
- ✅ `OP_SERVICE_ACCOUNT_TOKEN` rotated 2026-06-22 (Phase 1) — old SA deleted. [[credentials-state]]
- ✅ **All 3 MCP bearers rotated 2026-06-23 (Phase 3B)**, fresh `openssl` values, non-echoing, Mac-side
  verified (`:8765`/`:8766` new→200/bogus→401; op-mcp `op_health` authenticated). Owner client legs
  (claude.ai `mac-mcp` bearer, Copilot `github-mcp` bearer) still pending; op-mcp clients are OAuth.
- ⏳ **Still outstanding (owner consoles, rotate-on-migrate):** `GITHUB_PAT` (+`GITHUB_PAT_ADMIN`),
  Anthropic API key, Claude OAuth, DB `sa`, Web App secrets, **`RUNNER_API_KEY`** (newly surfaced — see
  below), Webshare, Cloudflare.
- ⏳ Leak scrub of the ~28 `obsidian-vault` export files: not started (separate repo; history-rewrite
  still deferred until after rotation).

**New leak vector found 2026-06-23 (Phase 3B):** plaintext-secrets backup
`~/Library/LaunchAgents/com.schnapp.macmcp.plist.bak.20260524-105649` (the pre-op-wrap design) hardcoded
`MAC_MCP_AUTH_TOKEN` (now dead, rotated), `GH_PAT`, and `RUNNER_API_KEY` (`= Web App /runner_api_key`).
Owner: `rm` the `.bak`; `GITHUB_PAT` + `RUNNER_API_KEY` join the console-rotation set. `RUNNER_API_KEY`'s
value also transited the 2026-06-23 Code session transcript (a redaction gap when dumping the file).

**OWNER DECISION 2026-06-27 — residual risk ACCEPTED, no rotation, no scrub.** After the
2026-06-26 vault flatten (which COPIED values, did NOT rotate — split items still hold the
leaked 2026-05 values), the owner chose to leave all values as-is and proceed. Grounding
(verified 2026-06-27, counts only, no values printed): `SchnappAPI/obsidian-vault` is **PRIVATE**
and pushed (`main` = `origin/main`); 30+ tracked files under `Claude Export/Conversations/*.md`
still hold plaintext secret patterns — `github_pat_` ×89, `ghp_` ×22, `sk-ant-` ×11, `ops_` ×4
(the `ops_` SA tokens are dead post-rotation). **Honest status: NOT "nothing was exposed" — the
secrets are plaintext in a PRIVATE (not public) repo, exposed to anyone with access to that repo
or the linked GitHub account, but not to the open internet.** Owner judged that audience acceptable.
Real residual teeth = the live **GITHUB_PAT** + **Anthropic key** sitting in that plaintext;
declined to rotate those too. The rotate-on-migrate strategy above is therefore CLOSED as
"won't-do" unless the owner reopens it; the scrub is likewise deferred indefinitely. Do not
re-flag this as urgent without new exposure (e.g. repo goes public, or a third party gains access).

Links: [[credentials-state]], [[obsidian-state]], [[mac-connector-tooling]].
