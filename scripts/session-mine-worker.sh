#!/usr/bin/env bash
# session-mine-worker.sh - nightly session-mining driver (auto-improvement lane, ADR 0037 P2/P3).
#
# Pipeline: transcript-mine.py (deterministic fire-rate) -> session_mine.py (bounded Agent SDK
# proposal: at most one skill mint/sharpen + an evidence JSON) -> deterministic verification
# (every evidence quote greps verbatim in its named transcript; trigger phrases collide with no
# other skill's description) -> regenerate catalog projections -> learning-gate.sh with a skills
# scope -> commit straight to main (ADR 0016). Anything that fails verification or the gate is
# DISCARDED and filed as a GitHub issue (best-effort). The LLM never touches git.
#
# Auto-prune (P3): a skill with zero fires in BOTH of the two most recent history snapshots,
# whose directory predates the older snapshot, is removed in the same gated commit (git history
# keeps it recoverable).
#
# Usage: session-mine-worker.sh [--dry-run]
# Env:
#   MINING_TRANSCRIPT_ROOT - transcript corpus (default ~/.claude/projects)
#   MINING_WINDOW_DAYS     - fire-rate window (default 14)
#   MINING_HISTORY_DIR     - snapshot dir (default scheduled-tasks/.mining-history; git-ignored)
#   MINING_GATE_MAX_ADDED  - gate size cap for a skill proposal (default 150)
#   LEARNING_CLAUDE_TOKEN_REF - op:// ref for headless auth (same as learning-worker.sh)
# --dry-run: miner + snapshot + prune-scan only; NO SDK call, NO git, NO gh, NO tree change.
set -uo pipefail

DRY_RUN=false
for arg in "$@"; do [ "$arg" = "--dry-run" ] && DRY_RUN=true; done

# SESSION_MINE_REPO_ROOT: test override so the self-test can point the pure functions
# (check_collision) at a fixture tree. Live runs never set it.
REPO_ROOT="${SESSION_MINE_REPO_ROOT:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"}"
ROOT="${MINING_TRANSCRIPT_ROOT:-"$HOME/.claude/projects"}"
WINDOW="${MINING_WINDOW_DAYS:-14}"
HIST="${MINING_HISTORY_DIR:-"$REPO_ROOT/scheduled-tasks/.mining-history"}"
EVIDENCE="$REPO_ROOT/scheduled-tasks/.mining-evidence.json"
GATE="$REPO_ROOT/scripts/learning-gate.sh"
SKILL_SCOPE='skills/*/SKILL.md|CATALOG.md|surfaces/claude-ai-skills.md'

alert() { $DRY_RUN && return 0; "$REPO_ROOT/scripts/ops-alert.sh" "$@" >/dev/null 2>&1 || true; }

# verify_evidence <evidence.json>: >= 2 distinct transcripts, every quote greps -F in its file.
# Anti-hallucination core: a fabricated quote or session kills the whole proposal. Exit 0/1.
verify_evidence() {
  local ev="$1"
  [ -s "$ev" ] || { echo "verify: evidence file missing/empty: $ev"; return 1; }
  python3 - "$ev" <<'PYEOF'
import json, pathlib, sys
try:
    data = json.load(open(sys.argv[1]))
    entries = data["evidence"]
except Exception as exc:
    print(f"verify: bad evidence JSON: {exc}"); sys.exit(1)
paths = set()
for e in entries:
    p, q = pathlib.Path(e["transcript"]), e["quote"]
    if not p.is_file():
        print(f"verify: transcript not found: {p}"); sys.exit(1)
    if len(q) < 30:
        print(f"verify: quote too short ({len(q)} chars): {q!r}"); sys.exit(1)
    if q not in p.read_text(errors="replace"):
        print(f"verify: quote NOT in {p.name}: {q[:60]!r}"); sys.exit(1)
    paths.add(str(p))
if len(paths) < 2:
    print(f"verify: only {len(paths)} distinct transcript(s); need >= 2"); sys.exit(1)
print(f"verify: OK - {len(entries)} quotes across {len(paths)} sessions")
PYEOF
}

