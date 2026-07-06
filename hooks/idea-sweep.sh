#!/bin/bash
# SessionEnd (user-scope): sweep the just-ended transcript for tabled ideas / deferred
# offers and drop them into the schnapp-console Idea inbox, so shelved work resurfaces
# instead of dying with the session. Model-judged (a regex cannot tell a real deferred
# idea from a throwaway), backgrounded so it never slows session end, best-effort (always
# exits 0). Wired by shell/install.sh alongside global-vault-push.sh.
#
# Guards: recursion (SCHNAPP_IDEA_SWEEP), console reachable, transcript has substance,
# clean env for the child claude, hard timeout, dedup against the open inbox.

set -uo pipefail
CONSOLE="${SCHNAPP_CONSOLE_URL:-http://127.0.0.1:4747}"
MIN_LINES=25          # skip trivial sessions
MAX_CHARS=40000       # cap transcript text fed to the model
SWEEP_MODEL="claude-haiku-4-5"

# 0) recursion guard: the child claude we spawn will itself end a session
[ -n "${SCHNAPP_IDEA_SWEEP:-}" ] && exit 0

# 1) read the SessionEnd payload from stdin
payload="$(cat 2>/dev/null || true)"
transcript="$(printf '%s' "$payload" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("transcript_path",""))
except Exception: print("")' 2>/dev/null)"
cwd="$(printf '%s' "$payload" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("cwd",""))
except Exception: print("")' 2>/dev/null)"
[ -z "$transcript" ] || [ ! -f "$transcript" ] && exit 0

# 2) substance + console-reachable gates (both cheap; bail before spending a model call)
[ "$(wc -l < "$transcript" 2>/dev/null || echo 0)" -lt "$MIN_LINES" ] && exit 0
curl -fsS --max-time 2 "$CONSOLE/api/ideas" -o /dev/null 2>/dev/null || exit 0

# 3) hand off to the background so session end returns immediately
project="$(basename "${cwd:-session}")"
(
  # extracted user+assistant text only (drop tool noise), tail-capped
  content="$(python3 - "$transcript" "$MAX_CHARS" <<'PY' 2>/dev/null
import json, sys
path, cap = sys.argv[1], int(sys.argv[2])
out = []
for line in open(path, encoding="utf-8", errors="replace"):
    try: o = json.loads(line)
    except Exception: continue
    if o.get("type") not in ("user", "assistant") or o.get("isSidechain"): continue
    c = o.get("message", {}).get("content")
    role = o["type"]
    if isinstance(c, str): txt = c
    elif isinstance(c, list):
        txt = "\n".join(p.get("text", "") for p in c if isinstance(p, dict) and p.get("type") == "text")
    else: txt = ""
    txt = txt.strip()
    if txt and not txt.startswith("<"): out.append(f"{role.upper()}: {txt}")
text = "\n\n".join(out)
print(text[-cap:])
PY
)"
  [ -z "$content" ] && exit 0

  # already-open ideas, so the model does not re-capture them
  existing="$(curl -fsS --max-time 3 "$CONSOLE/api/ideas" 2>/dev/null | python3 -c 'import json,sys
try:
    xs=[i["text"] for i in json.load(sys.stdin).get("items",[]) if i.get("status")=="new"]
    print("\n".join("- "+x for x in xs))
except Exception: print("")' 2>/dev/null)"

  read -r -d '' PROMPT <<PROMPT_EOF
You are scanning one Claude Code session transcript for IDEAS THAT WERE RAISED BUT NOT DONE:
deferred offers the assistant made ("I can add X later", "if you want I could..."), work the
user explicitly shelved for another session, or concrete follow-ups nobody acted on.

EXCLUDE: anything actually completed in the session, routine next-steps already handled,
generic pleasantries, and vague musings. Only durable, actionable, worth-tracking ideas.

Already captured (do NOT repeat these):
${existing:-（none）}

Output ONLY a JSON array (max 5) of objects like {"text":"one concise sentence"}. If nothing
qualifies, output []. No prose, no code fence.

--- TRANSCRIPT ---
${content}
PROMPT_EOF

  # perl-alarm is the portable timeout (macOS has no coreutils `timeout`)
  result="$(printf '%s' "$PROMPT" | env -i HOME="$HOME" USER="${USER:-$(id -un)}" \
      PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin" SCHNAPP_IDEA_SWEEP=1 \
      perl -e 'alarm shift; exec @ARGV' 90 claude -p --model "$SWEEP_MODEL" \
      --output-format text --permission-mode bypassPermissions --no-session-persistence 2>/dev/null)"

  SWEEP_RESULT="$result" python3 - "$CONSOLE" "auto · $project session" <<'PY' 2>/dev/null || true
import json, os, sys, re, urllib.request
raw, console, source = os.environ.get("SWEEP_RESULT", ""), sys.argv[1], sys.argv[2]
m = re.search(r"\[.*\]", raw, re.S)
if not m: sys.exit(0)
try: ideas = json.loads(m.group(0))
except Exception: sys.exit(0)
for it in ideas[:5]:
    text = (it.get("text") if isinstance(it, dict) else str(it)) or ""
    text = text.strip()
    if not text: continue
    body = json.dumps({"text": text, "source": source}).encode()
    req = urllib.request.Request(console + "/api/ideas", data=body,
                                 headers={"Content-Type": "application/json"})
    try: urllib.request.urlopen(req, timeout=5).read()
    except Exception: pass
PY
) >/dev/null 2>&1 &

exit 0
