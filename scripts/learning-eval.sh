#!/usr/bin/env bash
# learning-eval.sh - read-only effectiveness report for the learning loop (agentic-OS Phase 4 eval).
#
# The loop's promise is that a correction becomes a rule the next session loads. The honest signal
# that a promotion "stuck" is the absence of RECURRENCE: if the same correction-topic comes back on a
# LATER date, the earlier promotion did not take, and the rule should be revisited. This reads the
# processed-capture archive and reports total / unique / recurred topics, naming each recurrence.
#
# It is the input a future eval agent (or a human) uses before auto-approving low-risk staged PRs:
# the deliberately-deferred half of Phase 4, now scaffolded against real data. Informational only:
# ALWAYS exits 0, never edits, never opens a PR. Portable (awk aggregation; no bash-4 assoc arrays,
# so it runs under the Mac's /bin/bash 3.2 as well as Linux CI).
#
# Usage: learning-eval.sh [archive]   (default: scheduled-tasks/.learning-queue.archive.tsv)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCHIVE="${1:-"$HERE/../scheduled-tasks/.learning-queue.archive.tsv"}"

if [ ! -s "$ARCHIVE" ]; then
  echo "learning-eval: no learning history yet (no processed captures)."
  exit 0
fi

# One pass: normalize each capture's text to a topic key (lowercase, strip a leading 'test:' marker,
# collapse whitespace, first 40 chars), count occurrences, and track first/last date + a sample.
awk -F'\t' '
  NF>=3 {
    text=$3
    key=tolower(text); sub(/^[ \t]*test:[ \t]*/,"",key); gsub(/[ \t]+/," ",key); key=substr(key,1,40)
    total++; cnt[key]++
    if (!(key in firstd)) firstd[key]=substr($1,1,10)
    lastd[key]=substr($1,1,10); sample[key]=text
  }
  END {
    u=0; r=0
    for (k in cnt) { u++; if (cnt[k]>1) r++ }
    printf "learning-eval: captures processed: %d | unique topics: %d | recurred topics: %d\n", total+0, u, r
    for (k in cnt) if (cnt[k]>1)
      printf "  RECURRED: \"%s\" (%dx, first %s, last %s) - promotion may not have stuck; revisit the rule.\n", \
             sample[k], cnt[k], firstd[k], lastd[k]
  }
' "$ARCHIVE"
exit 0
