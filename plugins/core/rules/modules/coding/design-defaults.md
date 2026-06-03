---
module: coding/design-defaults
updated: 2026-06-03
---
# Design defaults

- YAGNI: build for the requirement in front of you, not a speculative one. In ETL, do not
  unify NBA, NFL, and MLB logic until the shared shape actually exists; premature unification
  creates brittle code that fights each sport's quirks.
- KISS: prefer the simplest solution that works and reads clearly. Clarity over cleverness.
- DRY: extract shared logic only when the repetition is genuine and stable. Copy-paste twice
  is fine; on the third, consider abstracting.
