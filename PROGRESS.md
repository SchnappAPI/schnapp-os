# claude-kit — execution log

Append one line per step: date, step, what changed, why. Newest at the bottom of each day.

## 2026-06-03
- Part 0.2: scaffolded local repo (decisions/, handoffs/, plugins/core/hooks/); git init; branch `main`.
- Part 0.2: added PLAN.md (exact copy of the approved master plan), PROGRESS.md, .gitignore, README.md.
- Part 1.1 (pulled early): inventoried credential/auth state. See decisions/0001.
- BLOCKER: 1Password Service Account is deleted. `op`/`gh`/launchd secret resolution down.
  git over SSH and the GitHub MCP OAuth connector are healthy. Details in decisions/0001.
- Part 0.1 (remote): repo creation pending. Needs owner to create empty private
  `SchnappAPI/claude-kit` (then I push over SSH), OR SA rotation so `gh repo create` works.
  Local commits are ready.
- Corrected PLAN.md Part 4.1 (recreate SA, not verify). Wrote handoffs/000-setup.md.
- Saved memory: secrets-sa-deleted-20260603, claude-kit-rebuild (+ MEMORY.md index).
- Part 2.1: wrote global rules under plugins/core/rules/global/ (working-style,
  knowledge-capture, naming-discipline, secrets-as-references, verify-before-asserting,
  anti-stale, speed-by-default), seeded from the owner's engineering notes.
- Owner created PRIVATE repo SchnappAPI/claude-kit. Pushed main (3 commits). Verified private.
- Part 0 DONE (repo + tracker + remote live). Sync-hook automation (0.3) deferred to Part 7
  (needs hooks wired); manual push works now.
- Pending owner: Part 1 keep-set approval before disabling plugins.
- Part 4 (partial): owner ROTATED the 1Password SA. `op whoami` OK, `gh` works again.
  Note: SchnappAPI is a USER not an org, so GitHub Actions token is a per-repo secret.
- Part 3.1/3.2: built rule module gallery under plugins/core/rules/modules/ (coding x3,
  lang x8 incl. path-scoped python/ts/sql/pq + env/git/gha + naming-differences reference,
  tool x2 stubs, activity x4 [etl seeded, rest stubs], context x2) + presets/presets.md.
- Part 3.3: wrote /new-project composer command (preset + free pick, symlink modules).
- Part 2.3: wrote surfaces/ profiles (README + code-mac, code-work-machines, cowork,
  claude-ai-web, iphone) with the always-complete fallback model.
- Pushed. Parts 2 and 3 substantively done (2.2 ~/.claude wiring + 3.4 verify still pending).
- Part 4 (decisions): recorded cross-surface credential options (decisions/0002): all-repos
  token needs an org or per-repo script; off-Mac 1Password = host connector on Cloudflare.
- Part 1 DONE: tagged schnapp-kit record-2026-06-03; disabled schnapp-kit + 12 redundant
  plugins; kept 6 (caveman, github, superpowers, plugin-dev, pyright-lsp, frontend-design).
  schnapp-kit is now a source repo to dissect (decisions/0003). settings.json backed up.
  Verify quiet runtime next session.
