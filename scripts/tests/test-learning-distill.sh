#!/usr/bin/env bash
# test-learning-distill.sh - routing contract of the distillation step (learning_distill.py).
#
# ADR 0028: durable facts route to the VAULT memory lane (a worker-owned clone, env
# LEARNING_VAULT_DIR), never to a repo-local memory/ (removed in streamline Phase 1). These
# tests pin the prompt + SDK-option wiring WITHOUT importing the Agent SDK (module import is
# SDK-free by design; the SDK loads only inside the live call), so they run on any python3.
set -uo pipefail
export LC_ALL=C

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$(cd "$here/.." && pwd)"
pass=0; fail=0
check() { # $1=got $2=want $3=label
  if [ "$1" = "$2" ]; then pass=$((pass+1)); echo "ok   $3"
  else echo "FAIL $3 (got [$1] want [$2])" >&2; fail=$((fail+1)); fi
}

PY="$(command -v python3)"
[ -n "$PY" ] || { echo "SKIP: python3 not found"; exit 0; }

root="$(mktemp -d)"; trap 'rm -rf "$root"' EXIT

# --- 1. prompt + option wiring, vault dir from env --------------------------------------------------
out="$(cd "$root" && LEARNING_VAULT_DIR="$root/vaultx" "$PY" - "$SCRIPTS" <<'PYEOF'
import sys
sys.path.insert(0, sys.argv[1])
import learning_distill as d

checks = []
prompt = d.SYSTEM_PROMPT
vault = str(d.VAULT_DIR)
checks.append(("prompt-routes-facts-to-vault", f"{vault}/memory" in prompt))
checks.append(("prompt-drops-repo-local-memory", "supersede in memory/" not in prompt))
checks.append(("prompt-keeps-rules-routing", "rules/global/" in prompt))
checks.append(("prompt-instructs-index-line", "MEMORY.md" in prompt))
checks.append(("prompt-instructs-vault-schema", "agents.md" in prompt))
kw = d.sdk_option_kwargs()
checks.append(("options-add-vault-dir", kw.get("add_dirs") == [vault]))
checks.append(("options-keep-bash-disallowed", "Bash" in kw.get("disallowed_tools", [])))
checks.append(("options-cwd-is-repo-root", kw.get("cwd") == str(d.REPO_ROOT)))
for name, ok in checks:
    print(("ok " if ok else "BAD ") + name)
PYEOF
)"
rc=$?
check "$rc" 0 "module import + wiring probe exits 0"
check "$(printf '%s\n' "$out" | grep -c '^BAD ')" 0 "all wiring probes pass"
printf '%s\n' "$out" | grep '^BAD ' >&2 || true

# --- 2. default vault dir (env unset) is the worker-owned clone under ~/.cache ----------------------
defdir="$(env -u LEARNING_VAULT_DIR "$PY" -c "
import sys; sys.path.insert(0, '$SCRIPTS')
import learning_distill as d; print(d.VAULT_DIR)")"
case "$defdir" in
  */.cache/schnapp-os/learning-vault) pass=$((pass+1)); echo "ok   default vault dir is the .cache clone" ;;
  *) echo "FAIL default vault dir (got [$defdir])" >&2; fail=$((fail+1)) ;;
esac

# --- 3. --dry-run with an empty queue stays a clean no-op (no SDK, no vault needed) -----------------
: > "$root/empty.tsv"
LEARNING_QUEUE="$root/empty.tsv" LEARNING_VAULT_DIR="$root/absent" \
  "$PY" "$SCRIPTS/learning_distill.py" --dry-run >/dev/null 2>&1
check "$?" 0 "--dry-run empty queue exits 0"

# --- 4. fail-fast: captures + MISSING vault memory dir -> exit 4 BEFORE any SDK/network use ---------
# PATH is stripped to system dirs so even an installed claude CLI cannot be reached; the run must
# fail on the vault-dir check (exit 4), not by attempting a live SDK session.
printf '2026-07-01T00:00:00Z\tcorrection\tthe sql server port is 1433 not 1533\n' > "$root/q.tsv"
out="$(LEARNING_QUEUE="$root/q.tsv" LEARNING_VAULT_DIR="$root/absent" PATH="/usr/bin:/bin" \
  "$PY" "$SCRIPTS/learning_distill.py" 2>&1)"
check "$?" 4 "missing vault memory dir fails fast with exit 4"
case "$out" in
  *"vault"*) pass=$((pass+1)); echo "ok   fail-fast message names the vault" ;;
  *) echo "FAIL fail-fast message names the vault (got [$out])" >&2; fail=$((fail+1)) ;;
esac

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
