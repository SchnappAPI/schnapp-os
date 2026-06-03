---
name: keep-tracker-current
scope: global
source: owner correction, 2026-06-03 (claude-kit session)
updated: 2026-06-03
supersedes: ""
metadata:
  type: feedback
---
When a step's deliverable exists and is verified, flip its PLAN.md box and append a
PROGRESS.md line **in the same commit** as the deliverable — never batch tracker updates
to a later handoff. Mark partial work as `[~]`, not `[x]`. Never call something
done/verified before its verify command has actually run.

**Why:** The tracker is the source of truth for what is done. Batching its updates lets
PLAN.md drift (boxes stayed all-unchecked through Parts 0-4) and lets "verified" get
claimed on evidence that has not been produced. A stale tracker is worse than none —
it misleads the next session.

**How to apply:** Every commit that changes project state ALSO updates PLAN.md (box) and
PROGRESS.md (one line), automatically, without being asked, and is **pushed immediately** so the
GitHub remote always reflects local state (never let the remote go stale). `[x]` only after the
verify command ran and passed; `[~]` for built-but-unverified or partially-done; quote the verify
result in the PROGRESS line. See [anti-stale](../plugins/core/rules/global/anti-stale.md).
