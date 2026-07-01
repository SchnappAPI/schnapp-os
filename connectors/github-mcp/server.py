"""
github-mcp/server.py

Remote MCP server exposing the GitHub REST API to Claude.
Covers all repos the PAT has access to - not scoped to any single repo.

Auth: Bearer token in the Authorization header, validated on every request.
      Set GITHUB_MCP_AUTH_TOKEN in the launchd plist.
      Configure the same value as the bearer token in the claude.ai connector.

GitHub access: GH_PAT env var (fine-grained or classic PAT).

Tools (38):
  Repos:    list_repos, get_repo, list_branches, get_branch, create_branch,
            list_commits, get_commit, compare_commits, search_code,
            search_repos, list_tags
  Files:    get_file, create_or_update_file, delete_file, list_directory
  Issues:   list_issues, get_issue, create_issue, update_issue,
            add_issue_comment, list_issue_comments, close_issue
  PRs:      list_prs, get_pr, create_pr, update_pr, merge_pr,
            list_pr_files, list_pr_reviews, create_pr_review
  Actions:  list_workflows, list_workflow_runs, get_workflow_run,
            trigger_workflow, cancel_workflow_run, list_run_jobs,
            get_job_logs, list_artifacts, download_artifact
  Releases: list_releases, get_release, create_release
  Org:      list_org_repos, list_org_members

Start: python server.py
Managed by: launchd (com.schnapp.githubmcp.plist)
Transport: streamable-http on port 8766
"""

import base64
import os
from typing import Any

import requests
from mcp.server.fastmcp import FastMCP
from mcp.server.transport_security import TransportSecuritySettings

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

GH_PAT       = os.environ.get("GH_PAT", "")
MCP_TOKEN    = os.environ.get("GITHUB_MCP_AUTH_TOKEN", "")
GITHUB_API   = "https://api.github.com"

# ---------------------------------------------------------------------------
# FastMCP app
# ---------------------------------------------------------------------------

mcp = FastMCP(
    name="schnapp-github",
    instructions=(
        "Full GitHub API access across all SchnappAPI repositories. "
        "Tools cover repos, branches, files, commits, issues, pull requests, "
        "GitHub Actions workflows, releases, and org membership. "
        "Pass owner and repo explicitly on every call - this server is not "
        "scoped to any single repository."
    ),
    host="127.0.0.1",
    port=8766,
    transport_security=TransportSecuritySettings(
        enable_dns_rebinding_protection=True,
        allowed_hosts=["127.0.0.1:*", "localhost:*", "[::1]:*", "github-mcp.schnapp.bet"],
        allowed_origins=["http://127.0.0.1:*", "http://localhost:*", "http://[::1]:*",
                         "https://github-mcp.schnapp.bet"],
    ),
)

# ---------------------------------------------------------------------------
# Bearer token auth middleware (Starlette)
# ---------------------------------------------------------------------------

class BearerAuthMiddleware:
    """
    Accepts the auth token from either:
      - Authorization: Bearer <token> header
      - ?token=<token> query parameter (for claude.ai custom connectors)
    """
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] == "http":
            # Check Authorization header
            headers = dict(scope.get("headers", []))
            auth = headers.get(b"authorization", b"").decode("utf-8", errors="replace")
            header_token = auth[7:].strip() if auth.lower().startswith("bearer ") else ""

            # Check ?token= query param
            query = scope.get("query_string", b"").decode("utf-8", errors="replace")
            query_token = ""
            for part in query.split("&"):
                if part.startswith("token="):
                    query_token = part[6:]
                    break

            provided = header_token or query_token
            if not MCP_TOKEN or provided != MCP_TOKEN:
                await self._reject(scope, receive, send)
                return
        await self.app(scope, receive, send)

    @staticmethod
    async def _reject(scope, receive, send):
        import json
        body = json.dumps({"error": "unauthorized"}).encode()
        await send({"type": "http.response.start", "status": 401,
                    "headers": [[b"content-type", b"application/json"],
                                 [b"content-length", str(len(body)).encode()]]})
        await send({"type": "http.response.body", "body": body})

