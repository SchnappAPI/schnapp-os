---
name: os-config-and-flags
description: Use when you need to find, inspect, or change ANY configuration in schnapp-os - "where is X configured", "what hooks are wired", "which env var controls Y", "how do I add a new env var / MCP server / LaunchAgent / permission", "why did this hook fire", "what does install.sh write to ~/.claude", "what are the workflow inputs", "what knobs does this script have", or before touching .claude/settings.json, .mcp.json, .env.template, render.yaml, a plist, or a workflow. The full catalog of config axes, their defaults, and which gate fires when you change each one.
---

# os-config-and-flags

Catalog of every configuration axis in schnapp-os: where each lives, what it controls, how to
inspect it, how to change it safely, and which gates fire. Verified against the live repo
2026-07-17. Paths below are this machine's clones (`/Users/schnapp/code/schnapp-os`,
`/Users/schnapp/code/schnapp-vault`); on another machine substitute that machine's clone paths.

Jargon, defined once:
- **op:// reference**: a 1Password URI (`op://vault/item/field`) standing in for a secret value.
  Values never appear in tracked files ([rules/global/secrets-as-references.md](../../rules/global/secrets-as-references.md)).
- **hook**: a shell script Claude Code runs at a lifecycle event (SessionStart, PreToolUse, Stop...).
  Exit 2 blocks the action; exit 0 passes.
- **user scope vs project scope**: `~/.claude/settings.json` fires in every repo on the machine;
  `.claude/settings.json` fires only inside schnapp-os.
- **owner-armed**: the repo tracks the spec (plist), but only the owner loads it on the production
  Mac; CI never loads it.

## Map of all axes

| Axis | File(s) | Scope | Changed by |
|---|---|---|---|
| Project hooks + memory dir | `.claude/settings.json` | this repo, tracked | edit + restart session |
| Local permission allowlist | `.claude/settings.local.json` | this repo, this machine, untracked-by-convention | edit freely |
| User-scope wiring | `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `~/.claude/{skills,agents,commands}/` | every repo on the machine | `shell/install.sh` only, never by hand |
| Project MCP servers | `.mcp.json` | Code + Cowork + Code-on-web | edit; bearers stay `${ENV_VAR}` |
| Master env manifest | `.env.template` | all surfaces (manifest, not a process env) | add `op://` lines only |
| Connector env | `connectors/*/.env.template` | per connector | add `op://` lines only |
| Shell installers | `shell/install.sh`, `shell/mac-setup.sh`, `shell/web-setup.sh` | per machine / web env | edit + re-run |
| Mac LaunchAgents | `scheduled-tasks/com.schnapp.*.plist` | production Mac, owner-armed | edit spec; owner reloads |
| Render deploy | `render.yaml` (op-mcp), `connectors/memory-mcp/DEPLOY.md` (manual) | Render cloud | dashboard env vars |
| CI workflows | `.github/workflows/*.yml` | GitHub Actions | edit + push (CI self-validates) |
| Hook/script env knobs | inline `${VAR:-default}` in `hooks/` and `scripts/` | per invocation | export before running |
| Generated catalog | `CATALOG.md` via `scripts/gen-catalog.sh` | repo docs | regenerate, never hand-edit |

## 1. `.claude/settings.json` (project hooks + memory lane)

Tracked, shared. Two payloads (as of 2026-07-17):

- `autoMemoryDirectory: ~/code/schnapp-vault/memory`: points harness auto-memory at the vault
  memory lane. Same value set at user scope so the lane is active everywhere.
- `hooks`: the project gate set, all `bash "${CLAUDE_PROJECT_DIR}/hooks/<script>"`:

| Event | Matcher | Script | Behavior |
|---|---|---|---|
| PreToolUse | `Bash` | `no-force-push-guard.sh` | blocks force-push to protected history |
| PostToolUse | `Write\|Edit\|MultiEdit` | `secret-scan-on-write.sh` | exit 2 on a literal secret value |
| PostToolUse | same | `shellcheck-on-write.sh` | exit 2 on a shellcheck finding in written `*.sh` |
| PostToolUse | same | `em-dash-on-write.sh` | exit 2 on an em dash in a live file |
| PostToolUse | same | `length-advisory.sh` | soft WARN only, always exit 0 |
| SessionStart | `startup` | `session-start-gate.sh` | freshness/sync/drift gate |
| SessionStart | `compact` | `post-compact-reinject.sh` | reprints invariants after compaction |
| Stop | `*` | `session-stop-push-gate.sh` | blocks stopping with unpushed commits |
| SessionEnd | `*` | `session-end-backup.sh` | backup archive |

