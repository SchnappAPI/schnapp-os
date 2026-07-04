# Environment & access - the never-blocked configuration

Single source of truth for **what every surface must be allowed to reach** so neither the owner nor
Claude is ever blocked from doing the requested job. Born from the 2026-06-29 session where a removed
connector + an unallowlisted host + a read-only git relay each blocked work in turn (handoff 038).

Principle (from `surfaces/README.md`): *always-complete, never degraded.* A capability gap must be a
config fix here, not a silent failure. If a host/tool is blocked, the fix is to allow it, globally,
not to route around it.

## 1. Network egress allowlist (per-environment - the main thing to replicate)

Every outbound HTTPS host is **denied unless allowlisted** by the environment's network policy. This
is the one piece of config that is NOT global (it is set per web environment), so it must be applied
to **every** environment identically. Recommended: an **explicit allowlist** of exactly these hosts
(tightest security, never blocks a known service). A broad/unrestricted policy is the alternative if
convenience outweighs egress security - owner's call.

| Host | Purpose | Notes |
|---|---|---|
| `mac-mcp.schnapp.bet` | Mac MCP (shell, SQL, services, backups) | the `.mcp.json` `Schnapp_Mac` server |
| `obsidian-mcp.schnapp.bet` | Obsidian MCP (notes, off-Mac) | Mac-hosted |
| `mcp.schnapp.bet` | **Schnapp Portal**: OAuth front for op-mcp + memory-mcp + mac-mcp + github-mcp | Cloudflare Managed OAuth → the four origins (the claude.ai/iPhone path) |
| `github-mcp.schnapp.bet` | self-hosted GitHub MCP | |
| `mac-flask.schnapp.bet` | Flask live-data runner | |
| `dev.schnapp.bet`, `schnapp.bet` | production site / dev | |
| `memory-mcp-rtad.onrender.com` | cross-surface memory MCP (Render) | actual Render origin; also fronted by the `mcp.schnapp.bet` portal |
| `op-mcp.onrender.com` | op-mcp (Render) | superseded-by-Mac in some paths; keep if any client uses it |
| `github.com`, `api.github.com` | git + GitHub API (incl. the `shell/web-setup.sh` clones of both repos) | |
| `my.1password.com` | in-container `op` CLI (service-account API) | pairs with the `OP_SERVICE_ACCOUNT_TOKEN` env var |
| `cache.agilebits.com` | `op` CLI download | `shell/web-setup.sh` op-install step |
| `api.quickbase.com` | Quickbase integration | |
| `graph.microsoft.com`, `login.microsoftonline.com` | M365 / OneDrive backup mirror | needed for the backup + M365 MCP |
| `*.anthropic.com` | Claude API | already bypasses the proxy (noProxy) |

Symptom when a host is missing: the agent proxy returns **403 on CONNECT**; check
`curl "$HTTPS_PROXY/__agentproxy/status"` → `recentRelayFailures`. See [[mac-cloud-access]].

**Env vars (per-environment, literal VALUES)**: `OP_SERVICE_ACCOUNT_TOKEN`,
`MAC_MCP_AUTH_TOKEN`, `OP_MCP_BEARER`, `MEMORY_MCP_BEARER`. These are the one sanctioned
exception to secrets-as-references: a bootstrap credential cannot resolve itself, so the web
environment config holds the value directly (same class as the Mac's launchd plist env).
Exposure = anyone with access to the claude.ai environment settings; rotation via the
`rotate-secret` skill must include these fields (they are listed in `credentials-map.md`).

## 2. Git write path (cloud env is READ-ONLY for git)

The cloud session's git remote is a **read-only relay** (`127.0.0.1:<port>/git/...`): `fetch` works,
`push` returns **403**. Three ways to write, in preference order:

1. **Writable git for the environment (preferred).** If the platform supports granting the environment
   a push-capable token, local `git push` works directly - preserves file modes, supports branch
   deletes, no API gymnastics. This is the streamlined target.
2. **The Mac as the write node.** The Mac clone (`~/code/schnapp-os`) has full push creds. Route
   `git push` / `git push origin --delete <branch>` / `chmod` commits through `Schnapp_Mac` `shell_exec`.
   Works today; depends on the Mac being reachable.
3. **GitHub MCP (`push_files` / `create_or_update_file`).** Commits to `main` via the API without the
   Mac. **Limits:** drops the executable bit on files (re-`chmod` on the Mac after - see handoff 038),
   and has **no branch-delete** capability.

## 3. Known platform limitations + standing workarounds

| Limitation | Symptom | Workaround |
|---|---|---|
| MCP servers re-init each turn | "disconnected/reconnected" notices; "stream closed" tool errors | retry the call; keep the Mac warm (disable idle sleep); raise with support if persistent |
| `AskUserQuestion` unreliable here | "permission stream closed" | ask in plain text; take the recommended default and let the owner override |
| Large tool results overflow | e.g. `actions_list` 370k chars > token limit | query with filters; parse the saved result file with `jq`/python |
| `push_files` drops file mode | shell scripts land as `100644` | invoke via `bash script` (mode-agnostic) or `chmod 755` + commit on the Mac |
| Non-443 / raw-TCP / gRPC / mTLS | not tunnelable by the proxy | run it on the Mac, not from the cloud env |

## 4. Cross-surface delivery (what is global vs per-surface)

| Layer | Global? | How |
|---|---|---|
| Rules / skills / memory | ✅ | one repo; `@import` global rules; `autoMemoryDirectory` → repo path |
| `.mcp.json` MCP servers | ✅ | checked into the repo; carry to every Code/web surface |
| Secrets (`op://`) | ✅ | op-mcp connector + Mac `op_run`/`op_inject` |
| **Network allowlist** | ❌ per-environment | **must be set identically on every environment** (§1) |
| claude.ai / Cowork UI connectors | ⚠️ per-surface UI | prefer `.mcp.json`; the always-loaded block covers hookless surfaces |

To keep every surface working off the same data + tools: one repo (done), `.mcp.json` for servers
(done), and **the same §1 allowlist on every environment** (the only manual per-surface step).

## Owner steps (cannot be done from inside the repo)
1. Apply the §1 allowlist to the network policy of **every** web environment (recommended: explicit list).
2. Decide the git-write model (§2) - grant writable git if possible; else the Mac stays the write node.
3. Optional: keep the Mac MCP warm (disable idle sleep) to reduce reconnect flaps.
