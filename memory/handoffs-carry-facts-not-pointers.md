---
name: handoffs-carry-facts-not-pointers
metadata:
  node_type: memory
  scope: global
  source: "session 042+/043 streamline; owner correction 2026-07-01"
  updated: 2026-07-01
  supersedes: ""
---
When handing work to a new session OR locking a design, GIVE FULL CONTEXT — the established facts, not just decisions or pointers.

**What happened (2026-07-01):** the streamline design handed a fresh Phase-1 session the decisions (spec + plan) but left the audit's current-state FACTS in an ephemeral session scratchpad. The new session had to reconstruct the whole topology from scratch, and the design had already missed real infra — an existing `SchnappAPI/obsidian-vault` repo with two clones, and the Obsidian Brain Agent that hardcodes the OneDrive path. Locked on an incomplete picture.

**Why it matters:** the owner's #1 goal is accuracy and NOT repeating the shelf-vs-gate disease. Forcing rediscovery wastes the new session and re-surfaces already-decided questions to the owner — the exact thing to avoid. Designing on a partial map risks breaking things the plan never named.

**How to apply:**
1. A handoff / spawn-prompt CARRIES the full current-state MAP (repos, paths, services, schemas) + every locked decision — facts inline, not just pointers. New sessions VERIFY against the map, never RECONSTRUCT it.
2. Before locking any design that touches infra, VERIFY the full current-state topology first — never conclude from a partial audit.

Same anti-stale spirit as [[keep-tracker-current]].
