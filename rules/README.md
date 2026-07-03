# rules/ - the behavior layer

Two lanes, different load models. Full inventory with scopes: [CATALOG.md](../CATALOG.md)
(generated).

- [global/](global/) - the always-on rules. Loaded in EVERY project on the machine via
  `~/.claude/CLAUDE.md` `@import`s (canonical copy of that file:
  [templates/user-global-CLAUDE.md](../templates/user-global-CLAUDE.md)). This directory is the
  single source; never edit `~/.claude/` directly. Adding/removing a file here means updating the
  template's explicit `@import` list AND every machine's `~/.claude/CLAUDE.md` in the same change.
- [modules/](modules/) - on-demand reference library ([modules/README.md](modules/README.md)).
  Nothing here loads automatically; a project `@import`s what it needs.

Keep global/ lean: every line loads into every session on the machine. The length-advisory hook
warns on bloat; [writing-style.md](global/writing-style.md) is the style contract for rule files.