# check_collision <skill-name>: no quoted "..." trigger phrase in the new/changed description may
# appear verbatim in any OTHER skill's description (the taxonomy no-overlap invariant). Exit 0/1.
check_collision() {
  local name="$1" desc phrase rc=0
  desc="$(awk '/^description:/{sub(/^description: /,""); print; exit}' \
    "$REPO_ROOT/skills/$name/SKILL.md")"
  [ -n "$desc" ] || { echo "collision: no description in skills/$name/SKILL.md"; return 1; }
  while IFS= read -r phrase; do
    [ "${#phrase}" -ge 12 ] || continue
    if grep -lF "$phrase" "$REPO_ROOT"/skills/*/SKILL.md 2>/dev/null \
        | grep -v "/skills/$name/" | grep -q .; then
      echo "collision: trigger phrase \"$phrase\" already claimed by another skill"
      rc=1
    fi
  done < <(printf '%s\n' "$desc" | grep -oE '"[^"]+"' | tr -d '"')
  return $rc
}

# prune_candidates: skill names with zero fires in BOTH of the two newest snapshots and a
# directory that predates the older snapshot (by git first-commit date). One name per line.
prune_candidates() {
  local older newer
  newer="$(find "$HIST" -maxdepth 1 -name '*.tsv' 2>/dev/null | sort | tail -1)"
  older="$(find "$HIST" -maxdepth 1 -name '*.tsv' 2>/dev/null | sort | tail -2 | head -1)"
  [ -n "$older" ] && [ -n "$newer" ] && [ "$older" != "$newer" ] || return 0
  local older_date; older_date="$(basename "$older" .tsv)"
  local d name first
  for d in "$REPO_ROOT"/skills/*/; do
    name="$(basename "$d")"
    grep -q $'^skill\t'"$name"$'\t' "$older" "$newer" 2>/dev/null && continue
    first="$(git -C "$REPO_ROOT" log --diff-filter=A --follow --format=%as -1 \
      -- "skills/$name/SKILL.md" 2>/dev/null | head -1)"
    [ -n "$first" ] && [[ "$first" < "$older_date" ]] && echo "$name"
  done
}

