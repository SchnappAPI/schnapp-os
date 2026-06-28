# Handoff 037 — Loops LIVE; no-branches + full-capability worker; Mac-autonomy half-wired

**Date:** 2026-06-27. **Supersedes context of:** handoff 036. **State:** both governing loops are
built AND the learning loop has **fired for real** — a real correction became a merged rule on `main`
(PR #21). Since 036 the model shifted hard toward **owner autonomy + no branches**. This handoff packs
everything a fresh session needs to continue without re-deriving it.

## The big picture (what changed since 036)
- **The loop closed for real.** A real correction ("record what failed before retrying") was captured →
  distilled by a headless `claude -p` → gated → merged to `main` (`working-style.md`). Both loops fire.
- **No branches, everything to main (ADR 0016, owner pref 2026-06-27).** All work — mine and the
  learning loop's — commits straight to `main`. Feature branches + PRs are retired.
- **The self-edit gate was reworked from branch+PR → PRE-COMMIT.** `claude -p` writes a proposed `.md`
  edit; the worker runs `learning-gate.sh` on the diff; **clean → commit+push to main; held → a GitHub
  ISSUE** (no branch). Retired: `self-edit-stage.sh`, `self-edit-gate.yml`, their test. Kept:
  `learning-gate.sh` (the vet; hardened against symlink/non-md/provenance-spoof/binary/dup bypasses — 20/20).
- **Worker now runs at FULL capability (owner directive).** `claude -p --dangerously-skip-permissions`
  (all tools incl. Bash, no prompts; the prompt still steers it to the gated edit-only flow). Max
  capability, never blocked.
- **Worker now fires on capture, not a nightly time.** LaunchAgent uses **WatchPaths** on the queue
  file (runs within seconds of any capture) + a 30-min backstop. The 03:17 calendar is gone.
- **ecc-tools removed.** The upsell-bot GitHub App was uninstalled; verified nothing broke (CI green,
  workflows intact, GitHub access intact).

## Decisions this session (all on main)
- **ADR 0012** two-lane self-edit gate → **refined by 0016**.
- **ADR 0013** no standing cloud-agent Mac shell → **0014 enabled** it (connector bearer).
- **ADR 0014** enable autonomous cloud-agent Mac access via the connector `Authorization: Bearer ${MAC_MCP_AUTH_TOKEN}`.
- **ADR 0015** standing agent authority + auto-merge green PRs (self-edits gated).
- **ADR 0016** no branches; autonomous self-edits via pre-commit gate (clean→main, held→issue).
- **anti-stale.md** sharpened: current-state-only docs (overwrite; history → decisions/changelog).
- **owner-working-preferences.md** #7: main-only, no branches.

## OPEN — what the next session must do (in order)
1. **Fix Mac autonomy (blocks everything Mac-side).** The repo `.mcp.json` sends
   `Authorization: Bearer ${MAC_MCP_AUTH_TOKEN}` (the Mac MCP server's `_BearerAuthMiddleware` accepts
   it → ALL tools incl `shell_exec` work). But a fresh-session test returned `unauthorized`. Most likely
   cause: a **duplicate UI-added `Schnapp_Mac` connector shadowing** the `.mcp.json` one (so calls route
   to the unauthenticated instance), or the env var not reaching the connector header. **Owner must
   remove the UI `Schnapp_Mac` connector** (Claude connector settings) so `.mcp.json` is the only one;
   confirm `MAC_MCP_AUTH_TOKEN` is in the **environment** (persistent) config; approve the project server
   once. Then verify: `shell_exec("whoami")` should NOT return `unauthorized`.
2. **Re-install the LaunchAgent on the Mac** (it changed: WatchPaths + full-capability + ANTHROPIC_API_KEY
   ref). Steps in `scheduled-tasks/README.md` — substitute `__REPO__`/`__HOME__`/`__CLAUDE_TOKEN_REF__`
   (= `op://web-variables/ANTHROPIC_API_KEY/credential`), `touch` the queue file, `launchctl unload+load`.
3. **Verify the worker's NEW live path end-to-end** — it is UNTESTED against `claude` (only the gate +
   dry-run are CI-tested). Seed a real correction, let the worker run (or `launchctl start`), confirm it
   commits a clean rule to main OR opens a review issue, and that main isn't broken.
4. **Delete the 14 stale branches** (this env's git proxy can't; run on the Mac):
   `cd ~/code/schnapp-os && git fetch -p && git for-each-ref --format='%(refname:short)' refs/remotes/origin | grep -vE 'origin/(main|HEAD)$' | sed 's#origin/##' | xargs -I{} git push origin --delete {}`

## Key facts / locations
- **Auth:** the worker authenticates `claude -p` with **`ANTHROPIC_API_KEY`** resolved from
  `op://web-variables/ANTHROPIC_API_KEY/credential` (launchd can't read the Keychain — see
  `docs/headless-claude-auth.md`). `MAC_MCP_AUTH_TOKEN` is in the cloud env (len 64).
- **Loop files:** capture = `plugins/core/hooks/capture-nudge.sh` → git-ignored
  `scheduled-tasks/.learning-queue.tsv`. Worker = `plugins/core/scripts/learning-worker.sh`. Gate =
  `plugins/core/scripts/learning-gate.sh` (+ tests). Eval report = `learning-eval.sh`. Classifier skill
  = `plugins/core/skills/learn-route/SKILL.md`. LaunchAgent = `scheduled-tasks/com.schnapp.memory-consolidation.plist`.
- **Mac MCP server source:** `connectors/mac-mcp/server.py` (privileged tools gated by `_check_token`,
  which the Bearer header satisfies). Connector reaches it via `mac-mcp.schnapp.bet/mcp`.
- **Conventions:** commit straight to main, no branches/PRs (ADR 0016). Standing authority to act +
  merge without asking (ADR 0015). Concise/actionable replies; automate don't tell; current-state-only
  docs (owner-working-preferences.md).
- **Worker run time:** empty queue <1s; with captures ~30–120s.

## What is DONE and verified
- Phases 1–4 + eval gate, all on main, CI green. Loop fired for real (PR #21 merged).
- `docs/headless-claude-auth.md` = the auth troubleshooting bible.
- ecc-tools removed, no breakage (verified: get_me, workflow list, a dispatched scheduled-routines run = success).
