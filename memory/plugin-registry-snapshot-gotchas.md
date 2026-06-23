---
name: plugin-registry-snapshot-gotchas
metadata:
  node_type: memory
  scope: global
  source: "this session (observed 2026-06-23, handoff 035 loop live-proof)"
  updated: 2026-06-23
  supersedes: ""
  originSessionId: code-2026-06-23-loops-liveproof
---

Two durable Claude-plugin tooling gotchas, both of which bit while fixing the stale
`claude-kit SESSION-START GATE` double-fire. Handoff 034 mis-called this "cosmetic"; it was not.

1. **`claude plugin uninstall <name>@<marketplace>` resolves by plugin NAME, ignoring the
   `@marketplace` suffix.** With two installs of the same plugin name from different marketplaces
   (here `claude-kit-core@claude-kit` and `claude-kit-core@schnapp-os`), `uninstall ...@claude-kit`
   removed the ENABLED/live `@schnapp-os` one instead. To remove a specific duplicate, hand-edit
   `~/.claude/plugins/installed_plugins.json` (delete that exact `name@marketplace` key); don't trust
   the CLI to disambiguate.

2. **The Claude desktop local-agent-mode harness snapshots each enabled plugin from its PINNED
   commit, not the working tree.** Snapshot lands in
   `~/Library/Application Support/Claude/local-agent-mode-sessions/<id>/.../rpm/plugin_*/`, built from
   the `gitCommitSha` in `installed_plugins.json`. So a plugin pinned to an OLD commit keeps firing
   whatever hooks that commit's `hooks.json` declared, even after repo HEAD emptied them. The stale
   gate fired because `claude-kit-core@schnapp-os` was pinned at `8417c2c4` (pre-hook-move), whose
   `hooks.json` still declared SessionStart+Stop; it ran the old bare `git pull --ff-only` which raced
   the project-settings gate's pull on `FETCH_HEAD` → "Cannot fast-forward to multiple branches" in
   BOTH gates. `claude plugin update` is VERSION-keyed (no-ops when plugin.json version is unchanged,
   so it won't re-pin across commits at the same `0.1.0`). To force a re-pin to HEAD:
   `claude plugin uninstall` then `claude plugin install <name>@<marketplace>` (reinstall reads the
   directory source at current HEAD). Effect applies at the NEXT session start (fresh snapshot), so
   verification is always next-restart. Permanent class-fix = drop the plugin packaging entirely
   (decision 0011 #2, repo-flattening); until then, re-pin after any hook/structure change.
</content>
</invoke>