main() {
  cd "$REPO_ROOT" || exit 1
  mkdir -p "$HIST"

  # 1. Deterministic fire-rate + snapshot (dated; snapshots are the prune ledger).
  local today tsv
  today="$(date +%Y-%m-%d)"
  tsv="$HIST/$today.tsv"
  python3 "$REPO_ROOT/scripts/transcript-mine.py" --root "$ROOT" --since "$WINDOW" > "$tsv" \
    || { alert red session-mine "Session mining failed" "transcript-mine.py failed"; exit 1; }
  echo "session-mine: fire-rate snapshot -> $tsv ($(wc -l < "$tsv") rows)"

  local prunes; prunes="$(prune_candidates)"
  if $DRY_RUN; then
    [ -n "$prunes" ] && printf 'would prune (zero fires, 2 windows):\n%s\n' "$prunes"
    echo "session-mine: dry-run complete (no SDK, no git)."
    exit 0
  fi

  command -v claude >/dev/null 2>&1 || { echo "session-mine: no claude CLI - no-op."; exit 0; }

  # Headless auth: same op:// resolution as learning-worker.sh.
  if [ -z "${ANTHROPIC_API_KEY:-}" ] && [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ] \
      && [ -n "${LEARNING_CLAUDE_TOKEN_REF:-}" ] && command -v op >/dev/null 2>&1; then
    _tok="$(op read "$LEARNING_CLAUDE_TOKEN_REF" 2>/dev/null)" && {
      case "$_tok" in sk-ant-api*) export ANTHROPIC_API_KEY="$_tok" ;;
                      *) export CLAUDE_CODE_OAUTH_TOKEN="$_tok" ;; esac; }
    unset _tok
  fi

  # Pre-commit discipline (ADR 0016): clean main synced to origin, or abort.
  git fetch -q origin main 2>/dev/null || true
  if [ -n "$(git status --porcelain)" ]; then
    alert red session-mine "Session mining blocked" "working tree not clean - aborted"
    echo "session-mine: working tree not clean - aborting." >&2; exit 1
  fi
  git checkout -q main && git reset -q --hard origin/main

  # Staged-rollout escalator for the autonomous hook lane (ADR 0037 tier 3). Runs on the CLEAN
  # tree so its tiny observe->enforce commit (it pushes itself) never mixes with the skill
  # proposal below; after it, re-sync so our later diff base is current. Best-effort.
  bash "$REPO_ROOT/scripts/auto-hook-escalate.sh" || true
  git fetch -q origin main 2>/dev/null || true
  git reset -q --hard origin/main

  # 2. Bounded SDK proposal. Same dedicated venv as learning_distill (the Agent SDK is not in
  # the system python3, and launchd sees only the system one).
  local mine_python="${LEARNING_DISTILL_PYTHON:-$HOME/.venvs/learning-distill/bin/python}"
  [ -x "$mine_python" ] || mine_python="$(command -v python3)"
  rm -f "$EVIDENCE"
  MINING_TSV="$tsv" MINING_TRANSCRIPT_ROOT="$ROOT" \
    "$mine_python" "$REPO_ROOT/scripts/session_mine.py" \
    || { git reset -q --hard origin/main; git clean -qfd skills/
         alert red session-mine "Session mining failed" "session_mine.py failed - tree reset"
         exit 1; }

  # 3. Apply prune (deterministic, independent of whether the agent proposed anything).
  local p
  for p in $prunes; do
    echo "session-mine: pruning zero-fire skill '$p'"
    git rm -rq "skills/$p"
  done

  local changed; changed="$(git status --porcelain)"
  if [ -z "$changed" ] && [ ! -s "$EVIDENCE" ]; then
    echo "session-mine: no proposal, no prune - clean no-op."
    alert green session-mine "Session mining healthy" "no candidate cleared the bar"
    exit 0
  fi

  # 4. Verify the proposal (skip when this run is prune-only).
  local skill=""
  if [ -s "$EVIDENCE" ]; then
    skill="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["skill"])' \
      "$EVIDENCE" 2>/dev/null || true)"
    if [ -z "$skill" ] || ! verify_evidence "$EVIDENCE" || ! check_collision "$skill"; then
      git reset -q --hard origin/main; git clean -qfd skills/
      alert red session-mine "Session mining held" "proposal failed evidence/collision checks - discarded"
      echo "session-mine: proposal DISCARDED (verification failed)."; exit 1
    fi
  elif git status --porcelain | grep -q '^.. skills/.*SKILL\.md'; then
    # A skill changed but no evidence file: unverifiable - discard.
    git reset -q --hard origin/main; git clean -qfd skills/
    alert red session-mine "Session mining held" "skill edit without evidence file - discarded"
    exit 1
  fi

  # 5. Regenerate projections (same commit) and gate.
  bash "$REPO_ROOT/scripts/gen-catalog.sh" >/dev/null
  bash "$REPO_ROOT/scripts/gen-claude-ai-skills.sh" >/dev/null
  git add -A skills/ CATALOG.md surfaces/claude-ai-skills.md
  local what="prune"; [ -n "$skill" ] && what="mint/sharpen $skill"
  git commit -qm "feat(learning): session-mine auto-$what (ADR 0037)" \
    -m "Autonomous lane: evidence-verified proposal + zero-fire prune. Gate: learning-gate.sh scope skills."
  if LEARNING_GATE_MAX_ADDED="${MINING_GATE_MAX_ADDED:-150}" \
      bash "$GATE" origin/main "$SKILL_SCOPE"; then
    git push -q origin HEAD:main \
      || { alert red session-mine "Session mining push failed" "commit made but push failed"; exit 1; }
    echo "session-mine: LANDED on main."
    alert green session-mine "Session mining landed" "skill='${skill:-none}' prunes='${prunes:-none}'"
  else
    local diff; diff="$(git diff origin/main...HEAD | head -200)"
    git reset -q --hard origin/main
    command -v gh >/dev/null 2>&1 && gh issue create \
      --title "session-mine HELD: ${skill:-prune} proposal needs review" \
      --body "$(printf 'Gate held this autonomous proposal (ADR 0037).\n\n~~~diff\n%s\n~~~' "$diff")" \
      >/dev/null 2>&1 || true
    echo "session-mine: gate HELD - discarded working-tree change, issue filed (best-effort)."
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi
