---
name: pr-sweep
description: Use to clear open pull requests across the SchnappAPI org on demand - "are there open PRs", "close the stray PRs", "never leave open PRs", "sweep/triage open PRs", or after a session leaves a PR behind. Lists every open PR org-wide, classifies each (empty/stray, moot/superseded, mergeable-clean, needs-review), then closes the dead ones and surfaces the rest for a merge decision. The on-demand action counterpart to the read-only `status` skill and the nightly `sync/unmerged` routine: those REPORT, this ACTS. Mutating + gated - closing dead PRs is safe; merging is asks-first, never blind-merge a production/security PR.
---

# pr-sweep

Enforces the owner's standing rule **never leave open PRs** on demand (owner-working-preferences #7;
`main`-only per [ADR 0016](../../decisions/0016-no-branches-precommit-gate.md) /
[0017](../../decisions/0017-web-sessions-target-main.md)). Builds on, does not duplicate,
[`status`](../status/SKILL.md) (reports open PRs among other signals) and the read-only
[`sync/unmerged`](../../scheduled-tasks/sync-unmerged-check.md) routine (flags stray **branches**).
This skill is the **PR-object** action: classify, then close the dead and merge the clean. Probe every
signal; never assume ([`verify-before-asserting`](../../rules/global/verify-before-asserting.md)).

## 1. Inventory - one org-wide call (not per-repo poking)

```
gh search prs --owner SchnappAPI --state open --json number,title,repository,url,author,createdAt
```

For each hit, pull only **token-readable** fields (requesting `statusCheckRollup` 403s on some repos
with the current token - omit it; read checks separately if needed):

```
gh pr view <n> --repo SchnappAPI/<repo> --json number,title,isDraft,mergeable,mergeStateStatus,additions,deletions,headRefName,reviewDecision,createdAt
```

## 2. Classify each PR

| Class | Signal | Action |
|---|---|---|
| **Empty / stray** | `additions==0 && deletions==0`; stray `claude/*` branch, no content | **Close** (safe) |
| **Moot / superseded** | targets a migrated/dead repo, or the change is overtaken by events | **Close** (safe) with a reason |
| **Mergeable-clean engineering** | `mergeable=CLEAN`, reviewed, low-risk (docs/tooling), CI green | **Merge** per [ADR 0015](../../decisions/0015-standing-agent-authority-and-auto-merge.md) (auto-merge *green* work) |
| **Needs-review** | touches prod/auth/secrets/migrations, OR no visible CI, OR `CONFLICTING`/`draft` | **Do not auto-merge.** Read the diff (`gh pr diff`), summarize, surface for explicit approval |

## 3. Act - safe vs asks-first (framework principle F)

- **Close dead PRs** (empty/moot): runs unattended. Always give a reason for the audit trail:
  `gh pr close <n> --repo SchnappAPI/<repo> --comment "<why>"`
- **Merge** (gated): `gh pr merge <n> --repo SchnappAPI/<repo> --merge --delete-branch`.
  Never blind-merge a production or security change - review the diff first. The auto-mode safety
  classifier **will deny** merging a PR the agent did not open unless the owner **specifically
  authorizes that PR** ("merge #N"); expect it, surface the PR for one-tap approval, do not try to
  bypass it.

## Cross-surface fallback

- **Code:** `gh` as above.
- **web / iPhone / Cowork:** no `gh`. Use the **GitHub connector** (github-mcp = GitHub's official
  MCP server, fronted by the Schnapp Portal - ADRs
  [0020](../../decisions/0020-portal-front-mac-github-mcp.md),
  [0036](../../decisions/0036-github-mcp-official-swap.md); official tool names, e.g.
  `pull_request_read` and its write counterpart): list PRs, close/merge
  through it. If the connector is absent, **generate a ready-to-run `gh` prompt** for a Code session and
  hand it over (always-complete: never silently skip).

## Rules

- Read + classify freely; mutations follow safe-vs-asks-first. Closing is reversible (reopen); merging
  to a production repo may trigger a deploy - treat it as the asks-first action.
- **Always-complete honesty:** if the token cannot read a signal (e.g. checks), say so per repo; never
  let an unreadable check look green.
- Do not delete a branch the `sync/unmerged` routine flags as **unmerged** (real work). pr-sweep retires
  the PR object; branch-level residue is that routine's job.
- End state to report: a one-line verdict and the open-PR count org-wide (target: 0, or N awaiting a
  named merge decision).
