# Handoff 058: single-registrar component move (.claude/{skills,agents,commands} -> repo root)

Date: 2026-07-13. Surface: Claude Code web (same session as 057, resumed). Prior: [057](057-setup-audit-and-fix-pass.md).

## Goal
Execute the first queued item from 057: kill the skill double-registration by making the portable
shell the single registrar.

## Decisions + reasoning
- Canonical component roots moved to repo top level: `skills/`, `agents/`, `commands/`.
  `.claude/` now carries wiring only (settings.json, README). Rationale: anything under
  `.claude/{skills,commands}` auto-loads at PROJECT scope inside schnapp-os while the shell's
  user-scope symlinks load the same components everywhere, so every schnapp-os session listed
  every skill and command twice (~11KB duplicated trigger text). Agents moved too for uniformity
  (they deduped by name, but one rule beats two).
- Delivery to main from this branch-pinned session: local verified commits pushed to the pinned
  claude/* branch as TRANSPORT, Mac fast-forwards main to the exact SHA, pushes, deletes the
  branch immediately (per the CLAUDE.md always-merge playbook).

## Actions + outcomes
- 33 git renames; link depth inside moved files shifted (skills 3-up -> 2-up, agents/commands
  2-up -> 1-up; verified no 4-up links existed first).
- Updated the movers and readers: shell/install.sh (symlink source = repo root), hooks/
  global-session-gate.sh (heal loop), scripts/gen-catalog.sh, scripts/gen-claude-ai-skills.sh,
  scripts/scan-secrets.sh comment, scripts/tests/test-shell-install.sh,
  scripts/tests/test-global-session-gate.sh (os-side fixtures only; user-scope ~/.claude fixture
  paths unchanged), 13 live markdown files, .claude/README.md rewritten as wiring-only.
- Regenerated CATALOG.md + surfaces/claude-ai-skills.md.
- Verified: check-links 401 OK, writing-style OK, freshness OK, scan-secrets 0 BLOCK,
  test-shell-install 27/27; installer run against a temp HOME links 29 components (21 skills,
  4 agents, 4 commands) with symlinks resolving to the new top-level roots.
- test-global-session-gate: 12/14 here, same 2 failures on the UNTOUCHED tree - environmental
  (this container's proxied git breaks the test's local bare-repo push); green in CI.

## Status + next steps
- After merge: Mac re-runs shell/install.sh (relinks 29 components to the new paths, prunes the
  29 old ones). Next schnapp-os session on any surface lists each skill once.
- Next queued work (from 057): the memory-mcp write-path fix (preserve frontmatter verbatim
  except updated:, replace-by-slug idempotent index update); then the owner's meta-freeze week.

## Open questions / edge cases (owner-only)
- claude.ai live-read: surfaces/claude-ai-skills.md regenerated with the new paths, but if any
  claude.ai project config pins raw GitHub URLs to `.claude/skills/...`, repoint them to
  `skills/...` (one-time spot check).

## Copy-paste primer (new session)
Components live at repo root (skills/, agents/, commands/); .claude/ is wiring only; the portable
shell is the single registrar, so skills list once everywhere. Resume queue: memory-mcp write-path
fix (specced in handoff 057), then object work (meta-freeze week).
