#!/usr/bin/env bash
# transcript-sync.sh - mirror local Claude Code transcripts to the private cloud repo.
#
# Owner standing rule (vault memory sessions-cloud-accessible): no session may be
# local-only. This worker extracts message TEXT from ~/.claude/projects (tool blobs
# excluded, secrets masked - see transcript-extract.py) into the PRIVATE repo
# SchnappAPI/claude-transcripts and pushes. Runs every 15 min via
# scheduled-tasks/com.schnapp.transcript-sync.plist; safe to run by hand.
#
# Security gate: every changed output file is re-scanned with scan-secrets.sh.
# Any BLOCK finding aborts the whole run BEFORE commit (fail-closed, "holds too
# much" over "pushes a value") and raises an ops-alert incident.
#
# Env overrides (defaults in parens): TRANSCRIPT_SRC (~/.claude/projects),
# TRANSCRIPT_DEST (~/code/claude-transcripts), TRANSCRIPT_REMOTE
# (git@github.com:SchnappAPI/claude-transcripts.git).
set -uo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="${TRANSCRIPT_SRC:-$HOME/.claude/projects}"
dest="${TRANSCRIPT_DEST:-$HOME/code/claude-transcripts}"
remote="${TRANSCRIPT_REMOTE:-git@github.com:SchnappAPI/claude-transcripts.git}"
alert="$repo_dir/scripts/ops-alert.sh"

log() { printf '%s [transcript-sync] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }

[ -d "$src" ] || { log "src missing: $src - nothing to do"; exit 0; }

if [ ! -d "$dest/.git" ]; then
  log "cloning $remote -> $dest"
  git clone --quiet "$remote" "$dest" || { bash "$alert" red transcript-sync "transcript-sync: clone failed" "git clone $remote failed"; exit 2; }
fi

block_re_file="$(mktemp)"
trap 'rm -f "$block_re_file"' EXIT
bash "$repo_dir/scripts/scan-secrets.sh" --block-re > "$block_re_file"
[ -s "$block_re_file" ] || { log "scan-secrets --block-re produced nothing; refusing to run"; exit 2; }

changed_file="$(mktemp)"
trap 'rm -f "$block_re_file" "$changed_file"' EXIT
if ! python3 "$repo_dir/scripts/transcript-extract.py" \
    --src "$src" --dest "$dest" --block-re-file "$block_re_file" > "$changed_file"; then
  bash "$alert" red transcript-sync "transcript-sync: extract failed" "transcript-extract.py exited non-zero"
  exit 2
fi

unpushed="$(git -C "$dest" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 1)"
if [ ! -s "$changed_file" ] && [ -z "$(git -C "$dest" status --porcelain)" ] && [ "$unpushed" = "0" ]; then
  log "no changes"
  exit 0
fi

# Secrets gate on the WHOLE uncommitted set (not just this run's extract list:
# a killed prior run can leave unscanned files pending). Extract already masked;
# this verifies the mask held - defense in depth, single pattern source. One
# batched xargs pass: per-file spawns took >10 min on the initial 4k-file sync.
scan_list="$(mktemp)"
findings_file="$(mktemp)"
trap 'rm -f "$block_re_file" "$changed_file" "$scan_list" "$findings_file"' EXIT
git -C "$dest" status --porcelain | sed -e 's/^...//' -e "s|^|$dest/|" > "$scan_list"
if [ -s "$scan_list" ]; then
  if ! tr '\n' '\0' < "$scan_list" | xargs -0 bash "$repo_dir/scripts/scan-secrets.sh" > "$findings_file" 2>&1; then
    log "BLOCK finding in extracted output - aborting before commit"
    cat "$findings_file"
    git -C "$dest" checkout -- . 2>/dev/null
    git -C "$dest" clean -fdq 2>/dev/null
    bash "$alert" red transcript-sync "transcript-sync: secret leaked past mask" \
      "scan-secrets found a BLOCK value in extracted transcript output; run aborted before commit (log: ~/Library/Logs/schnapp-os/transcript-sync.log)."
    exit 2
  fi
fi

git -C "$dest" add -A
n="$(git -C "$dest" diff --cached --name-only | grep -c '\.md$' || true)"
if ! git -C "$dest" diff --cached --quiet; then
  git -C "$dest" commit --quiet -m "sync: $n session(s) $(date '+%Y-%m-%dT%H:%M:%S')"
fi
branch="$(git -C "$dest" branch --show-current)"
# Fresh mirror repo starts empty: pull only once the remote branch exists.
if git -C "$dest" ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
  if ! git -C "$dest" pull --rebase --quiet; then
    bash "$alert" red transcript-sync "transcript-sync: pull --rebase failed" "manual reconcile needed in $dest"
    exit 2
  fi
fi
if ! git -C "$dest" push --quiet -u origin "$branch"; then
  bash "$alert" red transcript-sync "transcript-sync: push failed" "git push from $dest failed"
  exit 2
fi
bash "$alert" green transcript-sync "transcript-sync recovered" "sync pushed $n session(s)"
log "pushed $n session(s)"