# ---------------------------------------------------------------------------
# GitHub helpers
# ---------------------------------------------------------------------------

def _gh(method: str, path: str, **kwargs) -> dict:
    """Make a GitHub API call. Returns the parsed JSON or an error dict."""
    headers = {
        "Authorization": f"Bearer {GH_PAT}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    url = f"{GITHUB_API}{path}" if path.startswith("/") else path
    try:
        resp = requests.request(method, url, headers=headers, timeout=20, **kwargs)
        if resp.status_code == 204:
            return {"success": True}
        if resp.status_code >= 400:
            try:
                detail = resp.json()
            except Exception:
                detail = resp.text[:500]
            return {"error": f"GitHub API {resp.status_code}", "detail": detail}
        if not resp.content:
            return {"success": True}
        return resp.json()
    except requests.Timeout:
        return {"error": "GitHub API request timed out"}
    except Exception as e:
        return {"error": str(e)}


def _paginate(path: str, params: dict, max_items: int = 100) -> list:
    """Fetch up to max_items results across pages."""
    results = []
    params = {**params, "per_page": min(100, max_items)}
    url = f"{GITHUB_API}{path}"
    headers = {
        "Authorization": f"Bearer {GH_PAT}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    while url and len(results) < max_items:
        resp = requests.get(url, headers=headers, params=params, timeout=20)
        if resp.status_code >= 400:
            break
        data = resp.json()
        if isinstance(data, list):
            results.extend(data)
        else:
            results.append(data)
            break
        # Follow Link header for next page
        link = resp.headers.get("Link", "")
        next_url = None
        for part in link.split(","):
            if 'rel="next"' in part:
                next_url = part.split(";")[0].strip().strip("<>")
                break
        url = next_url
        params = {}  # params are already in the next URL
    return results[:max_items]

# ---------------------------------------------------------------------------
# Repos
# ---------------------------------------------------------------------------

@mcp.tool()
def list_repos(owner: str, repo_type: str = "all", max_results: int = 50) -> Any:
    """
    List repositories for a user or org.
    repo_type: 'all', 'public', 'private', 'forks', 'sources', 'member'.
    """
    items = _paginate(f"/users/{owner}/repos", {"type": repo_type, "sort": "updated"}, max_results)
    return [{"name": r["name"], "full_name": r["full_name"], "private": r["private"],
             "description": r.get("description"), "default_branch": r.get("default_branch"),
             "pushed_at": r.get("pushed_at"), "url": r.get("html_url")} for r in items if isinstance(r, dict)]


@mcp.tool()
def get_repo(owner: str, repo: str) -> Any:
    """Get metadata for a repository."""
    return _gh("GET", f"/repos/{owner}/{repo}")


@mcp.tool()
def list_branches(owner: str, repo: str, max_results: int = 50) -> Any:
    """List branches in a repository."""
    items = _paginate(f"/repos/{owner}/{repo}/branches", {}, max_results)
    return [{"name": b["name"], "sha": b["commit"]["sha"], "protected": b.get("protected")}
            for b in items if isinstance(b, dict)]


@mcp.tool()
def get_branch(owner: str, repo: str, branch: str) -> Any:
    """Get details for a specific branch including latest commit."""
    return _gh("GET", f"/repos/{owner}/{repo}/branches/{branch}")


@mcp.tool()
def create_branch(owner: str, repo: str, branch: str, from_branch: str = "main") -> Any:
    """Create a new branch from an existing branch (defaults to main)."""
    base = _gh("GET", f"/repos/{owner}/{repo}/git/ref/heads/{from_branch}")
    if "error" in base:
        return base
    sha = base["object"]["sha"]
    return _gh("POST", f"/repos/{owner}/{repo}/git/refs",
               json={"ref": f"refs/heads/{branch}", "sha": sha})


@mcp.tool()
def list_commits(owner: str, repo: str, branch: str = "main",
                 path: str = "", max_results: int = 20) -> Any:
    """
    List recent commits on a branch, optionally filtered to a file path.
    Returns sha, message, author, date for each.
    """
    params: dict[str, Any] = {"sha": branch}
    if path:
        params["path"] = path
    items = _paginate(f"/repos/{owner}/{repo}/commits", params, max_results)
    out = []
    for c in items:
        if not isinstance(c, dict):
            continue
        commit = c.get("commit", {})
        out.append({
            "sha": c.get("sha"),
            "message": commit.get("message", "").split("\n")[0],
            "author": commit.get("author", {}).get("name"),
            "date": commit.get("author", {}).get("date"),
            "url": c.get("html_url"),
        })
    return out


@mcp.tool()
def get_commit(owner: str, repo: str, ref: str) -> Any:
    """Get details for a commit including files changed. ref can be a SHA or branch name."""
    return _gh("GET", f"/repos/{owner}/{repo}/commits/{ref}")


@mcp.tool()
def compare_commits(owner: str, repo: str, base: str, head: str) -> Any:
    """Compare two commits, branches, or tags. Returns diff stats and file list."""
    result = _gh("GET", f"/repos/{owner}/{repo}/compare/{base}...{head}")
    if "error" in result:
        return result
    return {
        "status": result.get("status"),
        "ahead_by": result.get("ahead_by"),
        "behind_by": result.get("behind_by"),
        "total_commits": result.get("total_commits"),
        "files": [{"filename": f["filename"], "status": f["status"],
                   "additions": f["additions"], "deletions": f["deletions"]}
                  for f in result.get("files", [])],
    }


@mcp.tool()
def list_tags(owner: str, repo: str, max_results: int = 20) -> Any:
    """List tags in a repository."""
    items = _paginate(f"/repos/{owner}/{repo}/tags", {}, max_results)
    return [{"name": t["name"], "sha": t["commit"]["sha"]} for t in items if isinstance(t, dict)]


@mcp.tool()
def search_repos(query: str, max_results: int = 20) -> Any:
    """
    Search GitHub repositories.
    query supports GitHub search syntax e.g. 'org:SchnappAPI language:python'.
    """
    result = _gh("GET", "/search/repositories", params={"q": query, "per_page": min(max_results, 30)})
    if "error" in result:
        return result
    return [{"full_name": r["full_name"], "description": r.get("description"),
             "stars": r.get("stargazers_count"), "url": r.get("html_url")}
            for r in result.get("items", [])]


@mcp.tool()
def search_code(query: str, owner: str = "", repo: str = "", max_results: int = 20) -> Any:
    """
    Search code across GitHub (or within a specific repo).
    If owner and repo are provided, search is scoped to that repo.
    query is the text to search for; GitHub code search syntax is supported.
    Note: GitHub rate-limits code search to 10 requests/minute.
    """
    q = query
    if owner and repo:
        q = f"{query} repo:{owner}/{repo}"
    elif owner:
        q = f"{query} org:{owner}"
    result = _gh("GET", "/search/code", params={"q": q, "per_page": min(max_results, 30)})
    if "error" in result:
        return result
    return [{"path": item["path"], "repo": item["repository"]["full_name"],
             "url": item.get("html_url"), "sha": item.get("sha")}
            for item in result.get("items", [])]

# ---------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------

@mcp.tool()
def get_file(owner: str, repo: str, path: str, ref: str = "main") -> Any:
    """
    Get a file's content from a repository. Decodes base64 automatically.
    path is the file path relative to repo root e.g. 'web/app/page.tsx'.
    Returns content as text plus the SHA (needed for create_or_update_file).
    """
    result = _gh("GET", f"/repos/{owner}/{repo}/contents/{path}", params={"ref": ref})
    if "error" in result:
        return result
    if result.get("type") != "file":
        return {"error": f"Path '{path}' is not a file (type: {result.get('type')})"}
    try:
        content = base64.b64decode(result["content"]).decode("utf-8", errors="replace")
    except Exception as e:
        content = f"[binary or decode error: {e}]"
    return {
        "path": result["path"],
        "sha": result["sha"],
        "size": result.get("size"),
        "content": content,
        "encoding": result.get("encoding"),
    }


@mcp.tool()
def list_directory(owner: str, repo: str, path: str = "", ref: str = "main") -> Any:
    """
    List the contents of a directory in a repository.
    path defaults to repo root. Returns name, type (file/dir/symlink), size, sha.
    """
    result = _gh("GET", f"/repos/{owner}/{repo}/contents/{path}", params={"ref": ref})
    if "error" in result:
        return result
    if isinstance(result, list):
        return [{"name": item["name"], "path": item["path"], "type": item["type"],
                 "size": item.get("size"), "sha": item.get("sha")} for item in result]
    return result


@mcp.tool()
def create_or_update_file(owner: str, repo: str, path: str, content: str,
                           message: str, branch: str = "main", sha: str = "") -> Any:
    """
    Create or update a file in a repository.
    content is the raw text to write (not base64 - this tool handles encoding).
    sha is required when updating an existing file; omit to create a new file.
    Get the current sha with get_file first if updating.
    NEVER use this for .py files with literal \\n in content - pass real newlines.
    """
    body: dict[str, Any] = {
        "message": message,
        "content": base64.b64encode(content.encode("utf-8")).decode("ascii"),
        "branch": branch,
    }
    if sha:
        body["sha"] = sha
    return _gh("PUT", f"/repos/{owner}/{repo}/contents/{path}", json=body)


@mcp.tool()
def delete_file(owner: str, repo: str, path: str, message: str,
                sha: str, branch: str = "main") -> Any:
    """
    Delete a file from a repository.
    sha is required - get it from get_file first.
    """
    return _gh("DELETE", f"/repos/{owner}/{repo}/contents/{path}",
               json={"message": message, "sha": sha, "branch": branch})

# ---------------------------------------------------------------------------
# Issues
# ---------------------------------------------------------------------------

@mcp.tool()
def list_issues(owner: str, repo: str, state: str = "open",
                labels: str = "", max_results: int = 30) -> Any:
    """
    List issues in a repository.
    state: 'open', 'closed', 'all'.
    labels: comma-separated label names to filter by.
    """
    params: dict[str, Any] = {"state": state, "per_page": min(max_results, 100)}
    if labels:
        params["labels"] = labels
    items = _paginate(f"/repos/{owner}/{repo}/issues", params, max_results)
    return [{"number": i["number"], "title": i["title"], "state": i["state"],
             "labels": [l["name"] for l in i.get("labels", [])],
             "created_at": i.get("created_at"), "url": i.get("html_url")}
            for i in items if isinstance(i, dict) and "pull_request" not in i]


@mcp.tool()
def get_issue(owner: str, repo: str, issue_number: int) -> Any:
    """Get a single issue including its body and comments count."""
    return _gh("GET", f"/repos/{owner}/{repo}/issues/{issue_number}")


@mcp.tool()
def create_issue(owner: str, repo: str, title: str, body: str = "",
                 labels: list[str] | None = None) -> Any:
    """Create a new issue. labels is an optional list of label name strings."""
    payload: dict[str, Any] = {"title": title, "body": body}
    if labels:
        payload["labels"] = labels
    return _gh("POST", f"/repos/{owner}/{repo}/issues", json=payload)


@mcp.tool()
def update_issue(owner: str, repo: str, issue_number: int,
                 title: str = "", body: str = "", state: str = "",
                 labels: list[str] | None = None) -> Any:
    """
    Update an issue's title, body, state, or labels.
    Only fields you provide are changed. state: 'open' or 'closed'.
    """
    payload: dict[str, Any] = {}
    if title:
        payload["title"] = title
    if body:
        payload["body"] = body
    if state:
        payload["state"] = state
    if labels is not None:
        payload["labels"] = labels
    return _gh("PATCH", f"/repos/{owner}/{repo}/issues/{issue_number}", json=payload)


@mcp.tool()
def close_issue(owner: str, repo: str, issue_number: int) -> Any:
    """Close an issue."""
    return _gh("PATCH", f"/repos/{owner}/{repo}/issues/{issue_number}",
               json={"state": "closed"})


@mcp.tool()
def add_issue_comment(owner: str, repo: str, issue_number: int, body: str) -> Any:
    """Add a comment to an issue or pull request."""
    return _gh("POST", f"/repos/{owner}/{repo}/issues/{issue_number}/comments",
               json={"body": body})


@mcp.tool()
def list_issue_comments(owner: str, repo: str, issue_number: int) -> Any:
    """List all comments on an issue or pull request."""
    items = _paginate(f"/repos/{owner}/{repo}/issues/{issue_number}/comments", {}, 100)
    return [{"id": c["id"], "author": c["user"]["login"],
             "body": c["body"], "created_at": c.get("created_at")}
            for c in items if isinstance(c, dict)]

# ---------------------------------------------------------------------------
# Pull Requests
# ---------------------------------------------------------------------------

@mcp.tool()
def list_prs(owner: str, repo: str, state: str = "open", max_results: int = 20) -> Any:
    """List pull requests. state: 'open', 'closed', 'all'."""
    items = _paginate(f"/repos/{owner}/{repo}/pulls", {"state": state}, max_results)
    return [{"number": p["number"], "title": p["title"], "state": p["state"],
             "head": p["head"]["ref"], "base": p["base"]["ref"],
             "draft": p.get("draft"), "created_at": p.get("created_at"),
             "url": p.get("html_url")}
            for p in items if isinstance(p, dict)]


@mcp.tool()
def get_pr(owner: str, repo: str, pr_number: int) -> Any:
    """Get a single pull request with full details."""
    return _gh("GET", f"/repos/{owner}/{repo}/pulls/{pr_number}")


@mcp.tool()
def create_pr(owner: str, repo: str, title: str, head: str, base: str,
              body: str = "", draft: bool = False) -> Any:
    """
    Create a pull request.
    head: the branch with your changes (e.g. 'feature/my-branch').
    base: the branch to merge into (e.g. 'main').
    """
    return _gh("POST", f"/repos/{owner}/{repo}/pulls",
               json={"title": title, "head": head, "base": base,
                     "body": body, "draft": draft})


@mcp.tool()
def update_pr(owner: str, repo: str, pr_number: int,
              title: str = "", body: str = "", state: str = "", base: str = "") -> Any:
    """Update a pull request's title, body, state, or base branch."""
    payload: dict[str, Any] = {}
    if title:
        payload["title"] = title
    if body:
        payload["body"] = body
    if state:
        payload["state"] = state
    if base:
        payload["base"] = base
    return _gh("PATCH", f"/repos/{owner}/{repo}/pulls/{pr_number}", json=payload)


@mcp.tool()
def merge_pr(owner: str, repo: str, pr_number: int,
             merge_method: str = "squash", commit_title: str = "") -> Any:
    """
    Merge a pull request.
    merge_method: 'merge', 'squash', or 'rebase'. Defaults to 'squash'.
    """
    payload: dict[str, Any] = {"merge_method": merge_method}
    if commit_title:
        payload["commit_title"] = commit_title
    return _gh("PUT", f"/repos/{owner}/{repo}/pulls/{pr_number}/merge", json=payload)


@mcp.tool()
def list_pr_files(owner: str, repo: str, pr_number: int) -> Any:
    """List files changed in a pull request."""
    items = _paginate(f"/repos/{owner}/{repo}/pulls/{pr_number}/files", {}, 100)
    return [{"filename": f["filename"], "status": f["status"],
             "additions": f["additions"], "deletions": f["deletions"],
             "patch": f.get("patch", "")[:2000]}
            for f in items if isinstance(f, dict)]


@mcp.tool()
def list_pr_reviews(owner: str, repo: str, pr_number: int) -> Any:
    """List reviews submitted on a pull request."""
    items = _paginate(f"/repos/{owner}/{repo}/pulls/{pr_number}/reviews", {}, 50)
    return [{"id": r["id"], "state": r["state"], "author": r["user"]["login"],
             "body": r.get("body", ""), "submitted_at": r.get("submitted_at")}
            for r in items if isinstance(r, dict)]


@mcp.tool()
def create_pr_review(owner: str, repo: str, pr_number: int,
                     body: str, event: str = "COMMENT") -> Any:
    """
    Submit a review on a pull request.
    event: 'APPROVE', 'REQUEST_CHANGES', or 'COMMENT'.
    """
    return _gh("POST", f"/repos/{owner}/{repo}/pulls/{pr_number}/reviews",
               json={"body": body, "event": event})

# ---------------------------------------------------------------------------
# GitHub Actions
# ---------------------------------------------------------------------------

@mcp.tool()
def list_workflows(owner: str, repo: str) -> Any:
    """List all workflows defined in a repository."""
    result = _gh("GET", f"/repos/{owner}/{repo}/actions/workflows")
    if "error" in result:
        return result
    return [{"id": w["id"], "name": w["name"], "filename": w["path"].split("/")[-1],
             "state": w["state"], "url": w.get("html_url")}
            for w in result.get("workflows", [])]


@mcp.tool()
def list_workflow_runs(owner: str, repo: str, workflow_filename: str,
                       limit: int = 10) -> Any:
    """List recent runs for a workflow. limit max 30."""
    limit = min(limit, 30)
    result = _gh("GET", f"/repos/{owner}/{repo}/actions/workflows/{workflow_filename}/runs",
                 params={"per_page": limit})
    if "error" in result:
        return result
    from datetime import datetime, timezone
    runs = []
    for r in result.get("workflow_runs", []):
        duration = None
        try:
            fmt = "%Y-%m-%dT%H:%M:%SZ"
            s = datetime.strptime(r["run_started_at"], fmt).replace(tzinfo=timezone.utc)
            e = datetime.strptime(r["updated_at"], fmt).replace(tzinfo=timezone.utc)
            duration = int((e - s).total_seconds())
        except Exception:
            pass
        runs.append({"run_id": r["id"], "status": r["status"], "conclusion": r["conclusion"],
                     "started_at": r.get("run_started_at"), "duration_seconds": duration,
                     "triggered_by": r.get("event"), "url": r.get("html_url")})
    return {"workflow": workflow_filename, "runs": runs}


@mcp.tool()
def get_workflow_run(owner: str, repo: str, run_id: int) -> Any:
    """Get details for a specific workflow run by ID."""
    return _gh("GET", f"/repos/{owner}/{repo}/actions/runs/{run_id}")


@mcp.tool()
def trigger_workflow(owner: str, repo: str, workflow_filename: str,
                     ref: str = "main", inputs: dict | None = None) -> Any:
    """
    Trigger a workflow_dispatch event on a workflow.
    inputs is an optional dict of input key/value pairs.
    """
    payload: dict[str, Any] = {"ref": ref}
    if inputs:
        payload["inputs"] = inputs
    return _gh("POST",
               f"/repos/{owner}/{repo}/actions/workflows/{workflow_filename}/dispatches",
               json=payload)


@mcp.tool()
def cancel_workflow_run(owner: str, repo: str, run_id: int) -> Any:
    """Cancel a running workflow run."""
    return _gh("POST", f"/repos/{owner}/{repo}/actions/runs/{run_id}/cancel")


@mcp.tool()
def list_run_jobs(owner: str, repo: str, run_id: int) -> Any:
    """List jobs for a workflow run with step-level status."""
    result = _gh("GET", f"/repos/{owner}/{repo}/actions/runs/{run_id}/jobs")
    if "error" in result:
        return result
    jobs = []
    for job in result.get("jobs", []):
        steps = [{"name": s["name"], "status": s["status"],
                  "conclusion": s.get("conclusion"), "number": s["number"]}
                 for s in job.get("steps", [])]
        jobs.append({"job_id": job["id"], "name": job["name"], "status": job["status"],
                     "conclusion": job.get("conclusion"), "started_at": job.get("started_at"),
                     "completed_at": job.get("completed_at"), "steps": steps,
                     "url": job.get("html_url")})
    return {"run_id": run_id, "jobs": jobs}


@mcp.tool()
def get_job_logs(owner: str, repo: str, job_id: int, max_lines: int = 200) -> Any:
    """
    Fetch the log for a specific workflow job.
    Returns the last max_lines lines (cap 500).
    Get job_id from list_run_jobs.
    """
    max_lines = min(max_lines, 500)
    headers = {
        "Authorization": f"Bearer {GH_PAT}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    try:
        resp = requests.get(
            f"{GITHUB_API}/repos/{owner}/{repo}/actions/jobs/{job_id}/logs",
            headers=headers, timeout=30, allow_redirects=True,
        )
        if resp.status_code == 302:
            resp = requests.get(resp.headers["Location"], timeout=30)
        if resp.status_code != 200:
            return {"error": f"GitHub API {resp.status_code}"}
        lines = resp.text.splitlines()
        return {"job_id": job_id, "total_lines": len(lines),
                "lines": lines[-max_lines:]}
    except Exception as e:
        return {"error": str(e)}


@mcp.tool()
def list_artifacts(owner: str, repo: str, run_id: int) -> Any:
    """List artifacts produced by a workflow run."""
    result = _gh("GET", f"/repos/{owner}/{repo}/actions/runs/{run_id}/artifacts")
    if "error" in result:
        return result
    return [{"id": a["id"], "name": a["name"], "size_mb": round(a["size_in_bytes"] / 1_048_576, 2),
             "created_at": a.get("created_at"), "expires_at": a.get("expires_at")}
            for a in result.get("artifacts", [])]

# ---------------------------------------------------------------------------
# Releases
# ---------------------------------------------------------------------------

@mcp.tool()
def list_releases(owner: str, repo: str, max_results: int = 10) -> Any:
    """List releases in a repository."""
    items = _paginate(f"/repos/{owner}/{repo}/releases", {}, max_results)
    return [{"id": r["id"], "tag": r.get("tag_name"), "name": r.get("name"),
             "draft": r.get("draft"), "prerelease": r.get("prerelease"),
             "published_at": r.get("published_at"), "url": r.get("html_url")}
            for r in items if isinstance(r, dict)]


@mcp.tool()
def get_release(owner: str, repo: str, release_id: int) -> Any:
    """Get a specific release by ID."""
    return _gh("GET", f"/repos/{owner}/{repo}/releases/{release_id}")


@mcp.tool()
def create_release(owner: str, repo: str, tag: str, name: str,
                   body: str = "", draft: bool = False, prerelease: bool = False) -> Any:
    """Create a release. tag is the git tag to create the release from."""
    return _gh("POST", f"/repos/{owner}/{repo}/releases",
               json={"tag_name": tag, "name": name, "body": body,
                     "draft": draft, "prerelease": prerelease})

# ---------------------------------------------------------------------------
# Org
# ---------------------------------------------------------------------------

@mcp.tool()
def list_org_repos(org: str, repo_type: str = "all", max_results: int = 50) -> Any:
    """
    List all repositories in a GitHub organization.
    repo_type: 'all', 'public', 'private', 'forks', 'sources', 'member'.
    """
    items = _paginate(f"/orgs/{org}/repos", {"type": repo_type, "sort": "updated"}, max_results)
    return [{"name": r["name"], "full_name": r["full_name"], "private": r["private"],
             "description": r.get("description"), "default_branch": r.get("default_branch"),
             "pushed_at": r.get("pushed_at"), "url": r.get("html_url")}
            for r in items if isinstance(r, dict)]


@mcp.tool()
def list_org_members(org: str, max_results: int = 50) -> Any:
    """List members of a GitHub organization."""
    items = _paginate(f"/orgs/{org}/members", {}, max_results)
    return [{"login": m["login"], "url": m.get("html_url")} for m in items if isinstance(m, dict)]


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import socket
    import uvicorn

    # SO_REUSEADDR pre-bound socket: rebind :8766 across a graceful restart
    # without the [Errno 48] race. SO_REUSEPORT intentionally NOT set (it would
    # let a stray second instance silently share the port). See decision 0010.
    _sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    _sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    _sock.bind(("127.0.0.1", 8766))
    _sock.listen()

    app = mcp.streamable_http_app()
    app.add_middleware(BearerAuthMiddleware)
    _config = uvicorn.Config(app, host="127.0.0.1", port=8766)
    uvicorn.Server(_config).run(sockets=[_sock])
