#!/usr/bin/env bash
# learning-worker.sh — nightly learning-loop driver (Phase 4, pre-commit gate, ADR 0016).
#
# Reads the local learning queue (git-ignored .learning-queue.tsv), has a headless Agent SDK run
# distill+classify each capture and WRITE any proposed rule/fact edit to the working tree (no branch,
# no commit, no PR), then the WORKER gates the working-tree diff (learning-gate.sh): a clean proposal
# is committed straight to main; anything the gate holds is filed as a GitHub issue. No branches —
# everything that lands goes to main (owner pref 2026-06-27; ADR 0016 refines 0012/0013/0015).
#
# Recurrence pre-step (Phase 3 T2, spec sec 4.4): BEFORE distillation, learning-recurrence.sh counts
# error-class frequency over archive+queue. A class that recurs (>= 2) is drafted as a GATE PROPOSAL —
# a GitHub issue for owner approval — instead of another prose fact, and the class's captures are held
# OUT of this run's distill input (so the loop does not also write prose for it). A drafted gate NEVER
# auto-lands: it is only an issue; it is never a working-tree edit/commit/push. learning-gate.sh (the
# auto-land gate) still admits only .md under rules/memory, so a gate could not route through it anyway.
#
# Usage: learning-worker.sh [--dry-run]
# Env:
#   LEARNING_QUEUE   — queue file (default: scheduled-tasks/.learning-queue.tsv)
#   LEARNING_ARCHIVE — archive file (default: alongside queue, .learning-queue.archive.tsv)
#   LEARNING_GATE_DRAFTED — recurrence marker (default: alongside queue, .learning-queue.gate-drafted.tsv)
#   LEARNING_CLAUDE_TOKEN_REF — op:// ref to the Claude credential (headless auth; see docs/headless-claude-auth.md)
#
# --dry-run: exercises queue/recurrence/classify/archive plumbing with NO distill call, NO git, NO
#   network, NO gh, NO working-tree change (proven by scripts/tests/test-learning-worker.sh).
#
# Safety:
#   - Empty/missing queue → message + exit 0.  Live path needs the `claude` CLI; absent → no-op exit 0.
#   - Distillation runs via the Agent SDK (learning_distill.py): file-edit tools only
#     (Read/Edit/Write/Grep/Glob, NO Bash/git/network), bounded turns + timeout + retry-once. The
#     prompt scopes edits to rules/memory; the worker gates+commits the diff (not a hard sandbox).
#   - Default flow: the worker gates the resulting diff (learning-gate.sh) and pushes only APPROVED
#     changes to main; held proposals never touch main (→ issue).
#   - Recurrence drafting is best-effort (like alert()): a missing/failing `gh` prints a notice and
#     CONTINUES — it must NEVER fail the worker or lose a capture. Gated captures are STILL archived.
#   - Archiving (not deleting) means a capture is never silently lost.
set -uo pipefail

DRY_RUN=false
for arg in "$@"; do [ "$arg" = "--dry-run" ] && DRY_RUN=true; done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
Q="${LEARNING_QUEUE:-"$REPO_ROOT/scheduled-tasks/.learning-queue.tsv"}"
A="${LEARNING_ARCHIVE:-"${Q%.tsv}.archive.tsv"}"
# Recurrence-gate marker: signatures of error-classes already drafted as a gate proposal (one per
# line) so a class drafts at most once. GIT-IGNORED (see .gitignore) — an untracked marker would show
# in `git status --porcelain` and corrupt the post-distill clean-check. The worker appends to it; the
# recurrence tool only reads it. Never committed.
DRAFTED="${LEARNING_GATE_DRAFTED:-"${Q%.tsv}.gate-drafted.tsv"}"
RECURRENCE="$REPO_ROOT/scripts/learning-recurrence.sh"

