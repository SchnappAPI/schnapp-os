# Handoff 039 — silent-stop monitoring + native alerting stack shipped; iMessage dropped

Resume point after [038](038-mac-access-restored-sessions-reconciled.md). This session built the full
silent-stop monitoring + alerting stack and the root CLAUDE.md, then hardened it via an adversarial
review. Everything is on `main`, CI green, **0 open issues / 0 open PRs**.

## What shipped (all on main)
- **Root [CLAUDE.md](../CLAUDE.md)** — thin, reference-only agent front door (dogfoods `templates/project-CLAUDE.md`); linked from the README map.
- **Owner preference captured** — commit + push to `main` automatically by default; never leave open PRs ([owner-working-preferences](../memory/owner-working-preferences.md) #7).
- **[pr-sweep](../plugins/core/skills/pr-sweep/SKILL.md)** skill — on-demand org-wide open-PR triage. Cleared 3 stray org PRs (closed 2 dead, merged schnapp-bet #2 fail-closed-secrets fix).
- **Backup P0 verified RESOLVED** — `bet.schnapp.bacpac-backup` armed Sun 05:00, ran 2026-06-30 (the "55-day gap" was the old `sports-modeling` DB name; renamed `schnapp-bet` is current).
- **infra-health probe INSTALLED + upgraded** — `com.schnapp.infra-health`, **every 30 min**. Checks: expected LaunchAgents, backup freshness, mssql, MCP ports, **+ a gh-auth self-check**. On RED → opens an owner-assigned **GitHub issue → email + GitHub mobile push**, deduped (one issue/incident, no comment spam), auto-closes on recovery. Pure-bash dependency-free detection; alerting best-effort via [ops-alert.sh](../plugins/core/scripts/ops-alert.sh) + [notify-ops.sh](../plugins/core/scripts/notify-ops.sh) (ntfy) + macOS notification.
- **mac-liveness dead-man's-switch** — [.github/workflows/mac-liveness.yml](../.github/workflows/mac-liveness.yml), GitHub Actions cron every 30 min (Mac-independent), pings `schnapp.bet`; Mac-dark → GitHub issue, auto-closes. Spec: [scheduled-tasks/mac-liveness.md](../scheduled-tasks/mac-liveness.md).
- **Review hardening** (ce-correctness-reviewer): notify-ops `--data-raw`; bash-3.2 empty-array guard; jq `key` sanitize; anchored liveness dedup; verified gh-under-launchd works and made it explicit (`GH_TOKEN` in ops.env) + monitored (the self-check).
- **iMessage DROPPED** — self-sent iMessages don't notify (Apple limitation), so they can't page. GitHub mobile push + email cover the phone.

## Alerting architecture (how the owner gets paged)
Every failure → an owner-assigned **GitHub issue** → **email** (Mail/Gmail app push) **+ GitHub mobile app push**. Two watchers, both every 30 min: **infra-health** (on the Mac — a service/agent/backup down) and **mac-liveness** (in the cloud — the Mac itself dark, the watcher-of-the-watchdog). ntfy + macOS notification are optional, transition-only secondaries.

## Owner-optional (NOT pending — system is complete without it)
**Cloudflare Tunnel Health Alert** (free, ~2 min): dash.cloudflare.com → Notifications → Add → *Tunnel Health Alert* → Email → the Mac's tunnel. Event-driven (seconds) complement to `mac-liveness` for Mac-dark.

## Mac-local config (not in the repo)
`~/.config/schnapp-os/ops.env` (chmod 600): `NTFY_URL` (optional ntfy topic) + `GH_TOKEN` (explicit gh auth for the alert path). `OPS_IMESSAGE_TO` removed.

## Copy-paste primer for a fresh session
> Resuming schnapp-os after handoff 039. The silent-stop monitoring + alerting stack is live: **infra-health** (on the Mac, every 30 min) and **mac-liveness** (cloud dead-man's-switch, every 30 min) both open auto-closing **GitHub issues → email + GitHub mobile push** on failure. Root `CLAUDE.md` is the front door. Standing rule: auto commit+push to `main`, never leave open PRs. Everything is on main, CI green, 0 open issues/PRs. Only optional item: Cloudflare Tunnel Health Alert (owner dashboard, ~2 min).
