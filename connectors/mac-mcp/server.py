"""
mac-mcp/server.py

Remote MCP server for the Schnapp MacBook Pro.
Exposes shell, file, system, Flask, GitHub Actions, SQL, and infrastructure tools to Claude over Cloudflare Tunnel.

Tools:
  shell_exec          -- Run an arbitrary shell command on the Mac.
  read_file           -- Read a file from the filesystem.
  write_file          -- Write content to a file (creates parent dirs).
  mac_info            -- System summary: hardware, OS, disk, uptime.
  flask_status        -- Is the Mac Flask service running?
  flask_restart       -- Restart bet.schnapp.flask launchd agent.
  live_scoreboard     -- Today's NBA game statuses from CDN via Mac Flask.
  live_boxscore       -- Live player stats for a specific game via Mac Flask.
  workflow_trigger    -- Trigger a GitHub Actions workflow by filename.
  workflow_status     -- Check the last run status of a workflow.
  workflow_logs       -- Fetch the last N lines of a workflow run log.
  workflow_list_runs  -- List recent runs for a workflow with status/conclusion.
  sql_query           -- Run a read-only SQL query against the local SQL Server container.
  web_status          -- Check bet.schnapp.web (dev) and bet.schnapp.web-prod (prod) launchd agents.
  service_status      -- Check any launchd agent by label.
  service_restart     -- Restart any launchd agent by label.
  tunnel_status       -- Check cloudflared and all live Schnapp subdomains.
  docker_status       -- Check Colima VM, SQL Server container, and DB connectivity.
  backup_status       -- Show BACPAC backup files, dates, sizes, and retention state.
  site_health         -- Composite check: tunnel + web-prod + Flask + SQL container.
  op_whoami           -- Report the authenticated 1Password service-account identity.
  op_list_items       -- List 1Password item titles/ids (metadata only, no values).
  op_run              -- Run a command with op:// secrets injected; output is value-scrubbed.
  op_inject           -- Render an op:// template to a file on the Mac (content never returned).
  op_read             -- Resolve one op:// ref; always masked (length + last4), never raw.

Start: python server.py
Managed by: launchd (com.schnapp.macmcp.plist)
Transport: streamable-http on port 8765
"""

import contextvars
import os
import subprocess
import platform
import time
from datetime import datetime, timezone
from pathlib import Path

import requests
import uvicorn
from mcp.server.fastmcp import FastMCP
from starlette.responses import Response
from starlette.types import ASGIApp, Receive, Scope, Send

MCP_TOKEN = os.environ.get("MAC_MCP_AUTH_TOKEN", "")

# Set to True for the duration of a request authenticated via Bearer header.
# _check_token() accepts either HTTP-level auth or the explicit token parameter,
# so local callers (passing token=) and cloud callers (using Bearer) both work.
_http_authed: contextvars.ContextVar[bool] = contextvars.ContextVar(
    "http_authed", default=False
)
RUNNER_KEY = os.environ.get("RUNNER_API_KEY", "runner-Lake4971")
FLASK_BASE = "http://localhost:5000"
GH_PAT = os.environ.get("GH_PAT", "")
GITHUB_REPO = "SchnappAPI/schnapp-bet"
GITHUB_API = "https://api.github.com"
FLASK_LABEL = "bet.schnapp.flask"

# SQL connection — env-driven, populated by op run --env-file=.env.template
# via services/launchd/op-wrap.sh in the schnapp-bet repo (ADR-20260517-5).
SQL_SERVER = os.environ.get("SQL_SERVER", "localhost,1433")
SQL_DB = os.environ.get("SQL_DATABASE", "")
SQL_USER = os.environ.get("SQL_USERNAME", "sa")
SQL_PASSWORD = os.environ.get("SQL_PASSWORD", "")
SQL_TRUST_CERT = os.environ.get("SQL_TRUST_CERT", "1").lower() in ("1", "true", "yes")
BACKUP_DIR = "/Users/schnapp/azure-sql-backups"

WEB_PROD_LABEL = "bet.schnapp.web-prod"
WEB_DEV_LABEL = "bet.schnapp.web"
WEB_PROD_PORT = 3001
WEB_DEV_PORT = 3000

TUNNEL_CHECKS = [
    ("schnapp.bet", "https://schnapp.bet/api/ping"),
    ("mac-mcp.schnapp.bet", "https://mac-mcp.schnapp.bet/mcp"),
    ("mac-flask.schnapp.bet", "https://mac-flask.schnapp.bet/ping"),
    ("dev.schnapp.bet", "https://dev.schnapp.bet/api/ping"),
]