# Best-effort native alerting (incident-managed via ops-alert.sh: opens/auto-closes a GitHub issue +
# ntfy). Detection stays in this caller; the alert layer must NEVER break the worker, hence `|| true`.
# No-op under --dry-run. Closes the silent-swallow gap: a failed claude run used to exit non-zero with
# no signal off the Mac.
alert() { $DRY_RUN && return 0; "$REPO_ROOT/scripts/ops-alert.sh" "$@" >/dev/null 2>&1 || true; }

if [ ! -f "$Q" ] || [ ! -s "$Q" ]; then
  echo "learning-worker: queue empty — nothing to consolidate"
  alert green learning-worker "Learning worker healthy" "queue empty — nothing to consolidate"
  exit 0
fi

# Deterministic label for --dry-run only (the live LLM does the real classification).
classify_capture() {
  if printf '%s' "$1" | grep -qE '[0-9]{2,}|op://|/[a-zA-Z]'; then echo "judgment"; else echo "mechanical"; fi
}

# --- recurrence gate: shared between the live and dry-run paths (one filter, no duplication) -------
# DRAFTED_SIGS holds the signatures drafted THIS run (one per line), populated by run_recurrence_draft.
# A capture whose class signature is in that set was escalated to a gate proposal and is kept OUT of
# distillation (live) / labeled "would draft gate" (dry-run).
DRAFTED_SIGS=""

# Is a capture's class among the signatures drafted this run? (the shared filter both paths call)
capture_is_drafted() { # $1 = capture text ; 0 if its class was drafted, 1 otherwise
  [ -n "$DRAFTED_SIGS" ] || return 1
  local s; s="$(bash "$RECURRENCE" signature "$1" 2>/dev/null)"
  [ -n "$s" ] || return 1
  printf '%s\n' "$DRAFTED_SIGS" | grep -qxF "$s"
}

# Run the deterministic draft over archive+queue and write its block output to $1 (a temp file).
# Sets DRAFTED_SIGS to the CANDIDATE set — every emitted block's SIG: line (the classes that recurred
# this run). Pure/read-only (no gh, no git, no marker write) — the caller decides what to do with the
# blocks. In the LIVE path the candidate set is later NARROWED to only the classes whose `gh issue
# create` actually SUCCEEDED (see below), because a class is marked drafted + held out of distillation
# ONLY once its gate issue is truly filed. The DRY-RUN path (no gh) uses the candidate set as-is.
# Best-effort: on any failure it leaves DRAFTED_SIGS empty and returns 0 (recurrence must never break
# the worker).
run_recurrence_draft() { # $1 = output file for the raw draft blocks
  : > "$1"
  bash "$RECURRENCE" draft "$Q" "$A" "$DRAFTED" > "$1" 2>/dev/null || true
  DRAFTED_SIGS="$(grep '^SIG: ' "$1" 2>/dev/null | sed 's/^SIG: //' || true)"
}

# Archive processed captures, THEN drain — never drain if the archive write failed (no captures lost).
# Archives the FULL original queue (gated captures included) so a drafted class keeps being counted on
# later runs; only the DISTILL INPUT is ever filtered, never the archive.
archive_and_drain() {
  if ! cat "$Q" >> "$A" 2>/dev/null; then
    echo "learning-worker: ERROR — could not write archive '$A'; queue NOT drained (no captures lost)." >&2
    exit 1
  fi
  : > "$Q"
}

if $DRY_RUN; then
  # Recurrence draft: deterministic, NO gh, NO git, NO marker write. Just report what WOULD happen.
  draft_out="$(mktemp)"
  run_recurrence_draft "$draft_out"
  while IFS= read -r title; do
    echo "would draft gate issue: $title"
  done < <(grep '^TITLE: ' "$draft_out" 2>/dev/null | sed 's/^TITLE: //')
  rm -f "$draft_out"
  # Per-capture routing: a drafted class shows "would draft gate" (instead of prose); else distill.
  # `|| [ -n "${text-}" ]` keeps the last line when the queue lacks a trailing newline (same idiom as
  # learning-recurrence.sh emit() and the live filter loop) so a no-trailing-newline capture is shown.
  while IFS=$'\t' read -r _ _ text || [ -n "${text-}" ]; do
    [ -n "${text-}" ] || continue
    if capture_is_drafted "$text"; then
      echo "would draft gate: $text"
    else
      echo "would distill+route: [$(classify_capture "$text")] $text"
    fi
  done < "$Q"
  archive_and_drain
  exit 0
