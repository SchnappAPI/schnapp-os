# Handoff 060: cross-surface config closed; substrate P2+P3 executed

Date: 2026-07-18. Surface: Code (Mac). Prior: [059](059-os-skill-library.md).

## Goal
Owner-driven "what next" chain after the skill library: close every cross-surface config loose
end, then execute the two stale substrate swaps (P2 GitHub, P3 Obsidian) instead of letting them
rot.

## Facts established
- Web honors user-scope wiring: VERIFIED YES (ADR 0033's question closed; `[shell]` gate line
  observed live). Per-session `claude/*` branches are the PLATFORM default (env config has no
  branch field); merge-on-green is permanent mitigation, nothing to flag.
- One web environment remains (global-environment, canonical allowlist); ClaudeDefault archived.
- Bootstrap CORE re-pasted and quote-back verified 2026-07-18 (watermark in campaign Phase 3b).
- Memory round trip from claude.ai chat: clean (health/write/read/delete incl. index line). The
  `supersedes` write-arg vs `superseded:` frontmatter key are two different correct things, not a
  schema bug (disproved on source read, tools.ts:286).
- claude.ai "GitHub Integration" (account-level) is load-bearing for web sessions: never
  disconnect it; the removable thing was the custom MCP connector scaffolding.
- cloudflared is a LOCALLY configured tunnel (`/etc/cloudflared/config.yml`, root, daemon label
  `com.cloudflare.cloudflared`); do not use the Zero Trust migrate flow.

## Decisions + reasoning
- ADR 0035: obsidian-mcp OAuth -> static bearer (-278 LOC); portal slot added by owner and
  live-verified (7 tools + get_index through the portal).
- ADR 0036: github-mcp hand-rolled server decommissioned; portal slot re-origined to GitHub's
  official server with `Authorization` + `X-MCP-Toolsets: context,repos,issues,pull_requests,actions,orgs`
  headers. Key finding: claude.ai's connector UI cannot send headers, so the default endpoint
  lacks Actions tools; the PORTAL sends the headers, so parity rides the portal. The
  "drop the portal hop" payoff died; the delete-the-Mac-service payoff shipped.
- Gap tools accepted with workarounds (get_repo, get_branch, compare_commits, create_release);
  zero scripted dependents.

## Actions + outcomes
- P3: server.py 505->227; new 1P item OBSIDIAN_MCP_AUTH_TOKEN; live 401/200 local + tunnel;
  full doc sweep; owner added portal slot, retired standalone OAuth connector, removed stale
  runtime files.
- P2: parity probed server-to-server (46 official tools incl. actions_*); owner re-added the
  portal server entry; live read + vault write/delete round trip (commits 36a471c/8bfdb88, also
  re-proves the ADR 0027 Cowork write leg); then launchd bootout, plist -> .bak, connectors/
  github-mcp git-rm (756 LOC), GITHUB_MCP_AUTH_TOKEN retired everywhere + 1P item deleted,
  infra-health pruned (live green), tunnel ingress removed + cloudflared restarted (github-mcp
  curls 404; mac-mcp 406 / obsidian 401 healthy), owner removed the scaffolding standalone
  connector. Full live-doc sweep to official tool names.
- Found in passing and fixed: os-diagnostics-and-tooling quoted a stale-note trigger phrase
  (scan-stale-notes red on clean HEAD); check-freshness.sh stale header comment (three generated
  docs, not two).

## Status + next steps
Substrate rethink fully executed (P0-P3; P4 polish optional). Cross-surface config track closed:
one env, wiring verified, CORE current, memory continuity proven, portal fronts all five legs
(op, memory, mac, obsidian, github-official). Next: the meta-freeze object-work week (owner runs
real domain tasks through fresh sessions; then a session mines digests and prunes unused skills),
and campaign Phase 5 (proactive drift alerts) as session work.

## Open questions / edge cases
- Owner cosmetic cleanups: `rm -rf /Users/schnapp/github-mcp`; delete the `github-mcp` DNS CNAME
  if one exists (route already dead, curl 404).
- os-run-and-operate / os-build-and-env now describe the two-service Mac fleet; if anything still
  says "trio", it is stale (sweep was done; trust the docs, verify on doubt).

## Copy-paste primer (new session)
Cross-surface enablement is closed and substrate P2+P3 shipped (ADRs 0035/0036, 2026-07-18): the
portal fronts op/memory/mac/obsidian plus GitHub's official server (toolset headers portal-side),
the Mac runs only mac-mcp (8765) and obsidian-mcp (8767), and web user-scope wiring is verified
live. Resume with the meta-freeze week or campaign Phase 5; skills os-* (15, landed in 059) are
the operating manual.