Inspect: Read the file; its `$comment` documents every entry. Change: edit, then restart the
session (hooks load at session start). The file's `$comment` is load-bearing documentation:
update it in the same edit. Firing map for everything: [hooks/README.md](../../hooks/README.md).

## 2. `.claude/settings.local.json` (local permission allowlist)

Machine-local `permissions.allow` list of pre-approved Bash/MCP patterns. Not a gate surface;
edit freely to reduce prompts. Known debt (as of 2026-07-17): several entries still reference the
retired `plugins/core/scripts/...` paths (that layout was flattened; scripts now live in
`scripts/`). Those entries are dead, not harmful.

## 3. User scope: what `shell/install.sh` writes to `~/.claude`

Never hand-edit these; the installer is the only writer and is idempotent (ADR 0033,
[decisions/0033-portable-shell-user-scope-wiring.md](../../decisions/0033-portable-shell-user-scope-wiring.md)).
Three layers (verified in `shell/install.sh`):

1. `~/.claude/CLAUDE.md`: rendered from `templates/user-global-CLAUDE.md` with this machine's
   repo path substituted. It only `@import`s `rules/global/*`; content lives in the repo.
2. `~/.claude/settings.json` merge (preserves foreign keys): `autoMemoryDirectory` to the vault
   memory lane, plus the every-repo hooks: `standing-rules.sh` + `capture-nudge.sh`
   (UserPromptSubmit), `global-session-gate.sh` (SessionStart `startup|resume|clear`),
   `global-vault-push.sh` + `idea-sweep.sh` + `session-digest.sh` (SessionEnd),
   `global-force-push-guard.sh` + `global-secret-scan.sh` (PreToolUse Bash),
   `global-secret-scan.sh` (PostToolUse Write/Edit/MultiEdit). The guard wrappers self-skip
   inside schnapp-os so project wiring never double-fires, except the secret-scan Bash
   command-text leg, which never self-skips.
3. `~/.claude/{skills,agents,commands}/<name>` symlinks into the live clone. Dead links pruned;
   non-symlink collisions warned and left alone.

Flags and env of `install.sh`: `--dry-run`; `VAULT_DIR` (default `~/code/schnapp-vault`, falls
back to a sibling of the repo); `CLAUDE_CONFIG_DIR` (default `~/.claude`). It also sets the
vault's `core.hooksPath` to `scripts/git-hooks` so vault commits are gated.

Inspect current state:

```bash
python3 -c "import json;d=json.load(open('$HOME/.claude/settings.json'));print(d.get('autoMemoryDirectory'));print(json.dumps(d.get('hooks',{}),indent=1))"
ls -l ~/.claude/skills | head
```

Repair drift: re-run `bash /Users/schnapp/code/schnapp-os/shell/install.sh` (safe any time; the
SessionStart gate also auto-heals via the installer).

## 4. `.mcp.json` (project MCP servers)

Three HTTP servers, bearers as `${ENV_VAR}` expanded at connect time, never literals:

| Server | URL | Bearer env var | Notes |
|---|---|---|---|
| `Schnapp_Mac` | `https://mac-mcp.schnapp.bet/mcp` | `MAC_MCP_AUTH_TOKEN` | full Mac access once bearer presented (ADR 0014) |
| `Schnapp_Secrets` | `https://op-mcp.onrender.com/mcp` | `OP_MCP_BEARER` | off-Mac 1Password resolver (Render) |
| `Schnapp_Memory` | `https://memory-mcp-rtad.onrender.com/mcp` | `MEMORY_MCP_BEARER` | off-Mac memory lane (Render) |

A server activates only where its bearer env var is set. On the Mac the Render pair stays
disconnected by design (local op CLI + git instead). claude.ai web + iPhone do NOT read this
file; they use the Cloudflare OAuth portal `mcp.schnapp.bet`. In a cloud env, a missing tool
usually means the host is absent from the env NETWORK ALLOWLIST (proxy 403s CONNECT), not a
config error here: see `docs/environment-and-access.md` and memory fact `mac-cloud-access`.

Adding a server: add the block with a `${NEW_BEARER}` header, add the bearer to `.env.template`
as an `op://` line, store the value in 1Password, update the `$comment`. First use prompts a
one-time approval in Claude Code.