fi

# Live path — require the claude CLI
if ! command -v claude >/dev/null 2>&1; then
  echo "learning-worker: 'claude' CLI not found — install it to run the live learning worker. Exiting (no-op)."
  exit 0
fi

# Run from repo root so the headless session loads CLAUDE.md / .claude/settings.json + relative paths.
cd "$REPO_ROOT" || { echo "learning-worker: ERROR — cannot cd to repo root '$REPO_ROOT'." >&2; exit 1; }

# Headless auth: launchd can't read the login Keychain, so inject the credential from 1Password at
# runtime (the LaunchAgent inherits OP_SERVICE_ACCOUNT_TOKEN). LEARNING_CLAUDE_TOKEN_REF is an op://
# REFERENCE; the item may hold an Anthropic API key (sk-ant-api…) or a Claude OAuth token (sk-ant-oat…)
# — export under the matching env var. No-op if a credential is already set or no ref is configured.
if [ -z "${ANTHROPIC_API_KEY:-}" ] && [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ] && [ -n "${LEARNING_CLAUDE_TOKEN_REF:-}" ]; then
  op_sa_state="set"; [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ] || op_sa_state="UNSET"
  echo "learning-worker: auth — op:$(command -v op || echo MISSING) OP_SA:${op_sa_state} ref:${LEARNING_CLAUDE_TOKEN_REF}"
  if command -v op >/dev/null 2>&1; then
    if _tok="$(op read "$LEARNING_CLAUDE_TOKEN_REF" 2>&1)"; then
      case "$_tok" in
        sk-ant-api*) export ANTHROPIC_API_KEY="$_tok";       _kind=ANTHROPIC_API_KEY ;;
        *)           export CLAUDE_CODE_OAUTH_TOKEN="$_tok"; _kind=CLAUDE_CODE_OAUTH_TOKEN ;;
      esac
      echo "learning-worker: auth — resolved credential via op (${#_tok} chars) -> $_kind."
      unset _kind
    else
      echo "learning-worker: auth — ERROR: op read failed: $_tok" >&2
    fi
    unset _tok
  else
    echo "learning-worker: auth — ERROR: op not on PATH; cannot resolve headless credential." >&2
  fi
fi

# Pre-commit gate flow (ADR 0016, no branches): start from a clean main synced to origin so the only
# diff after the run is the worker's proposal.
git fetch -q origin main 2>/dev/null || true
if [ -n "$(git status --porcelain)" ]; then
  echo "learning-worker: working tree not clean — aborting (queue preserved)." >&2
  alert red learning-worker "Learning worker blocked" "working tree not clean — aborted; queue preserved"
  exit 1
fi
git checkout -q main 2>/dev/null || true
git reset -q --hard origin/main 2>/dev/null || true

