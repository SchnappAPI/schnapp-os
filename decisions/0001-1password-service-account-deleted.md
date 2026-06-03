# 0001 — 1Password Service Account deleted (2026-06-03)

## Finding
`OP_SERVICE_ACCOUNT_TOKEN` is set on the Mac (852 chars) but the Service Account it
belongs to is DELETED. Every `op` call returns:
`403 Forbidden (Service Account Deleted): The Service Account used in this integration has been deleted.`

## Impact (verified this session)
- `op read` / `op run` / `op whoami`: DOWN on the Mac.
- `gh` (aliased to `op plugin run -- gh`): DOWN. The plain `gh` binary has no independent token.
- launchd services using `op-wrap` and any other consumer of the SA token: DOWN.
- GitHub Actions using the same SA secret: likely DOWN (verify in Part 4).
- Mac MCP `op_*` tools: likely DOWN if they share the SA token (verify in Part 4).

## Still healthy (verified)
- `git` over SSH (`git@github.com`): WORKS, authenticated as SchnappAPI. Push/pull/clone fine.
- GitHub MCP connector (OAuth, server `79bac402`): WORKS, admin/push on SchnappAPI repos.

## Why this matters
This is the recurring cross-surface "unauthorized" failure, caught live. It is owner-only
to fix. It supersedes the prior "secrets verified complete" memory, which is now stale.

## Remediation (owner)
1. Create a new 1Password Service Account; grant it the required vault(s).
2. Update the token everywhere it is stored:
   - `~/.zshrc` and `~/.zshenv` (Mac)
   - GitHub Actions secret `OP_SERVICE_ACCOUNT_TOKEN`
   - any other surface's secret store / connector
3. Confirm with `op whoami` and `gh auth status`.

## Note
`claude-kit` must be a PRIVATE repo. `SchnappAPI/schnapp-kit` is currently public; flag for
review since the record may contain sensitive config.