mcp = FastMCP(
    name="schnapp-mac",
    instructions=(
        "Operational tools for the Schnapp MacBook Pro: shell access, file read/write, "
        "SQL queries, service management, tunnel health, Docker/Colima, backups, and "
        "GitHub Actions. The Mac hosts SQL Server in Docker (Colima), the production "
        "Next.js site, the Flask live-data runner, and the self-hosted GitHub Actions runner."
    ),
    host="127.0.0.1",
    port=8765,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _check_token(token: str) -> bool:
    # Accept: request pre-authenticated via Bearer header, OR explicit token match.
    return _http_authed.get() or (bool(MCP_TOKEN) and token == MCP_TOKEN)


def _flask_headers():
    return {"X-Runner-Key": RUNNER_KEY}


def _github_headers():
    return {
        "Authorization": f"Bearer {GH_PAT}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }


def _launchctl_pid(label: str) -> int | None:
    """Return the running PID of a launchd agent, or None if not loaded/running."""
    r = subprocess.run(
        ["launchctl", "list", label],
        capture_output=True,
        text=True,
        timeout=10,
    )
    if r.returncode != 0:
        return None
    for line in r.stdout.splitlines():
        s = line.strip()
        if s.startswith('"PID"'):
            try:
                return int(s.split("=")[1].strip().rstrip(";").strip())
            except Exception:
                return None
    return None


def _run_sqlcmd(query: str, timeout: int = 30) -> dict:
    """Run a query via sqlcmd and return rows as a list of dicts."""
    if not SQL_PASSWORD:
        return {
            "error": "SQL_PASSWORD not set in environment (expect op run via op-wrap.sh)"
        }
    if not SQL_DB:
        return {
            "error": "SQL_DATABASE not set in environment (expect op run via op-wrap.sh)"
        }
    cmd = [
        "sqlcmd",
        "-S",
        SQL_SERVER,
        "-d",
        SQL_DB,
        "-U",
        SQL_USER,
        "-P",
        SQL_PASSWORD,
        "-Q",
        query,
        "-o",
        "/dev/stdout",
        "-s",
        "\t",  # tab separator
        "-W",  # remove trailing spaces
        "-h",
        "-1",  # no header row separator line
    ]
    if SQL_TRUST_CERT:
        cmd.append("-C")  # trust server certificate (self-signed container)
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return {
            "returncode": r.returncode,
            "stdout": r.stdout.strip(),
            "stderr": r.stderr.strip(),
        }
    except subprocess.TimeoutExpired:
        return {"error": f"sqlcmd timed out after {timeout}s"}
    except FileNotFoundError:
        return {"error": "sqlcmd not found on PATH"}
    except Exception as e:
        return {"error": str(e)}


# ---------------------------------------------------------------------------
# Existing tools (unchanged)
# ---------------------------------------------------------------------------


@mcp.tool()
def shell_exec(command: str, token: str = "", timeout: int = 60) -> dict:
    """Run a shell command on the Mac as the logged-in user. Requires MAC_MCP_AUTH_TOKEN.

    The 1Password identity is stripped from this subprocess, so `op` cannot read
    secrets here — route any credential-bearing command through op_run instead."""
    if not _check_token(token):
        return {"error": "unauthorized"}
    try:
        result = subprocess.run(
            ["/bin/bash", "-c", command],
            capture_output=True,
            text=True,
            timeout=min(timeout, 600),
            env=_no_op_identity_env(),
        )
        return {
            "returncode": result.returncode,
            "stdout": result.stdout[-20000:],
            "stderr": result.stderr[-5000:],
        }
    except subprocess.TimeoutExpired:
        return {"error": "timeout", "timeout_seconds": timeout}
    except Exception as e:
        return {"error": str(e)}


@mcp.tool()
def read_file(path: str, token: str = "") -> dict:
    """Read a file from the Mac filesystem. Requires MAC_MCP_AUTH_TOKEN."""
    if not _check_token(token):
        return {"error": "unauthorized"}
    try:
        p = Path(path).expanduser()
        if not p.exists():
            return {"error": f"not found: {path}"}
        if p.stat().st_size > 5_000_000:
            return {
                "error": f"file too large ({p.stat().st_size} bytes); use shell_exec with head/tail"
            }
        return {"path": str(p), "content": p.read_text(errors="replace")}
    except Exception as e:
        return {"error": str(e)}


@mcp.tool()
def write_file(path: str, content: str, token: str = "") -> dict:
    """Write content to a file on the Mac, creating parent dirs. Requires MAC_MCP_AUTH_TOKEN."""
    if not _check_token(token):
        return {"error": "unauthorized"}
    try:
        p = Path(path).expanduser()
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content)
        return {"path": str(p), "bytes_written": len(content.encode())}
    except Exception as e:
        return {"error": str(e)}


@mcp.tool()
def mac_info() -> dict:
    """Summarize the Mac: hardware, OS, disk, uptime, Docker state."""

    def run(cmd):
        try:
            r = subprocess.run(
                ["/bin/bash", "-c", cmd], capture_output=True, text=True, timeout=10
            )
            return r.stdout.strip()
        except Exception as e:
            return f"error: {e}"

    return {
        "hostname": platform.node(),
        "os": run("sw_vers -productVersion"),
        "model": run("sysctl -n hw.model"),
        "cpu": run("sysctl -n machdep.cpu.brand_string"),
        "memory_gb": run("echo $(($(sysctl -n hw.memsize) / 1073741824))"),
        "disk_free": run("df -h / | tail -1 | awk '{print $4 \" of \" $2}'"),
        "uptime": run("uptime"),
        "docker_running": run("docker ps >/dev/null 2>&1 && echo yes || echo no"),
    }


@mcp.tool()
def flask_status() -> dict:
    """Check the status of the Mac bet.schnapp.flask launchd agent and ping the local Flask."""
    pid = _launchctl_pid(FLASK_LABEL)
    flask_ok = False
    try:
        resp = requests.get(f"{FLASK_BASE}/ping", headers=_flask_headers(), timeout=5)
        flask_ok = resp.status_code == 200 and resp.json().get("ok") is True
    except Exception:
        pass
    return {
        "service_running": pid is not None,
        "pid": pid,
        "flask_ping_ok": flask_ok,
        "label": FLASK_LABEL,
    }


@mcp.tool()
def flask_restart() -> dict:
    """Restart the Mac bet.schnapp.flask launchd agent and confirm Flask comes back up."""
    uid = os.getuid()
    r = subprocess.run(
        ["launchctl", "kickstart", "-k", f"gui/{uid}/{FLASK_LABEL}"],
        capture_output=True,
        text=True,
        timeout=15,
    )
    if r.returncode != 0:
        return {"success": False, "error": (r.stderr or r.stdout).strip()}
    time.sleep(3)
    try:
        resp = requests.get(f"{FLASK_BASE}/ping", headers=_flask_headers(), timeout=5)
        ok = resp.status_code == 200 and resp.json().get("ok") is True
    except Exception as e:
        return {"success": False, "error": f"Restart issued but ping failed: {e}"}
    return {
        "success": ok,
        "message": "Flask restarted and ping confirmed."
        if ok
        else "Restarted but ping did not respond.",
    }


@mcp.tool()
def live_scoreboard() -> dict:
    """Fetch today's NBA game statuses from the CDN via the Mac Flask runner."""
    try:
        resp = requests.get(
            f"{FLASK_BASE}/scoreboard", headers=_flask_headers(), timeout=15
        )
        if resp.status_code != 200:
            return {"error": f"Flask returned {resp.status_code}"}
        return resp.json()
    except Exception as e:
        return {"error": str(e)}


@mcp.tool()
def live_boxscore(game_id: str) -> dict:
    """Fetch live player stats for a specific NBA game via Mac Flask. game_id e.g. '0042400301'"""
    try:
        resp = requests.get(
            f"{FLASK_BASE}/boxscore",
            headers=_flask_headers(),
            params={"gameId": game_id},
            timeout=15,
        )
        if resp.status_code != 200:
            return {"error": f"Flask returned {resp.status_code}"}
        return resp.json()
    except Exception as e:
        return {"error": str(e)}


@mcp.tool()
def workflow_trigger(workflow_filename: str, ref: str = "main") -> dict:
    """Trigger a GitHub Actions workflow. workflow_filename e.g. 'odds-etl-mac.yml'"""
    if not GH_PAT:
        return {"error": "GH_PAT not configured"}
    url = f"{GITHUB_API}/repos/{GITHUB_REPO}/actions/workflows/{workflow_filename}/dispatches"
    resp = requests.post(url, headers=_github_headers(), json={"ref": ref}, timeout=15)
    if resp.status_code == 204:
        return {
            "success": True,
            "message": f"Workflow '{workflow_filename}' triggered on {ref}.",
        }
    return {"success": False, "status_code": resp.status_code, "error": resp.text[:500]}


@mcp.tool()
def workflow_status(workflow_filename: str) -> dict:
    """Get the last run status of a GitHub Actions workflow."""
    if not GH_PAT:
        return {"error": "GH_PAT not configured"}
    url = f"{GITHUB_API}/repos/{GITHUB_REPO}/actions/workflows/{workflow_filename}/runs"
    resp = requests.get(
        url, headers=_github_headers(), params={"per_page": 1}, timeout=15
    )
    if resp.status_code != 200:
        return {"error": f"GitHub API returned {resp.status_code}"}
    runs = resp.json().get("workflow_runs", [])
    if not runs:
        return {"message": f"No runs found for {workflow_filename}"}
    r = runs[0]
    duration_seconds = None
    try:
        fmt = "%Y-%m-%dT%H:%M:%SZ"
        s = datetime.strptime(r.get("run_started_at", ""), fmt).replace(
            tzinfo=timezone.utc
        )
        e = datetime.strptime(r.get("updated_at", ""), fmt).replace(tzinfo=timezone.utc)
        duration_seconds = int((e - s).total_seconds())
    except Exception:
        pass
    return {
        "workflow": workflow_filename,
        "run_id": r.get("id"),
        "status": r.get("status"),
        "conclusion": r.get("conclusion"),
        "started_at": r.get("run_started_at"),
        "updated_at": r.get("updated_at"),
        "duration_seconds": duration_seconds,
        "url": r.get("html_url"),
        "triggered_by": r.get("event"),
    }


# ---------------------------------------------------------------------------
# New tools
# ---------------------------------------------------------------------------


@mcp.tool()
def workflow_logs(run_id: int, max_lines: int = 100) -> dict:
    """
    Fetch the last N lines of a GitHub Actions workflow run log.
    Use workflow_status or workflow_list_runs to get a run_id first.
    max_lines defaults to 100; cap is 500.
    """
    if not GH_PAT:
        return {"error": "GH_PAT not configured"}
    max_lines = min(max_lines, 500)
    # Fetch jobs for this run to get step-level detail
    jobs_url = f"{GITHUB_API}/repos/{GITHUB_REPO}/actions/runs/{run_id}/jobs"
    resp = requests.get(jobs_url, headers=_github_headers(), timeout=15)
    if resp.status_code != 200:
        return {"error": f"GitHub API returned {resp.status_code}"}
    jobs = resp.json().get("jobs", [])
    if not jobs:
        return {"run_id": run_id, "jobs": [], "message": "No jobs found for this run."}
    summary = []
    for job in jobs:
        steps = []
        for step in job.get("steps", []):
            steps.append(
                {
                    "name": step.get("name"),
                    "status": step.get("status"),
                    "conclusion": step.get("conclusion"),
                    "number": step.get("number"),
                }
            )
        summary.append(
            {
                "job_name": job.get("name"),
                "status": job.get("status"),
                "conclusion": job.get("conclusion"),
                "started_at": job.get("started_at"),
                "completed_at": job.get("completed_at"),
                "steps": steps,
                "log_url": job.get("html_url"),
            }
        )
    # Also fetch annotations (error/warning messages surfaced without needing raw log redirect)
    ann_url = f"{GITHUB_API}/repos/{GITHUB_REPO}/actions/runs/{run_id}/annotations"
    annotations = []
    try:
        ann_resp = requests.get(ann_url, headers=_github_headers(), timeout=15)
        if ann_resp.status_code == 200:
            for a in ann_resp.json()[:max_lines]:
                annotations.append(
                    {
                        "level": a.get("annotation_level"),
                        "title": a.get("title"),
                        "message": a.get("message", "")[:500],
                        "path": a.get("path"),
                    }
                )
    except Exception:
        pass
    return {"run_id": run_id, "jobs": summary, "annotations": annotations}


@mcp.tool()
def workflow_list_runs(workflow_filename: str, limit: int = 10) -> dict:
    """
    List recent runs for a GitHub Actions workflow.
    Returns run_id, status, conclusion, start time, duration, and URL for each.
    limit defaults to 10, max 30.
    """
    if not GH_PAT:
        return {"error": "GH_PAT not configured"}
    limit = min(limit, 30)
    url = f"{GITHUB_API}/repos/{GITHUB_REPO}/actions/workflows/{workflow_filename}/runs"
    resp = requests.get(
        url, headers=_github_headers(), params={"per_page": limit}, timeout=15
    )
    if resp.status_code != 200:
        return {"error": f"GitHub API returned {resp.status_code}"}
    runs = resp.json().get("workflow_runs", [])
    result = []
    fmt = "%Y-%m-%dT%H:%M:%SZ"
    for r in runs:
        duration_seconds = None
        try:
            s = datetime.strptime(r.get("run_started_at", ""), fmt).replace(
                tzinfo=timezone.utc
            )
            e = datetime.strptime(r.get("updated_at", ""), fmt).replace(
                tzinfo=timezone.utc
            )
            duration_seconds = int((e - s).total_seconds())
        except Exception:
            pass
        result.append(
            {
                "run_id": r.get("id"),
                "status": r.get("status"),
                "conclusion": r.get("conclusion"),
                "started_at": r.get("run_started_at"),
                "duration_seconds": duration_seconds,
                "triggered_by": r.get("event"),
                "url": r.get("html_url"),
            }
        )
    return {"workflow": workflow_filename, "runs": result}


@mcp.tool()
def sql_query(query: str, token: str = "", timeout: int = 30) -> dict:
    """
    Run a SQL query against the local SQL Server container (schnapp-bet DB, sa user).
    Read-only queries only — SELECT, sp_help, sys.* views etc.
    Requires MAC_MCP_AUTH_TOKEN. timeout defaults to 30s, max 120s.
    Examples: 'SELECT TOP 5 * FROM nba.player_props ORDER BY game_date DESC'
              'SELECT COUNT(*) FROM nba.player_props'
              'SELECT name FROM sys.tables ORDER BY name'
    """
    if not _check_token(token):
        return {"error": "unauthorized"}
    # Block obviously destructive statements
    upper = query.strip().upper()
    for keyword in (
        "INSERT",
        "UPDATE",
        "DELETE",
        "DROP",
        "TRUNCATE",
        "ALTER",
        "CREATE",
        "EXEC",
        "EXECUTE",
    ):
        if upper.startswith(keyword) or f" {keyword} " in upper:
            return {
                "error": f"Write operation '{keyword}' not permitted via sql_query. Use shell_exec if needed."
            }
    timeout = min(timeout, 120)
    result = _run_sqlcmd(query, timeout=timeout)
    return result


@mcp.tool()
def web_status() -> dict:
    """
    Check both Mac Next.js launchd agents and their HTTP endpoints.
    bet.schnapp.web-prod (port 3001) serves schnapp.bet.
    bet.schnapp.web (port 3000) serves dev.schnapp.bet.
    """

    def check(label, port):
        pid = _launchctl_pid(label)
        ping_ok = False
        http_status = None
        try:
            resp = requests.get(f"http://127.0.0.1:{port}/api/ping", timeout=5)
            http_status = resp.status_code
            ping_ok = resp.status_code == 200
        except Exception:
            pass
        return {
            "label": label,
            "service_running": pid is not None,
            "pid": pid,
            "port": port,
            "ping_ok": ping_ok,
            "http_status": http_status,
        }

    return {
        "prod": check(WEB_PROD_LABEL, WEB_PROD_PORT),
        "dev": check(WEB_DEV_LABEL, WEB_DEV_PORT),
    }


@mcp.tool()
def service_status(label: str) -> dict:
    """
    Check any launchd user agent by label.
    Useful labels: 'bet.schnapp.web-prod', 'bet.schnapp.web', 'bet.schnapp.flask',
                   'com.schnapp.macmcp', 'actions.runner.SchnappAPI-schnapp-bet.mac-runner-1',
                   'bet.schnapp.bacpac-backup'
    """
    pid = _launchctl_pid(label)
    # Get full launchctl print output for extra detail
    r = subprocess.run(
        ["launchctl", "print", f"gui/{os.getuid()}/{label}"],
        capture_output=True,
        text=True,
        timeout=10,
    )
    detail = r.stdout.strip()[:2000] if r.returncode == 0 else None
    return {
        "label": label,
        "running": pid is not None,
        "pid": pid,
        "detail": detail,
    }


@mcp.tool()
def service_restart(label: str, mode: str = "graceful", token: str = "") -> dict:
    """
    Restart a launchd user agent by label.
    mode='graceful' (default): SIGTERM via `launchctl kill TERM` so the process shuts
      down cleanly (closes its listen socket) and KeepAlive relaunches it — avoids the
      SIGKILL bind race (decision 0010). Use for the MCP socket servers
      (com.schnapp.macmcp/githubmcp/obsidian-mcp) and any KeepAlive agent. If the agent
      is NOT KeepAlive and does not return within ~4s, this falls back to a kickstart so
      it is left running.
    mode='hard': `launchctl kickstart -k` — immediate kill+restart; use only if graceful
      will not bring the agent back and an abrupt stop is acceptable.
    Requires MAC_MCP_AUTH_TOKEN.
    Note: restarting 'com.schnapp.macmcp' restarts THIS MCP server — the call will not return.
    """
    if not _check_token(token):
        return {"error": "unauthorized"}
    uid = os.getuid()
    if mode == "hard":
        r = subprocess.run(
            ["launchctl", "kickstart", "-k", f"gui/{uid}/{label}"],
            capture_output=True, text=True, timeout=15,
        )
        if r.returncode != 0:
            return {"success": False, "label": label, "mode": "hard",
                    "error": (r.stderr or r.stdout).strip()}
        return {"success": True, "label": label, "mode": "hard",
                "message": f"Kickstarted gui/{uid}/{label}."}
    # graceful
    r = subprocess.run(
        ["launchctl", "kill", "TERM", f"gui/{uid}/{label}"],
        capture_output=True, text=True, timeout=15,
    )
    if r.returncode != 0:
        return {"success": False, "label": label, "mode": "graceful",
                "error": (r.stderr or r.stdout).strip()}
    if label == "com.schnapp.macmcp":
        return {"success": True, "label": label, "mode": "graceful",
                "message": "TERM sent to self; KeepAlive will relaunch (no response expected)."}
    fell_back = False
    for _ in range(16):  # ~4s for KeepAlive to relaunch
        time.sleep(0.25)
        chk = subprocess.run(["launchctl", "list", label], capture_output=True, text=True)
        if chk.returncode == 0 and '"PID" =' in chk.stdout:
            break
    else:
        subprocess.run(["launchctl", "kickstart", f"gui/{uid}/{label}"],
                       capture_output=True, text=True, timeout=15)
        fell_back = True
    return {"success": True, "label": label, "mode": "graceful",
            "fell_back_to_kickstart": fell_back,
            "message": (f"TERM sent to gui/{uid}/{label}; "
                        + ("not KeepAlive — kickstarted to ensure running."
                           if fell_back else "relaunched by KeepAlive."))}


@mcp.tool()
def tunnel_status() -> dict:
    """
    Check cloudflared service state and reachability of all live Schnapp subdomains.
    Subdomains checked: schnapp.bet, mac-mcp.schnapp.bet, mac-flask.schnapp.bet, dev.schnapp.bet.
    """
    # cloudflared runs as system-level launchd job
    cf_r = subprocess.run(
        ["launchctl", "print", "system/com.cloudflare.cloudflared"],
        capture_output=True,
        text=True,
        timeout=10,
    )
    cloudflared_running = cf_r.returncode == 0

    results = []
    for name, url in TUNNEL_CHECKS:
        ok = False
        http_status = None
        error = None
        try:
            resp = requests.get(url, timeout=8, allow_redirects=True)
            http_status = resp.status_code
            ok = resp.status_code < 500
        except requests.exceptions.ConnectionError:
            error = "connection refused"
        except requests.exceptions.Timeout:
            error = "timeout"
        except Exception as e:
            error = str(e)[:200]
        results.append(
            {
                "subdomain": name,
                "url": url,
                "reachable": ok,
                "http_status": http_status,
                "error": error,
            }
        )

    all_ok = cloudflared_running and all(r["reachable"] for r in results)
    return {
        "cloudflared_running": cloudflared_running,
        "subdomains": results,
        "all_ok": all_ok,
    }


@mcp.tool()
def docker_status() -> dict:
    """
    Check Colima VM, SQL Server container, and database connectivity.
    Verifies the full stack that production depends on.
    """

    def run(cmd, timeout=15):
        try:
            r = subprocess.run(
                ["/bin/bash", "-c", cmd],
                capture_output=True,
                text=True,
                timeout=timeout,
            )
            return r.returncode, r.stdout.strip(), r.stderr.strip()
        except subprocess.TimeoutExpired:
            return -1, "", "timeout"
        except Exception as e:
            return -1, "", str(e)

    # Colima
    rc, colima_out, _ = run("colima status 2>&1")
    colima_running = rc == 0 and "running" in colima_out.lower()

    # SQL Server container
    rc, container_out, _ = run(
        "docker inspect --format '{{.State.Status}}' mssql 2>/dev/null || docker ps --filter name=mssql --format '{{.Status}}' 2>/dev/null"
    )
    container_status = container_out.strip() or "not found"
    container_running = "running" in container_status.lower()

    # DB connectivity via sqlcmd SELECT 1
    db_ok = False
    db_error = None
    if container_running:
        result = _run_sqlcmd("SELECT 1 AS ping", timeout=10)
        if result.get("returncode") == 0 and "1" in result.get("stdout", ""):
            db_ok = True
        else:
            db_error = (
                result.get("stderr") or result.get("error") or "unexpected output"
            )

    # Row counts for key tables as a quick data sanity check
    row_counts = {}
    if db_ok:
        for table in ("nba.player_props", "nba.game_stats", "mlb.player_at_bats"):
            rc_result = _run_sqlcmd(f"SELECT COUNT(*) FROM {table}", timeout=10)
            if rc_result.get("returncode") == 0:
                row_counts[table] = rc_result.get("stdout", "").strip()
            else:
                row_counts[table] = "error"

    return {
        "colima_running": colima_running,
        "colima_detail": colima_out[:300],
        "container_status": container_status,
        "container_running": container_running,
        "db_reachable": db_ok,
        "db_error": db_error,
        "row_counts": row_counts,
    }


@mcp.tool()
def backup_status() -> dict:
    """
    Show BACPAC backup files in /Users/schnapp/azure-sql-backups.
    Reports file name, size, age, and whether the weekly schedule is current.
    """
    backup_path = Path(BACKUP_DIR)
    if not backup_path.exists():
        return {"error": f"Backup directory not found: {BACKUP_DIR}"}

    bacpac_files = sorted(
        backup_path.glob("*.bacpac"), key=lambda p: p.stat().st_mtime, reverse=True
    )
    now = datetime.now(timezone.utc)
    files = []
    for f in bacpac_files:
        stat = f.stat()
        mtime = datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc)
        age_days = (now - mtime).days
        files.append(
            {
                "name": f.name,
                "size_mb": round(stat.st_size / 1_048_576, 1),
                "modified": mtime.strftime("%Y-%m-%d %H:%M UTC"),
                "age_days": age_days,
            }
        )

    most_recent_age = files[0]["age_days"] if files else None
    # Weekly backup should fire every Sunday; warn if most recent is > 8 days old
    backup_current = most_recent_age is not None and most_recent_age <= 8

    # Check launchd agent next-fire
    next_fire = None
    r = subprocess.run(
        ["launchctl", "print", f"gui/{os.getuid()}/bet.schnapp.bacpac-backup"],
        capture_output=True,
        text=True,
        timeout=10,
    )
    if r.returncode == 0:
        for line in r.stdout.splitlines():
            if "next scheduled fire date" in line.lower():
                next_fire = line.strip()
                break

    return {
        "backup_count": len(files),
        "files": files,
        "most_recent_age_days": most_recent_age,
        "backup_current": backup_current,
        "next_scheduled_fire": next_fire,
        "backup_dir": BACKUP_DIR,
    }


