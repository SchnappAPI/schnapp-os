# Plan: portable shell (two live links, any repo, any surface)

Date: 2026-07-03. ADR: [0033](../../../decisions/0033-portable-shell-user-scope-wiring.md).
Resume point: handoffs/054. Success = Link A (schnapp-os -> every session, live read) and
Link B (every session <-> vault, round-trip) verified from a NON-schnapp-os repo.

- [x] T1 Verify capabilities (plugin snapshot semantics live-tested; user-scope hook reach
  live-tested; web scope semantics from docs) + write ADR 0033 + this plan.
- [x] T2 Build wiring: `hooks/global-session-gate.sh` (any-repo ff-only pull of both repos,
  offline-tolerant, skips inside schnapp-os, one-line injected status),
  `hooks/global-vault-push.sh` (SessionEnd: vault commit+push when dirty, vault only),
  plus `hooks/global-secret-scan.sh` + `hooks/global-force-push-guard.sh` (user-scope
  delivery wrappers for the two guards, self-skip inside schnapp-os), self-tests under
  `scripts/tests/`. Verify: 3 new tests (10+8+21 checks) + full suite green, shellcheck clean.
- [x] T3 Build shell: `shell/install.sh` (idempotent: renders `~/.claude/CLAUDE.md` from
  template, merges user-scope settings keys incl. hooks + `autoMemoryDirectory`, symlinks
  skills/agents/commands, prunes dead links, prints verify summary), `shell/web-setup.sh`
  (clone both repos + run installer in container), `shell/README.md` (pointer-style).
  Verify: dry-run mode output correct; installer re-run is a no-op second time.
- [x] T4 Install on this Mac + sweep the ripple: installer run live (5 hook events wired, 33
  components linked, CLAUDE.md rendered w/ 9 imports); stale `schnapp-os` marketplace
  registration + `~/.claude/plugins/cache/schnapp-os` remnants deleted (0024 leftover);
  `.claude/settings.json` `$comment`, `hooks/README.md`, root `CLAUDE.md` hooks bullet,
  `templates/README.md` + template header, `docs/memory-lane.md` (global vault push), root
  README map + install steps all updated; CATALOG regenerated. Verify: check-freshness,
  check-links (375), check-writing-style green.
- [ ] T5 Live-verify both links from a non-schnapp-os repo: SessionStart gate fires + pulls +
  injects there; symlinked skill/agent resolves; skill-name collision behavior checked inside
  schnapp-os (project + user same name); memory write lands in the vault and the SessionEnd
  push reaches GitHub; a rule edit in schnapp-os is visible to the next foreign-repo session.
  Web leg: setup script delivered + first-web-session verify steps written (owner runs; user
  scope on web is the open question per ADR fact 5).
