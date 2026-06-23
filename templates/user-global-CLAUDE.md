<!--
  CANONICAL COPY of what goes in each machine's ~/.claude/CLAUDE.md. That file lives OUTSIDE the
  repo (it is per-machine), so this tracked template is its single source — to install or repair a
  machine, copy this file's body (everything below the comment) to ~/.claude/CLAUDE.md.

  Why @import and not a symlink: ~/.claude/CLAUDE.md @imports the global rules straight from the
  repo, so they load in every project and stay current via the SessionStart `git pull` (Part 2.2).
  A `~/.claude/rules/` symlink was deliberately skipped (that path is itself an auto-load level, so
  symlink + @import would double-load). @import has no glob support, so the 7 files are listed
  explicitly — if the global rule set in plugins/core/rules/global/ changes, update this list AND
  every machine's ~/.claude/CLAUDE.md together (the current set is in plugins/core/CATALOG.md).
-->
# Global instructions (this machine)

Single source of truth for the always-on global rules is the schnapp-os repo:
`~/code/schnapp-os/plugins/core/rules/global/`. These load in every project on this
machine and stay current via the repo's SessionStart `git pull` (PLAN.md Part 0.3 / 2.2).
Edit the files in the repo, never here. Path-scoped language/tool/activity modules are
NOT global — they live in `plugins/core/rules/modules/` as a plain reference library; a project
`@import`s only the ones it needs (no gallery/preset/composer — removed per decisions/0011 #4).

@~/code/schnapp-os/plugins/core/rules/global/working-style.md
@~/code/schnapp-os/plugins/core/rules/global/knowledge-capture.md
@~/code/schnapp-os/plugins/core/rules/global/naming-discipline.md
@~/code/schnapp-os/plugins/core/rules/global/secrets-as-references.md
@~/code/schnapp-os/plugins/core/rules/global/verify-before-asserting.md
@~/code/schnapp-os/plugins/core/rules/global/anti-stale.md
@~/code/schnapp-os/plugins/core/rules/global/speed-by-default.md
