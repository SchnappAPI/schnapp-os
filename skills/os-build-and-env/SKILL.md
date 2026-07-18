---
name: os-build-and-env
description: Use when recreating or repairing the schnapp-os environment on any surface - "set up a new Mac", "fresh machine install", "wire up ~/.claude", "run shell/install.sh", "configure the claude.ai web environment", "paste web-setup.sh", "the network allowlist is missing a host", "set up the 1Password service account token", "arm the LaunchAgents", "set up Cowork / the Cowork seed", "enable the portal connector on iPhone", "re-paste the bootstrap floor", "did the install work", or any question about what the installer writes and how to verify it per surface.
---

# os-build-and-env

How to recreate the environment from scratch on each surface class, and how to verify it worked.
Repo: `/Users/schnapp/code/schnapp-os` (path = this machine's clone; other machines clone under
`~/code`). There is no build step anywhere: the system is bash + markdown + two git clones, and
"install" means writing POINTERS (symlinks, `@import`s, absolute-path hook commands) into
`~/.claude` so every session reads the live clones. Nothing is copied, so nothing snapshots and
nothing goes stale. Design contract: [decisions/0033-portable-shell-user-scope-wiring.md](../../decisions/0033-portable-shell-user-scope-wiring.md)
and [shell/README.md](../../shell/README.md).

Definitions used once here:
- **The two repos**: `SchnappAPI/schnapp-os` (rules, hooks, skills, connectors) and
  `SchnappAPI/schnapp-vault` (the memory lane). Both private; both must be cloned side by side.
- **Portable shell**: the `shell/` installer trio (`install.sh`, `mac-setup.sh`, `web-setup.sh`)
  that wires a machine's `~/.claude` to the live clones.
- **Hookless surface**: claude.ai web/chat, iPhone, Cowork. No `~/.claude`, no hooks; behavior
  arrives via a pasted bootstrap plus live reads through the Schnapp Portal connector.