@mcp.tool()
def site_health() -> dict:
    """
    Single composite health check for the entire Schnapp stack.
    Checks: cloudflared tunnel, SQL Server container + DB, Flask, prod web service.
    Use this from mobile for a fast overall status read.
    """
    results = {}

    # Tunnel (cloudflared running + schnapp.bet reachable)
    cf_r = subprocess.run(
        ["launchctl", "print", "system/com.cloudflare.cloudflared"],
        capture_output=True,
        text=True,
        timeout=10,
    )
    results["tunnel_up"] = cf_r.returncode == 0
    try:
        r = requests.get("https://schnapp.bet/api/ping", timeout=8)
        results["site_reachable"] = r.status_code == 200
        results["site_http_status"] = r.status_code
    except Exception as e:
        results["site_reachable"] = False
        results["site_error"] = str(e)[:200]

    # SQL Server container
    rc, out, _ = (
        subprocess.run(
            [
                "/bin/bash",
                "-c",
                "docker inspect --format '{{.State.Status}}' mssql 2>/dev/null || docker ps --filter name=mssql --format '{{.Status}}' 2>/dev/null",
            ],
            capture_output=True,
            text=True,
            timeout=10,
        ).returncode,
        *["", ""],
    )
    try:
        proc = subprocess.run(
            [
                "/bin/bash",
                "-c",
                "docker inspect --format '{{.State.Status}}' mssql 2>/dev/null || docker ps --filter name=mssql --format '{{.Status}}' 2>/dev/null",
            ],
            capture_output=True,
            text=True,
            timeout=10,
        )
        results["sql_container_running"] = "running" in proc.stdout.lower()
    except Exception:
        results["sql_container_running"] = False

    # DB connectivity
    db_result = _run_sqlcmd("SELECT 1 AS ping", timeout=8)
    results["db_reachable"] = db_result.get("returncode") == 0 and "1" in db_result.get(
        "stdout", ""
    )

    # Flask
    flask_pid = _launchctl_pid(FLASK_LABEL)
    results["flask_running"] = flask_pid is not None
    try:
        fr = requests.get(f"{FLASK_BASE}/ping", timeout=5)
        results["flask_ping_ok"] = fr.status_code == 200
    except Exception:
        results["flask_ping_ok"] = False

    # Prod web
    web_pid = _launchctl_pid(WEB_PROD_LABEL)
    results["web_prod_running"] = web_pid is not None

    all_ok = all(
        [
            results.get("tunnel_up"),
            results.get("site_reachable"),
            results.get("sql_container_running"),
            results.get("db_reachable"),
            results.get("flask_running"),
            results.get("flask_ping_ok"),
            results.get("web_prod_running"),
        ]
    )
    results["all_ok"] = all_ok
    return results


