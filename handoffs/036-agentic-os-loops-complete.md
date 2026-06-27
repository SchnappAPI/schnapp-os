# Handoff 036 — Agentic-OS loops: COMPLETE (both loops firing)

**Date:** 2026-06-27. **Picks up from:** handoff 035 (Phase 1 shipped, Phases 2–4 next). **State:** the
four-phase agentic-OS loops build in [docs/superpowers/plans/2026-06-27-agentic-os-loops.md](../docs/superpowers/plans/2026-06-27-agentic-os-loops.md)
is **fully built and merged to main**, and the learning loop is **verified running on the Mac**.

## The objective, met
Both governing loops now self-fire (decision doc §1; 0011 #8 deferred orchestration until both loops fire):
- **Freshness** — knowledge is kept current and grounded: every fact carries provenance (CI-enforced),
  and age (7/30/90-day) is surfaced at SessionStart + nightly. Read-only; nothing auto-edited.
- **Learning** — a correction becomes a reviewed, merged rule/fact the next session loads: captured →
  queued → distilled by a nightly headless `claude -p` → classified → judgment-bearing changes routed
  through the self-edit gate as PRs. Mechanical changes go direct to main (two-lane, ADR 0012).

## What shipped (all TDD, subagent-driven: implementer → adversarial reviewer → fix → merge)
- **Phase 1 — provenance + CI** (handoff 035): `check-memory-frontmatter.sh` + CI gate.
- **Phase 2 — freshness** (PR #10): `lib-frontmatter.sh` (shared parser), `check-stale-facts.sh`
  (7/30/90-day flag, pure-integer date math), wired into the SessionStart gate + nightly report.
- **Phase 3 — self-edit gate** (PR #11): `self-edit-stage.sh` (stages judgment edits to a review
  branch + PR, never touches main — reviewer caught a Critical here and it was fixed), the `learn-route`
  classifier skill, capture-nudge rewire, ADR 0012 (two-lane policy).
- **Phase 4 — learning worker** (PRs #12–#18): capture enqueue (`capture-nudge` → local git-ignored
  queue), `learning-worker.sh` (distill→classify→route via the gate; `--dry-run` testable), the
  `com.schnapp.memory-consolidation` LaunchAgent (nightly 03:17), and the **eval pass**
  (`learning-eval.sh` — recurrence report, PR #18). Phase 4 Task 4 is now built, not deferred.

## The Mac activation (the long tail — all resolved)
Activating the worker on the Mac surfaced a chain of real issues, each fixed + documented:
1. launchd minimal `PATH` (no `claude`) → plist `EnvironmentVariables` PATH (#13).
2. `--allowedTools` swallowed the prompt arg → pass prompt on stdin (#14).
3. launchd can't read the login Keychain → resolve the credential from 1Password at runtime (#15),
   with silent-failure-killing auth logging (#16) and prefix-based env-var auto-select (#17).
4. The OAuth token was rejected (`invalid bearer token`); the API key path is the robust one. The
   worker now uses **`ANTHROPIC_API_KEY`** (`op://web-variables/ANTHROPIC_API_KEY/credential`).
5. The installed plist was missing the credential reference → re-install carried it; **verified
   working**: the worker authenticated, ran `claude -p`, distilled the seeded capture, and correctly
   classified it as a synthetic test (no spurious PR). Full chain confirmed.

**Read this first if the worker ever 401s again:** [docs/headless-claude-auth.md](../docs/headless-claude-auth.md)
— auth precedence, the launchd/Keychain trap, the two 401 meanings, and the fix checklist.

## Decisions recorded this session
- **ADR 0012** — two-lane self-edit gate (mechanical → main; rule-meaning/fact-supersede → PR).
- **ADR 0013** — cloud agents get NO standing shell access to the production Mac; privileged Mac ops
  stay gated. If autonomous Mac ops are ever wanted, inject the bearer at the connector layer + scope it.

## Operational notes
- The worker runs nightly at **03:17** via the LaunchAgent. Logs: `~/Library/Logs/schnapp-os/`.
  Verify health with the `Schnapp_Mac` `service_status` tool (label `com.schnapp.memory-consolidation`).
- The capture queue (`scheduled-tasks/.learning-queue.tsv`) and its archive are **local + git-ignored**;
  only the distilled, reviewed PR is durable.
- Plist changes require a RE-install (`launchctl unload && load`) — launchd runs the copy in
  `~/Library/LaunchAgents/`, not the repo file. (This was a real bug.)

## Nothing outstanding for the loops build
All four phases are merged and the loop is verified live. Possible future increments (not blockers):
- Turn the `learning-eval` recurrence signal into an eval *agent* that auto-approves low-risk staged PRs.
- Pre-existing WARN-only `check-op-refs` finding (`'[^'`) on main — unrelated to the loops; tidy when convenient.
- The unused `CLAUDE_CODE_OAUTH_TOKEN` vault item can be retired (we standardized on `ANTHROPIC_API_KEY`).