- **Schnapp Portal**: one Cloudflare OAuth MCP connector (`https://mcp.schnapp.bet/mcp`) fronting
  op-mcp (secrets), memory-mcp (vault), mac-mcp (Mac shell/SQL/files), and github-mcp
  (GitHub's official MCP server, portal-side headers - no Mac service).
- **SA token**: the 1Password service-account token (`OP_SERVICE_ACCOUNT_TOKEN`), the single
  bootstrap secret that resolves every other `op://` reference.

## Surface map (which runbook applies)

| Surface | Hooks? | Install mechanism | Verify |
|---|---|---|---|
| New Mac (Claude Code) | yes | `shell/mac-setup.sh` -> `shell/install.sh` | `[shell]` line at session start |
| Claude Code web env | project-scope only (user scope OPEN) | paste `shell/web-setup.sh` into the env setup script + allowlist + env vars | `[web-setup]` lines in init log; `[shell]` line is the ADR 0033 open probe |
| Cowork | no | portal connector + pasted CORE + Cowork block; seed auto-syncs | `surface-check` |
| claude.ai chat / iPhone | no | portal connector + pasted CORE (account Preferences) | `surface-check` |

## 1. New Mac

### 1.1 Owner prerequisites (interactive, once)

Quoted from `shell/mac-setup.sh`: GitHub auth for the Mac (SSH key or `gh auth login`) is required
to clone the private repos and push vault writes; `op signin` / the 1Password app is optional
(the op-mcp connector resolves secrets regardless).

### 1.2 Clone + bootstrap (one command)

```bash
git clone git@github.com:SchnappAPI/schnapp-os.git ~/code/schnapp-os
bash ~/code/schnapp-os/shell/mac-setup.sh
```

What `mac-setup.sh` does, in order (verified by reading the script, as of 2026-07-17):
1. Refuses non-macOS; checks `git` (Xcode CLT) and warns if `python3` is missing (the settings
   merge needs it).
2. Installs the op CLI via `brew install --cask 1password-cli` if Homebrew is present (non-fatal
   if not).
3. Clone-or-pulls both repos under `~/code` (override base with `SHELL_CLONE_BASE`).
4. Runs `shell/install.sh` with `VAULT_DIR` set. Best-effort: warns and continues, always exits 0.
Re-running is safe: it pulls and re-wires in place.

### 1.3 What install.sh writes (the three layers)

`shell/install.sh` is idempotent (`--dry-run` previews; env knobs `VAULT_DIR`,
`CLAUDE_CONFIG_DIR`). Verified by reading the script:

| Layer | Target | Content |
|---|---|---|
| Rules | `~/.claude/CLAUDE.md` | rendered from `templates/user-global-CLAUDE.md`; `@import`s of `rules/global/*` with this machine's repo path substituted. An existing differing copy is backed up to `CLAUDE.md.pre-shell.bak`. |
| Settings | `~/.claude/settings.json` | JSON merge (python3, atomic write, preserves foreign keys): `autoMemoryDirectory` -> the vault `memory/` lane; user-scope hooks at UserPromptSubmit (`standing-rules.sh`, `capture-nudge.sh`), SessionStart `global-session-gate.sh` (matcher `startup\|resume\|clear`), SessionEnd (`global-vault-push.sh`, `idea-sweep.sh`, `session-digest.sh`), PreToolUse Bash (`global-force-push-guard.sh`, `global-secret-scan.sh` command-text leg), PostToolUse Write/Edit/MultiEdit (`global-secret-scan.sh` file leg). Deduped by script basename, never double-registered. |
| Components | `~/.claude/{skills,agents,commands}/<name>` | per-item symlinks into the live clone's top-level `skills/ agents/ commands/`; dead links into this clone are pruned. |

It also sets the vault clone's `core.hooksPath` to `scripts/git-hooks` so the vault's pre-commit
schema/flatten/secret gate is active (a fresh clone commits UNGATED without this).

### 1.4 SA token setup (`~/.zshrc`)

The Mac-hosted launchd services resolve secrets through
`/Users/schnapp/code/schnapp-bet/services/launchd/op-wrap.sh`, which greps the literal line
`export OP_SERVICE_ACCOUNT_TOKEN=...` from `~/.zshrc` (no shell sourcing) and passes the value to
`op run`. Add the line yourself; the value comes from the 1Password service account
(reference map: [credentials-map.md](../../credentials-map.md), row `OP_SERVICE_ACCOUNT_TOKEN`).

- Quoting (as of 2026-07-17, verified by reading op-wrap.sh): the current wrapper strips one pair
  of surrounding DOUBLE quotes; anything else (single quotes, inner whitespace) is passed verbatim
  and crash-loops every service with `unrecognized auth type` (the 2026-06-22 incident, memory
  fact `op-wrap-token-unquoted`). Safest form: fully unquoted.
- After any SA rotation: services cache the old token in-process; restart each with
  `launchctl kill TERM gui/$(id -u)/<label>` (never `kickstart -k`, ADR 0010) and update the
  other homes listed in credentials-map.md (GH Actions secrets, Render op-mcp env).

Verify without printing the value:

```bash
grep -c '^export OP_SERVICE_ACCOUNT_TOKEN=' ~/.zshrc   # expect 1
op whoami   # in a fresh terminal; expect the service-account identity, no error
```

### 1.5 Launchd arming (owner-confirmed, production Mac only)

The schnapp-os LaunchAgents are never auto-loaded by CI or a cloud session; the owner loads them
once. Plists live in [scheduled-tasks/](../../scheduled-tasks/) with `__REPO__`/`__HOME__`
placeholders; the canonical install commands (sed-render into `~/Library/LaunchAgents`, then
`launchctl load`) are in [scheduled-tasks/README.md](../../scheduled-tasks/README.md), per agent:
`com.schnapp.memory-consolidation` (nightly learning worker; needs the headless-auth one-time
step in that README), `com.schnapp.vault-autocommit` (5-min vault sweep),
`com.schnapp.infra-health`, `com.schnapp.caffeinate`. Do not paraphrase-install; run the README's
blocks. Verify:

```bash
launchctl list | grep com.schnapp   # expect the loaded labels with exit status 0 or -
```

The mac-mcp/obsidian-mcp service plists are Mac-local state (not repo-tracked, run via
op-wrap.sh); their setup is per [connectors/mac-mcp/README.md](../../connectors/mac-mcp/README.md)
and siblings, out of scope here.

### 1.6 Verify the Mac install worked

1. `bash ~/code/schnapp-os/shell/install.sh` again: every layer reports `unchanged` /
   `components: 0 linked, N already live` and it ends
   `[shell-install] done. Wiring targets: OS=... VAULT=... CONFIG=...`.
2. Accept the workspace-trust dialog on first open (decisions/0005 prerequisite), then start a
   Claude Code session in ANY repo other than schnapp-os. Expect at session start:
   `[shell] schnapp-os: fresh | vault: fresh | wiring intact` plus the
   `[shell] memory: read .../memory/MEMORY.md ...` orient line. `pull FAILED` = network/auth;
   `wiring drift` = the gate auto-ran the installer (self-healing, fine).
3. Hooks load at session start: restart the session after the first install before expecting them.

## 2. Claude Code web environment (claude.ai "Code" cloud)

Three per-environment pieces, all set in the environment's settings UI (owner action; cannot be
done from inside a session):

1. **Setup script**: paste the WHOLE of [shell/web-setup.sh](../../shell/web-setup.sh) into the
   environment's setup script box. It runs at environment init (result cached ~7 days, NOT per
   session): installs the op CLI (pinned v2.33.1 zip from cache.agilebits.com), clone-or-pulls
   both repos under `~/code`, runs `install.sh` against the container `~/.claude`. Announce lines
   to expect in the init log: `[web-setup] op present: ...` (or the WARN),
   `[web-setup] cloning the two live repos under /root/code` (or `$HOME/code`), then the
   `[shell-install]` lines. Never bricks init: always exits 0.
2. **Env vars** (literal values, the one sanctioned exception to secrets-as-references):
   `OP_SERVICE_ACCOUNT_TOKEN`, `MAC_MCP_AUTH_TOKEN`, `OP_MCP_BEARER`, `MEMORY_MCP_BEARER`.
3. **Network allowlist**: canonical table is
   [docs/environment-and-access.md](../../docs/environment-and-access.md) §1; apply it identically
   to EVERY environment. Install-critical hosts: `github.com` + `api.github.com` (the clones),
   `cache.agilebits.com` (op download), `my.1password.com` (op API), `mac-mcp.schnapp.bet`,
   `mcp.schnapp.bet`, `memory-mcp-rtad.onrender.com`, `op-mcp.onrender.com`. A missing host shows
   as proxy 403 on CONNECT and MCP tools silently absent (memory fact `mac-cloud-access`).
4. **Repo access**: the environment's GitHub access must cover BOTH `SchnappAPI/schnapp-os` and
   `SchnappAPI/schnapp-vault`, or web-setup WARNs and the memory lane is silently dead there
   (an open owner knob per handoff 057/synthesis, as of 2026-07-17).

