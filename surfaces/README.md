# Surface profiles

How Claude should operate on each surface, so you are never blocked and never told a
capability exists that does not. One profile per surface.

## Operating model: always-complete, never degraded
For any requested action, resolve in this order:
1. **Native** on this surface (do it directly).
2. **Remote MCP** (call the Mac or a hosted service to do it).
3. **Generated prompt** (produce a ready-to-run command/prompt for the user to execute where
   it is possible).

Never silently fail because the surface lacks a capability. State which path is being used.

## Credentials (all surfaces)
Secrets resolve through 1Password, referenced by `op://`, never stored as values. The
bootstrap is a 1Password Service Account token (rotate per `decisions/0001` if it breaks).
The hosted **op-mcp connector** resolves secrets off-Mac on every surface when healthy
(current status: [`credentials-map.md`](../credentials-map.md); runbook: `connectors/op-mcp/DEPLOY.md`). To *use* a
secret in a command, prefer the Mac's `op_run`/`op_inject` (value stays out of the transcript);
`op_read` only when the Mac is off and the hosted connector is healthy.

## Profiles
- `code-mac.md` - primary, most capable.
- `code-work-machines.md` - work laptop and desktop (restricted).
- `cowork.md`
- `claude-ai-web.md`
- `iphone.md`

`always-loaded-instructions.md` is the canonical hookless always-loaded block, split into a
self-contained **CORE** (behavior, no tools/repo assumed) + a **Cowork operating block** (agentic
work rules). Paste **CORE** into claude.ai **Settings > Profile > Preferences** (account-wide,
covers iPhone - owner's choice 2026-06-16); paste **CORE + the Cowork block** into Cowork
instructions. CORE carries the four standing rules (no sycophancy, terse, no capitulation,
read-for-intent) that a hook enforces on Code but nothing enforces on a hookless surface.

The `surface-check` skill reports what is loaded vs missing on the current surface.