# ---------------------------------------------------------------------------
# 1Password tools (just-in-time secret access via the service account)
#
# This process runs inside `op run` (op-wrap.sh) with a 1Password
# service-account token in its environment, so the `op` CLI is authenticated.
# JIT model: secrets are injected into a subprocess or written to a file ON THE
# MAC, and every secret VALUE is scrubbed from tool output before returning.
# Prefer op_run over shell_exec for anything secret-bearing so raw credentials
# never enter the model context. Because these live in this remote connector,
# they are available wherever the Schnapp Mac connector is — web, mobile, CLI —
# without the token ever leaving the Mac.
# ---------------------------------------------------------------------------


def _op_read(ref: str, timeout: int = 20) -> str:
    """Resolve a single op:// reference to its value via the op CLI. Raises on failure."""
    r = subprocess.run(
        ["op", "read", ref], capture_output=True, text=True, timeout=timeout
    )
    if r.returncode != 0:
        raise RuntimeError(
            (r.stderr or r.stdout).strip() or f"op read failed for {ref}"
        )
    return r.stdout.rstrip("\n")


def _scrub(text: str, secrets: list[str]) -> str:
    """Replace every secret value occurrence in text with ***."""
    if not text:
        return text
    for s in secrets:
        if s:
            text = text.replace(s, "***")
    return text


