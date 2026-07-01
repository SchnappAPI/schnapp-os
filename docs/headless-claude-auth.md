# Headless Claude Code auth for the learning-worker

How `claude -p` authenticates when run from the macOS **launchd** LaunchAgent
(`scheduled-tasks/com.schnapp.memory-consolidation.plist` → `scripts/learning-worker.sh`),
and how to fix it when it 401s. Written after a long debugging arc (2026-06-27) so it never recurs.

> **Correction (2026-06-29, ADR 0019):** an earlier version sanctioned `ANTHROPIC_API_KEY` and blamed CLI
> v2.1.112 for rejecting the subscription OAuth token. That was a misdiagnosis. The stored
> `CLAUDE_CODE_OAUTH_TOKEN` value was **malformed** (saved as `␣'sk-ant-oat…'`: a leading space + wrapping
> single-quotes, 111 bytes vs 108 clean), so a valid token was transmitted corrupted and rejected. Cleaned,
> it authenticates headless on v2.1.112 (verified). The worker now uses the **subscription** OAuth token.

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

**Sanctioned credential: the subscription OAuth token** (`op://web-variables/CLAUDE_CODE_OAUTH_TOKEN/credential`,
an `sk-ant-oat…` token from `claude setup-token`). Verified 2026-06-29 to authenticate headless on CLI
v2.1.112; it bills the Claude **subscription**, not the metered API, so it is the cost-discipline default
(AUDIT group K). It expires ~yearly (re-mint via `claude setup-token`). `ANTHROPIC_API_KEY` (`sk-ant-api…`,
non-expiring, **metered**) is the documented fallback; do not leave both set (the API key wins precedence
and silently switches billing).

## Decoding the 401s

| API error | Meaning | In our arc |
|---|---|---|
| `Invalid authentication credentials` | No credential reached the API at all | the **wiring** bug — installed plist was missing `LEARNING_CLAUDE_TOKEN_REF`, so the worker resolved nothing |
| `Invalid bearer token` | A token was sent and rejected (expired / wrong type / **malformed value** / truncated) | the stored `CLAUDE_CODE_OAUTH_TOKEN` was **malformed** (leading space + wrapping quotes); cleaned, it authenticates. **Not** a CLI-version issue (corrected 2026-06-29, ADR 0019) |

## Fix / install checklist

```
[ ] Installed plist's EnvironmentVariables has BOTH:
      PATH = /usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin   (claude/op/git)
      LEARNING_CLAUDE_TOKEN_REF = op://web-variables/CLAUDE_CODE_OAUTH_TOKEN/credential
    Verify (no relay needed) with the Schnapp_Mac service_status tool — it prints the loaded env.
[ ] The op item value is a VALID subscription token from `claude setup-token` (sk-ant-oat…).
[ ] The op item value has NO surrounding whitespace/quotes — this exact bug 401'd a valid token.
      Check raw bytes: `op read <ref> | head -c4 | xxd -p` starts 73 ('s'), not 2027 (space + quote).
[ ] Only ONE credential env var ends up set (CLAUDE_CODE_OAUTH_TOKEN here; not also ANTHROPIC_API_KEY,
      which wins precedence and switches billing to the metered API).
[ ] Re-install after any plist change: substitute __REPO__/__HOME__/__CLAUDE_TOKEN_REF__,
      then `launchctl unload && launchctl load`. (See scheduled-tasks/README.md.)
[ ] The worker log shows: "auth — resolved credential via op (N chars) -> CLAUDE_CODE_OAUTH_TOKEN"
      then "learning-worker: done". Logs: ~/Library/Logs/schnapp-os/memory-consolidation.{log,err.log}
```

## Gotchas worth remembering

- **A stored secret with surrounding whitespace/quotes is sent verbatim and 401s as `Invalid bearer
  token`** — indistinguishable at a glance from a bad token or a bad CLI. When a credential mysteriously
  fails, check its raw bytes (`op read <ref> | xxd | head`) before blaming the tool. This caused the
  2026-06-27 "v2.1.112 unreliable" misdiagnosis (corrected in ADR 0019).
- **The plist must be RE-installed after editing it in the repo.** launchd runs the copy in
  `~/Library/LaunchAgents/`, not the repo file. A pull alone does not update the installed plist.
  (This was the wiring bug: an old installed plist lacked `LEARNING_CLAUDE_TOKEN_REF`.)
- **`op read` works in your interactive shell via your personal login OR the SA**; under launchd it
  uses the **service account** (`OP_SERVICE_ACCOUNT_TOKEN`). Test the headless path by running the
  actual LaunchAgent (`launchctl start …`), not just `op read` in your shell.
- **Don't trust an in-shell `claude -p "say ok"`** to validate a credential: with no env var it uses
  the Keychain and says `ok` regardless. Validate by setting the env var explicitly — a clean
  `env -i … CLAUDE_CODE_OAUTH_TOKEN=… claude -p` reproduces the launchd path — or by running the launchd job.
- **`--bare`** (`claude --bare -p …`) skips Keychain reads but pairs with `ANTHROPIC_API_KEY`, **not** the
  OAuth token (a `--bare` + OAuth-token call reports "Not logged in"). To test the subscription path use a
  plain `claude -p` with `CLAUDE_CODE_OAUTH_TOKEN` set.

Sources: [Authentication](https://code.claude.com/docs/en/authentication),
[Headless](https://code.claude.com/docs/en/headless) — Claude Code docs.
