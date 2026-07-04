#!/usr/bin/env bash
# shell/install.sh - install or repair the portable shell on this machine (ADR 0033).
#
# The shell is WIRING ONLY: every pointer it writes resolves into the live clones at runtime,
# so nothing here ever goes stale (no snapshot, no copy of content). Idempotent: re-run any
# time; a second run reports "unchanged" everywhere. Layers:
#   1. Rules      ~/.claude/CLAUDE.md rendered from templates/user-global-CLAUDE.md (@imports).
#   2. Settings   ~/.claude/settings.json merge: autoMemoryDirectory -> vault memory lane;
#                 user-scope hooks (UserPromptSubmit standing-rules + capture-nudge,
#                 SessionStart global-session-gate on startup|resume|clear, SessionEnd
#                 global-vault-push, PreToolUse global-force-push-guard + global-secret-scan
#                 (command-text leg), PostToolUse global-secret-scan (file leg)).
#                 Everything else in the file (permissions, plugins, statusLine) is preserved.
#   3. Components ~/.claude/{skills,agents,commands}/<name> symlinks into the live clone.
#
# Usage: bash shell/install.sh [--dry-run]
# Env: VAULT_DIR (vault clone; default ~/code/schnapp-vault, then sibling of this repo),
#      CLAUDE_CONFIG_DIR (target config dir; default ~/.claude).
# Exits non-zero on real failure (owner-run, unlike hooks it may fail loudly).
set -euo pipefail

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
OS_DIR="$(dirname "$SELF")"
VAULT="${VAULT_DIR:-$HOME/code/schnapp-vault}"
[ -d "$VAULT" ] || VAULT="$(dirname "$OS_DIR")/schnapp-vault"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

log() { echo "[shell-install] $*"; }
doit() { if [ "$DRY" = "1" ]; then log "DRY: $*"; else "$@"; fi; }

# Preflight
[ -d "$OS_DIR/rules/global" ] || { log "FATAL: $OS_DIR does not look like the schnapp-os clone"; exit 1; }
command -v python3 >/dev/null 2>&1 || { log "FATAL: python3 required for the settings merge"; exit 1; }
command -v git >/dev/null 2>&1 || { log "FATAL: git required"; exit 1; }
if [ ! -d "$VAULT/.git" ]; then
  log "WARN: no vault clone found (looked at VAULT_DIR, ~/code/schnapp-vault, sibling). Link B will be degraded until it is cloned."
else
  # The vault's schema/flatten/secret gate is its pre-commit git hook; a fresh clone has no
  # core.hooksPath, so an uninstalled machine would commit to the memory lane UNGATED.
  if [ "$(git -C "$VAULT" config core.hooksPath 2>/dev/null)" != "scripts/git-hooks" ]; then
    doit git -C "$VAULT" config core.hooksPath scripts/git-hooks
    log "vault: core.hooksPath -> scripts/git-hooks (pre-commit gate active)"
  fi
fi
doit mkdir -p "$CLAUDE_DIR"

# 1. Rules: render ~/.claude/CLAUDE.md from the template body (everything after the leading
#    HTML comment), with the repo path resolved for this machine.
TEMPLATE="$OS_DIR/templates/user-global-CLAUDE.md"
rendered="$(awk 'done{print} /^-->$/{done=1}' "$TEMPLATE" | sed -e '/./,$!d' -e "s|~/code/schnapp-os|$OS_DIR|g")"
target="$CLAUDE_DIR/CLAUDE.md"
if [ -f "$target" ] && [ "$(cat "$target")" = "$rendered" ]; then
  log "CLAUDE.md: unchanged"
else
  if [ -f "$target" ] && [ -s "$target" ]; then
    doit cp "$target" "$target.pre-shell.bak"
    log "CLAUDE.md: existing copy differed; backed up to CLAUDE.md.pre-shell.bak"
  fi
  if [ "$DRY" = "1" ]; then log "DRY: write $target from template"; else printf '%s\n' "$rendered" > "$target"; fi
  log "CLAUDE.md: rendered from templates/user-global-CLAUDE.md"
fi