# 1Password identity neutralization for subprocesses that must NOT read secrets
# on their own (shell_exec, and the command run by op_run). Only the op_* tools
# resolve secrets — via this parent process. A general shell is handed no usable
# 1Password identity, so the JIT guarantee holds.
#
# NOTE: simply unsetting OP_SERVICE_ACCOUNT_TOKEN is NOT enough on a Mac running
# the 1Password desktop app — `op` falls back to the desktop/CLI integration and
# still authenticates (verified). Setting a deliberately INVALID service-account
# token forces op into service-account mode and it refuses outright, with no
# desktop or keychain fallback (verified: "unrecognized auth type").
_OP_STRIP_PREFIXES = (
    "OP_SERVICE_ACCOUNT_TOKEN",
    "OP_SESSION",
    "OP_CONNECT_TOKEN",
    "OP_CONNECT_HOST",
)
_JIT_SENTINEL = "disabled-by-jit-guard"


def _no_op_identity_env(extra: dict | None = None) -> dict:
    """Process env with every 1Password identity stripped and the service-account
    token poisoned (so op denies), plus optional injected vars."""
    env = {
        k: v
        for k, v in os.environ.items()
        if not any(k.startswith(p) for p in _OP_STRIP_PREFIXES)
    }
    env["OP_SERVICE_ACCOUNT_TOKEN"] = _JIT_SENTINEL
    env["OP_BIOMETRIC_UNLOCK_ENABLED"] = "false"
    if extra:
        env.update(extra)
    return env