# --- recurrence pre-step (BEFORE distillation): draft a GATE for any newly-recurring class ----------
# Deterministic count over archive+queue → drafted-gate blocks. For each block: best-effort open a
# GitHub issue (like alert(): a missing/failing gh prints a notice and CONTINUES — never fails the
# worker, never loses a capture). A class is marked drafted (idempotency marker) AND held OUT of
# distillation ONLY once its `gh issue create` actually SUCCEEDED — so a class whose gh FAILED is not
# marked (it re-drafts next run) and is not filtered (it still flows to prose distillation THIS run,
# better than being orphaned into a gate that was never filed). A drafted gate is ONLY an issue: NO
# working-tree edit, commit, or push happens here. NOTE: this runs AFTER the clean-tree reset and BEFORE
# distillation, and writes only to the git-ignored marker + temp files, so it does not dirty the tree
# the distill clean-check reads.
# Single EXIT trap cleans up every live-path temp artifact (draft_out / blocks_dir / filtered), mirroring
# learning-gate.sh's one-trap pattern — no leaked tmp per drafted-class run in this nightly script.
draft_out=""; blocks_dir=""; filtered=""
cleanup_recurrence() { rm -f "$draft_out" "$filtered" 2>/dev/null; [ -n "$blocks_dir" ] && rm -rf "$blocks_dir" 2>/dev/null; }
trap cleanup_recurrence EXIT
draft_out="$(mktemp)"
run_recurrence_draft "$draft_out"
if [ -n "$DRAFTED_SIGS" ]; then
  # Split the draft output into per-block records (SIG \t title \t bodyfile), so a multi-line markdown
  # body survives intact to `gh --body-file` and each block's SIG rides along to the create loop. awk
  # owns the block boundaries it emitted.
  blocks_dir="$(mktemp -d)"
  bidx=0
  filed_sigs=""   # SIGs whose gate issue was ACTUALLY filed — only these get marked + filtered
  nl=$'\n'        # real newline for accumulating one filed SIG per line ($'\n' does not expand inside ${:+})
  # shellcheck disable=SC2016  # awk program is single-quoted on purpose; $0/$1 are awk fields
  awk -v dir="$blocks_dir" '
    /^<<<GATE-DRAFT>>>$/      { inblk=1; n++; sig=""; title=""; body=""; havebody=0; next }
    /^<<<GATE-DRAFT-END>>>$/  { if (inblk) { bf=dir "/body." n; printf "%s", body > bf; close(bf);
                                             print sig "\t" title "\t" bf } inblk=0; next }
    inblk && /^SIG: /         { sig=substr($0,6);   next }
    inblk && /^TITLE: /       { title=substr($0,8); next }
    inblk && /^BODY:$/        { havebody=1; next }
    inblk && havebody         { body=body $0 "\n"; next }
  ' "$draft_out" > "$blocks_dir/index.tsv"
  while IFS=$'\t' read -r sig title bodyfile; do
    [ -n "$sig" ] && [ -n "$title" ] && [ -n "$bodyfile" ] || continue
    bidx=$((bidx+1))
    if command -v gh >/dev/null 2>&1 && \
       gh issue create --title "$title" --body-file "$bodyfile" >/dev/null 2>&1; then
      # Only a truly-filed class is recorded (marker) and later held out of distillation.
      filed_sigs="${filed_sigs:+$filed_sigs$nl}$sig"
      echo "learning-worker: DRAFTED a gate proposal issue (owner approval required; nothing landed)."
    else
      echo "learning-worker: recurrence — could not open gate-proposal issue (gh absent/failed); continuing (class not marked; will retry; its captures flow to distillation this run)." >&2
    fi
  done < "$blocks_dir/index.tsv"
  # Narrow the held-out set to the FILED classes (a gh failure leaves that class unmarked + unfiltered).
  DRAFTED_SIGS="$filed_sigs"
  if [ -n "$filed_sigs" ]; then
    # Idempotency: record only successfully-filed SIGs so a filed class never re-drafts. Marker git-ignored.
    printf '%s\n' "$filed_sigs" >> "$DRAFTED"
    filed_count="$(printf '%s\n' "$filed_sigs" | grep -c .)"
    echo "learning-worker: recurrence — filed $filed_count of $bidx gate proposal(s); the filed classes' captures are held out of distillation."
  else
    echo "learning-worker: recurrence — $bidx gate proposal(s) drafted but none filed (gh absent/failed); no class marked, all captures flow to distillation." >&2
  fi
  rm -rf "$blocks_dir"; blocks_dir=""
fi
rm -f "$draft_out"; draft_out=""

