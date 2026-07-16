# 0034 — mac-mcp responses are self-identifying

**Status:** accepted (2026-07-16)
**Refines:** 0020 (portal fronting mac-mcp + github-mcp)

## Context

On 2026-07-16 one `shell_exec` call through the Schnapp Portal returned stdout belonging to a
different command: the output of a `cat property_profile.yaml` and an `ls Inbox/` that were not part
of that call. The next call returned correctly. One occurrence, but a tool response was silently
attributed to the wrong request, and nothing in the response said so.

The origin was ruled out:

- `connectors/mac-mcp/server.py` holds no shared output state. `shell_exec` / `op_run` use local
  variables and synchronous `subprocess.run(capture_output=True)`, so each call gets its own pipes.
  No module-level mutable output, no shared temp files, no caching. FastMCP runs each sync tool in
  its own worker thread with per-request locals.
- `mcp.err.log` shows the portal opening a brand-new streamable-HTTP transport session per tool call
  ("Created new transport with session ID: …" before each `CallToolRequest`). Each response is bound
  to its own HTTP connection; the origin cannot deliver call A's stdout to call B across sessions.

That puts the mix-up upstream of the origin, in the Cloudflare-managed MCP portal at
`mcp.schnapp.bet` (0020) or the tunnel path — most plausibly a late response from an earlier call
that timed out at the portal/client layer, surfaced against the next request. That layer is
Cloudflare-managed code we cannot patch, so prevention is not available to us.

## Decision

Make every response say what produced it, so a misdelivery is self-evident rather than silently
misleading. **Detection, not prevention** — the correlation we cannot trust is checked instead.

- Tools returning **opaque output** (`shell_exec`, `op_run`, `sql_query`) echo the caller's own input
  (`command` / `query`, truncated to 300 chars) plus a server-generated `call_id`
  (`uuid4().hex[:12]`) and UTC `ts`. `sql_query` is included on the same reasoning as the two the
  incident named: its response is equally anonymous and a misdelivered result set is the most
  dangerous of the three.
- Tools that already echo an identifier (`read_file`, `write_file`) gain `call_id` / `ts` only.
- Every return path carries the envelope, including `unauthorized`, `timeout`, and error paths.
- `op_run`'s echo is the **pre-scrub** command text. It is the caller's own input, so it reveals
  nothing the caller did not send, and scrubbing it would break the echo match the mechanism depends
  on. Resolved secret VALUES are still scrubbed from `stdout`/`stderr` as before.
- `_log_call` writes each `call_id` with its real input to `mcp.err.log`, so a suspect response can
  be traced to the command that actually produced it. Log lines run through `_redact_secrets`: the
  log is a disk sink, and a caller is free to put a secret in a command string.
- `MAX_COMMAND_TIMEOUT_SECONDS = 90` caps `shell_exec` / `op_run` / `sql_query` (was 600 / 600 / 120).
  A command outliving the edge timeout produces a response nothing is waiting for — the most
  plausible source of the orphan. A clamp is reported as `timeout_clamped_from` / `timeout_clamped_to`
  rather than applied silently.

## Consequences

- **A mismatch is now visible.** A caller compares the echo to what it sent; if they differ it has
  caught a misdelivery instead of acting on another call's output. This is the caller's check to
  make — the envelope makes it *possible*, it does not make it automatic.
- **Long commands fail attributably.** Anything over 90s previously ran to 600s and produced a
  response the caller could never receive anyway (the edge had already given up). It now returns a
  clean `timeout` naming the clamp. No result is lost that was reachable before.
- **`op_run`'s default timeout drops 120 → 90.** Its cached client-side schema still advertises 120;
  the server clamps and reports it.
- **Clients show stale tool descriptions until they reconnect.** The new docstrings reach a client
  only on reconnect; the response envelope is live immediately regardless.
- **One log line per call.** Absorbed by the existing `com.schnapp.macmcp.logrotate` rotation.

## Verification

Live through the portal after a graceful restart (2026-07-16):

- `shell_exec` echoed the exact command sent, with `call_id` + `ts`.
- `shell_exec` with `timeout=600` returned `timeout_clamped_from: 600, timeout_clamped_to: 90`.
- `op_run` injecting `op://web-variables/MAC_MCP_AUTH_TOKEN/credential` returned the envelope with
  `stdout: "probe-secret-is: ***\nlen=64\n"` — value resolved, never surfaced; scrub path intact.
- `read_file` carried `call_id` + expanded `path` on both the success and the not-found path.
- All four `call_id`s traced to their real input in `mcp.err.log`; the token value was confirmed
  absent from that log.
- An AST pass asserts every `return` in the five tools carries identity.

**Verified:** the tunnel sets only `connectTimeout: 30s` in `/etc/cloudflared/config.yml` — a TCP
connect timeout, not a response timeout — so cloudflared imposes no origin response deadline.
**Not independently measured:** the portal/edge's actual response deadline. 90s sits below
Cloudflare's documented ~100s origin-response limit (524) with headroom. Measuring it exactly would
mean temporarily removing the cap on a live service, which was not judged worth it; if the real
limit proves lower, `MAX_COMMAND_TIMEOUT_SECONDS` is a one-line change.

The root cause is unfixable from here. If a mismatch is ever observed again, the echo plus the
`mcp.err.log` ledger is the evidence to take to the portal layer.
