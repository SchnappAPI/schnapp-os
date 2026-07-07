#!/bin/bash
# SessionEnd (user-scope): append a one-line digest of the just-ended Claude Code session to
# schnapp-vault/sessions/index.jsonl, so a unified "what have I done across all my devices" view
# exists. The vault is git, so global-vault-push.sh (same SessionEnd batch) commits+pushes the
# line and every wired machine's SessionStart pull picks it up; the schnapp-console Session-log
# tab merges the index to show sessions from machines whose local transcripts it cannot reach.
# Wired by shell/install.sh alongside idea-sweep.sh + global-vault-push.sh.
#
# Deterministic, NO model call (fast, free, no auth dependency at session end). SAFETY: stores
# only structured, non-sensitive fields (machine, project, timing, message count, git branch/sha
# and the LAST COMMIT SUBJECT, which is owner-authored and already secret-gated). It never writes
# arbitrary transcript text, so a session where a secret was pasted cannot leak it into the
# pushed vault. Best-effort: always exits 0. Idempotent: skips a session_id already recorded.

set -uo pipefail
VAULT="${SCHNAPP_VAULT_DIR:-$HOME/code/schnapp-vault}"
MIN_LINES=25

[ -d "$VAULT/.git" ] || exit 0
payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0

SCHNAPP_VAULT_DIR="$VAULT" SCHNAPP_MIN_LINES="$MIN_LINES" python3 - "$payload" <<'PY' 2>/dev/null || true
import json, os, subprocess, sys, socket
from datetime import datetime, timezone

vault = os.environ["SCHNAPP_VAULT_DIR"]
min_lines = int(os.environ.get("SCHNAPP_MIN_LINES", "25"))
try:
    p = json.loads(sys.argv[1])
except Exception:
    sys.exit(0)

transcript = p.get("transcript_path", "")
cwd = p.get("cwd", "") or ""
if not transcript or not os.path.isfile(transcript):
    sys.exit(0)

# read the transcript once: substance gate + timing + message count + session id
first_ts = last_ts = ""
messages = 0
session_id = p.get("session_id", "") or ""
lines = 0
with open(transcript, encoding="utf-8", errors="replace") as fh:
    for line in fh:
        lines += 1
        try:
            o = json.loads(line)
        except Exception:
            continue
        ts = o.get("timestamp", "")
        if ts:
            first_ts = first_ts or ts
            last_ts = ts
        if o.get("type") in ("user", "assistant") and not o.get("isSidechain"):
            messages += 1
        if not session_id:
            session_id = o.get("sessionId", "") or ""
if lines < min_lines:
    sys.exit(0)
if not session_id:
    session_id = os.path.splitext(os.path.basename(transcript))[0]

# machine name (stable, human-facing)
try:
    machine = subprocess.run(["scutil", "--get", "ComputerName"], capture_output=True,
                             text=True, timeout=3).stdout.strip() or socket.gethostname()
except Exception:
    machine = socket.gethostname()

# git context of the working dir: branch, short sha, and the LAST COMMIT SUBJECT (owner-authored,
# already secret-gated) as a safe human-readable "what was worked on" proxy. No transcript text.
branch = head = subject = ""
if cwd and os.path.isdir(os.path.join(cwd, ".git")):
    def git(*a):
        try:
            return subprocess.run(["git", "-C", cwd, *a], capture_output=True,
                                  text=True, timeout=5).stdout.strip()
        except Exception:
            return ""
    branch = git("rev-parse", "--abbrev-ref", "HEAD")
    head = git("rev-parse", "--short", "HEAD")
    subject = git("log", "-1", "--format=%s")[:160]

index_dir = os.path.join(vault, "sessions")
index = os.path.join(index_dir, "index.jsonl")

# idempotent: skip if this session_id is already recorded
if os.path.isfile(index):
    with open(index, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            if session_id and (('"session_id": "%s"' % session_id) in line or
                               ('"session_id":"%s"' % session_id) in line):
                sys.exit(0)

rec = {
    "session_id": session_id,
    "machine": machine,
    "project": os.path.basename(cwd) if cwd else "",
    "started": first_ts,
    "ended": last_ts,
    "messages": messages,
    "branch": branch,
    "head": head,
    "subject": subject,
    "recorded": datetime.now(timezone.utc).isoformat(),
}
os.makedirs(index_dir, exist_ok=True)
with open(index, "a", encoding="utf-8") as fh:
    fh.write(json.dumps(rec, ensure_ascii=False) + "\n")
PY

exit 0
