#!/usr/bin/env bash
# capture-nudge.sh - UserPromptSubmit, wired user-scope (machine-wide) in ~/.claude/settings.json
# alongside standing-rules.sh. The learning loop's CAPTURE trigger (correction half).
#
# Why: the routing procedures already exist (docs/memory-lane.md "On-correction update": behavioral->rule,
# fact->memory-supersede, stale-doc->doc-fix). What was missing is the TRIGGER - capture relied on
# the agent remembering, so corrections got fixed locally and lost by the next session (the exact
# "fixes don't stick" failure). This fires capture at the moment a correction arrives.
#
# Deterministic + fast: a single grep over stdin, no interpreter spawn. Non-blocking; always exits 0
# (UserPromptSubmit exit 2 would suppress the prompt - never do that here). Stdout is injected into
# the session context by Claude Code, so the nudge primes routing as the agent answers.
#
# Precision over recall: high-confidence correction phrases only. Missed-but-real corrections are
# caught by the always-loaded working-style rule + judgment; a rare false positive costs one line.
set -uo pipefail
INPUT="$(cat)"

if printf '%s' "$INPUT" | grep -qiE "you'?re wrong|that'?s wrong|that is wrong|incorrect|i told you|i already (told|said)|you should have|you should ?n'?t|you should not|why did you|why are you|i did ?n'?t ask|stop asking|that'?s not what|not what i (asked|wanted|said|meant)|do ?n'?t ask"; then
  # Enqueue the correction for the nightly learning worker (local, git-ignored queue).
  # Absolute default so machine-wide firing always lands in the schnapp-os queue; LEARNING_QUEUE
  # overrides it (tests redirect to a temp dir; a machine with schnapp-os cloned elsewhere points here).
  # Best-effort: a write failure must never break the hook.
  q="${LEARNING_QUEUE:-$HOME/code/schnapp-os/scheduled-tasks/.learning-queue.tsv}"
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  line="$(printf '%s' "$INPUT" | tr '\n\t' '  ')"
  { printf '%s\tcorrection\t%s\n' "$ts" "$line" >> "$q"; } 2>/dev/null || true

  cat <<'EOF'
[capture] This reads like a correction. Before fixing, find the ROOT CAUSE so it cannot recur. The behavioral home is the schnapp-os rules + the vault memory lane (machine-wide), not whatever repo you are in now:
  1. Why did the wrong approach happen - a missing, ambiguous, or unfollowed rule, or a misread of intent? Name it.
  2. Fix THAT source, not just this instance (schnapp-os docs/memory-lane.md "On-correction update", via the learn-route skill):
     - behavioral / how-to-work -> sharpen the EXISTING rule in schnapp-os rules/global/ (new file only if there is no home; never duplicate)
     - durable fact (a value/name/where) -> the vault memory lane (supersede; source: correction; today's updated:)
     - stale doc or claim -> fix the doc in the SAME change
  3. Generalize to the whole class, not the one example. The fix commits to the schnapp-os (or vault) main - that behavioral lane, not the repo you are working in now.
EOF
fi
exit 0