**VERIFIED YES (2026-07-18, closes ADR 0033's one empirical question):** the web container honors
user-scope `~/.claude` wiring. First session after the paste showed the `[shell]` gate line
(`schnapp-os: fresh | vault: fresh | wiring intact`) plus the memory-orient line. Note the split
layout: web-setup clones land under the init user's `$HOME/code` (`/root/code`) while the session's
working clone is `/home/user/<repo>`; the gate handles both. Re-run the probe (campaign Phase 2)
after any claude.ai platform change.
Sessions still start on per-session `claude/*` branches: settled 2026-07-18 as the platform
default (the environment config exposes no branch field, so there is no owner knob to fix);
merge-on-green per ADR 0017 is the standing mitigation, nothing to flag.

Git in the cloud env is a read-only relay (`push` 403s): write paths and workarounds are
[docs/environment-and-access.md](../../docs/environment-and-access.md) §2.

## 3. Cowork

Hookless and shell-less; state rides the two repos via the GitHub connector (the **handoff
packet**, [decisions/0027-cowork-handoff-packet-over-git.md](../../decisions/0027-cowork-handoff-packet-over-git.md):
write-on-stop = memory facts + newest handoff + PROGRESS line + plan box, both repos pushed;
read-on-start = the freshness gate. Same packet as Code, different transport). Setup, per
[surfaces/cowork.md](../../surfaces/cowork.md):

1. Enable the **Schnapp Portal** connector (obsidian-mcp rides it too once the owner adds
   its portal slot - pending since the 2026-07-18 bearer swap).
2. Paste the **CORE** section AND the **Cowork operating block** of
   [surfaces/always-loaded-instructions.md](../../surfaces/always-loaded-instructions.md) into
   Cowork's instructions.
3. **Seed auto-sync (no hand-copy):** Cowork also copies a per-session global `CLAUDE.md` from a
   machine-local seed file. `scripts/sync-cowork-seed.sh` regenerates that seed from
   always-loaded-instructions.md (`## CORE` to EOF, generated header) on every Claude Code
   SessionStart, writing only on change. Editing the source file is the only step; the seed
   follows. Seed path is desktop-app state (override: `SCHNAPP_COWORK_SEED`; recorded in vault
   memory fact `cowork-claude-md-seed`); if the app is reinstalled under a new UUID the script
   reports `cowork-seed: seed not found` instead of creating a stray.
4. Verify: run `surface-check` in a Cowork session, then the vault read/write probe in
   surfaces/cowork.md enablement step 3 (fetch `memory/MEMORY.md` from the vault through the
   connector, write one schema-valid probe fact).

Must-happen procedures (freshness gate, end-of-session write, on-correction routing) run by hand
via the `session-hygiene` skill; repo writes are whole-file read-modify-write through the
connector; the backup never fires from Cowork.

## 4. claude.ai chat + iPhone

No install in any real sense; two account-level toggles, per
[surfaces/claude-ai-web.md](../../surfaces/claude-ai-web.md) and
[surfaces/iphone.md](../../surfaces/iphone.md):

1. **Connectors** (Settings > Connectors): **Schnapp Portal** (`https://mcp.schnapp.bet/mcp`;
   obsidian-mcp joins it once the owner adds its portal slot - pending since the 2026-07-18
   bearer swap). The portal is how these surfaces read `rules/global/` and any `SKILL.md`
   LIVE from the repo (probe-confirmed 2026-07-07); that live read is the default behavior
   channel, not the paste.
2. **Bootstrap floor**: paste the **CORE** section of
   [surfaces/always-loaded-instructions.md](../../surfaces/always-loaded-instructions.md) into
   **Settings > Profile > Preferences** (account-wide; covers iPhone on the same account). CORE
   is a fallback floor for when the connector is down, plus the clause directing the surface to
   read the live rules and treat them as authoritative. It snapshots: RE-PASTE whenever the
   source file's CORE changes. The trigger is deterministic:
   `git -C /Users/schnapp/code/schnapp-os log -1 --format='%h %ci' -- surfaces/always-loaded-instructions.md`
   (last change 6f74078, 2026-07-13; whether the paste was refreshed after it is an open owner
   question as of 2026-07-17).
3. Do NOT paste static skill copies (they go stale); the optional thin-stub registration pattern
   is in surfaces/claude-ai-web.md enablement step 2.
4. What replaces hooks here: the `session-hygiene` skill, run by hand (start = freshness gate,
   wrap-up = end-of-session write, after a correction = route the fix). iPhone additionally
   prefers firing procedures on the Mac via the portal's mac-mcp tools over doing repo writes
   from the phone.
5. Verify: run `surface-check`. Expected: connectors present, global rules readable live, no
   hooks (correct here, not a defect), persistence via the GitHub connector or a generated Code
   prompt.

## 5. Known traps per surface

| Surface | Trap | Fix / reference |
|---|---|---|
| Mac | SA token line quoted with single quotes or malformed | §1.4; memory `op-wrap-token-unquoted`, ADR 0019 |
| Mac | hooks absent right after install | restart the session; hooks load at session start |
| Mac | trust dialog never accepted on a fresh machine | accept it first (decisions/0005) |
| Mac | vault commits bypass the schema gate | re-run install.sh; it sets `core.hooksPath` |
| Web env | MCP tools silently missing | allowlist gap, proxy 403 CONNECT; §2.3 |
| Web env | setup ran days ago, clones stale | init cache ~7 days; the SessionStart gate pull covers it only IF user scope is honored (OPEN, §2) |
| Web env | `git push` 403 | read-only relay by design; docs/environment-and-access.md §2 |
| Web/cloud | first connector call hangs ~50s | Render idle wake, normal; retry |
| Cowork | tracker/handoff writes blind-append | connector `create_or_update_file` replaces the whole file: read-modify-write always |
| Cowork | assuming the backup ran | the OneDrive/Obsidian mirror is Code/Mac SessionEnd only |
| chat/iPhone | pasted CORE silently stale | re-paste on source change; the paste is a projection |
| chat/iPhone | trusting the floor when the portal is up | live rules are authoritative over the paste |
| all hookless | claiming something was remembered | durable memory needs a connector write or a Code session; say so if absent |

## When NOT to use

- Diagnosing a broken but already-installed system (401s, missing tools, crash-loops):
  `os-debugging-playbook`.
- Finding or changing a specific config knob (settings.json keys, env vars, workflow inputs,
  plist contents): `os-config-and-flags`.
- Day-to-day operation of the running system (restarts, routines, health): `os-run-and-operate`.
- Landing a change to the repo (gates, ADRs, tracker discipline): `os-change-control`.
- Why the architecture is shaped this way (plugin rejection, two repos, portal):
  `os-architecture-contract`; component-model theory: `agentic-os-reference`.
- Checking what THIS surface has loaded right now: the `surface-check` skill; whole-system
  health: `status`; hookless session procedures themselves: `session-hygiene`; resolving a
  secret's value: `vault-resolve`.

## Provenance and maintenance

Every claim above was verified 2026-07-17 by reading the named file. Re-verify before trusting:

- Installer layers + announce lines: `cat /Users/schnapp/code/schnapp-os/shell/install.sh`
- mac-setup steps: `cat /Users/schnapp/code/schnapp-os/shell/mac-setup.sh`
- web-setup steps + op CLI version pin: `cat /Users/schnapp/code/schnapp-os/shell/web-setup.sh`
- Gate `[shell]` line format + auto-heal: `cat /Users/schnapp/code/schnapp-os/hooks/global-session-gate.sh`
- op-wrap quoting behavior: `sed -n 40,55p /Users/schnapp/code/schnapp-bet/services/launchd/op-wrap.sh`
- Allowlist + env vars: `sed -n 1,60p /Users/schnapp/code/schnapp-os/docs/environment-and-access.md`
- LaunchAgent install blocks: `grep -n launchctl /Users/schnapp/code/schnapp-os/scheduled-tasks/README.md`
- Cowork seed sync: `cat /Users/schnapp/code/schnapp-os/scripts/sync-cowork-seed.sh`
- Paste map + CORE text: `sed -n 1,40p /Users/schnapp/code/schnapp-os/surfaces/always-loaded-instructions.md`
- Web user-scope verdict (VERIFIED YES 2026-07-18) still current: re-run the campaign Phase 2 probe after any claude.ai platform change; vault fact `web-user-scope-verified`
