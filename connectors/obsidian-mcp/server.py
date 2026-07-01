"""
obsidian-mcp/server.py

Remote MCP server for the Schnapp Obsidian vault.
OAuth 2.1 + PKCE + Dynamic Client Registration via FastMCP native auth.

Vault:   ~/code/schnapp-vault
Port:    8767
"""

import json
import os
import secrets
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlencode

import uvicorn
from mcp.server.auth.provider import (
    OAuthAuthorizationServerProvider,
    AuthorizationParams,
    AccessToken,
    RefreshToken as RefreshTokenBase,
    AuthorizationCode as AuthorizationCodeBase,
)
from mcp.server.auth.settings import AuthSettings, ClientRegistrationOptions
from mcp.server.fastmcp import FastMCP
from mcp.shared.auth import OAuthClientInformationFull, OAuthToken
from starlette.requests import Request
from starlette.responses import HTMLResponse, RedirectResponse

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
VAULT = Path.home() / "code/schnapp-vault"
INDEX = VAULT / "_brain/_index.json"
STATE_FILE = Path(__file__).parent / "oauth_state.json"
BASE_URL = "https://obsidian-mcp.schnapp.bet"

# One-time boot secret for CSRF on the consent form
BOOT_SECRET = secrets.token_urlsafe(32)

# ---------------------------------------------------------------------------
# Persistent state helpers
# ---------------------------------------------------------------------------

def _load() -> dict:
    if STATE_FILE.exists():
        try:
            return json.loads(STATE_FILE.read_text())
        except Exception:
            pass
    return {"clients": {}, "codes": {}, "tokens": {}, "refresh_tokens": {}}

def _save(state: dict):
    STATE_FILE.write_text(json.dumps(state, indent=2))

# ---------------------------------------------------------------------------
# Token types
# ---------------------------------------------------------------------------

class StoredAccessToken(AccessToken):
    pass  # AccessToken is a Pydantic BaseModel with all required fields

# ---------------------------------------------------------------------------
# OAuth provider implementation
# ---------------------------------------------------------------------------

