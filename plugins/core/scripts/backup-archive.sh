#!/usr/bin/env bash
# backup-archive.sh — mirror schnapp-os knowledge + Claude Code session
# transcripts into two destinations (PLAN.md Part 6; decisions/0004 is unrelated):
#   1. OneDrive `claude-archive/` — cloud-durable backup (repo md + raw .jsonl sessions).
#   2. The canonical Obsidian vault `claude-archive/` subfolder — the browsable, searchable
#      copy Obsidian + the obsidian MCP read; md only (raw transcripts would bloat the
#      git-synced vault). The vault auto-syncs to GitHub via the obsidian-git plugin.
#
# Markdown is mirrored (current truth; git holds history). Transcripts accumulate in
# OneDrive (each session is a distinct artifact). The repo is never modified — read-only source.
#
# Config (env overrides, machine-portable):
#   CLAUDE_KIT_REPO     default ~/code/schnapp-os
#   CLAUDE_ARCHIVE_DIR  default ~/Library/CloudStorage/OneDrive-Schnapp/claude-archive
#   OBSIDIAN_VAULT_DIR  default ~/Library/CloudStorage/OneDrive-Schnapp/Obsidian
#                       (canonical vault, OneDrive-synced; ~/Documents/Obsidian is a back-compat
#                        symlink to it; vault mirror skipped if the dir is absent)
#
# Run manually now; Part 7 wires it to the Stop/SessionEnd hook (PLAN 5.4).
set -euo pipefail

REPO="${CLAUDE_KIT_REPO:-$HOME/code/schnapp-os}"
ARCHIVE="${CLAUDE_ARCHIVE_DIR:-$HOME/Library/CloudStorage/OneDrive-Schnapp/claude-archive}"

# Claude Code stores transcripts under a slug derived from the project path.
PROJECT_SLUG="$(echo "$REPO" | sed 's#/#-#g')"
TRANSCRIPTS="$HOME/.claude/projects/$PROJECT_SLUG"

[ -d "$REPO" ]    || { echo "FATAL: repo not found: $REPO" >&2; exit 1; }
[ -d "$ARCHIVE" ] || { echo "FATAL: archive dir not found: $ARCHIVE (create it / sign into OneDrive)" >&2; exit 1; }

mkdir -p "$ARCHIVE/repo" "$ARCHIVE/sessions"

# 1. Mirror git-tracked markdown knowledge (readable + searchable in Obsidian).
#    --delete keeps the mirror current (supersede-not-append); git keeps history.
for sub in memory handoffs decisions; do
  [ -d "$REPO/$sub" ] && rsync -a --delete \
    --include="*/" --include="*.md" --exclude="*" \
    "$REPO/$sub/" "$ARCHIVE/repo/$sub/"
done
cp -f "$REPO/PLAN.md" "$REPO/PROGRESS.md" "$ARCHIVE/repo/" 2>/dev/null || true

# 2. Archive Claude Code session transcripts (raw .jsonl; additive, never deleted).
if [ -d "$TRANSCRIPTS" ]; then
  rsync -a --include="*.jsonl" --include="*/" --exclude="*" \
    "$TRANSCRIPTS/" "$ARCHIVE/sessions/" 2>/dev/null || true
fi

# 3. Refresh the vault home note (generated; do not hand-edit).
SESSION_COUNT="$(find "$ARCHIVE/sessions" -name '*.jsonl' 2>/dev/null | wc -l | tr -d ' ')"
cat > "$ARCHIVE/README.md" <<EOF
# claude-archive (generated — do not edit)

OneDrive-synced, Obsidian-mirrored backup of the schnapp-os knowledge base.
Refreshed by \`plugins/core/scripts/backup-archive.sh\`. The live source of truth
is the git repo; this is a browsable, cross-device copy.

- \`repo/memory/\` — global memory lane (per-fact files)
- \`repo/handoffs/\` — session handoffs
- \`repo/decisions/\` — decision log
- \`repo/PLAN.md\`, \`repo/PROGRESS.md\` — live trackers
- \`sessions/\` — raw Claude Code transcripts (.jsonl), $SESSION_COUNT archived

Do not edit here — changes belong in the repo, then re-run the backup. claude.ai
chats are not on the Mac filesystem; back those up via export / live-session-cache.
EOF

echo "backup-archive: mirrored repo md + $SESSION_COUNT transcript(s) -> $ARCHIVE"

# 4. Mirror the browsable knowledge md into the canonical Obsidian vault (optional).
#    Reuses the just-built OneDrive copy. Sessions (.jsonl) stay OneDrive-only so the
#    git-synced vault does not bloat. obsidian-git pushes this to GitHub on next sync.
VAULT="${OBSIDIAN_VAULT_DIR:-$HOME/Library/CloudStorage/OneDrive-Schnapp/Obsidian}"
if [ -d "$VAULT" ]; then
  mkdir -p "$VAULT/claude-archive"
  rsync -a --delete "$ARCHIVE/repo/" "$VAULT/claude-archive/repo/"
  cp -f "$ARCHIVE/README.md" "$VAULT/claude-archive/README.md"
  echo "backup-archive: mirrored knowledge md -> $VAULT/claude-archive"
else
  echo "backup-archive: OBSIDIAN_VAULT_DIR not found ($VAULT) — vault mirror skipped"
fi
