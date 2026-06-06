---
description: Prune local branches whose remote was deleted ([gone]) and remove their worktrees
argument-hint: ""
---
# /clean-gone

Safe cleanup util. The default workflow is to work on `main` with rare, approval-gated branches
([git module](../rules/modules/lang/git.md)), so leftover `[gone]` branches (merged and deleted
on the remote) accumulate. This prunes them and any attached worktrees.

Steps Claude follows:

1. Refresh remote-tracking state so `[gone]` is current: `git fetch --prune`.
2. List branches and their status: `git branch -v`. A `+` prefix means an attached worktree,
   which must be removed before the branch can be deleted.
3. For each `[gone]` branch, remove its worktree (if any), then delete the branch:
   ```bash
   git branch -v | grep '\[gone\]' | sed 's/^[+* ]//' | awk '{print $1}' | while read branch; do
     worktree=$(git worktree list | grep "\[$branch\]" | awk '{print $1}')
     if [ -n "$worktree" ] && [ "$worktree" != "$(git rev-parse --show-toplevel)" ]; then
       git worktree remove --force "$worktree"
     fi
     git branch -D "$branch"
   done
   ```
4. Report which worktrees and branches were removed. If none were `[gone]`, say no cleanup was
   needed.
