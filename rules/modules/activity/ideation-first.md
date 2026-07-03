---
module: activity/ideation-first
updated: 2026-07-03
---
# Ideation before execution (diverge, then converge)

Load when the task has more than one credible direction and the *choice of direction* matters as
much as the execution: content angles, a strategy, a name, a debugging hypothesis, a research
framing. The default failure is collapsing two different tasks (generate options, pick one) into one
rushed prompt, so the model commits to the most probable path instead of the best one.

## The two stages
1. **Diverge.** Ask for 4-7 genuinely distinct options (5 is the default), each described in one or
   two sentences, none developed. Force spread: "each a different angle / assumption / hook", or
   "range from conservative to unconventional". End with an explicit brake: "do not write the full
   thing yet, just the directions". Without the brake the model starts executing option 1 and
   collapses back to a single path.
2. **Converge.** Evaluate the options against the goal and constraints (this is where the owner's
   judgment lives, not the model's), pick one, then execute it fully with the direction locked.

## Rules of thumb
- **Give evaluation criteria up front**, or diversity produces interesting-but-irrelevant options.
- **Keep the ideation prompt under-specified.** Save the details for the execution prompt: too many
  constraints upfront kill the spread.
- **Small, high-stakes outputs benefit most** (a subject line, a name, a CTA), not least.
- **This is the generative front half.** The convergent tools are
  [`council`](../../../.claude/skills/council/SKILL.md) (decide under ambiguity) and
  [`grill-me`](../../../.claude/skills/grill-me/SKILL.md) (stress-test one plan). Diverge here first,
  then hand the chosen direction to them.
