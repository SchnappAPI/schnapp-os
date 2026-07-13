<!--
  CANONICAL COPY of what goes in each machine's ~/.claude/CLAUDE.md. That file lives OUTSIDE the
  repo (it is per-machine), so this tracked template is its single source - shell/install.sh
  renders the body (everything below this comment, repo path resolved per machine) into
  ~/.claude/CLAUDE.md; to install or repair a machine, run the installer (ADR 0033).

  Why @import and not a symlink: ~/.claude/CLAUDE.md @imports the global rules straight from the
  repo, so they load in every project and stay current via the SessionStart `git pull`.
  A `~/.claude/rules/` symlink was deliberately skipped (that path is itself an auto-load level, so
  symlink + @import would double-load). @import has no glob support, so the files are listed
  explicitly - if the global rule set in rules/global/ changes, update this list AND
  every machine's ~/.claude/CLAUDE.md together (the current set is in CATALOG.md).
-->
# Global instructions (this machine)

Single source of truth for the always-on global rules is the schnapp-os repo:
`~/code/schnapp-os/rules/global/`. These load in every project on this
machine and stay current via the repo's SessionStart `git pull`.
Edit the files in the repo, never here. Path-scoped language/tool/activity modules are
NOT global - they live in `rules/modules/` as a plain reference library; a project
`@import`s only the ones it needs (no gallery/preset/composer - removed per decisions/0011 #4).

@~/code/schnapp-os/rules/global/working-style.md
@~/code/schnapp-os/rules/global/acting-autonomously.md
@~/code/schnapp-os/rules/global/knowledge-capture.md
@~/code/schnapp-os/rules/global/naming-discipline.md
@~/code/schnapp-os/rules/global/secrets-as-references.md
@~/code/schnapp-os/rules/global/verify-before-asserting.md
@~/code/schnapp-os/rules/global/anti-stale.md
@~/code/schnapp-os/rules/global/context-discipline.md
@~/code/schnapp-os/rules/global/writing-style.md
