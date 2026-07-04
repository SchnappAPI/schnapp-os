# Handoff 055: Portable shell built, installed, live-verified (ADR 0033)

Date: 2026-07-03. Surface: Claude Code (Mac). Prior: [054](054-agentic-os-optimize-pass.md).

## Goal
Package schnapp-os + schnapp-vault into ONE portable, wiring-only structure so any session in
any repo gets Link A (live read of rules/hooks/skills/agents from the schnapp-os clone) and
Link B (vault memory round-trip, pushed). Design-then-implement; verify capabilities first.

## Facts established (verified, method noted)
- **Plugin delivery is structurally a snapshot** (live test, CLI 2.1.112): a scratch
  directory-source marketplace install copied to `~/.claude/plugins/cache/<v>`; live edits did
  not propagate; version-keyed `plugin update` no-oped. Plugins also cannot set
  `autoMemoryDirectory` or deliver always-on context. Plugin shell rejected; 0024 re-confirmed.
- **User-scope hooks fire in EVERY repo** (live foreign-repo SessionStart probe + the
  standing-rules precedent); SessionStart stdout injects (docs + observed).
- **`~/.claude/skills` loads symlinks live** (find-skills precedent).
- **Web honors project scope only** (docs); env setup script runs at env init (cached ~7d),
  can clone extra repos; project SessionStart hooks run on web (`$CLAUDE_CODE_REMOTE`).
  Whether a setup-script-written `~/.claude` is honored on web: UNVERIFIED-BY-DOCS.
- **0024 removal was incomplete** (found mid-verify): stale `schnapp-os` directory-marketplace
  registration + cache remnants existed; now deleted.

## Decisions
ADR [0033](../decisions/0033-portable-shell-user-scope-wiring.md): shell = native user-scope
wiring managed by an idempotent installer; symlinks + `@import` + absolute-path hooks = zero
snapshots. 0011 #2's hook SCOPE reopened (cross-repo required), packaging intent kept. Vault
push global, schnapp-os backup stays project-scoped (0005 boundary). Hookless surfaces stay
memory-mcp + session-hygiene (0027); the shell does not pretend to reach them.

## Actions + outcomes
Commits 57a4131 (ADR+plan), 565d468 (wiring+installer+tests), 3c328e7 (live install + doc
ripple), vault bdab746 (fact, pushed by the hook itself). Built: `hooks/global-session-gate.sh`
(any-repo pull of both clones + wiring drift check), `hooks/global-vault-push.sh` (SessionEnd
wrapper over vault-autocommit.sh, debounce off), `hooks/global-secret-scan.sh` +
`hooks/global-force-push-guard.sh` (guard wrappers, self-skip in schnapp-os), `shell/install.sh`
(3 layers: CLAUDE.md render, settings merge, 33 symlinks; `--dry-run`), `shell/web-setup.sh`,
3 test files (39 checks). Installed live on this Mac.

**Live verification from a foreign repo (nested `claude -p`, hooks fire pre-auth):**
- Link A: both clones' `FETCH_HEAD` advanced during the foreign-repo session = global gate
  fired + pulled. All 9 rule imports resolve; 33 symlinks point into the live clone.
- Link B: vault fact `portable-shell-live` written, then the foreign-repo session's SessionEnd
  hook auto-committed AND pushed it; origin/main == local HEAD verified. Full round-trip live.

## Open items (owner)
1. **Web env paste**: put `shell/web-setup.sh`'s content into each Claude Code web
   environment's setup script (claude.ai web UI, environment settings), with the environment's
   GitHub access covering both SchnappAPI repos. First web session answers ADR 0033's open
   question: a `[shell]` line at session start = user scope honored on web; none = documented
   boundary stands (clones + MCP only there).
2. **Next interactive schnapp-os session, one look**: skills now exist at BOTH project and
   user scope (same files via symlink). If the skill list shows duplicates, decide dedupe
   (they are byte-identical, so behavior is unaffected either way).
3. **Other machines**: `git clone` both repos + `bash ~/code/schnapp-os/shell/install.sh`
   (replaces the manual ~/.claude wires from 053/054; capture-nudge/standing-rules wiring is
   included in the installer).

## Copy-paste primer (new session)
Portable shell LIVE (ADR 0033, plan docs/superpowers/plans/2026-07-03-portable-shell.md, T1-T4
done, T5 verified on Mac, web leg = owner paste): user-scope wiring links every repo session to
the live clones - global-session-gate pulls both repos + drift-checks symlinks, SessionEnd
global-vault-push closes the memory round-trip (verified: foreign-repo session pushed the vault
to GitHub), guards machine-wide via self-skipping wrappers, 33 skills/agents/commands
symlinked. Install/repair any machine: clone both repos, run shell/install.sh. Plugin packaging
re-rejected on live snapshot evidence. Resume point = this handoff.
