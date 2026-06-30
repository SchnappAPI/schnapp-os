---
scope: global
updated: 2026-06-30
---
# Verify before asserting

- Before stating that a file, function, flag, table, column, tool, or connector exists,
  confirm it. Recalled memory and docs are point-in-time and may be stale.
- Read a file immediately before editing it — with the **Read tool**, not a shell `cat`/`head`/`tail`/`grep`.
  `Edit`/`Write` only register a file as read when the Read tool viewed it; seeing the bytes in Bash does not, so
  the edit fails with "File has not been read yet." Grep for callers before changing a function.
- If you cannot verify, say so explicitly rather than presenting a guess as fact.
