---
description: Red-team the schnapp-os system (portable shell + loops + wiring) - critique, verify live, fix or subtract, ranked findings
---
# /critique-os

Critique and optimize the schnapp-os portable shell + whole-system architecture. Repo is
`~/code/schnapp-os`; resume point is the newest handoff in `handoffs/` (read it, the ADRs and
plan docs it names, `shell/README.md`, and `hooks/README.md` before forming any opinion). You
are the red team, not the builder: find what is weak, wasteful, fragile, or unverified, and
fix or subtract it, not admire it.

## Ground rules
- Verify every claim against the LIVE system before flagging it (run the hooks, read
  `~/.claude/settings.json`, follow the symlinks, check git state). Handoff 054's lesson is in
  force: audit claims get disproven live before action; two of four were wrong last time.
- Confront prior art, don't re-litigate it without NEW evidence: plugin packaging was rejected
  on a live snapshot test (decisions/0033 + 0024), main-only is decided (0016/0017), the vault
  push / backup scope split is decided (0005). Challenging a settled decision requires
  evidence the original decision lacked; otherwise move on.
- Loops before features, subtract before adding (decisions/0011). An optimization that adds a
  moving part must pay for itself.

## Critique dimensions (cover all; rank findings by impact)
1. **Failure modes**: offline Mac, dirty/diverged clone at gate time, two sessions ending
   simultaneously (vault push race), gate latency added to EVERY session start, hook timeout
   killing a mid-flight push, vault pre-commit rejection leaving the tree dirty silently.
2. **Security**: every repo's session can now write+push the memory lane - scoped right?
   Guard coverage gaps (secret-scan fires on Write/Edit only - what about Bash-written
   files?). Force-push guard bypass shapes. Web env vars sitting in environment config.
3. **Context cost**: all shell-delivered skills/agents/commands + rules load in EVERY session
   on the machine. Run the `context-budget` audit; recommend a curation split (global vs
   on-demand) with numbers, not vibes.
4. **Staleness edges**: web env setup cache (~7d) vs the SessionStart pull; symlink drift
   window; drift across machines not yet installed; the duplicate-skill question in
   schnapp-os sessions (project + user scope both carry them) - RESOLVE it, don't re-note it.
5. **Open verification debt**: whatever the newest handoff lists as unverified (e.g. ADR 0033
   fact 5: does web honor user-scope wiring written by the setup script?). Design the
   cheapest decisive test; run it if the surface is available.
6. **Simplification**: anything in `shell/`, `hooks/global-*`, or the installer that
   duplicates an existing mechanism or could be deleted with no capability loss.

## Method + deliverables
- Read-only subagents for file sweeps; keep raw dumps out of the main context.
- Genuinely-close calls: run `grill-me` or `council`, then DECIDE; no menus.
- Defects found = fixed in the same session (working-style rule), each with its verify run.
- Deliverable: ranked findings (evidence + verdict keep/fix/subtract for each), fixes
  committed per state-change discipline (plan-doc box + PROGRESS line in the same commit,
  push immediately), an ADR only if a settled decision is actually reopened, and the next
  handoff as the new resume point. End with the single highest-leverage change you did NOT
  make and why.
