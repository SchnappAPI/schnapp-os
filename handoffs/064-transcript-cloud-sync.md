# Handoff 064: Transcript cloud-sync live (sessions never local-only)

Date: 2026-07-18. Surface: Code (Mac). Prior: [063](063-skills-taxonomy-and-auto-improvement-lane.md).

## Goal
Owner standing rule (vault fact `sessions-cloud-accessible`): no chat/session local-only. Close
the last gap: `~/.claude/projects` (~1.1 GB, ~4.3k session JSONLs) existed only on the Mac.

## Facts established
- Filtered extraction (user/assistant text only) is ~27% of raw; the tool-payload churn that
  would strain git is excluded by construction.
- rclone/wrangler are not installed; R2 has no claude.ai reader path without new infrastructure.
- `scan-secrets.sh --block-re` exports the BLOCK regexes, so the extractor masks from the single
  pattern source (no duplication).
- First full extracted set scanned 0 BLOCK (consistent with the 2026-07-18 local-transcript
  redaction noted in PROGRESS).
- Per-file scan-secrets spawns took >10 min over 4k files; one batched xargs pass takes seconds.
  Steady-state sync run: ~5 s.

## Decisions + reasoning
[ADR 0038](../decisions/0038-transcript-cloud-sync.md): private GitHub repo
`SchnappAPI/claude-transcripts` over R2 (connector-readable from every surface today,
accessibility-first) and over raw JSONL (leak surface + churn, no search benefit). Fail-closed
secrets gate; archive semantics (locally deleted sessions stay mirrored).

## Actions + outcomes
- `scripts/transcript-extract.py` (mask + incremental state), `scripts/transcript-sync.sh`
  (extract, batched re-scan of the whole git-dirty set, commit, rebase-pull, push, ops-alert
  incidents on key `transcript-sync`), `scheduled-tasks/com.schnapp.transcript-sync.plist`
  (15 min), README install block, self-test `scripts/tests/test-transcript-sync.sh` wired into
  freshness.yml. CI plist lint switched to glob (com.schnapp.session-mine.plist had been missing
  from the hardcoded list). `com.schnapp.transcript-sync` added to `check-infra-health.sh`.
- Repo created private; first full sync (3,991 sessions, ~335 MB markdown) pushed clean.
- LaunchAgent rendered, loaded, verified in `launchctl list`.
- Vault fact + MEMORY.md index superseded to point at the live sync.
- One early red ops-alert fired (first-push had no remote main ref; fixed the worker); next green
  run closes it.

## Status + next steps
Live and scheduled. Next session: nothing required for this lane. Chipped follow-up: chat-archive
local-transcript ingest lane reading the mirror (deeper search than GitHub code search).

## Open questions / edge cases
- Repo growth is unbounded (~335 MB now, text-only). Revisit sharding/rotation only if GitHub
  soft limits (~1 GB warn) approach.
- A secret that survives both mask and scan would land in a PRIVATE repo - same envelope the
  owner accepted 2026-06-27; rotation rules unchanged.
- Catch-up note: 7 commits (auto-improvement lane, render-health, failover decision) landed
  before this session without a handoff; their state is in PROGRESS 2026-07-18 lines and ADR 0037.

## Copy-paste primer (new session)
Transcript cloud-sync is live: com.schnapp.transcript-sync mirrors ~/.claude/projects as masked
text-only markdown to private SchnappAPI/claude-transcripts every 15 min (ADR 0038). Verify with
`launchctl list | grep transcript-sync` and the repo's latest commit. Only open item: the chipped
chat-archive ingest lane over the mirror.