# Distill input: the queue MINUS any capture whose class was FILED as a gate this run (so the loop does
# not also write prose for an escalated class). DRAFTED_SIGS now holds only the filed set; if nothing
# was filed, distillation sees the full queue (a gh-failed class still gets a prose pass this run).
DISTILL_QUEUE="$Q"
if [ -n "$DRAFTED_SIGS" ]; then
  # Guard the mktemp: under `set -uo pipefail` (no -e) a failed mktemp would leave filtered="" →
  # export LEARNING_QUEUE="" → distill treats an empty-but-SET var as a path of "." and silently
  # no-ops ALL captures. On mktemp failure, fall back to the full queue (distill everything) rather
  # than skip — better a redundant prose pass for a filed class than dropping every capture.
  if filtered="$(mktemp)"; then
    while IFS= read -r line || [ -n "$line" ]; do
      text="${line#*$'\t'}"; text="${text#*$'\t'}"   # column 3 = after the second TAB
      if [ -n "$text" ] && capture_is_drafted "$text"; then continue; fi
      printf '%s\n' "$line" >> "$filtered"
    done < "$Q"
    DISTILL_QUEUE="$filtered"
  else
    echo "learning-worker: recurrence — mktemp for the filtered queue failed; distilling the full queue." >&2
    filtered=""
    DISTILL_QUEUE="$Q"
  fi
fi

echo "learning-worker: processing $(wc -l < "$DISTILL_QUEUE" | tr -d ' ') capture(s) via Agent SDK (learning_distill.py) ..."
# Bounded, file-scoped Agent SDK distillation (no Bash/git/network). The worker gates+commits the diff.
export LEARNING_QUEUE="$DISTILL_QUEUE"
DISTILL_PY="$REPO_ROOT/scripts/learning_distill.py"
DISTILL_PYTHON="${LEARNING_DISTILL_PYTHON:-$HOME/.venvs/learning-distill/bin/python}"
[ -x "$DISTILL_PYTHON" ] || DISTILL_PYTHON="$(command -v python3)"
if ! "$DISTILL_PYTHON" "$DISTILL_PY"; then
  git reset -q --hard origin/main 2>/dev/null || true
  echo "learning-worker: ERROR — Agent SDK distillation failed; queue NOT drained (captures preserved)." >&2
  alert red learning-worker "Learning worker failed" "Agent SDK distillation failed; queue preserved, will retry"
  exit 1
fi

if [ -z "$(git status --porcelain)" ]; then
  echo "learning-worker: no rule/fact change proposed (skipped / duplicate / mechanical)."
else
  git add -A
  git commit -q -m "self-edit: learning-loop promotion $(date -u +%F)"
  gate_out="$(mktemp)"
  if bash "$REPO_ROOT/scripts/learning-gate.sh" origin/main > "$gate_out" 2>&1; then
    if git push -q origin HEAD:main 2>/dev/null; then
      echo "learning-worker: PROMOTED a clean self-edit to main."
    else
      git reset -q --hard origin/main 2>/dev/null || true
      echo "learning-worker: push to main failed (remote moved?) — discarded; will recapture." >&2
    fi
  else
    patch="$(git show HEAD --patch --stat 2>/dev/null | head -c 8000)"
    reasons="$(cat "$gate_out")"
    git reset -q --hard origin/main 2>/dev/null || true
    # shellcheck disable=SC2016  # single-quoted printf format is intentional — printf expands %s/\n, not the shell
    issue_body="$(printf 'The nightly learning worker proposed a self-edit the eval gate HELD (no branch, nothing landed on main).\n\n## Gate reasons\n%s\n\n## Proposed change\n```diff\n%s\n```\n' "$reasons" "$patch")"
    if command -v gh >/dev/null 2>&1 && \
       gh issue create --title "learning-loop: self-edit held for review ($(date -u +%F))" \
         --body "$issue_body" \
         >/dev/null 2>&1; then
      echo "learning-worker: HELD self-edit — opened a review issue (nothing on main)."
    else
      echo "learning-worker: HELD self-edit (could not open issue) — $reasons" >&2
    fi
  fi
  rm -f "$gate_out"
fi

archive_and_drain
alert green learning-worker "Learning worker healthy" "run completed; $(wc -l < "$A" | tr -d ' ') total archived captures"
echo "learning-worker: done — $(wc -l < "$A" | tr -d ' ') total archived captures."
