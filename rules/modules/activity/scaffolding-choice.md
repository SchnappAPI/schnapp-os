---
module: activity/scaffolding-choice
updated: 2026-07-02
---
# Choosing the scaffolding primitive

Load when designing or refactoring a capability and deciding *what form it should take* - a prompt,
a rule/module, a skill, a hook, an MCP server, or a subagent. Picking wrong wastes time re-explaining
structure every session, or adds surface area that makes the agent worse.

## Decision tree (stop at the first yes)

1. **One-off, no repetition?** -> just a **prompt**. Test: if you have written it more than twice,
   leave prompt territory.
2. **A behavior/standard that should hold every time?** -> a **rule**. Always-on and universal ->
   [`rules/global/`](../global/); scoped to a language/tool/activity -> a
   [`rules/modules/`](../) module (on-demand). Rules shape how the agent *thinks*; keep them lean.
3. **A repeatable multi-step procedure the agent runs on request?** -> a **skill**
   (`.claude/skills/`, progressive-disclosure markdown). Single-purpose, one sentence to describe.
4. **A check that must be enforced without model judgment?** -> a **hook or script**
   (`hooks/` + `.claude/settings.json`, or a `scripts/check-*.sh` gate). Deterministic verification
   is code's job, not the model's (secret-scan, shellcheck, freshness, no-force-push already are).
5. **A specialized read/build task better run in isolated context?** -> a **subagent**
   (the Agent/Task tool or a `.claude/agents/` type). Keeps big file reads out of the main window.
6. **Needs live data or actions from an external system?** -> an **MCP connector**
   (`.mcp.json` + `connectors/`), usually behind the portal.

## Rules of thumb

- **CLI beats MCP when a CLI exists.** An MCP server costs roughly an order of magnitude more tokens
  than the equivalent CLI call (schema re-sent every turn) and gets less reliable as it grows. `gh`,
  `git`, `op`, `npm` are CLIs - do not wrap them in a server. Reserve MCP for genuinely remote
  systems with no local CLI. Reinforces [context-budget](../../../.claude/skills/context-budget/SKILL.md)
  ("MCP schema overhead ~500 tokens/tool") and ADR 0011 #6.
- **One sentence or it is too big.** If you cannot describe the skill/hook/agent in one sentence, it
  is doing too much - split it.
- **Skill-ify repetition, but subtract too.** Anything done repeatedly becomes a skill *only if* it
  clears the bar (recurs, non-obvious, generalizable) and does not overlap an existing one. Fewer,
  well-scoped components beat many broad ones - run the [context-budget](../../../.claude/skills/context-budget/SKILL.md)
  subtraction pass before adding. This is [`docs/framework.md`](../../../docs/framework.md) §H, kept honest.
- **No plugin packaging.** schnapp-os is one owner's OS, not a distributable - native `.claude/`
  discovery, `@import`, and `git pull` propagate it, not npm/marketplace (ADR 0011 #2, ADR 0024).

## When a session reveals a new capability
Extract a reusable *procedure* from a finished session with the `session-to-skill` skill; route a
recurring *principle/correction* with `rules-distill` / `learn-route`. Author the skill itself with
the `skill-creator`.