# 2. Settings merge (python3: JSON-safe, preserves unknown keys). Dedupe per hook script
#    basename so re-runs and pre-existing wiring never double-register a hook.
mem_dir="$VAULT/memory"
case "$mem_dir" in "$HOME"/*) mem_dir="~${mem_dir#"$HOME"}" ;; esac
merge_out="$(python3 - "$CLAUDE_DIR/settings.json" "$OS_DIR" "$mem_dir" "$DRY" <<'PYEOF'
import json, os, sys
path, os_dir, mem_dir, dry = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1"
settings = {}
if os.path.exists(path):
    with open(path) as f:
        settings = json.load(f)
before = json.dumps(settings, sort_keys=True)

changes = []
if settings.get("autoMemoryDirectory") != mem_dir:
    settings["autoMemoryDirectory"] = mem_dir
    changes.append(f"autoMemoryDirectory -> {mem_dir}")

hooks = settings.setdefault("hooks", {})
wanted = [
    ("UserPromptSubmit", None, "standing-rules.sh", None),
    ("UserPromptSubmit", None, "capture-nudge.sh", None),
    # resume + clear re-fire the gate: a resumed session can sit on days-stale clones, and a
    # /clear wipes the orient line; both need freshness restored (matchers per hooks docs).
    ("SessionStart", "startup|resume|clear", "global-session-gate.sh", 30),
    ("SessionEnd", "*", "global-vault-push.sh", 60),
    ("PreToolUse", "Bash", "global-force-push-guard.sh", 10),
    # The same wrapper twice: PreToolUse Bash scans the command TEXT (heredoc/echo writes the
    # file hooks never see); PostToolUse scans the Write/Edit'd file.
    ("PreToolUse", "Bash", "global-secret-scan.sh", 15),
    ("PostToolUse", "Write|Edit|MultiEdit", "global-secret-scan.sh", 15),
]
for event, matcher, script, timeout in wanted:
    groups = hooks.setdefault(event, [])
    if script in json.dumps(groups):
        continue  # already wired (any form) - never double-register
    entry = {"type": "command", "command": f'bash "{os_dir}/hooks/{script}"'}
    if timeout:
        entry["timeout"] = timeout
    group = next((g for g in groups if g.get("matcher") == matcher or (matcher is None and "matcher" not in g)), None)
    if group is None:
        group = {"hooks": []}
        if matcher is not None:
            group["matcher"] = matcher
        groups.append(group)
    group.setdefault("hooks", []).append(entry)
    changes.append(f"hook {event}/{matcher or '-'} += {script}")

# Matcher migration: when the wanted matcher for an already-wired script changes (e.g.
# SessionStart startup -> startup|resume|clear), update the group in place - but only a
# group whose hooks are all schnapp-os's own (never rewrite foreign wiring).
for event, matcher, script, timeout in wanted:
    if matcher is None:
        continue
    for g in hooks.get(event, []):
        if script not in json.dumps(g) or g.get("matcher") == matcher:
            continue
        if all("schnapp-os/hooks/" in h.get("command", "") for h in g.get("hooks", [])):
            changes.append(f"hook {event}: matcher '{g.get('matcher')}' -> '{matcher}' ({script})")
            g["matcher"] = matcher

if json.dumps(settings, sort_keys=True) == before:
    print("settings.json: unchanged")
else:
    if not dry:
        # Atomic write: two sessions can auto-heal drift concurrently (the gate runs the
        # installer); a torn settings.json would kill every hook on the machine.
        tmp = path + ".tmp"
        with open(tmp, "w") as f:
            json.dump(settings, f, indent=2)
            f.write("\n")
        os.replace(tmp, path)
    for c in changes:
        print(("DRY: " if dry else "") + c)
PYEOF
)"
printf '%s\n' "$merge_out" | sed 's/^/[shell-install] /'

# 3. Component symlinks: live-by-construction delivery of skills/agents/commands.
linked=0; kept=0; skipped=0; pruned=0
for kind in skills agents commands; do
  src="$OS_DIR/.claude/$kind"
  [ -d "$src" ] || continue
  destdir="$CLAUDE_DIR/$kind"
  doit mkdir -p "$destdir"
  for item in "$src"/*; do
    name="$(basename "$item")"
    [ "$name" = ".DS_Store" ] && continue
    dest="$destdir/$name"
    if [ -L "$dest" ]; then
      if [ "$(readlink "$dest")" = "$item" ]; then kept=$((kept+1)); continue; fi
      doit rm "$dest"; doit ln -s "$item" "$dest"; linked=$((linked+1))
    elif [ -e "$dest" ]; then
      log "WARN: $kind/$name exists and is not our symlink - left alone (resolve manually)"
      skipped=$((skipped+1))
    else
      doit ln -s "$item" "$dest"; linked=$((linked+1))
    fi
  done
  # Prune dead symlinks that point into this clone (component was removed upstream).
  if [ -d "$destdir" ]; then
    for existing in "$destdir"/*; do
      [ -L "$existing" ] || continue
      tgt="$(readlink "$existing")"
      case "$tgt" in
        "$OS_DIR"/*) [ -e "$existing" ] || { doit rm "$existing"; pruned=$((pruned+1)); } ;;
      esac
    done
  fi
done
log "components: $linked linked, $kept already live, $pruned pruned, $skipped skipped"

log "done. Wiring targets: OS=$OS_DIR VAULT=$VAULT CONFIG=$CLAUDE_DIR"
log "next: restart the Claude Code session (hooks load at session start); on a fresh machine accept the workspace-trust dialog first (decisions/0005 prerequisite)."
exit 0
