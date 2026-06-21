---
name: credential-leak-2026-06-17
description: Plaintext dump of ALL vault secrets (incl. the master OP_SERVICE_ACCOUNT_TOKEN) is committed + pushed in obsidian-vault Claude Export files — every value compromised; rotate-on-migrate in progress.
metadata: 
  node_type: memory
  type: project
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

Status as of 2026-06-17: leak found, plan locked, SA-token rotation pending owner mint.
Reorg in-flight: created items `MAC_MCP_AUTH_TOKEN` + `GITHUB_MCP_AUTH_TOKEN` (currently hold
leaked bearer values → must get fresh values), repointed 6 connector `.env.template` files
(repo + deployed). Nothing committed/deleted/restarted yet. Links: [[credentials-state]],
[[obsidian-state]], [[mac-connector-tooling]].