@mcp.tool()
def op_whoami(token: str = "") -> dict:
    """Report the authenticated 1Password identity (service account). No secrets returned.
    Requires MAC_MCP_AUTH_TOKEN."""
    if not _check_token(token):
        return {"error": "unauthorized"}
    try:
        r = subprocess.run(
            ["op", "whoami"], capture_output=True, text=True, timeout=15
        )
        if r.returncode != 0:
            return {"error": (r.stderr or r.stdout).strip()}
        return {"ok": True, "whoami": r.stdout.strip()}
    except Exception as e:
        return {"error": str(e)}


@mcp.tool()
def op_list_items(vault: str = "", token: str = "") -> dict:
    """List 1Password item titles/ids (and vault). Metadata only — no field values.
    Optionally scope to one vault. Requires MAC_MCP_AUTH_TOKEN."""
    if not _check_token(token):
        return {"error": "unauthorized"}
    try:
        import json

        cmd = ["op", "item", "list", "--format=json"]
        if vault:
            cmd += ["--vault", vault]
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if r.returncode != 0:
            return {"error": (r.stderr or r.stdout).strip()}
        items = json.loads(r.stdout or "[]")
        return {
            "count": len(items),
            "items": [
                {
                    "id": it.get("id"),
                    "title": it.get("title"),
                    "vault": (it.get("vault") or {}).get("name"),
                    "category": it.get("category"),
                }
                for it in items
            ],
        }
    except Exception as e:
        return {"error": str(e)}


