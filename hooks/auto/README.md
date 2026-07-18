# hooks/auto/ - autonomous hook lane (ADR 0037 tier 3)

Agent-minted hooks land HERE as plain `.sh` files and fire via
[auto-dispatch.sh](../auto-dispatch.sh) (registered once in `.claude/settings.json`,
PostToolUse Write|Edit). No settings edit per hook: a drop-in file is the whole install.
Project scope (schnapp-os) first; promote a hook to the ANY-REPO portable-shell layer only by
the normal change process, never autonomously.

## Contract (every auto-hook)

```bash
#!/usr/bin/env bash
# auto-hook: <name> - <one line: what class of mistake it catches, and the >= 2 incidents>
AUTO_HOOK_MODE=observe   # observe | enforce - the escalator flips this line, nothing else
. "$(dirname "${BASH_SOURCE[0]}")/../auto-hook-lib.sh"
# ...deterministic check over the hook stdin JSON / the written file...
# on failure:
auto_hook_verdict "<name>" "$AUTO_HOOK_MODE" "<reason>"
# on pass: exit 0
```

- Born `observe`: never blocks; a failed check appends a `would-block` line to
  `~/Library/Logs/schnapp-os/auto-hooks.log` and exits 0.
- [scripts/auto-hook-escalate.sh](../../scripts/auto-hook-escalate.sh) (run nightly by the
  session-mine worker) flips `observe` -> `enforce` when the hook is >= 7 days old AND no open
  GitHub issue labeled `auto-hook-fp` names it. That issue is the false-positive brake: any
  session (or the owner) that sees a wrong would-block files one, and escalation holds until it
  closes. No issue = clean week = the hook starts blocking, no approval step (ADR 0037).
- A hook must check ONE deterministic thing. Judgment calls never become hooks
  (decisions/0026: a gate that cannot mechanically decide is theatre).
- Mint bar: >= 2 occurrences of the same mistake class, named in the header comment.

## When a would-block is wrong

File the brake issue, then fix or delete the hook (delete = `git rm`, normal commit):

```bash
gh issue create --label auto-hook-fp --title "auto-hook-fp: <name>" \
  --body "would-block was wrong because <why>; ledger line: <paste>"
```
