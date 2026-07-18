# Transcript cloud-sync (sessions never local-only)

Owner standing rule: all sessions cloud-accessible ([ADR 0038](../../../decisions/0038-transcript-cloud-sync.md)).
Mirror `~/.claude/projects` message text to private `SchnappAPI/claude-transcripts`.

- [x] `scripts/transcript-extract.py`: text-only extraction (tool payloads/sidechains dropped),
      BLOCK-pattern masking from `scan-secrets.sh --block-re`, incremental state
- [x] `scripts/transcript-sync.sh`: clone/extract/re-scan gate (fail-closed, ops-alert)/commit/push
- [x] self-test `scripts/tests/test-transcript-sync.sh` wired into freshness.yml
- [x] plist `scheduled-tasks/com.schnapp.transcript-sync.plist` (15 min) + README install block
- [x] private repo `SchnappAPI/claude-transcripts` created; first full sync pushed clean
      (scan-secrets green over the extracted set)
- [x] LaunchAgent loaded on the Mac; verify `launchctl list` + log
- [x] vault memory `sessions-cloud-accessible` superseded to point at the live sync
- [ ] follow-up (chipped, lives in ~/code/chat-archive): local-transcript ingest lane reading
      the mirror into the knowledge graph
