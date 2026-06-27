# 0015 — Standing agent authority + auto-merge

Date: 2026-06-27. Status: DECIDED by owner (explicit grant).

## Context
Through the loops build the owner approved each merge and many actions individually. The owner
explicitly granted standing authority: "want all pull requests to auto merge and for you to have full
access to do the actions necessary to carry out what I ask. consider this the explicit permission."

## Decision
1. **Act without per-action confirmation.** The agent carries out the actions necessary to fulfil a
   request — create branches, push, merge, run Mac/GitHub/op actions — without pausing for approval on
   each step. Genuinely consequential or irreversible/outward actions are still surfaced briefly, but
   the default is to act.
2. **Auto-merge green PRs.** Engineering/build PRs that pass CI are merged directly (no waiting for a
   per-PR "go"). True unattended GitHub-native auto-merge additionally needs the repo setting
   *Settings → General → Pull Requests → Allow auto-merge* enabled (owner action; the API cannot set it).

## The one carve-out: self-edit PRs stay gated (recommended)
Auto-merging **`self-edit/*`** PRs (the learning loop's own rule/fact rewrites) is NOT enabled by this
grant by default, because it removes the human/eval review the gate exists for — "a learning loop
without the eval gate learns confident junk" (decision doc §7.8; ADR 0012/0013). A live example: the
loop's first real run produced TWO PRs for the same rule (#19/#21); auto-merging both would have
duplicated a rule on main. Self-edits remain reviewed (by the owner, or a future eval agent using the
`learning-eval` recurrence signal) until the owner explicitly opts into auto-merging them too.

## Consequences
- The agent stops asking "should I merge?" for build PRs and acts on standing authority.
- Self-edit PRs are still opened by the loop but wait for review; the next learning-loop increment
  (dedupe captures against open self-edit PRs / recent promotions; auto-approve low-risk via the eval
  gate) is the path to safely auto-landing them later.
- Revocable: the owner can narrow or withdraw this at any time.