class ObsidianOAuthProvider(OAuthAuthorizationServerProvider):

    async def get_client(self, client_id: str) -> OAuthClientInformationFull | None:
        state = _load()
        data = state["clients"].get(client_id)
        if not data:
            return None
        # Reconstruct the FULL registration. mcp>=1.x validates the requested scope at
        # /authorize and the auth method at /token against these fields; dropping them
        # yields invalid_scope and "Unsupported auth method: None". Round-trip everything.
        info = data.get("info")
        if info:
            return OAuthClientInformationFull.model_validate(info)
        # Legacy partial record (pre-fix): supply sane defaults so old clients still work.
        return OAuthClientInformationFull(
            client_id=client_id,
            client_secret=data.get("client_secret"),
            redirect_uris=data.get("redirect_uris", []),
            client_name=data.get("client_name", "Claude"),
            scope="mcp:tools",
            token_endpoint_auth_method=data.get("token_endpoint_auth_method", "client_secret_post"),
        )

    async def register_client(self, client_info: OAuthClientInformationFull) -> None:
        state = _load()
        # Persist the complete client registration so get_client() round-trips every field
        # the auth layer validates (scope, token_endpoint_auth_method, grant/response types).
        state["clients"][client_info.client_id] = {
            "info": client_info.model_dump(mode="json"),
            "registered_at": int(time.time()),
        }
        _save(state)

    async def authorize(self, client: OAuthClientInformationFull, params: AuthorizationParams) -> str:
        """Return URL of our consent page — FastMCP redirects the user there."""
        qs = urlencode({
            "client_id":             client.client_id,
            "redirect_uri":          str(params.redirect_uri),
            "state":                 params.state or "",
            "code_challenge":        params.code_challenge or "",
            "code_challenge_method": "S256",  # mcp>=1.x AuthorizationParams has no code_challenge_method field; S256 is the only supported method
            "scope":                 " ".join(params.scopes or ["mcp:tools"]),
            "boot_secret":           BOOT_SECRET,
        })
        return f"{BASE_URL}/consent?{qs}"

    async def load_authorization_code(
        self, client: OAuthClientInformationFull, authorization_code: str
    ) -> AuthorizationCodeBase | None:
        state = _load()
        data = state["codes"].get(authorization_code)
        if not data or data["client_id"] != client.client_id:
            return None
        if data["expires_at"] < int(time.time()):
            del state["codes"][authorization_code]
            _save(state)
            return None
        return AuthorizationCodeBase(
            code=authorization_code,
            scopes=data["scope"].split() if data.get("scope") else ["mcp:tools"],
            expires_at=data["expires_at"],
            client_id=data["client_id"],
            code_challenge=data["code_challenge"],
            redirect_uri=data["redirect_uri"],
            redirect_uri_provided_explicitly=True,
            resource=data.get("resource"),
        )

    async def exchange_authorization_code(
        self, client: OAuthClientInformationFull, authorization_code: AuthorizationCodeBase
    ) -> OAuthToken:
        # PKCE is verified by the framework's token handler before this is called.
        scope_str = " ".join(authorization_code.scopes) if authorization_code.scopes else "mcp:tools"
        access_token  = secrets.token_urlsafe(48)
        refresh_token = secrets.token_urlsafe(48)
        expires_in    = 3600

        state = _load()
        state["tokens"][access_token] = {
            "client_id": client.client_id,
            "scope": scope_str,
            "expires_at": int(time.time()) + expires_in,
        }
        state["refresh_tokens"][refresh_token] = {
            "client_id": client.client_id,
            "scope": scope_str,
            "access_token": access_token,
        }
        if authorization_code.code in state["codes"]:
            del state["codes"][authorization_code.code]
        _save(state)

        return OAuthToken(
            access_token=access_token,
            token_type="Bearer",
            expires_in=expires_in,
            refresh_token=refresh_token,
            scope=scope_str,
        )

    async def load_refresh_token(
        self, client: OAuthClientInformationFull, refresh_token: str
    ) -> RefreshTokenBase | None:
        state = _load()
        data = state["refresh_tokens"].get(refresh_token)
        if not data or data["client_id"] != client.client_id:
            return None
        return RefreshTokenBase(
            token=refresh_token,
            client_id=data["client_id"],
            scopes=data["scope"].split() if data.get("scope") else ["mcp:tools"],
            expires_at=None,
        )

    async def exchange_refresh_token(
        self, client: OAuthClientInformationFull, refresh_token: RefreshTokenBase, scopes: list[str]
    ) -> OAuthToken:
        state = _load()
        old = state["refresh_tokens"].get(refresh_token.token, {})
        old_access = old.get("access_token")
        if old_access and old_access in state["tokens"]:
            del state["tokens"][old_access]

        access_token      = secrets.token_urlsafe(48)
        new_refresh_token = secrets.token_urlsafe(48)
        expires_in        = 3600
        scope             = " ".join(scopes) if scopes else " ".join(refresh_token.scopes)

        state["tokens"][access_token] = {
            "client_id": client.client_id,
            "scope": scope,
            "expires_at": int(time.time()) + expires_in,
        }
        state["refresh_tokens"][new_refresh_token] = {
            "client_id": client.client_id,
            "scope": scope,
            "access_token": access_token,
        }
        if refresh_token.token in state["refresh_tokens"]:
            del state["refresh_tokens"][refresh_token.token]
        _save(state)

        return OAuthToken(
            access_token=access_token,
            token_type="Bearer",
            expires_in=expires_in,
            refresh_token=new_refresh_token,
            scope=scope,
        )

    async def load_access_token(self, token: str) -> StoredAccessToken | None:
        state = _load()
        data = state["tokens"].get(token)
        if not data:
            return None
        if data["expires_at"] < int(time.time()):
            del state["tokens"][token]
            _save(state)
            return None
        return StoredAccessToken(
            token=token,
            client_id=data["client_id"],
            scopes=data["scope"].split() if data.get("scope") else ["mcp:tools"],
            expires_at=data["expires_at"],
        )

    async def revoke_token(self, token) -> None:
        state = _load()
        changed = False
        tok = getattr(token, "token", None)
        if tok:
            if tok in state["tokens"]:
                del state["tokens"][tok]
                changed = True
            if tok in state["refresh_tokens"]:
                del state["refresh_tokens"][tok]
                changed = True
        if changed:
            _save(state)

# ---------------------------------------------------------------------------
# Consent page routes (mounted separately by FastMCP as custom_routes)
# ---------------------------------------------------------------------------

