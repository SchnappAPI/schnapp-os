# Routine: Mac liveness (dead-man's-switch for the watchdog)

- **Class:** safe (probe) — read-only HTTP pings; no remediation.
- **Implementation:** [`.github/workflows/mac-liveness.yml`](../.github/workflows/mac-liveness.yml) — pure
  GitHub Actions + `curl` + `gh`. No secrets (built-in `GITHUB_TOKEN`), no Mac-side install.
- **Scheduler:** GitHub Actions `cron` every 30 min (+ `workflow_dispatch`). **Mac-independent by design** —
  it runs on GitHub's infra so it stays up precisely when the Mac does not.
- **Why it exists:** it is the answer to "who watches the watchdog." [`infra-health`](infra-health.md) runs
  *on* the Mac, so it cannot report that the Mac (or its own LaunchAgent) went dark. This outer loop proves
  the Mac platform is alive from outside it. Closes infra-health residual #1.
- **What it checks:** `https://schnapp.bet` (served by the Mac `web-prod` LaunchAgent); HTTP 200-499 = the
  origin answered = **up**. A connection failure, `000`, or a Cloudflare origin-down 5xx = **down**
  (3 retries ride out a blip). `https://mac-flask.schnapp.bet` is the secondary signal.
- **On DOWN:** opens a GitHub **issue** assigned to the owner — a **native email alert, no app to install** —
  using *open-issue-as-state* (one open issue at a time; dedups by the `[mac-liveness]` title token) and exits
  non-zero (a red scheduled run is a second native signal). **On recovery:** comments + **auto-closes** the issue.
- **Alerting choice:** GitHub issue → email is deliberately native (owner preference: nothing to download). This
  is independent of the on-Mac `notify-ops.sh`/ntfy push, which remains the optional finer-grained channel.

## Coverage and the remaining edge

Catches the dominant case: the Mac off / asleep / tunnel down / `web-prod` crashed — which is exactly when
`infra-health` is also not running. It does **not** catch "the Mac is fully up and serving, but the
`com.schnapp.infra-health` LaunchAgent specifically got unloaded." That edge is rare (the Mac serves
production, so it stays awake) and is an optional upgrade: have the cron additionally call the Mac MCP
(`service_status`) each run — that needs `MAC_MCP_AUTH_TOKEN` as a repo secret and the tunnel up, so it is
left as a documented enhancement, not wired.

## Owner setup

None to install. The only thing that makes the alert land in your inbox is GitHub's own notification setting —
see the run-instructions handed over when this was built (Settings → Notifications; you are the issue assignee).