## 5. `.env.template` (master env manifest) and connector templates

`.env.template` is a MANIFEST covering every vault item, not a single process env: each surface
copies only the lines it needs. Rules (all stated in the file header):

- Every line is an `op://web-variables/...` reference. Never a value.
- Two deliberate exceptions, set directly per surface: `OP_SERVICE_ACCOUNT_TOKEN` (it IS the
  bootstrap key) and `NTFY_URL`/`GH_TOKEN` (alert path must not depend on 1Password; live in
  `~/.config/schnapp-os/ops.env`, chmod 600).
- Item names containing spaces get quoted refs (`"op://web-variables/Webshare Proxy/host"`).
- Field labels must match [credentials-map.md](../../credentials-map.md); confirm with
  `op item get <item>` before adding.

Per-connector `connectors/*/.env.template` files carry only that service's refs, resolved by
`op-wrap.sh` at launchd startup (Mac trio) or set as host secrets (Render pair).
`connectors/obsidian-mcp/.env.template` is intentionally empty of refs: it authenticates via
OAuth 2.1, no static bearer.

Adding a new env var, full checklist:
1. Create/extend the 1Password item in vault `web-variables`.
2. Add the `op://` line to `.env.template` (and the consuming connector's template if any).
3. Record it in `credentials-map.md` (references only).
4. If a Render service consumes it: set the value in the Render dashboard by hand.
5. If a launchd service consumes it: the service caches env in-process; restart it with
   `launchctl kill TERM gui/$(id -u)/<label>` (never `kickstart -k`, ADR 0010).
6. Never write the value anywhere tracked; the PostToolUse secret-scan hook and CI
   `scan-secrets.sh` both block it.

## 6. `shell/` installers

- `install.sh`: see section 3. Idempotent wiring; re-run to repair.
- `mac-setup.sh`: new-Mac bootstrap (op CLI, clone both repos, run install.sh). Owner
  prerequisites: GitHub auth first. Knob: `SHELL_CLONE_BASE` (default `~/code`).
- `web-setup.sh`: pasted whole into a Claude Code web environment's setup script. Runs at
  container init (cached ~7 days), never bricks init (always exit 0). Requires env vars
  `OP_SERVICE_ACCOUNT_TOKEN`, `MAC_MCP_AUTH_TOKEN`, `OP_MCP_BEARER`, `MEMORY_MCP_BEARER` plus
  the network allowlist per `docs/environment-and-access.md`. Whether the web container honors
  the user-scope wiring it writes is ADR 0033's OPEN question (as of 2026-07-17): the first web
  session either prints a `[shell]` announce line or user scope is ignored there.

## 7. Mac LaunchAgents (`scheduled-tasks/*.plist`, owner-armed)

Specs are tracked; loading is an owner action on the production Mac only, never CI. Plists carry
`__REPO__` and `__HOME__` placeholders rendered at install
([scheduled-tasks/README.md](../../scheduled-tasks/README.md) has the exact sed + `launchctl load`
blocks). The four (verified in the plists):

| Label | Runs | Trigger | Key env |
|---|---|---|---|
| `com.schnapp.memory-consolidation` | `scripts/learning-worker.sh` | WatchPaths on `scheduled-tasks/.learning-queue.tsv` + every 1800s | `PATH` prepend; `LEARNING_CLAUDE_TOKEN_REF` (op:// ref, substituted at install) |
| `com.schnapp.infra-health` | `scripts/check-infra-health.sh` (pure bash, no LLM/MCP) | every 1800s + RunAtLoad | `PATH` prepend |
| `com.schnapp.vault-autocommit` | `scripts/vault-autocommit.sh` | every 300s + RunAtLoad | `PATH` prepend; 120s quiet-window debounce in-script |
| `com.schnapp.caffeinate` | `/usr/bin/caffeinate -s` | RunAtLoad + KeepAlive | AC-power sleep hold only |

Inspect on the Mac: `launchctl list | grep com.schnapp`; logs under
`~/Library/Logs/schnapp-os/`. Change safely: edit the tracked plist (CI validates plist XML in
`freshness.yml`), then owner re-renders and `launchctl unload` + `load`. Restart the tunneled MCP
services with `launchctl kill TERM ...`, never `kickstart -k` (SIGKILL bind race, ADR 0010).

## 8. Render (`render.yaml` + dashboard env vars)

- `render.yaml` deploys ONLY op-mcp (Blueprint, docker runtime, `rootDir: connectors/op-mcp`,
  `healthCheckPath: /health`, `autoDeployTrigger: off`). Its two secrets are `sync: false`:
  `OP_SERVICE_ACCOUNT_TOKEN` and `OP_MCP_BEARER`, set by hand in the Render dashboard.
- memory-mcp is deployed MANUALLY per `connectors/memory-mcp/DEPLOY.md` (live at
  `memory-mcp-rtad.onrender.com`). Its env (from its `.env.template`): `GITHUB_TOKEN` (contents
  R/W on SchnappAPI/schnapp-vault), `MEMORY_MCP_BEARER`, and lane knobs
  `MEMORY_REPO`/`MEMORY_BRANCH`/`MEMORY_DIR` (defaults `SchnappAPI/schnapp-vault` / `main` /
  `memory`), `PORT` (default 3000).
- Free tier sleeps after ~15 min idle; first call cold-starts (~30-60s). `render-health.yml`
  doubles as keep-warm.

## 9. GitHub Actions workflows (inputs and secrets)

| Workflow | Trigger | Knobs |
|---|---|---|
| `freshness.yml` | push + PR | none; gates: catalog regen diff, self-tests, links, plist XML, `scan-secrets.sh --exclude 'scripts/tests/*'`, stale-note scan |
| `ci-lint.yml` | push + PR | writing-style (em dash) lint |
| `mac-liveness.yml` | cron `*/30 * * * *` + dispatch | input `simulate=down` forces the DOWN path to test alerting (opens a dedup'd issue) |
| `render-health.yml` | cron `*/30 * * * *` + dispatch | input `simulate=down`, same alert-path test |
| `scheduled-routines.yml` | cron `17 8 * * *` (~08:17 UTC nightly) + dispatch | repo secret `VAULT_READ_TOKEN`: without it the vault-checkout step and memory sweep SKIP silently. Set: `gh secret set VAULT_READ_TOKEN --repo SchnappAPI/schnapp-os`. Whether it is currently set is unverified from this machine (open item, briefing #7) |

Test the alert path: `gh workflow run mac-liveness.yml -f simulate=down`.

## 10. Hook and script env knobs (inline `${VAR:-default}`)

The load-bearing ones (owning file in parentheses; grep is the exhaustive inventory, see
Provenance):

| Knob | Default | Effect |
|---|---|---|
| `CLAUDE_KIT_REPO` (`gen-catalog.sh` and most scripts) | derived from script location | repo root override so scripts run anywhere incl. CI |
| `VAULT_DIR` (installers, hooks) | `~/code/schnapp-vault` | vault clone location |
| `LENGTH_ADVISORY_RULES` / `_GLOBAL` / `_CLAUDE` (`length-advisory.sh`) | 120 / 50 / 120 | line-limit heuristics for the soft WARN |
| `AUTOCOMMIT_QUIET_SECONDS` (`vault-autocommit.sh`, `global-vault-push.sh`) | 120 | debounce before auto-committing the vault |
| `AUTOCOMMIT_LOCK_STALE_SECONDS` (`vault-autocommit.sh`) | 300 | mkdir-mutex staleness |
| `OPS_ALERT_DISABLE` (`check-infra-health.sh`) | 0 | 1 = probe without paging |
| `OPS_GH_REPO` / `OPS_GH_ASSIGNEE` (`ops-alert.sh`) | `SchnappAPI/schnapp-os` / `SchnappAPI` | where RED issues open |
| `OPS_ENV` (`ops-alert.sh`, `notify-ops.sh`) | `~/.config/schnapp-os/ops.env` | Mac-local alert secrets file (`NTFY_URL`, `GH_TOKEN`) |
| `MAX_BACKUP_AGE_DAYS` (`check-infra-health.sh`) | 8 | backup-staleness RED threshold |
| `INFRA_EXPECTED_AGENTS` (`check-infra-health.sh`) | empty | override the expected LaunchAgent set |
| `CLAUDE_ARCHIVE_DIR` (`backup-archive.sh`) | `~/Library/CloudStorage/OneDrive-Schnapp/claude-archive` | backup target |
| `LEARNING_QUEUE` (`capture-nudge.sh`, `learning-worker.sh`) | `scheduled-tasks/.learning-queue.tsv` | correction capture queue |
| `LEARNING_GATE_MAX_ADDED` / `LEARNING_GATE_DUP_MIN` (`learning-gate.sh`) | 40 / 40 | auto-land size bound / dup threshold for distilled edits |
| `LEARNING_CLAUDE_TOKEN_REF` (`learning-worker.sh`, plist) | empty | op:// ref to the headless Claude OAuth token |
| `SCHNAPP_IDEA_SWEEP` / `SCHNAPP_CONSOLE_URL` (`idea-sweep.sh`) | empty / `http://127.0.0.1:4747` | idea-sweep toggle / console endpoint |
| `SHELL_CLONE_BASE` (`web-setup.sh`, `mac-setup.sh`) | `~/code` | where the installers clone |

`.claude/launch.json` holds one dev-server config (`console`, port 4747) for the Browser-pane
preview tool; not a gate surface.

## 11. `CATALOG.md` generation

`CATALOG.md` is a projection of `rules/`, `skills/`, `agents/`, `commands/`, `hooks/`. Never
hand-edit. After adding/renaming any component:

```bash
bash /Users/schnapp/code/schnapp-os/scripts/gen-catalog.sh
```

Same commit as the component change, or `freshness.yml` fails the push (it regenerates and
diffs). Output is deterministic (C-locale sort, no timestamps). Input knob: `CLAUDE_KIT_REPO`.
New skills also need `bash shell/install.sh` re-run to symlink into `~/.claude/skills/`.

## Which gates fire when you change what

| You change | Gates that fire |
|---|---|
| any tracked file | PostToolUse secret-scan + em-dash + (if `*.sh`) shellcheck; CI `freshness.yml` + `ci-lint.yml` on push |
| a component (skill/rule/hook/command) | all the above + CATALOG.md regen diff in CI |
| `.claude/settings.json` hooks | nothing until session restart; test via `scripts/tests/` |
| a plist | CI plist XML validation; behavior changes only after owner reloads on the Mac |
| a secret's home | `scan-secrets.sh` blocks values; `check-op-refs.sh` WARNs on broken refs (WARN-only as of 2026-07-17) |
| anything | Stop-hook push-gate: you cannot end the session with unpushed commits |

Change control itself (main-only, same-commit tracker+PROGRESS discipline) is the
`os-change-control` skill's territory; this skill only tells you which mechanical gate fires.

## When NOT to use

- Making/landing a change through the process (commit discipline, trackers): `os-change-control`.
- Something misbehaving and you need diagnosis, not the config map: `os-debugging-playbook`,
  `os-diagnostics-and-tooling`.
- "What is loaded on THIS surface right now": existing `surface-check` skill. Whole-system
  health: `status`. Rotating or resolving a secret VALUE: `rotate-secret`, `vault-resolve`.
- Install/bootstrap of a whole machine or environment end to end: `os-build-and-env`.
- Why the architecture is shaped this way: `os-architecture-contract`, `agentic-os-reference`.

## Provenance and maintenance

Every claim above was read from the live files on 2026-07-17. Re-verify before trusting:

- Project hooks + memory dir: `python3 -m json.tool /Users/schnapp/code/schnapp-os/.claude/settings.json | grep -E 'command|matcher|autoMemory'`
- User-scope wiring spec: Read `shell/install.sh` (the `wanted` hook list is the source).
- Live user scope on this machine: `python3 -c "import json;print(json.dumps(json.load(open('$HOME/.claude/settings.json')).get('hooks',{}),indent=1))"`
- MCP servers/bearers: `grep -E 'url|Bearer' /Users/schnapp/code/schnapp-os/.mcp.json`
- Env manifest rules: head of `.env.template`; connector envs: `cat connectors/*/.env.template`
- Plist intervals/env: `grep -A2 -E 'StartInterval|WatchPaths|EnvironmentVariables' scheduled-tasks/com.schnapp.*.plist`
- Workflow schedules/inputs: `grep -n 'cron:\|simulate\|VAULT_READ_TOKEN' .github/workflows/*.yml`
- Exhaustive knob inventory: `grep -hoE '\$\{[A-Z_]+:-[^}]*\}' hooks/*.sh scripts/*.sh shell/*.sh | sort -u`
- Render config: Read `render.yaml`; memory-mcp env: `connectors/memory-mcp/.env.template` + `DEPLOY.md`
- `VAULT_READ_TOKEN` presence: `gh secret list --repo SchnappAPI/schnapp-os`