@mcp.tool()
def op_run(
    command: str,
    env_refs: dict | None = None,
    env_file: str = "",
    timeout: int = 120,
    token: str = "",
) -> dict:
    """Run a shell command on the Mac with 1Password secrets injected into its environment,
    then return the result with all secret VALUES scrubbed to ***.

    env_refs: mapping of ENV_NAME -> op:// reference, resolved and injected.
    env_file: path to an op-style env template (NAME="op://...") — each ref is resolved
              in this process and injected (no `op run`; the child gets no op identity).

    Prefer this over shell_exec for anything that needs credentials — raw secrets never
    enter the response, and the command cannot read any secret beyond what is injected.
    Requires MAC_MCP_AUTH_TOKEN."""
    if not _check_token(token):
        return {"error": "unauthorized"}
    timeout = min(timeout, 600)
    resolved: list[str] = []
    injected: list[str] = []
    extra: dict[str, str] = {}
    try:
        # Inline ENV_NAME -> op:// refs, resolved here (authenticated parent).
        for name, ref in (env_refs or {}).items():
            val = _op_read(ref)
            extra[name] = val
            resolved.append(val)
            injected.append(name)
        # op-style env-file (NAME="op://..."), also resolved here — not via `op run`.
        if env_file:
            for line in Path(env_file).expanduser().read_text().splitlines():
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                name, raw = line.split("=", 1)
                name = name.strip()
                raw = raw.strip().strip('"').strip("'")
                if raw.startswith("op://"):
                    val = _op_read(raw)
                    extra[name] = val
                    resolved.append(val)
                    injected.append(name)
        # Child runs with NO 1Password identity — only the injected values.
        r = subprocess.run(
            ["/bin/bash", "-c", command],
            capture_output=True,
            text=True,
            timeout=timeout,
            env=_no_op_identity_env(extra),
        )
        return {
            "returncode": r.returncode,
            "stdout": _scrub(r.stdout[-20000:], resolved),
            "stderr": _scrub(r.stderr[-5000:], resolved),
            "injected": sorted(injected),
        }
    except subprocess.TimeoutExpired:
        return {"error": "timeout", "timeout_seconds": timeout}
    except Exception as e:
        return {"error": _scrub(str(e), resolved)}


