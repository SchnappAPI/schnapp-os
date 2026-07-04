# 0033 - Portable shell: user-scope wiring over live clones, plugin rejected again

Date: 2026-07-03. Status: ACCEPTED. Reopens decisions/0011 #2's hook scoping (cross-repo is now
the requirement) while keeping its plainer-repo intent; honors decisions/0005's scope boundary;
confirms decisions/0024 with fresh evidence. Plan:
`docs/superpowers/plans/2026-07-03-portable-shell.md`.

## Requirement
One thin, portable structure that wires ANY session in ANY repo to the two live repos, carrying
no content of its own:
- **Link A (read, live)**: rules, guard + behavioral hooks, skills, agents load FROM the live
  `~/code/schnapp-os` clone; an edit there is visible to the next session in any repo, no
  reinstall. Something portable must also keep the clone itself fresh in every repo.
- **Link B (read/write)**: every session reads memory from `~/code/schnapp-vault` and writes back
  per `docs/memory-lane.md` + the vault `agents.md` schema, pushed so GitHub mirrors local.

## Capability facts verified this session (method in parens)
1. **Plugin install ALWAYS snapshots to `~/.claude/plugins/cache/<mkt>/<plugin>/<version>`, even
   from a directory-source local marketplace** (live test: scratch marketplace + plugin; edit to
   the live source did not propagate; `plugin update` no-oped at unchanged version. Docs:
   plugins-reference "copies ... to the plugin cache rather than using them in-place"). Live-read
   plugin delivery does not exist. Plugins also cannot set settings keys (`autoMemoryDirectory`)
   or deliver always-loaded context.
2. **User-scope `~/.claude/settings.json` hooks with absolute paths fire in EVERY repo** (live:
   standing-rules/capture-nudge precedent at UserPromptSubmit; SessionStart probe fired from a
   foreign repo this session; SessionStart stdout injection is documented and observed).
3. **`~/.claude/skills/` loads a symlinked skill from a live path** (live: the long-standing
   `find-skills` symlink is active in sessions today). User `agents/` + `commands/` are the same
   user-scope mechanism (re-verified live at install).
4. **`autoMemoryDirectory` is already live at user scope** pointing at the vault lane.
5. **Web containers honor PROJECT scope only** (docs: user-scope plugins/settings do not carry to
   web; `~/.claude/CLAUDE.md` on web is UNVERIFIED-BY-DOCS). The per-environment setup script
   runs at environment init (cached ~7 days), can clone extra GitHub repos and write files;
   project `.claude/settings.json` SessionStart hooks DO run on web (`$CLAUDE_CODE_REMOTE`).
   Plugin CLI is unavailable on web.

## Decision
The shell is **native user-scope wiring managed by one idempotent installer**, not a plugin.
New top-level `shell/` (owner-commissioned): `install.sh`, `web-setup.sh`, `README.md`. Wiring
only; every pointer is an absolute path into the live clones.

Per layer (Mac / any machine with a real `~/.claude`):
- **Rules**: `~/.claude/CLAUDE.md` rendered from `templates/user-global-CLAUDE.md` (existing
  `@import` mechanism; live by construction).
- **Hooks** (user scope, absolute live paths): existing UserPromptSubmit pair
  (standing-rules, capture-nudge); NEW SessionStart `hooks/global-session-gate.sh` (ff-only pull
  of BOTH repos in any repo, offline-tolerant, skips inside schnapp-os where the project gate
  already runs, one-line status injected); NEW SessionEnd `hooks/global-vault-push.sh` (vault
  commit+push when the memory lane is dirty; VAULT ONLY, the schnapp-os backup stays
  project-scoped per decisions/0005's wrong-scope warning); PostToolUse
  `hooks/secret-scan-on-write.sh` goes machine-wide (already repo-agnostic; self-skips inside
  schnapp-os to avoid double-fire with the project wiring, which stays for web parity).
- **Skills/agents/commands**: per-item symlinks `~/.claude/{skills,agents,commands}/<name>` into
  `.claude/{skills,agents,commands}/` in the live clone. Installer re-run adds new items and
  prunes dead links.
- **Memory**: `autoMemoryDirectory` (already set) + the SessionEnd vault push close Link B's
  round-trip on Code surfaces.

Per surface:
- **Web**: `shell/web-setup.sh` (canonical here, pasted into the web environment setup) clones
  both repos and runs the same installer against the container `~/.claude`. Whether web honors
  user-scope wiring is the one open empirical question (fact 5); the first web session after
  install verifies it. If web ignores it, the honest boundary stands: web sessions in other repos
  get account-scope MCP + git only, and the container clones still make both repos reachable.
  Setup-script cache staleness (~7d) is mitigated by the SessionStart pull when hooks are honored.
- **Hookless surfaces (claude.ai, iPhone, Cowork)**: memory-mcp IS Link B there (decisions/0027);
  rules/hooks do not reach them; `session-hygiene` stays the manual procedure. The shell adds
  nothing; this boundary is the documented limit, not a gap to paper over.

## Why not a plugin (0024 confronted, not assumed)
The snapshot semantics that killed schnapp-os-core were re-tested today on CLI 2.1.112 and are
structural (fact 1): any plugin-shaped shell reintroduces the stale-plugin-pin class by
construction, plus it cannot deliver the two keys the shell needs (`autoMemoryDirectory`, rules
context). Auto-update (opt-in, version-keyed, session-start) narrows but does not close the gap:
it is still a snapshot with a failure mode, versus symlinks + `@import` + absolute-path hooks
with none. Reopening 0011 #2's "hooks scoped to schnapp-os" changes the SCOPE decision, not the
PACKAGING decision: the repo stays plain, nothing is packaged or copied.

## Consequences
- Per-machine install/repair collapses to: clone both repos, run `shell/install.sh`, accept the
  trust dialog. Templates and docs updated to say exactly that.
- Machine-wide context cost: all skills/agents/commands now list in every session on the machine.
  Accepted per the requirement; `context-budget` owns future curation.
- The leftover `schnapp-os` directory-marketplace registration and plugin cache remnants
  (incomplete 0024 removal, found this session) are deleted with this change.
- `.claude/settings.json` `$comment` claim "cross-surface freshness is the remote-MCP layer's
  job" is superseded for Code surfaces: the global gate now owns it; remote MCP remains the
  hookless-surface layer.

## References
Live tests + docs pulls: this session (scratch marketplace probe, foreign-repo SessionStart
probe, `known_marketplaces.json` audit; code.claude.com/docs plugins-reference,
plugin-marketplaces, claude-code-on-the-web, settings, hooks). Prior art: decisions/0005, 0011,
0024, 0027; handoffs/054.
