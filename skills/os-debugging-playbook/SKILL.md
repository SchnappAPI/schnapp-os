---
name: os-debugging-playbook
description: Use when something in schnapp-os is broken and you need the known-failure-mode triage before inventing a theory - "401 Invalid bearer token" on a stored secret, MCP tools silently missing on a cloud/web surface, a hook that is not firing, a launchd service crash-looping, a vault memory file rewritten into a nested schema, mac-mcp write_file destroyed a file, the first connector call hangs ~50s, a tool response that looks like someone else's output, Edit fails "File has not been read yet", a killed process that will not die, the freshness CI is red, or git push/stop is being blocked by a guard. Symptom in, discriminating experiment out.
---

# os-debugging-playbook

Every row below cost real debugging time once. Run the FIRST CHECK before forming any theory:
each one is a cheap discriminating experiment that splits the likely causes. History and full
post-mortems live in `decisions/`, `handoffs/`, and the vault memory lane
(`/Users/schnapp/code/schnapp-vault/memory/`); this file is the triage index, not the archive.

Paths are this machine's clones (`/Users/schnapp/code/schnapp-os`, `/Users/schnapp/code/schnapp-vault`);
on another machine substitute its clone paths.

## Triage table

| Symptom | First check | Root-cause fork | Fix | Story ref |
|---|---|---|---|---|
| `401 Invalid bearer token` (or generic auth error) on a stored secret | `op read "<op://ref>" \| head -c4 \| xxd -p` | Raw bytes start with `20`/`27` (space/quote) = malformed stored VALUE. Clean first bytes = actually a bad/expired token | Re-store the bare value, no whitespace/quotes/trailing newline. Do NOT rotate reflexively | decisions/0019; vault memory `malformed-stored-secret-401.md` |
| MCP tools silently absent in a cloud/web Claude Code session | `curl "$HTTPS_PROXY/__agentproxy/status"` and look for `connect_rejected ... 403 to CONNECT` | 403 CONNECT = host missing from the environment network allowlist. No 403 = server actually down (probe `/health`) | Owner adds the host (e.g. `mac-mcp.schnapp.bet`) to the environment's allowed domains in the web UI. Not connector shadowing | vault memory `mac-cloud-access.md` (corrects handoff 037 #1); decisions/0018 |
| A hook is not firing | Find its wiring: `grep -rn "<hook>" /Users/schnapp/code/schnapp-os/.claude/settings.json ~/.claude/settings.json` | Wrong scope (project vs user file), OR session started before the wiring change (hooks reload at session start), OR (desktop local-agent) a stale plugin pin replaying an old snapshot | Wire in the right file, restart the session. Plugin pin: uninstall + reinstall to re-pin to HEAD (`update` is version-keyed, no-ops) | hooks/README.md; vault memory `plugin-registry-snapshot-gotchas.md`; decisions/0024 |
| launchd service crash-loops at start, log says `unrecognized auth type` | `grep '^export OP_SERVICE_ACCOUNT_TOKEN=' ~/.zshrc` | `op-wrap.sh` greps the line literally (no sourcing) but strips one pair of surrounding DOUBLE quotes. Single quotes or inner whitespace = those chars ship into the token. Fully unquoted or double-quoted line = look elsewhere, read the service log | Safest form is fully unquoted: `export OP_SERVICE_ACCOUNT_TOKEN=ops_...`; then graceful-restart each service. Wrapper detail: `os-build-and-env` §1.4 | vault memory `op-wrap-token-unquoted.md` (broke all 6 services 2026-06-22; the fact predates the wrapper's double-quote stripping and needs superseding) |
| Mac connector restart slow / `[Errno 48] Address already in use` | Which restart command was used? | `launchctl kickstart -k` SIGKILLs and races the socket rebind; graceful TERM does not | Always `launchctl kill TERM gui/$(id -u)/<label>`; never `kickstart -k` | decisions/0010 |
| Vault memory fact file mutated into nested frontmatter (`metadata:`, `originSessionId`) | `head -15 <file>`: flat 8-key block or nested? | Harness auto-memory re-serializes Edit/Write-tool writes into the lane within ~2s. Contained: the vault pre-commit hook flattens at commit; CI backstops | For byte-exact writes use a shell redirect (`cat > file <<'EOF'`), not Edit/Write. Never adopt the nested form | decisions/0029; vault memory `harness-auto-memory-interception.md` |
| File on the Mac lost content after a connector write | Was `write_file` used on an existing file? | mac-mcp `write_file` OVERWRITES, no append mode (it truncated PROGRESS.md once) | Restore from git. Append via `shell_exec` `cat >> path <<'EOF'`; edit via python read-modify-write. Related: `shell_exec` strips the op identity, route secrets through `op_run` | vault memory `mac-connector-tooling.md`; handoffs/016 |
| First connector call after idle hangs ~50s or times out once | Retry once before declaring it down | Render free tier sleeps when idle (~50s cold start); the Mac host can also sleep with the same symptom | Expected; retry. `render-health.yml` doubles as keep-warm | connectors/memory-mcp/DEPLOY.md; vault memory `mac-cloud-access.md` |
| mac-mcp response looks like another call's output | Compare the response's echoed `command`/`query` + `call_id` to what you sent | Echo mismatch = portal-layer misdelivery (Cloudflare side, unpatchable; detection-only). Echo matches = your own confusion | Discard the response, retry, and keep the `call_id`: trace it in the Mac's `mcp.err.log`. Commands are clamped to 90s for this reason | decisions/0034 (2026-07-16 incident) |
| Edit/Write fails `File has not been read yet` | Did the Read TOOL view the file this session? | Bytes seen via Bash `cat`/`head`/`grep` do not register as read; only the Read tool does | Read the file with the Read tool, then edit | rules/global/verify-before-asserting.md |
| Killed process still alive; `kill` reported success | Was `kill` issued inside a `for`/`while` loop? | The Bash sandbox silently blocks `kill` inside loops (reports success, process survives) | One direct top-level command: `kill -TERM <pid> <pid> ...` | vault memory `session-worktree-orphan-cleanup.md` |
| Freshness CI red | Read the failing STEP name in the `freshness` workflow run | Each step is a distinct gate; see the gate map below | Fix what the step names; never hand-edit a generated doc to appease it | .github/workflows/freshness.yml; fix 410e819 |
| Push or stop blocked by a guard | Read the block message; it names the guard | Force-push guard, secret-in-command-text scan, or Stop push-gate; see the guard map below | The guard is right by default: push non-force, remove the literal secret, or push the unpushed commits | hooks/README.md; decisions/0011 #9, 0016 |

## Gate map: what each freshness CI step means

Steps in `.github/workflows/freshness.yml` (as of 2026-07-17):

| Step | Meaning when red | Fix |
|---|---|---|
| Documentation freshness gate | (a) A generated doc (CATALOG.md, handoffs/README.md, surfaces/claude-ai-skills.md) is stale vs its sources, or (b) a `last-verified:` doc has a source committed after its date | Re-run `bash scripts/gen-catalog.sh` / `bash scripts/gen-handoff-index.sh` / `bash scripts/gen-claude-ai-skills.sh`; or re-verify the doc and bump `last-verified:` |
| The `*self-test` steps (inventory and CI/local split: `os-validation-and-qa`) | A script's own test suite regressed | Run the named `scripts/tests/test-*.sh` locally and fix the script |
| Internal link check | A relative link in a live doc points at nothing | Fix or remove the link |
| LaunchAgent plists are valid | A plist in `scheduled-tasks/` fails plutil | Fix the plist |
| Secret scan | A literal secret VALUE in a tracked file | Remove it; use an `op://` reference. See the `cleanse-secrets` skill |
| Stale-note scan | Credential-incident phrasing outside the sanctioned homes (vault ledger, handoffs/, decisions/, archives) | DELETE the line, never annotate it "since rotated" (rules/global/anti-stale.md) |
| op:// reference check | WARN-only, exit 0 (as of 2026-07-17): credentials-map lag never blocks a push | Update credentials-map.md when convenient |

Known false-positive class (fixed 410e819): the gate once walked git-EXCLUDED nested checkouts
(`.claude/worktrees/*`) and produced local-only false STALE. It now scans git-tracked files only.
If local disagrees with CI, trust CI and check for an untracked-tree artifact locally.

## Guard map: what blocks a push or a stop

| Guard | Trigger | Behavior |
|---|---|---|
| `hooks/no-force-push-guard.sh` (+ user-scope wrapper, fires in every repo) | `git push` with `--force`/`-f`/`--force-with-lease`/`+refspec` | Hard exit-2 block, even under `--dangerously-skip-permissions`. There is no sanctioned force-push |
| `hooks/global-secret-scan.sh` PreToolUse Bash leg | A literal token-format secret in the command text (heredoc, `echo >`) | Blocks before execution. Rewrite with `op read`/`op run`, never the value |
| `hooks/session-stop-push-gate.sh` | Trying to stop with commits not on upstream | Blocks the stop once, instructs a push; on a second failing attempt warns and allows (offline case) |

## Method

1. Match the symptom to a row; run the first check verbatim before theorizing.
2. If no row matches, check the newest handoff (`handoffs/`, highest number) and grep
   `decisions/` and the vault memory lane for the symptom text: most failures here recur.
3. Before retrying a failed approach, record what was tried and why it failed
   (rules/global/working-style.md). A fix lands with its verify command run, not before.
4. New failure mode solved: route the lesson via the `learn-route` skill so it lands in a rule,
   memory fact, or ADR and this table's class grows instead of the incident recurring.

## When NOT to use

- Whole-system health sweep, nothing specific broken: `status` skill.
- "What is loaded/available on THIS surface": `surface-check` skill.
- The full incident narrative and dead-end history: `os-failure-archaeology` sibling skill.
- Changing the system (rules/skills/hooks) after the fix: `os-change-control` sibling skill.
- Running/restarting services and routines when they are healthy: `os-run-and-operate` sibling skill.
- A secret that genuinely leaked or must be replaced: `rotate-secret` / `cleanse-secrets` skills.
- Generic debugging method for non-schnapp-os code: `superpowers:systematic-debugging`.

## Provenance and maintenance

Drift-prone claims and their one-line re-verification (all repo-relative to
`/Users/schnapp/code/schnapp-os` unless noted):

- Hook wiring split: `sed -n '1,30p' hooks/README.md`
- Freshness step list: `grep 'name:' .github/workflows/freshness.yml`
- op-ref check still WARN-only: `grep -in 'WARN-only' scripts/check-op-refs.sh`
- Tracked-files-only freshness scan: `grep -n 'git-TRACKED' scripts/check-freshness.sh`
- 90s mac-mcp clamp: `grep -n 'MAX_COMMAND_TIMEOUT_SECONDS' connectors/mac-mcp/server.py`
- Render ~50s cold start note: `grep -n 'Cold start' connectors/memory-mcp/DEPLOY.md`
- Harness ~2s re-serialization + flattener containment: `decisions/0029-vault-flat-schema-harness-writer-containment.md`
- Vault memory facts cited above: `ls /Users/schnapp/code/schnapp-vault/memory/`
- op-wrap grep-not-source + double-quote stripping: `sed -n '40,55p' /Users/schnapp/code/schnapp-bet/services/launchd/op-wrap.sh` (verified 2026-07-17: greps, does not source; strips one pair of surrounding double quotes)
- Sandbox kill-in-loop block: behavioral, no repo source; re-test only if the vault fact is doubted
