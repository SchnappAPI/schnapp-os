# Handoff 049: Phase 5 repo-side complete (handoff packet live); resume = owner Cowork legs (round-trip)

**Date:** 2026-07-01. **Surface:** Claude Code on the Mac, Fable 5.
**Status:** Streamline Phases 1-4 COMPLETE (handoff 048). Phase 5 repo-side COMPLETE this session;
the plan closes when the owner runs the Cowork legs below and the return leg verifies clean.

## What this session delivered (all on `main`, one commit, CI green)
- **Handoff-packet convention (T2, done):** defined ONCE in
  [docs/memory-lane.md](../docs/memory-lane.md#handoff-packet-cross-surface-resume): write-on-stop
  = the end-of-session write (working-memory facts to the vault + newest `handoffs/NNN` + indexes +
  PROGRESS + plan-box, BOTH repos pushed); read-on-start = the freshness gate. Same packet every
  surface, only transport differs.
- **session-hygiene fold-in (T2):** hookless transport mechanics added - connector writes are
  read-modify-write whole-file commits spanning BOTH repos; `handoffs/README.md` updated by
  byte-exact emulation of `gen-handoff-index.sh` (CI freshness diffs it against a fresh regen next
  push, so a slip fails visibly). Description de-staled ("Cowork until verified" → "Cowork").
- **surfaces/cowork.md rewritten:** dead plugin-install path dropped (decisions/0024), packet
  wired in, enablement now carries the T1 verify + T3 probe steps.
- **ADR [decisions/0027](../decisions/0027-cowork-handoff-packet-over-git.md) (T4):** packet over
  git; connector transport; sanctioned generated-index emulation; memory-mcp as optional upgrade.
- **De-staled in passing:** credentials-map `SCHNAPP_OS_PAT` scope (now schnapp-os + schnapp-vault,
  matching the Phase-1 gate-3 grant); `code-mac.md` + `code-work-machines.md` hook delivery
  ("plugin-wide" → `.claude/settings.json` per 0024).
- **Key T1 finding:** NO grant to add. The Cowork github leg (github-mcp) authenticates with
  `GITHUB_PAT` (all-repos), so `SchnappAPI/schnapp-vault` is already in scope. T1 reduces to the
  verify below.

## THIS handoff is the Code-stop leg of the T4 round-trip
The round-trip is: **Code stop (this packet) → Cowork resume + stop → Code resume + verify.**
Everything below is the exact runbook for the remaining legs.

## Owner runbook (the only remaining work)

### Leg 1 - Cowork session (T1 verify + T3 probe + Cowork half of T4)
Open Cowork with the Schnapp Portal + obsidian-mcp connectors enabled
([surfaces/cowork.md](../surfaces/cowork.md) enablement). Prompt it:
"Resume schnapp-os work: read handoffs/README.md in SchnappAPI/schnapp-os via the GitHub
connector, follow the resume point (handoff 049), and execute its Cowork leg."
The session then does, per the packet convention:
1. **Read the packet:** fetch `handoffs/README.md` → resume point = this file → read it. Also
   fetch the vault's `memory/MEMORY.md` + any fact it needs (= T1 READ half).
2. **T3 probe:** check whether `memory_health` / `memory_list` tools exist and respond. Record
   the result either way (it decides the 0027 upgrade path; absent/failing is a valid result).
3. **T1 WRITE half:** create `memory/cowork-vault-write-verified.md` in `SchnappAPI/schnapp-vault`
   with EXACTLY this frontmatter shape (schema: vault `agents.md`, CI-enforced; fill real dates):

   ```
   ---
   name: cowork-vault-write-verified
   description: Cowork reads + writes the vault through the GitHub connector (Phase 5 T1 verify)
   type: project
   area: global
   source: <cowork session id or "cowork-session">
   created: <today YYYY-MM-DD>
   updated: <today YYYY-MM-DD>
   superseded: false
   ---

   Verified <date>: a Cowork session read memory/MEMORY.md and wrote this fact via the GitHub
   connector (github-mcp, GITHUB_PAT). The vault leg of the handoff packet works from Cowork.
   memory-mcp probe result: <reachable / not reachable>. Context: schnapp-os handoffs/049 +
   decisions/0027.
   ```

   Then append its index line to the vault `memory/MEMORY.md` (read-modify-write; match the
   existing line format, which uses an em dash: `- [Title](cowork-vault-write-verified.md) — hook`).
4. **Write the packet (Cowork-stop leg of T4)** to `SchnappAPI/schnapp-os`, all read-modify-write:
   - `handoffs/050-cowork-leg-round-trip.md`: H1 `# Handoff 050: Cowork leg of the Phase-5
     round-trip` + what was verified (T1 result, T3 result) + "resume in Code to close".
   - `handoffs/README.md`: emulate the generator - insert
     `` - [`050`](050-cowork-leg-round-trip.md) Handoff 050: Cowork leg of the Phase-5 round-trip (resume point)``
     as the first list line and strip `` (resume point)`` from the 049 line.
   - `PROGRESS.md`: append one line (date, Cowork leg ran, T1/T3 results, pointer to 050).
   - Plan doc `docs/superpowers/plans/2026-06-30-schnapp-os-streamline.md`: flip T1 `[~]`→`[x]`
     (verify ran) and T3 `[~]`→`[x]` (probe ran; note the result inline).

### Leg 2 - back in Code (return leg, closes the phase AND the plan)
Start a Code session in schnapp-os: "Resume: verify the Phase-5 round-trip per handoff 049."
It should: pull; confirm handoff 050 + its index line are present and `check-freshness.sh` +
`check-writing-style.sh` pass; confirm the vault fact + MEMORY.md line landed and vault CI is
green; confirm the PROGRESS line + plan flips landed. Nothing lost = Done-when MET. Then it
flips T4 `[~]`→`[x]`, marks the Phase-5 Done-when met, appends the PROGRESS close line
("Phase 5 COMPLETE; streamline plan CLOSED"), writes closing handoff 051, regenerates
`handoffs/README.md` with the script, commits + pushes.

### If a leg fails
- Connector cannot reach `schnapp-vault` → the `GITHUB_PAT` claim broke or Cowork uses a
  different GitHub connector: add `SchnappAPI/schnapp-vault` to THAT connector's repo grant
  (GitHub → Settings → Applications, or the fine-grained PAT's repository list), retry.
- Vault CI rejects the fact → fix frontmatter to the exact block above (vault `agents.md` owns
  the schema).
- Freshness CI rejects the emulated index → next Code session runs
  `bash scripts/gen-handoff-index.sh` and commits; note the format slip in the closing handoff.

## Operating flow (unchanged)
main-only, commit + push each change, flip the plan-doc box + PROGRESS line in the same commit.
Secrets are `op://` refs. Instruction files follow `rules/global/writing-style.md` (no em dashes).
Live status = [the plan doc](../docs/superpowers/plans/2026-06-30-schnapp-os-streamline.md) /
[PROGRESS.md](../PROGRESS.md).
