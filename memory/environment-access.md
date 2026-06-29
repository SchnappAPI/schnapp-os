---
name: environment-access
metadata:
  node_type: memory
  scope: global
  source: "session 2026-06-29 (access-blocks review; handoff 038, ADR 0018)"
  updated: 2026-06-29
  supersedes: ""
---

Never-blocked access — where to look when a surface can't reach something. Full spec:
`docs/environment-and-access.md`; rationale: `decisions/0018`.

- **403 on CONNECT / blocked host** → the host is not on the environment's network allowlist (set
  per web environment, NOT global). Add it. Canonical list lives in `docs/environment-and-access.md` §1
  (all `*.schnapp.bet` + Render + GitHub + Quickbase + MS Graph). See [[mac-cloud-access]].
- **`git push` 403 from cloud env** → the cloud git remote is a READ-ONLY relay. Write via: writable-git
  token (preferred, if platform allows) → the Mac (`Schnapp_Mac` shell_exec, full git) → GitHub MCP
  (`push_files`, but it DROPS file exec bits and can't delete branches). Branch deletes = Mac only.
- **MCP "stream closed" / disconnect-reconnect each turn** → platform reconnection flap, not config;
  retry. **`AskUserQuestion` fails here** ("permission stream closed") → ask in plain text instead.
- **Tool result too large** (e.g. `actions_list`) → it's saved to a file; parse with `jq`/python.
