---
name: context-budget
description: Use when a session feels sluggish or output quality is degrading, after adding many skills/agents/MCP servers, when you want to know how much context headroom is left, or before adding more components and need to know if there is room. Audits what every loaded component costs and recommends what to trim.
---

# context-budget

Estimate token overhead across the loaded components (agents, skills, rules, MCP servers,
CLAUDE.md) and surface what to trim. This is about *loaded-component* cost. Estimation
heuristics: prose `words × 1.3`, code-heavy `chars / 4`.

## 1. Inventory

Scan each directory and estimate tokens per file:

| Component | Path | Flag |
|---|---|---|
| Agents | `agents/*.md` | >200 lines; description >30 words |
| Skills | `skills/*/SKILL.md` | >400 lines; skip duplicate copies |
| Rules | `rules/**/*.md` | >100 lines; overlap within a module |
| MCP | active MCP config | >20 tools/server; servers wrapping plain CLIs (gh/git/npm) |
| CLAUDE.md | project + user chain | combined >300 lines |

MCP schema overhead ≈ 500 tokens/tool - usually the biggest single lever.

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
and per-tool MCP schema sizes - use only when pinpointing a driver, not for routine audits.

**Always-load target:** the always-on layer (global rules + the CLAUDE.md chain) is re-sent every
turn, so it pays its cost per turn, not once. Keep it lean: each global rule one screen; if a rule
fires on <80% of sessions, it belongs in a module (on-demand), not the global lane. If the global
chain regularly injects more than a few thousand tokens, demote the least-universal rule.

## 5. In-session rot signals

The above audits *static* loaded cost. Rot is the *dynamic* decay as a session fills (see
[context-discipline](../../rules/global/context-discipline.md)). Detect it before output suffers:

- **Recall test:** early on, note a specific nontrivial constraint; later ask a question that should
  invoke it. Reaching for a generic answer = rot has started.
- **Consistency check:** ask for a summary of the task/architecture and compare to the start; gaps
  are effective-context gaps.
- **Token-spike proxy:** a usage spike vs. session start marks a high-rot zone; re-explaining more
  than an hour ago is the signal to compact or hand off.

## 6. Subtraction pass (fewer tools beat more)

Every loaded tool/skill/MCP expands the decision space the model navigates on every step - the
paradox of choice applies to models, so removing capability often beats adding it. Counterweight to
"skill-ify repetition": skill-ify only what clears the bar *and* does not overlap an existing skill.
For each candidate component, three questions:

1. Does it appear in *successful* work, or mostly when the agent was confused/failing?
2. Could its job move to a cheaper layer - a static lookup, preprocessing, hardcoded logic?
3. Does removing it force other changes, and at what cost?

Cut what appears in failures more than successes, or overlaps another component's output. Route the
removed capability, do not just delete it (edge case -> handoff; predictable fetch -> pre-load).
**Never cut a rare-but-critical tool** (a security/secret gate fires rarely by design). Emit a
`recommend-removal` line in the report for each. Sweet spot: 5-10 well-scoped over 20-30 broad.

Run after adding any agent, skill, or MCP server to catch creep early. General speed
principles: [speed-by-default](../../rules/modules/coding/speed-by-default.md).
