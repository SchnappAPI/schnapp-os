# Headless Claude Code auth for the learning-worker

How `claude -p` authenticates when run from the macOS **launchd** LaunchAgent
(`scheduled-tasks/com.schnapp.memory-consolidation.plist` → `plugins/core/scripts/learning-worker.sh`),
and how to fix it when it 401s. Written after a long debugging arc (2026-06-27) so it never recurs.

## The core trap

launchd runs in a minimal, sandboxed environment. It **cannot read the login Keychain**, which is
where `claude setup-token` and interactive `/login` store OAuth credentials on macOS. So any headless
`claude -p` that relies on the Keychain 401s — even though `claude -p` works fine in your interactive
shell (which *can* read the Keychain). launchd also does **not** source `~/.zshrc`, and its `PATH` is
just `/usr/bin:/bin:/usr/sbin:/sbin`.

## Auth precedence (first match wins)

Per [code.claude.com/docs/en/authentication](https://code.claude.com/docs/en/authentication):

1. Cloud provider vars (`CLAUDE_CODE_USE_BEDROCK` / `_VERTEX` / `_FOUNDRY`)
2. `ANTHROPIC_AUTH_TOKEN` — bearer token for an LLM gateway/proxy (NOT a subscription OAuth token)
3. **`ANTHROPIC_API_KEY`** — direct API key (`X-Api-Key`); in `-p` mode it is always used when present
4. `apiKeyHelper` — a script whose stdout is the credential (re-invoked on 401 / every 5 min)
5. `CLAUDE_CODE_OAUTH_TOKEN` — long-lived (~1 yr) token from `claude setup-token`; subscription only
6. Keychain OAuth from `/login` — **launchd cannot read this**

`ANTHROPIC_API_KEY` (#3) beats both the OAuth token (#5) and the Keychain (#6). Set only ONE.

## What our worker does

`learning-worker.sh` resolves a credential from 1Password at runtime — the LaunchAgent inherits
`OP_SERVICE_ACCOUNT_TOKEN`, so `op read` works in that headless context (the login Keychain does not).
The reference is `LEARNING_CLAUDE_TOKEN_REF` (an `op://` reference, carried in the plist's
`EnvironmentVariables`). The worker then **auto-selects the env var by prefix**: `sk-ant-api…` →
`ANTHROPIC_API_KEY`, otherwise `CLAUDE_CODE_OAUTH_TOKEN`. It logs the outcome (length + which var,
never the value).

**Sanctioned credential: `ANTHROPIC_API_KEY`** (vault item `ANTHROPIC_API_KEY` in `web-variables`).
It is non-expiring, version-independent, and wins precedence over the Keychain. The subscription OAuth
path is a fallback only and was unreliable on CLI v2.1.112.

## Decoding the 401s

| API error | Meaning | In our arc |
|---|---|---|
| `Invalid authentication credentials` | No credential reached the API at all | the **wiring** bug — installed plist was missing `LEARNING_CLAUDE_TOKEN_REF`, so the worker resolved nothing |
| `Invalid bearer token` | A token was sent and rejected (expired / wrong type / unsupported / truncated) | the stored `CLAUDE_CODE_OAUTH_TOKEN` value, rejected (v2.1.112 + subscription/format caveats) |

## Fix / install checklist

```
[ ] Installed plist's EnvironmentVariables has BOTH:
      PATH = /usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin   (claude/op/git)
      LEARNING_CLAUDE_TOKEN_REF = op://web-variables/ANTHROPIC_API_KEY/credential
    Verify (no relay needed) with the Schnapp_Mac service_status tool — it prints the loaded env.
[ ] The op item value is a VALID key from platform.claude.com → API Keys (sk-ant-api03-…).
[ ] Only ONE credential env var ends up set (ANTHROPIC_API_KEY here; not also the OAuth token).
[ ] op item value has no trailing newline/space (op item edit stores exactly what you pass).
[ ] Re-install after any plist change: substitute __REPO__/__HOME__/__CLAUDE_TOKEN_REF__,
      then `launchctl unload && launchctl load`. (See scheduled-tasks/README.md.)
[ ] The worker log shows: "auth — resolved credential via op (N chars) -> ANTHROPIC_API_KEY"
      then "learning-worker: done". Logs: ~/Library/Logs/schnapp-os/memory-consolidation.{log,err.log}
```

## Gotchas worth remembering

- **The plist must be RE-installed after editing it in the repo.** launchd runs the copy in
  `~/Library/LaunchAgents/`, not the repo file. A pull alone does not update the installed plist.
  (This was the wiring bug: an old installed plist lacked `LEARNING_CLAUDE_TOKEN_REF`.)
- **`op read` works in your interactive shell via your personal login OR the SA**; under launchd it
  uses the **service account** (`OP_SERVICE_ACCOUNT_TOKEN`). Test the headless path by running the
  actual LaunchAgent (`launchctl start …`), not just `op read` in your shell.
- **Don't trust an in-shell `claude -p "say ok"`** to validate a credential: with no env var it uses
  the Keychain and says `ok` regardless. Validate by running the launchd job (no Keychain there) or by
  setting the env var explicitly.
- **`--bare`** (`claude --bare -p …`) skips Keychain reads and is the recommended mode for scripted
  calls; it pairs with `ANTHROPIC_API_KEY` (not the OAuth token). A future option if we harden further.

Sources: [Authentication](https://code.claude.com/docs/en/authentication),
[Headless](https://code.claude.com/docs/en/headless) — Claude Code docs.
