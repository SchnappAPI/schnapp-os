---
name: handoff-resume
description: Use when resuming prior work mid-project - triggered by "resume", "continue from where we left off", "read handoff NNN and continue", or any session that inherits unfinished state from a prior session. Orients to correct current-state before starting work, not for a general health check.
---

# handoff-resume

Orient to prior session state before touching anything. Reading only the handoff
misses work that completed after it was written. The four-doc read takes two minutes
and prevents redoing done work or missing a locked decision.

## Steps

1. **Find the handoff.** If the owner named a specific number, use it. Otherwise find
   the most recent: `ls -t handoffs/*.md | head -1` (or `handoffs/README.md` index).

2. **Read the handoff fully.** Do not skim for "next steps" first - context shapes
   what "next" means. Read all of it.

3. **Read PROGRESS.md.** This is the execution log. Work may have been committed AFTER
   the handoff was written; PROGRESS.md is authoritative over the handoff for what is
   already done.

4. **Read the live plan doc.** Newest dated `.md` in `docs/superpowers/plans/`. Check
   box state: a `[x]` there that the handoff marks `[ ]` means that step is done.

5. **Spot-check cited decisions.** If the handoff says "just locked: decisions/NNNN",
   read that ADR. A superseded decision makes the handoff's reasoning stale.

6. **Reconcile conflicts.** PROGRESS.md beats the handoff on what is done. The live
   plan doc beats both on the next unchecked box. A newer ADR beats prior reasoning.

7. **Check git state** (if the SessionStart hook has not already run):
   `git status && git log --oneline -5`. Confirm main, no dirty tree, no unpushed.

8. **Start work.** State briefly what state you found and what you are picking up.

## Judgment calls

- If the handoff mentions an open PR or branch, check whether it merged before
  starting "next" work - the work may already be in main.
- If PROGRESS.md and the handoff agree but the live plan doc shows a box not in
  either, the plan doc reflects owner updates made directly and takes precedence.
- If you cannot find the handoff number the owner cited, say so and read the most
  recent one instead. Do not silently fall back without telling them.
- If only the handoff exists (no PROGRESS.md, no plan doc): use the handoff's stated
  state as ground truth, and note this explicitly before starting work.

## When NOT to use

- Checking system health without intent to work: `status` (whole-system view).
- Starting a genuinely new task with no prior handoff: load the relevant domain skill
  directly; no anchor-doc read is needed.
- On a hookless surface where the freshness gate has not run: invoke `session-hygiene`
  first, then return here.
- Writing or ending a session: `session-hygiene` (end-of-session write, on-correction
  route).
