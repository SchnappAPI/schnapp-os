# schnapp-os - plan pointer

The original build plan (the 11-Part rebuild of this system) is DONE: all Parts closed. Its full text
is archived verbatim at [docs/archive/PLAN-archive-2026-07-01.md](docs/archive/PLAN-archive-2026-07-01.md)
(history, never edited after write).

## Where planning lives now
- **Active plans**: per-initiative, under [docs/superpowers/plans/](docs/superpowers/plans/). Each
  carries its own task checkboxes (the live tracker for that work). Current: the
  [streamline plan](docs/superpowers/plans/2026-06-30-schnapp-os-streamline.md).
- **Decisions** (the why, append-only): [decisions/](decisions/).
- **Status / execution log**: [PROGRESS.md](PROGRESS.md), newest at the bottom.
- **Component inventory**: [CATALOG.md](CATALOG.md) (generated).

## Why this file is a pointer
decisions/0011 reframed PLAN.md from the spine to a backlog; the 11-Part build then closed. A 677-line
plan of finished work is not a live tracker: it rots and buries the few still-open threads. Retired to
this pointer plus archive, mirroring the PROGRESS.md reconcile
([decisions/0022](decisions/0022-progress-md-rotation-policy.md)). Rationale and policy:
[decisions/0025](decisions/0025-plan-md-retired-to-pointer.md).

## Open threads carried forward from the archived plan
- None still open and tracked only here. The vault-PAT rotation once marked PENDING is closed as
  accepted-risk (`credentials-state` memory); the per-machine `autoMemoryDirectory` one-liner is
  tracked in the latest handoff; the plugin work is done via the flatten (ADR 0024).
