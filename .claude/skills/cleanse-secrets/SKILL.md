---
name: cleanse-secrets
description: Use when files may contain literal secret VALUES that must be found and removed — auditing a repo/diff before commit or sharing, retro-scrubbing leaked exports (e.g. the obsidian-vault Claude-export dump), or confirming a tree holds references not values. Symptoms include "did a secret leak", "scrub the credentials out", hardcoded api_key/token/password, "is this safe to push/open-source". This skill finds AND removes (scrub/redact); for a read-only review pass that only flags without editing, use the secrets-leak-reviewer agent.
---

# cleanse-secrets

Invariant: **no secret value in any tracked file — references (`op://`) only**
([secrets-as-references](../../../rules/global/secrets-as-references.md)). This skill finds violations
and removes them. Detection is delegated to one canonical scanner so CI and this skill can never
drift apart: [`scan-secrets.sh`](../../../scripts/scan-secrets.sh). For *diff-level* review during
normal edits, the `secrets-leak-reviewer` agent is the lighter tool; use this skill for
whole-file / whole-repo scans and for the redact step.

## Mode 1 — report (read-only)

```bash
# absolute path — agent Bash resets cwd between calls (adjust to your schnapp-os clone)
~/code/schnapp-os/scripts/scan-secrets.sh [--strict] [--exclude GLOB]... [PATH...]
```

- No `PATH` → scans this repo's git-tracked files (the CI default; run from inside the repo).
- `PATH` a dir → scans every file under it, cross-repo. For the leak scrub:
  `~/code/schnapp-os/scripts/scan-secrets.sh --strict ~/path/to/obsidian-vault/"Claude Export"`.
- `BLOCK` = exact token formats (a match IS a leaked value: `ops_`, `sk-ant-`, `github_pat_`,
  GitHub/AWS/Slack/SendGrid/JWT/DB-URL, private keys). `WARN` = heuristics (64-hex bearers,
  `name: value` assignments, private IPs) for human review. Values print **masked** (prefix +
  length) — the scanner never emits a full secret.
- Exit non-zero on any `BLOCK`; `--strict` also fails on `WARN`.

## Mode 2 — redact (write — only after report)

For each finding, remove the value in place, preserving surrounding content:

| The value is… | Replace with |
|---|---|
| config/code that should resolve at runtime | the matching `op://web-variables/<ITEM>/<field>` ref ([vault-resolve](../vault-resolve/SKILL.md)) |
| prose in a chat export / note (no runtime consumer) | `[REDACTED:<class>]` — keep the surrounding conversation, strip only the value |

**Edit without echoing the value** (the redact step is itself a leak vector). Do NOT read the value
into context and paste it back in a diff or explanation. Replace it in place with a non-echoing
edit keyed off the scanner's `file:line`, e.g.:

```bash
# redact a leaked value at a known file:line, in place, without ever printing it
perl -i -pe 's/\Q$ENV{LEAK}\E/[REDACTED:onepassword]/g if $. == 42' file.md   # LEAK set non-interactively, never echoed
```

Picking the right `op://` ref for a config value: **do not guess**. Match the value to its item by
its consumer/context in [credentials-map.md](../../../credentials-map.md) `consumed_by` — a wrong
ref resolves to empty and fails silently ([vault-resolve](../vault-resolve/SKILL.md) field-label gotcha).

Then:
1. **Re-run report on the same path → expect zero `BLOCK`.**
2. **A redacted value is already compromised** (it existed in plaintext). Redaction hides it going
   forward; it does **not** make it safe. Every redacted secret must be rotated —
   [rotate-secret](../rotate-secret/SKILL.md) — and the leak recorded ([[credential-leak-2026-06-17]]).
3. Redaction edits the working tree only. The value still lives in git **history**; a history
   rewrite is a separate, deferred decision (do it *after* rotation, when the old value is dead).

## The leak-scrub case (the ~28 export files)

`obsidian-vault/Claude Export/Conversations/*.md` + `Notes/Credentials CLAUDE.md` hold dumped
values ([[credential-leak-2026-06-17]]). Procedure: report-scan the export dir → redact each hit
to `[REDACTED:<class>]` (keep the conversations) → re-scan to zero `BLOCK` → confirm every
redacted item is on the rotate list. That repo is separate from schnapp-os; commit the scrub there.

## Common mistakes

- Treating redaction as remediation — it is not; **rotate** the value.
- Scanning only the diff and missing pre-existing leaks — for a real audit scan the whole tree.
- Adding a new pattern here instead of in `scan-secrets.sh` — there is **one** pattern source; edit
  the scanner (and its `tests/` fixture), never re-list patterns in this doc.

Related: [`scan-secrets.sh`](../../../scripts/scan-secrets.sh) · `secrets-leak-reviewer` agent
(diff-level) · [vault-resolve](../vault-resolve/SKILL.md) · [rotate-secret](../rotate-secret/SKILL.md).
