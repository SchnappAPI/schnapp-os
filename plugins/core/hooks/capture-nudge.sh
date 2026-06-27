#!/usr/bin/env bash
# capture-nudge.sh — UserPromptSubmit. The learning loop's CAPTURE trigger (correction half).
#
# Why: the routing procedures already exist (memory/README "on-correction": behavioral->rule,
# fact->memory-supersede, stale-doc->doc-fix). What was missing is the TRIGGER — capture relied on
# the agent remembering, so corrections got fixed locally and lost by the next session (the exact
# "fixes don't stick" failure). This fires capture at the moment a correction arrives.
#
# Deterministic + fast: a single grep over stdin, no interpreter spawn. Non-blocking; always exits 0
# (UserPromptSubmit exit 2 would suppress the prompt — never do that here). Stdout is injected into
# the session context by Claude Code, so the nudge primes routing as the agent answers.
#
# Precision over recall: high-confidence correction phrases only. Missed-but-real corrections are
# caught by the always-loaded working-style rule + judgment; a rare false positive costs one line.
set -uo pipefail
INPUT="$(cat)"

if printf '%s' "$INPUT" | grep -qiE "you'?re wrong|that'?s wrong|that is wrong|incorrect|i told you|i already (told|said)|you should have|you should ?n'?t|you should not|why did you|why are you|i did ?n'?t ask|stop asking|that'?s not what|not what i (asked|wanted|said|meant)|do ?n'?t ask"; then
  # Enqueue the correction for the nightly learning worker (local, git-ignored queue).
  # Best-effort: a write failure must never break the hook.
  q="${CLAUDE_PROJECT_DIR:-$PWD}/scheduled-tasks/.learning-queue.tsv"
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  line="$(printf '%s' "$INPUT" | tr '\n\t' '  ')"
  { printf '%s\tcorrection\t%s\n' "$ts" "$line" >> "$q"; } 2>/dev/null || true

  cat <<'EOF'
[capture] This reads like a correction. Route it now (memory/README "on-correction") so it can't recur:
  - behavioral / how-to-work -> sharpen the EXISTING rule in rules/global/ (add a new file only if there is no home; never duplicate)
  - durable fact (a value/name/where) -> memory/ (supersede the old fact; source: correction; today's updated:)
  - stale doc or claim -> fix the doc in the SAME change
  Route via the learn-route skill. In-session: edit the rule/fact + commit straight to main (no
  branches — owner pref 2026-06-27 / ADR 0016). The nightly learning-worker gates its OWN autonomous
  proposals (learning-gate.sh): clean ones land on main, held ones become a review issue.
  If the lesson maps to an existing rule, the fix is adherence, not a new file.
EOF
fi
exit 0
