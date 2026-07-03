# docs/superpowers/ - live planning

- [plans/](plans/) - one plan doc per initiative, dated `YYYY-MM-DD-slug.md`, each with task
  checkboxes. The boxes ARE the tracker: every state-changing commit flips its box + appends a
  [PROGRESS.md](../../PROGRESS.md) line in the same commit. The newest dated file with unflipped
  boxes is the live plan; fully-flipped plans are closed history and stay put.
- [specs/](specs/) - design docs behind major initiatives (what/why before the plan's how).
  Frozen once their plan ships.

Entry points: [PLAN.md](../../PLAN.md) (pointer), [PROGRESS.md](../../PROGRESS.md) (execution
log). Discipline: [anti-stale](../../rules/global/anti-stale.md) "tracker currency".
