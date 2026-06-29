# 0017 — Claude Code on the web sessions target `main` directly

Date: 2026-06-29. Status: DECIDED by owner.

## Context
ADR 0016 made the repo main-only (no branches, no PRs). But **Claude Code on the web** defaults to
running each session on its own per-session branch (`claude/<name>`), and the web environment/trigger
here was configured with an explicit `Develop on branch claude/...` directive. The owner routinely
starts a fresh web session whenever a connector / network-allowlist / tool config change must take
effect (config is read at session start). Each of those sessions created a branch; sessions that ended
without merging left the branch behind. By 2026-06-29 **14 stray branches** had accumulated
(`claude/*` ×12, `self-edit/*` ×2). Analysis showed all 14 were already merged into `main` or were
superseded duplicates — **zero lost work**, but persistent litter that obscured real state and
contradicted ADR 0016.

## Decision
1. **Web sessions commit directed work straight to `main`**, like every other surface (ADR 0016) — no
   per-session `claude/*` branch.
2. **Enforcement is the web environment / trigger configuration** (owner-set, in the Claude Code web
   UI): the environment's working branch is `main` and the per-session-branch default is not used.
   This is a surface-config knob, not a repo file, so it is an **owner step** — the repo records the
   policy; the owner applies the toggle.
3. **Backstop: the `sync/unmerged` scheduled routine now surfaces ALL non-`main` branches**, classified
   as *unmerged* (review before retiring) vs *merged residue* (safe to delete). It never deletes
   (safe-class), but it makes stray session branches visible so an approved session can sweep them with
   `git push origin --delete <branch>`. This catches any branch that slips through regardless of the
   surface that created it.

## Why this is safe
- Under ADR 0016 the only review surface is the owner in real time + CI on the push to `main`; a web
  session committing to `main` gets the same treatment as a Code-on-Mac session. No review surface is lost.
- The 2026-06-29 sweep was verified non-destructive (every deleted branch's content confirmed already
  on `main`, tip-vs-tip), so the policy starts from a clean slate.
- Branch deletion cannot be done from the cloud env (its git proxy 403s pushes); it is run on the Mac
  (working push creds) or via an approved session. The routine only *reports*.

## Consequences
- No more cross-session branch residue; `main` is the single live branch on every surface.
- Refines ADR 0016 (main-only) by closing the web-session branch loophole; refines the
  `sync/unmerged` routine (`scheduled-tasks/sync-unmerged-check.md`) to flag merged residue, not just
  unmerged work. Recorded fact: [[mac-cloud-access]] (the allowlist fix that re-enabled this session's
  Mac access), `memory/owner-working-preferences.md` #7.