async def consent_get(request: Request) -> HTMLResponse:
    p = dict(request.query_params)
    client_id = p.get("client_id", "unknown")
    state = _load()
    client_name = state["clients"].get(client_id, {}).get("client_name", client_id)
    scope = p.get("scope", "mcp:tools")
    boot = p.get("boot_secret", "")

    hidden = "".join(
        f'<input type="hidden" name="{k}" value="{v}">'
        for k, v in p.items()
    )
    html = f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Obsidian MCP — Authorize</title>
  <style>
    body{{font-family:-apple-system,sans-serif;max-width:440px;margin:80px auto;padding:0 24px;color:#111}}
    h1{{font-size:20px;margin-bottom:6px}}
    p{{color:#555;font-size:14px;line-height:1.5;margin:0 0 16px}}
    .card{{border:1px solid #e0e0e0;border-radius:10px;padding:20px;margin:20px 0;font-size:14px}}
    .scope{{font-family:monospace;background:#f3f3f3;padding:2px 6px;border-radius:4px}}
    button{{background:#7c3aed;color:#fff;border:none;border-radius:8px;
            padding:11px 0;font-size:15px;cursor:pointer;width:100%;margin-top:4px}}
    button:hover{{background:#6d28d9}}
  </style>
</head>
<body>
  <h1>Obsidian MCP</h1>
  <p>A client is requesting access to your Obsidian vault.</p>
  <div class="card">
    <strong>Client:</strong> {client_name}<br><br>
    <strong>Scope:</strong> <span class="scope">{scope}</span>
  </div>
  <form method="POST" action="/consent">
    {hidden}
    <button type="submit">Authorize Access</button>
  </form>
</body>
</html>"""
    return HTMLResponse(html)


async def consent_post(request: Request) -> RedirectResponse:
    form = dict(await request.form())
    boot = form.get("boot_secret", "")
    if not secrets.compare_digest(boot, BOOT_SECRET):
        return HTMLResponse("Invalid request.", status_code=403)

    client_id        = form.get("client_id", "")
    redirect_uri     = form.get("redirect_uri", "")
    state_param      = form.get("state", "")
    code_challenge   = form.get("code_challenge", "")
    challenge_method = form.get("code_challenge_method", "S256")
    scope            = form.get("scope", "mcp:tools")

    code = secrets.token_urlsafe(32)
    state = _load()
    state["codes"][code] = {
        "client_id":             client_id,
        "redirect_uri":          redirect_uri,
        "code_challenge":        code_challenge,
        "code_challenge_method": challenge_method,
        "scope":                 scope,
        "expires_at":            int(time.time()) + 600,
    }
    _save(state)

    qs = urlencode({"code": code, "state": state_param})
    return RedirectResponse(url=f"{redirect_uri}?{qs}", status_code=302)

# ---------------------------------------------------------------------------
# Build and run
# ---------------------------------------------------------------------------

mcp = FastMCP(
    name="obsidian-mcp",
    host="127.0.0.1",
    port=8767,
    auth_server_provider=ObsidianOAuthProvider(),
    auth=AuthSettings(
        resource_server_url=BASE_URL,
        issuer_url=BASE_URL,
        client_registration_options=ClientRegistrationOptions(
            enabled=True,
            valid_scopes=["mcp:tools"],
            default_scopes=["mcp:tools"],
        ),
        required_scopes=["mcp:tools"],
    ),
)

# Add consent routes.
# NOTE: FastMCP (mcp>=1.x) builds its Starlette app from `_custom_starlette_routes`,
# which is populated ONLY by the custom_route() decorator. Assigning to the private
# `_custom_routes` attribute is silently ignored, dropping the consent page (404) and
# breaking the entire OAuth authorize->code->token flow. Use the supported API:
mcp.custom_route("/consent", methods=["GET"])(consent_get)
mcp.custom_route("/consent", methods=["POST"])(consent_post)

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
        return {"error": "Index not found — brain agent may not have run yet"}
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
    import uvicorn

    # Mirror FastMCP.run_streamable_http_async() (mcp 1.27.2): same
    # streamable_http_app() (carries the OAuth consent routes, decision 0009)
    # and Config(host, port, log_level) -- but serve a pre-bound
    # SO_REUSEADDR socket to rebind :8767 across a graceful restart without the
    # [Errno 48] race. SO_REUSEPORT intentionally NOT set (it would let a stray
    # second instance silently share the port). See decision 0010.
    _sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    _sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    _sock.bind((mcp.settings.host, mcp.settings.port))
    _sock.listen()

    _config = uvicorn.Config(
        mcp.streamable_http_app(),
        host=mcp.settings.host,
        port=mcp.settings.port,
        log_level=mcp.settings.log_level.lower(),
    )
    uvicorn.Server(_config).run(sockets=[_sock])
