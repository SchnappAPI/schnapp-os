---
name: surface-check
claude-ai-tier: core
description: Use when the user asks "what's loaded here", "what can this surface do", "is my memory/rules/connector active", "why doesn't X work here", or when starting work on an unfamiliar surface (claude.ai web, iPhone, Cowork, a work machine) and you need to know what is present vs missing before relying on it. Reports loaded-vs-missing capabilities for the current surface and the fallback for each gap.
---

# surface-check

Report what is actually loaded on the **current** surface versus what its profile
expects, and give the always-complete fallback for anything missing. Never assert a
capability exists without probing it (see
[verify-before-asserting](../../../rules/global/verify-before-asserting.md)).

## 1. Identify the surface

Infer from observable signals, then state which it is:
- **Code-Mac**: local filesystem + shell, hooks run, local Mac MCP (`op_*`, `shell_exec`, SQL) present.
- **Code-work-machine**: local filesystem + shell, but no local Mac MCP; work restrictions.
- **Cowork**: plugin host, hosted MCP only, no local shell; hook execution unverified.
- **claude.ai web/chat**: no filesystem/shell/hooks; hosted connectors + skills only.
- **iPhone**: most limited; hosted connectors only.

If ambiguous, probe (try a read-only `ls`/shell; list MCP tools) or ask. Read the matching
[`surfaces/<surface>.md`](../../../surfaces/) profile for the expected baseline.

## 2. Probe each capability (don't assume)

| Capability | How to check |
|---|---|
| Global rules | Are the [`rules/global/`](../../../rules/global/) rules in context this session? |
| Memory lane | Is the vault memory lane (`~/code/schnapp-vault/memory/`) present and is `autoMemoryDirectory` honored (trust dialog accepted)? |
| Credentials | Does a secret resolve? `op_health` on the 1Password connector, or `op whoami` on Code. |
| Connectors/MCP | List available MCP tools; compare to the profile (1Password, GitHub, Mac ops, context7, cloudflare). |
| Hooks | Code/Cowork only: is the SessionStart sync + any Part-7 hooks active? (claude.ai/iPhone: never.) |
| Skills | Are this repo's skills enabled here? (claude.ai/Cowork need them enabled per account/plugin.) |
| Git sync | Code only: `git status` clean + pushed; unmerged work surfaced first. |

## 3. Report

Output a compact table: **Capability | Expected (per profile) | Present now | Fallback if missing**.

For every missing item, give the always-complete path (per
[`surfaces/README.md`](../../../surfaces/README.md)): Native → Remote MCP (call the Mac /
hosted connector) → Generated prompt. Never leave a gap as a dead end - state the route.

End with a one-line verdict: what works here, what to route elsewhere, and (Code) whether any
git/memory state must be addressed before new work.
