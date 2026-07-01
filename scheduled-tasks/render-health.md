# Routine: Render connector health (heartbeat + keep-warm)

- **Class:** safe (probe) - read-only HTTP `/health` pings; no remediation.
- **Implementation:** [`.github/workflows/render-health.yml`](../.github/workflows/render-health.yml) - pure
  GitHub Actions + `curl` + `gh`. No secrets (built-in `GITHUB_TOKEN`), no Mac-side install.
- **Scheduler:** GitHub Actions `cron` every 30 min (+ `workflow_dispatch`). **Mac-independent by design**: 
  it runs on GitHub's infra, so it stays up to watch the cloud connectors regardless of the Mac.
- **Why it exists:** [`op-mcp`](../connectors/op-mcp/) and [`memory-mcp`](../connectors/memory-mcp/) are the
  two **Render-hosted** connectors - the off-Mac credential + memory paths for claude.ai web / iPhone / Cowork.
  The on-Mac [`infra-health`](infra-health.md) probe only watches Mac-local services, so a Render sleep/crash was
  the one **unmonitored** surface (silent-stop gap, surfaced by the 2026-06-30 substrate-rethink review). This
  loop closes it.
- **What it checks:** `https://op-mcp.onrender.com/health` and `https://memory-mcp-rtad.onrender.com/health`;
  each returns `200 {"status":"ok",...}` when up. Free-tier services sleep after ~15 min idle, so a waking
  container may `502/503` briefly - the probe retries up to ~105s (3× / 25s timeout / 10s sleep) before calling
  it down. The ping itself **doubles as a keep-warm**, killing the ~30-60s cold start for the next real caller.
- **On DOWN (either service):** opens a GitHub **issue** assigned to the owner - a **native email alert, no app
  to install**: using *open-issue-as-state* (dedups by the `[render-health]` title token) and exits non-zero.
  **On recovery:** comments + **auto-closes** the issue.
- **Distinct from [`mac-liveness`](mac-liveness.md):** that watches the **Mac** platform; this watches the
  **Render** connectors. A down Render service is not a Mac outage, so it carries its own issue title - the two
  alarms never get confused.

## Owner setup

None to install. The alert lands in your inbox via GitHub's own notification setting (you are the issue
assignee). Test either path with `gh workflow run render-health.yml -f simulate=down` (opens + emails) and a
normal run recovers + closes.
