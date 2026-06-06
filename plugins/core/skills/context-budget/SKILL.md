---
name: context-budget
description: Use when a session feels sluggish or output quality is degrading, after adding many skills/agents/MCP servers, when you want to know how much context headroom is left, or before adding more components and need to know if there is room. Audits what every loaded component costs and recommends what to trim.
---

# context-budget

Estimate token overhead across the loaded components (agents, skills, rules, MCP servers,
CLAUDE.md) and surface what to trim. This is about *loaded-component* cost. For per-answer
output depth see `token-budget-advisor`; for when to compact mid-session see
`strategic-compact`. Estimation heuristics live here and are reused by `token-budget-advisor`:
prose `words × 1.3`, code-heavy `chars / 4`.

## 1. Inventory

Scan each directory and estimate tokens per file:

| Component | Path | Flag |
|---|---|---|
| Agents | `agents/*.md` | >200 lines; description >30 words |
| Skills | `skills/*/SKILL.md` | >400 lines; skip duplicate copies |
| Rules | `rules/**/*.md` | >100 lines; overlap within a module |
| MCP | active MCP config | >20 tools/server; servers wrapping plain CLIs (gh/git/npm) |
| CLAUDE.md | project + user chain | combined >300 lines |

MCP schema overhead ≈ 500 tokens/tool — usually the biggest single lever.

## 2. Classify

| Bucket | Criteria | Action |
|---|---|---|
| Always needed | in CLAUDE.md, backs a command, matches project type | keep |
| Sometimes | domain-specific, not referenced | on-demand load |
| Rarely | no reference, overlaps, no project match | remove / lazy-load |

## 3. Detect

Bloated agent descriptions (loaded into every Task call), heavy agents (>200 lines),
redundant components (skill duplicates agent, rule duplicates CLAUDE.md), MCP
over-subscription (>10 servers or CLI-replaceable ones), CLAUDE.md bloat (verbose or stale).

## 4. Report

```
Total overhead: ~XX,XXX tokens | window 200K | available ~XXX,XXX (XX%)
Agents N ~X,XXX | Skills N ~X,XXX | Rules N ~X,XXX | MCP N ~XX,XXX | CLAUDE.md N ~X,XXX
Issues (N), ranked by savings:
1. [action] → ~X,XXX   2. [action] → ~X,XXX   3. [action] → ~X,XXX
Potential savings: ~XX,XXX (XX%)
```

Verbose mode adds per-file counts, heaviest-file breakdown, overlapping lines side by side,
and per-tool MCP schema sizes — use only when pinpointing a driver, not for routine audits.

Run after adding any agent, skill, or MCP server to catch creep early. General speed
principles: [speed-by-default](../../rules/global/speed-by-default.md).
