# 0038 - Transcript cloud-sync: filtered private GitHub mirror, not R2, not raw bytes

Date: 2026-07-18
Status: accepted

## Context

Owner standing rule (vault memory `sessions-cloud-accessible`, 2026-07-18): no chat/session may
be local-only. The gap was the local Claude Code transcripts at `~/.claude/projects` (~1.1 GB,
~4,280 session JSONLs, continuous churn), which existed only on the Mac. The owner's actual use
is "what did you say last Tuesday" from any surface, i.e. accessibility-from-claude.ai first.

## Decision

Mirror to a **private GitHub repo `SchnappAPI/claude-transcripts`**, syncing **extracted message
text only**, every 15 minutes via LaunchAgent `com.schnapp.transcript-sync`.

1. **Target: GitHub, not Cloudflare R2.** The GitHub connector already reads private SchnappAPI
   repos from every surface (claude.ai chat, Cowork, cloud sessions), so search + read work with
   zero new infrastructure. R2 is cheaper for bulk bytes but has no reader path from claude.ai
   without building a Worker or widening the portal; rclone/wrangler are not even installed on
   the Mac. Accessibility beats storage elegance for this use.
2. **Content: filtered markdown, not raw JSONL.** `scripts/transcript-extract.py` keeps only
   user/assistant TEXT blocks (plus timestamps and per-session frontmatter) and drops tool_use /
   tool_result payloads, attachments, and sidechain (subagent) turns. Sampled ratio ~27% of raw;
   text-only markdown is what "find what was said" needs, diffs append-mostly, and the churn
   that would strain git (tool-result blobs rewritten per session) is excluded by construction.
3. **Security envelope.** The 2026-06-17 leak class lived mostly in tool outputs echoing secret
   values; dropping tool payloads removes that class structurally. Residual text is masked
   against the BLOCK patterns from `scan-secrets.sh --block-re` (single pattern source, never
   duplicated), then every changed output is re-scanned; any BLOCK finding aborts the run before
   commit (fail-closed) and raises an `ops-alert.sh` incident. The mirror repo is PRIVATE under
   SchnappAPI; this stays inside the exposure envelope the owner already accepted for private
   repos (memory `credential-leak-2026-06-17`) and never widens it. Self-test:
   `scripts/tests/test-transcript-sync.sh`, wired into freshness.yml.
4. **Archive semantics.** Sources deleted locally stay in the mirror: the cloud copy outliving
   local cleanup is the point of the rule.
5. **Search depth.** Raw reachability + GitHub search ship now. Deeper search (the chat-archive
   knowledge graph in `~/code/chat-archive`) gets a local-transcript ingest lane as a follow-up
   in that repo; it reads the mirror, so this decision does not block it.

## Alternatives rejected

- **Raw JSONL mirror to GitHub**: 1.1 GB with heavy per-session rewrite churn strains git and
  syncs the whole tool-output leak surface for no search benefit.
- **Cloudflare R2**: no claude.ai reader path without new infrastructure (Worker or portal
  widening); fails the accessibility-first requirement.
- **chat-archive ingest only (no mirror)**: the graph is derived and lossy; the standing rule
  wants the sessions themselves reachable off-Mac.

## Consequences

- New LaunchAgent + worker + extractor + self-test (install: `scheduled-tasks/README.md`).
- The mirror repo is generated output: never hand-edit; the extractor overwrites.
- If a secret ever passes the mask AND the scan (double miss), the exposure is a private-repo
  one, same class as the accepted 2026-06-17 envelope; rotation rules apply unchanged.
