#!/usr/bin/env bash
# learning-recurrence.sh — deterministic error-class recurrence detector for the nightly learning loop.
#
# Spec sec 2/4.4 + decisions/0026 (enforcement ladder): a lesson that became a code/hook/CI fix STOPS
# recurring; a lesson that stayed prose KEEPS recurring. So when the same error-class shows up again
# (>= 2 captures across the archive + this run's queue), the worker should escalate it from "write more
# prose" to "draft a GATE" — a GitHub issue proposing enforcement, for OWNER APPROVAL. This script is
# the pure, deterministic core of that: it computes a class signature and, on a fresh recurrence, prints
# a drafted-gate block. The WORKER (learning-worker.sh) turns a block into a `gh issue create`.
#
# SAFETY INVARIANT: this script is a READ-ONLY query/report tool. It performs NO git mutation, NO
# working-tree write, NO network, NO `gh`, and NO clock read that affects output. It reads the queue +
# archive files and prints to stdout. A drafted gate is ONLY a proposal here — it can never auto-land,
# by construction (nothing it does touches the tree the auto-land path commits). Determinism: signatures
# and counts are pure functions of the input files (no LLM, no clock, no randomness). Idempotency is the
# caller's marker file: a class is drafted at most once.
#
# Portable: bash 3.2 (Mac) + ubuntu CI; BSD + GNU awk; LC_ALL=C so tolower()/regex stay ASCII.
#
# Usage:
#   learning-recurrence.sh signature "<text>"
#       -> prints ONE line: the deterministic class signature of a capture's free text (may be empty).
#   learning-recurrence.sh draft <queue_file> <archive_file> <drafted_marker_file>
#       -> prints zero or more <<<GATE-DRAFT>>>...<<<GATE-DRAFT-END>>> blocks (nothing if no class
#          newly recurs). Reads only; never writes any of the three files.
#
# Exit codes: 0 on success whether or not a block was emitted (this is a query tool); 2 on a usage error
# (wrong arg count / unknown subcommand).
set -uo pipefail
export LC_ALL=C

# Stopwords dropped from a signature (kept in ONE place). The masking placeholders opref/url/path/num
# are NOT stopwords — they carry class signal and must survive.
STOPWORDS=" a an the is are was were be been to of in on at for and or but it this that these those with as by from into if when then than not no yes do does did use used using should must can will would has have had "

# signature "<text>" -> the deterministic class signature (one line; empty if < 2 tokens survive).
# Algorithm (brief "Subcommand 1"): lowercase; mask op-ref/url/path/num tokens; strip remaining
# non-alphanumerics; split; drop stopwords + <2-char tokens; sort+unique+join; "" if < 2 tokens.
signature() {
  printf '%s' "$1" | awk -v stop="$STOPWORDS" '
    { line = line " " tolower($0) }   # fold any (defensive) multi-line input into one record
    END {
      # Split on whitespace, mask each token, rebuild a masked string.
      m = split(line, tok, /[ \t\r\n]+/)
      masked = ""
      for (i = 1; i <= m; i++) {
        t = tok[i]
        if (t == "") continue
        if (index(t, "op://") == 1)                                     t = "opref"
        else if (index(t, "http://") == 1 || index(t, "https://") == 1) t = "url"
        else if (index(t, "/") > 0 || index(t, "~") == 1)               t = "path"
        else {
          gsub(/[0-9a-f]{4,}/, " num ", t)   # run of >=4 hex digits -> num
          gsub(/[0-9]+/,       " num ", t)   # any run of >=1 ASCII digit -> num
        }
        masked = masked " " t
      }
      # Replace every remaining non-alphanumeric char with a space, then split into tokens.
      gsub(/[^a-z0-9]+/, " ", masked)
      c = split(masked, w, /[ \t]+/)
      n = 0
      for (i = 1; i <= c; i++) {
        tk = w[i]
        if (tk == "" || length(tk) < 2) continue
        if (index(stop, " " tk " ") > 0) continue      # stopword (placeholders never match)
        if (!(tk in seen)) { seen[tk] = 1; keep[++n] = tk }
      }
      if (n < 2) { print ""; exit }                     # too little signal -> never gated
      for (i = 2; i <= n; i++) {                         # insertion sort (portable; no asort())
        key = keep[i]; j = i - 1
        while (j >= 1 && keep[j] > key) { keep[j+1] = keep[j]; j-- }
        keep[j+1] = key
      }
      s = keep[1]
      for (i = 2; i <= n; i++) s = s " " keep[i]
      print s
    }'
}