@mcp.tool()
def op_inject(template_path: str, out_path: str, token: str = "") -> dict:
    """Fill a `{{ op://... }}` template file with 1Password secrets and write the result to
    out_path ON THE MAC. Returns only the path and byte count — never the rendered content.
    Use for materializing config/.env files server-side. Requires MAC_MCP_AUTH_TOKEN."""
    if not _check_token(token):
        return {"error": "unauthorized"}
    try:
        tin = str(Path(template_path).expanduser())
        tout = str(Path(out_path).expanduser())
        Path(tout).parent.mkdir(parents=True, exist_ok=True)
        r = subprocess.run(
            ["op", "inject", "-i", tin, "-o", tout, "-f"],
            capture_output=True,
            text=True,
            timeout=30,
        )
        if r.returncode != 0:
            return {"error": (r.stderr or r.stdout).strip()}
        return {"ok": True, "out_path": tout, "bytes_written": Path(tout).stat().st_size}
    except Exception as e:
        return {"error": str(e)}


@mcp.tool()
def op_read(ref: str, token: str = "") -> dict:
    """Resolve a single op:// reference and return proof-of-resolution only
    (length + last4) — the raw value never enters the model context. There is no
    reveal option by design; use op_run to consume a secret without exposing it.
    Requires MAC_MCP_AUTH_TOKEN."""
    if not _check_token(token):
        return {"error": "unauthorized"}
    if not ref.startswith("op://"):
        return {"error": "ref must start with op://"}
    try:
        val = _op_read(ref)
    except Exception as e:
        return {"error": str(e)}
    return {
        "ref": ref,
        "length": len(val),
        "last4": val[-4:] if len(val) >= 4 else "",
        "masked": "***",
    }


class _BearerAuthMiddleware:
    """ASGI middleware: validates Authorization: Bearer <token> before passing to FastMCP.
    If no Bearer header is present the request passes through unchanged (per-tool
    token= parameter auth still applies). If a wrong token is presented, 401 immediately.
    """
    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] == "http" and MCP_TOKEN:
            headers = {k: v for k, v in scope.get("headers", [])}
            auth = headers.get(b"authorization", b"").decode()
            if auth.startswith("Bearer "):
                if auth[7:] == MCP_TOKEN:
                    tok = _http_authed.set(True)
                    try:
                        await self.app(scope, receive, send)
                    finally:
                        _http_authed.reset(tok)
                    return
                else:
                    await Response("Unauthorized", status_code=401)(scope, receive, send)
                    return
        await self.app(scope, receive, send)


if __name__ == "__main__":
    import socket

    # Pre-bind the listen socket with SO_REUSEADDR so a fresh process can rebind
    # :8765 across a graceful restart: uvicorn closes the socket on SIGTERM before
    # launchd KeepAlive relaunches. Fixes the [Errno 48] race that throttled
    # recovery to ~2 min. SO_REUSEPORT intentionally NOT set -- it would also let a
    # stray second instance silently share the port (split-brain) instead of
    # failing loudly with errno 48. See decision 0010 / handoff 021.
    _sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    _sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    _sock.bind(("127.0.0.1", 8765))
    _sock.listen()

    app = mcp.streamable_http_app()
    _config = uvicorn.Config(_BearerAuthMiddleware(app), host="127.0.0.1", port=8765)
    uvicorn.Server(_config).run(sockets=[_sock])
