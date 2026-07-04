# shell/ - the portable shell (wiring only, no content)

One thin structure that links any session, in any repo, to the two live repos (ADR
[0033](../decisions/0033-portable-shell-user-scope-wiring.md)): schnapp-os supplies rules,
hooks, skills, agents; schnapp-vault is the memory. Everything here writes POINTERS
(symlinks, `@import`s, absolute-path hook commands) into `~/.claude`; nothing copies content,
so nothing snapshots and nothing goes stale.

- [install.sh](install.sh) - install/repair a machine: renders `~/.claude/CLAUDE.md`, merges
  the user-scope settings keys + hooks, symlinks skills/agents/commands. Idempotent;
  `--dry-run` previews. Per-machine install is: clone both repos, run this, accept the trust
  dialog.
- [web-setup.sh](web-setup.sh) - canonical web-environment setup script (pasted into the web
  env config): clones both repos in the container, runs install.sh there. Web user-scope
  honoring is the ADR's open verify item.
- Global hook scripts live in [hooks/](../hooks/) (`global-*.sh`), not here: hooks/ is the
  canonical hooks home; this directory only wires them.

Surfaces without `~/.claude` (claude.ai, iPhone, Cowork): the shell does not reach them;
memory-mcp is the vault link and `session-hygiene` is the manual procedure (decisions/0027).
