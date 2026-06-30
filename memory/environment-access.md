---
name: environment-access
metadata:
  node_type: memory
  scope: global
  source: "session 2026-06-29 (access-blocks review; handoff 038, ADR 0018); corrected 2026-06-30 (direct push verified working)"
  updated: 2026-06-30
  supersedes: ""
---

Never-blocked access — where to look when a surface can't reach something. Full spec:
`docs/environment-and-access.md`; rationale: `decisions/0018`.

- **403 on CONNECT / blocked host** → the host is not on the environment's network allowlist (set
  per web environment, NOT global). Add it. Canonical list lives in `docs/environment-and-access.md` §1
  (all `*.schnapp.bet` + Render + GitHub + Quickbase + MS Graph). See [[mac-cloud-access]].
- **`git push` from cloud env** → NOT universally read-only. Direct `git push origin HEAD:main` over
  SSH **succeeded** from a Claude-Code-web session 2026-06-30 (this env's remote is writable; clean
  ff to `main`, no branch residue). **Try the direct push first.** Only where it 403s (per-env, like
  the allowlist) is the remote a read-only relay — then write via: writable-git token → the Mac
  (`Schnapp_Mac` shell_exec, full git) → GitHub MCP (`push_files`, but it DROPS file exec bits and
  can't delete branches). Branch deletes = Mac only.
- **MCP "stream closed" / disconnect-reconnect each turn** → platform reconnection flap, not config;
  retry. **`AskUserQuestion` fails here** ("permission stream closed") → ask in plain text instead.
- **Tool result too large** (e.g. `actions_list`) → it's saved to a file; parse with `jq`/python.