# draft <queue_file> <archive_file> <drafted_marker_file> -> print GATE-DRAFT blocks for newly-recurring
# classes. A class is "draft-now" iff: combined (archive+queue) count >= 2 AND it appears in >= 1 queue
# capture (draft only when the class shows up THIS run) AND it is not already a line in the marker.
#
# Design: bash computes each row's signature ONCE (reusing the signature() above — the algorithm lives
# in one place) and streams "sig \t source \t timestamp \t text" records to a single awk pass. awk does
# all counting/selection and prints the COMPLETE block (body included) — no fragile round-trip.
draft() {
  local queue_file="$1" archive_file="$2" marker_file="$3"
  local title="learning-loop: recurring error-class may warrant a gate [gate-proposal]"

  # Records are separated by the ASCII Record Separator (0x1e); fields by TAB. The capture text is
  # single-line free text, so a TAB never appears inside it — TAB is a safe field delimiter here.
  local records="" ts kind text sigv
  emit() { # $1=file $2=source-tag ; append one record per non-empty capture
    [ -f "$1" ] && [ -s "$1" ] || return 0
    while IFS=$'\t' read -r ts kind text || [ -n "${ts-}" ]; do
      : "${kind-}"                       # column 2 is unused here; read to reach column 3 (text)
      [ -n "${text-}" ] || continue
      sigv="$(signature "$text")"
      [ -n "$sigv" ] || continue         # empty signature is NEVER gated (deliberate over-trigger guard)
      records="${records}${sigv}	$2	${ts}	${text}"$'\036'
    done < "$1"
  }
  emit "$archive_file" a          # archive occurrences first (older), then this run's queue
  emit "$queue_file" q
  [ -n "$records" ] || return 0

  local marker_content=""
  [ -f "$marker_file" ] && marker_content="$(cat "$marker_file" 2>/dev/null || true)"

  printf '%s' "$records" | awk \
    -v RS=$'\036' -v FS='\t' -v marker="$marker_content" -v title="$title" '
    BEGIN {
      mn = split(marker, ml, /\n/)                    # seed the already-drafted set from the marker
      for (i = 1; i <= mn; i++) if (ml[i] != "") drafted[ml[i]] = 1
    }
    {
      if (NF < 4) next
      sig = $1; src = $2; ts = $3
      text = $4; for (k = 5; k <= NF; k++) text = text "\t" $k   # rejoin any defensive stray tabs
      if (!(sig in total)) { order[++nsig] = sig; total[sig] = 0; inq[sig] = 0; occ[sig] = "" }
      total[sig]++
      if (src == "q") inq[sig] = 1
      occ[sig] = occ[sig] "- " ts " — " text "\n"       # occurrences in archive-then-queue read order
    }
    END {
      for (i = 2; i <= nsig; i++) {                     # deterministic emission order (insertion sort)
        key = order[i]; j = i - 1
        while (j >= 1 && order[j] > key) { order[j+1] = order[j]; j-- }
        order[j+1] = key
      }
      for (i = 1; i <= nsig; i++) {
        s = order[i]
        if (total[s] < 2) continue                      # not recurring
        if (inq[s] != 1) continue                       # class did not appear THIS run
        if (s in drafted) continue                      # already drafted once (idempotency)
        emit_block(s, total[s], occ[s])
      }
    }
    function emit_block(sig, count, bullets) {
      print "<<<GATE-DRAFT>>>"
      print "SIG: " sig
      print "TITLE: " title
      print "BODY:"
      print "**AUTOMATED DRAFT — owner approval required. Nothing has been auto-landed.**"
      print ""
      print "The nightly learning worker saw an error-class recur (>= 2 captures). Per the enforcement ladder"
      print "(decisions/0026, spec sec 4), a recurring class is a candidate to escalate from prose to a GATE."
      print "This issue is a PROPOSAL only: no code, hook, CI gate, rule, or memory fact was changed."
      print ""
      print "## Class signature (deterministic)"
      print "`" sig "`"
      print ""
      print "## Occurrences (" count ")"
      printf "%s", bullets                              # bullets already carry their own trailing \n
      print ""
      print "## Decide (owner)"
      print "- DETERMINISTIC (a mechanical check exists)? -> build a gate: CI-first (freshness.yml), add a Code"
      print "  hook for point-of-action speed. Pattern to copy: scripts/check-secret-bytes.sh (Phase 3 T1)."
      print "- JUDGMENT (verify-before-asserting, generalize-the-fix)? -> do NOT build a fake gate; keep it on the"
      print "  lean always-load shelf + optional Code nudge (spec sec 4.2)."
      print "- Staff-engineer test: is a gate justified by THIS evidence? Do not gate what should stay advisory."
      print ""
      print "## Why a draft, not an auto-edit"
      print "Gates are code/CI/hooks — outside the auto-land path (learning-gate.sh auto-lands only .md under"
      print "rules/ or memory/). Building enforcement is an owner decision, by design."
      print ""
      print "<<<GATE-DRAFT-END>>>"
    }'
  return 0
}

case "${1-}" in
  signature)
    [ "$#" -eq 2 ] || { echo "usage: learning-recurrence.sh signature \"<text>\"" >&2; exit 2; }
    signature "$2"
    ;;
  draft)
    [ "$#" -eq 4 ] || { echo "usage: learning-recurrence.sh draft <queue_file> <archive_file> <drafted_marker_file>" >&2; exit 2; }
    draft "$2" "$3" "$4"
    ;;
  *)
    echo "learning-recurrence.sh: unknown subcommand: ${1-}" >&2
    echo "usage: learning-recurrence.sh {signature \"<text>\" | draft <queue> <archive> <marker>}" >&2
    exit 2
    ;;
esac
