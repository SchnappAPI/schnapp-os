# Handoff 050: Cowork leg of the Phase-5 round-trip

**Date:** 2026-07-01. **Surface:** Cowork (hookless), Fable 5.
**Status:** Cowork leg DONE (T1 verified, T3 probed, packet written). Resume in Code to close.

## What this session verified (runbook: [handoff 049](049-phase-5-cowork-packet-repo-side.md))

- **Read leg (packet read-on-start):** the freshness gate ran by hand through the GitHub
  connector: caught up to schnapp-os HEAD `454a7e9` and vault HEAD `ce1ba7a`, zero open PRs in
  either repo, plan-tracker state matched handoff 049 (T2 `[x]`, T1/T3/T4 `[~]`). Read
  `handoffs/README.md`, followed the resume point to 049, read the vault `memory/MEMORY.md`
  through the connector (the T1 READ half).
- **T1 (connector vault access) VERIFIED:** wrote `memory/cowork-vault-write-verified.md` to
  `SchnappAPI/schnapp-vault` via github-mcp (fact commit `8973634`, index commit `b845a7d`),
  flat 8-key frontmatter, MEMORY.md index line appended read-modify-write. vault-freshness CI
  green on the fact commit (run `28563359296`). No grant was added: github-mcp rides the
  all-repos `GITHUB_PAT`, exactly as handoff 049 predicted.
- **T3 (memory-mcp probe) REACHABLE:** `memory_health` = authenticated,
  repo=SchnappAPI/schnapp-vault, branch=main; `memory_list` serves the 14 flat-schema facts.
  Per [decisions/0027](../decisions/0027-cowork-handoff-packet-over-git.md), schema-validated
  `memory_*` writes are the memory-leg front line from Cowork; the connector write above stays
  the proven fallback.
- **Gotcha respected (ADR 0029):** the vault fact went through the connector, not a raw
  Edit/Write file edit, so the harness auto-memory re-nest never touched it; frontmatter
  verified flat 8-key before commit.

## Packet (Cowork-stop leg of T4)

This file, the `handoffs/README.md` index line (emulated per the convention), the PROGRESS.md
line, and the plan-doc flips (T1 and T3 `[~]` to `[x]`) all land this session as connector
read-modify-write commits to main, both repos pushed.

## Resume in Code to close (leg 2 of the 049 runbook)

Start a Code session in schnapp-os: "Resume: verify the Phase-5 round-trip per handoff 049."
Verify: pull; handoff 050 + its index line present and `check-freshness.sh` +
`check-writing-style.sh` pass; the vault fact + MEMORY.md line landed and vault CI is green;
the PROGRESS line + plan flips landed. Nothing lost = Done-when MET. Then flip T4 `[~]` to
`[x]`, mark the Phase-5 Done-when met, append the PROGRESS close line ("Phase 5 COMPLETE;
streamline plan CLOSED"), write closing handoff 051, regenerate `handoffs/README.md` with
`scripts/gen-handoff-index.sh`, commit + push.

## Operating flow (unchanged)

main-only, commit + push each change, tracker flips ride with the deliverable. Secrets are
`op://` refs. Live status: [the plan doc](../docs/superpowers/plans/2026-06-30-schnapp-os-streamline.md)
/ [PROGRESS.md](../PROGRESS.md).
