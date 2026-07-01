---
name: vault-resolve
description: Use when you need a secret's actual value at runtime - reading an API key/token/password, wiring a new env var, or a script needs a credential - and want it resolved from the 1Password vault on the current surface without leaking it. Symptoms include op:// references, "where does this secret come from", op_read/op CLI, "resolve the credential".
---

# vault-resolve

The `web-variables` 1Password vault is the **sole source** of secret values
([secrets-as-references](../../../rules/global/secrets-as-references.md)). This skill is how to
pull a value at runtime on whatever surface you are on, never how to store one in a file. The
canonical index of what every reference is and where it resolves is
[credentials-map.md](../../../credentials-map.md) - read it to find the right item/field.

## Resolve by surface

**Determine the surface first:** if `op whoami` succeeds in this shell you are on the Mac - use the
`op` CLI. If it errors (or you are off-Mac), use the op-mcp MCP tools.

| Surface | How | Note |
|---|---|---|
| Code (Mac, this Bash) | `op read "op://web-variables/<ITEM>/<field>"` | SA token in shell env; `op` is authenticated. Verify with `op whoami`. |
| Code / Cowork (off-Mac) | op-mcp MCP `op_read` / `op_run` | via the connector; needs the bearer. If MCP returns `unauthorized`, fall back to local Bash `op`. |
| GitHub Actions | `1password/load-secrets-action@v2` + `op://` env | bootstrap = repo secret `OP_SERVICE_ACCOUNT_TOKEN`. Never `secrets.<X>` for vault values. |

The Mac MCP tools (`ec6a9080…` / `e4f92151…`) often return `unauthorized` in a Claude session
(stale connector bearer, not the SA) - when they do, **drive vault reads through local Bash `op`**.
[[mac-connector-tooling]]

## The field-label gotcha (read before wiring a new ref)

`op://web-variables/<ITEM>/<field>` - `<field>` must match the item's **real field label**, which
is NOT always `credential`. Verified: `GITHUB_PAT` resolves at `/token`, not `/credential`. The
[map](../../../credentials-map.md) records the exact `op_ref` per item - trust it, or discover
labels with `op item get "<ITEM>" --vault web-variables --format json` (concealed fields stay
masked without `--reveal`). A wrong label resolves to empty and fails silently downstream.

## Never echo a value

- **Prefer injection over printing.** `op run -- <cmd>` and `op inject -i tpl -o out` pass secrets
  to a process without putting them on screen. Reach for `op read` only when you must, and never
  pipe it somewhere the value gets logged or committed.
- **Never `--reveal`** in a session whose transcript is captured (this one is). `op item get`
  masks concealed fields by default - keep it that way.
- A value that has appeared in any tracked file, log, or transcript is **compromised** → rotate it
  ([rotate-secret](../rotate-secret/SKILL.md)), do not just relocate it.
- New env var? Add it to `.env.template` as an `op://` URI, never a literal
  ([secrets-as-references](../../../rules/global/secrets-as-references.md)).

## Quick reference

```bash
op whoami                                            # which surface? success here = Mac local op
op run -- ./script.sh                                 # BEST: run a cmd with op:// env injected - value never printed
op inject -i config.tpl -o config                    # render a template - value goes to the file, not the screen
val=$(op read "op://web-variables/<ITEM>/<FIELD>")   # capture into a var WITHOUT printing; never run bare `op read` in a logged session
op item list --vault web-variables --format json     # discover item titles (no values)
```

The commands above are non-echoing **by construction**: `op run`/`op inject` pass the value to a
process or file, and `$(op read …)` captures it into a variable. Never run a bare `op read` whose
output lands in this transcript, and never substitute a literal value where `<ITEM>`/`<FIELD>`/`$val`
appear.

Related: [cleanse-secrets](../cleanse-secrets/SKILL.md) (find/strip leaked values),
[rotate-secret](../rotate-secret/SKILL.md) (replace a value everywhere). [[credentials-state]]
