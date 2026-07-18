"""
obsidian-mcp/server.py

Remote MCP server for the Schnapp Obsidian vault.

Auth: Bearer token in the Authorization header, validated on every request.
      Set OBSIDIAN_MCP_AUTH_TOKEN in the service env (op-wrap.sh resolves
      ~/obsidian-mcp/.env.template). Configure the same value as the Custom
      header on the Cloudflare portal (mcp.schnapp.bet) server entry.

Vault:   ~/code/schnapp-vault
Port:    8767
Managed by: launchd (com.schnapp.obsidian-mcp.plist)
Transport: streamable-http
"""

import json
import os
from datetime import datetime, timezone
from pathlib import Path

import uvicorn
from mcp.server.fastmcp import FastMCP

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
VAULT = Path.home() / "code/schnapp-vault"
INDEX = VAULT / "_brain/_index.json"
MCP_TOKEN = os.environ.get("OBSIDIAN_MCP_AUTH_TOKEN", "")

mcp = FastMCP(
    name="obsidian-mcp",
    host="127.0.0.1",
    port=8767,
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
        body = json.dumps({"error": "unauthorized"}).encode()
        await send({"type": "http.response.start", "status": 401,
                    "headers": [[b"content-type", b"application/json"],
                                 [b"content-length", str(len(body)).encode()]]})
        await send({"type": "http.response.body", "body": body})

# ---------------------------------------------------------------------------
# MCP tools
# ---------------------------------------------------------------------------

def _resolve_note(path_or_title: str) -> Path | None:
    candidate = VAULT / path_or_title
    if candidate.exists():
        return candidate
    query = path_or_title.lower().removesuffix(".md")
    for f in VAULT.rglob("*.md"):
        if f.stem.lower() == query:
            return f
    return None


@mcp.tool()
def read_note(path_or_title: str) -> dict:
    """Read a note from the vault by relative path or title."""
    note = _resolve_note(path_or_title)
    if not note:
        return {"error": f"Note not found: {path_or_title}"}
    return {
        "path": str(note.relative_to(VAULT)),
        "content": note.read_text(encoding="utf-8"),
        "modified": datetime.fromtimestamp(note.stat().st_mtime, tz=timezone.utc).isoformat(),
    }


@mcp.tool()
def write_note(path: str, content: str) -> dict:
    """Create or overwrite a note. Path relative to vault root e.g. 'Daily/2026-06-16.md'."""
    target = VAULT / path
    if not path.endswith(".md"):
        target = target.with_suffix(".md")
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")
    return {"written": str(target.relative_to(VAULT)), "bytes": len(content.encode())}


@mcp.tool()
def append_note(path_or_title: str, content: str) -> dict:
    """Append content to an existing note."""
    note = _resolve_note(path_or_title)
    if not note:
        return {"error": f"Note not found: {path_or_title}"}
    existing = note.read_text(encoding="utf-8")
    separator = "\n" if existing.endswith("\n") else "\n\n"
    note.write_text(existing + separator + content, encoding="utf-8")
    return {"appended_to": str(note.relative_to(VAULT)), "added_bytes": len(content.encode())}


@mcp.tool()
def search_notes(query: str, folder: str = "", limit: int = 20) -> dict:
    """Full-text search across the vault. Optionally scope to a folder."""
    root = VAULT / folder if folder else VAULT
    if not root.exists():
        return {"error": f"Folder not found: {folder}"}
    query_lower = query.lower()
    results = []
    for f in sorted(root.rglob("*.md"), key=lambda p: p.stat().st_mtime, reverse=True):
        if f.is_relative_to(VAULT / "_brain"):
            continue
        try:
            text = f.read_text(encoding="utf-8")
            if query_lower in text.lower():
                snippet = next(
                    (line.strip() for line in text.splitlines() if query_lower in line.lower()),
                    text[:120].strip(),
                )
                results.append({
                    "path": str(f.relative_to(VAULT)),
                    "snippet": snippet[:200],
                    "modified": datetime.fromtimestamp(f.stat().st_mtime, tz=timezone.utc).isoformat(),
                })
                if len(results) >= limit:
                    break
        except Exception:
            continue
    return {"query": query, "count": len(results), "results": results}


@mcp.tool()
def list_notes(folder: str = "") -> dict:
    """List notes in a vault folder. Defaults to vault root."""
    root = VAULT / folder if folder else VAULT
    if not root.exists():
        return {"error": f"Folder not found: {folder}"}
    notes, dirs = [], []
    for item in sorted(root.iterdir()):
        if item.name.startswith(".") or item.name.startswith("_"):
            continue
        if item.is_dir():
            dirs.append({"name": item.name, "notes": sum(1 for _ in item.rglob("*.md"))})
        elif item.suffix == ".md":
            notes.append({
                "name": item.stem,
                "path": str(item.relative_to(VAULT)),
                "modified": datetime.fromtimestamp(item.stat().st_mtime, tz=timezone.utc).isoformat(),
            })
    return {"folder": folder or "/", "dirs": dirs, "notes": notes}


@mcp.tool()
def inbox_drop(title: str, content: str) -> dict:
    """Drop a note into Inbox/. Triggers the brain agent automatically via FSEvents."""
    safe = "".join(c if c.isalnum() or c in " -_" else "" for c in title).strip()
    filename = f"{safe}.md" if safe else f"{datetime.now(tz=timezone.utc).strftime('%Y%m%d-%H%M%S')}.md"
    target = VAULT / "Inbox" / filename
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")
    return {"dropped": str(target.relative_to(VAULT)), "brain_agent": "will process via FSEvents"}


@mcp.tool()
def get_index() -> dict:
    """Return the brain agent index: notes, clusters, and pending actions."""
    if not INDEX.exists():
        return {"error": "Index not found - brain agent may not have run yet"}
    idx = json.loads(INDEX.read_text(encoding="utf-8"))
    return {
        "note_count": len(idx.get("notes", [])),
        "clusters": idx.get("clusters", {}),
        "actions": idx.get("actions", []),
        "last_processed": idx.get("last_processed"),
        "recent_notes": idx.get("notes", [])[-10:],
    }


if __name__ == "__main__":
    import socket

    # SO_REUSEADDR pre-bound socket: rebind :8767 across a graceful restart
    # without the [Errno 48] race. SO_REUSEPORT intentionally NOT set (it would
    # let a stray second instance silently share the port). See decision 0010.
    _sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    _sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    _sock.bind((mcp.settings.host, mcp.settings.port))
    _sock.listen()

    app = mcp.streamable_http_app()
    app.add_middleware(BearerAuthMiddleware)
    _config = uvicorn.Config(
        app,
        host=mcp.settings.host,
        port=mcp.settings.port,
        log_level=mcp.settings.log_level.lower(),
    )
    uvicorn.Server(_config).run(sockets=[_sock])
