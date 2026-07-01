#!/usr/bin/env bash
# test-learning-worker-vault-live.sh - LIVE-path regression test for the VAULT fact leg (ADR 0028).
#
# The global memory lane lives in the vault repo (schnapp-vault), not in schnapp-os (its memory/
# was removed in streamline Phase 1). The worker therefore lands durable-fact proposals on the
# VAULT's main via a worker-owned clone, and the schnapp-os auto-land scope is rules/*.md ONLY.
# Invariants locked here:
#   1. A clean fact proposal lands on VAULT main (never schnapp-os main), via gate + schema check.
#   2. An out-of-scope vault write is HELD: nothing lands, clone reset, review issue filed.
#   3. A clone-schema-check failure is HELD the same way (the clone's own check-frontmatter.sh runs).
#   4. A repo-local memory/ write in schnapp-os is HELD (narrowed rules-only scope) - never lands.
#   5. Vault clone prep failure aborts BEFORE distillation: exit 1, queue preserved.
#   6. No vault write -> vault leg is a clean no-op.
#
# Harness mirrors test-learning-worker-recurrence-live.sh: throwaway bare origins + clones holding
# the REAL scripts, PATH shims for gh/claude, and a shim distill python that writes fixtures per
# DISTILL_WRITE_MODE. NO network; every remote is a local bare repo.
set -uo pipefail
export LC_ALL=C

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_SCRIPTS="$(cd "$here/.." && pwd)"
pass=0; fail=0

check() { # $1=got $2=want $3=label
  if [ "$1" = "$2" ]; then pass=$((pass+1)); echo "ok   $3"
  else echo "FAIL $3 (got [$1] want [$2])" >&2; fail=$((fail+1)); fi
}
contains() { case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }
check_contains() { # $1=haystack $2=needle $3=label
  if contains "$1" "$2"; then pass=$((pass+1)); echo "ok   $3"
  else echo "FAIL $3 (missing [$2])" >&2; fail=$((fail+1)); fi
}

# --- schnapp-os side: bare origin + working clone with the real scripts ------------------------------
root="$(mktemp -d)"; trap 'rm -rf "$root"' EXIT
origin="$root/origin.git"
work="$root/work"
export GIT_CONFIG_GLOBAL="$root/.gitconfig"
# -b main on every bare init: without it the bare HEAD points at the host default branch
# (master on CI), the seeded refs/heads/main never becomes HEAD, and fresh clones check out an
# unborn branch (broke case 1 on ubuntu CI while passing on the Mac's git).
git init -q --bare -b main "$origin"
git clone -q "$origin" "$work" 2>/dev/null
git -C "$work" config user.email test@example.com
git -C "$work" config user.name  test
git -C "$work" config commit.gpgsign false
mkdir -p "$work/scripts" "$work/rules" "$work/scheduled-tasks"
cp "$SRC_SCRIPTS/learning-worker.sh"     "$work/scripts/"
cp "$SRC_SCRIPTS/learning-recurrence.sh" "$work/scripts/"
cp "$SRC_SCRIPTS/learning-gate.sh"       "$work/scripts/"
cp "$SRC_SCRIPTS/lib-frontmatter.sh"     "$work/scripts/"
printf '#!/usr/bin/env bash\nexit 0\n' > "$work/scripts/ops-alert.sh"
printf '# stub - never executed (LEARNING_DISTILL_PYTHON is a shim)\n' > "$work/scripts/learning_distill.py"
chmod +x "$work/scripts/"*.sh
printf 'placeholder\n' > "$work/rules/placeholder.md"
git -C "$work" add -A
git -C "$work" commit -q -m "seed"
git -C "$work" push -q origin HEAD:main
git -C "$work" branch -q -M main 2>/dev/null || true

# --- vault side: bare origin seeded with an index, one schema'd fact, and a stub schema checker ------
vault_origin="$root/vault-origin.git"
vseed="$root/vault-seed"
git init -q --bare -b main "$vault_origin"
git clone -q "$vault_origin" "$vseed" 2>/dev/null
git -C "$vseed" config user.email test@example.com
git -C "$vseed" config user.name  test
git -C "$vseed" config commit.gpgsign false
mkdir -p "$vseed/memory" "$vseed/scripts"
printf '# MEMORY index\n- [Sql port](sql-port.md) - the sql server port fact one-line hook here.\n' > "$vseed/memory/MEMORY.md"
cat > "$vseed/memory/sql-port.md" <<'EOF'
---
name: sql-port
description: sql server port fact for the vault-live harness
type: reference
area: work
source: harness
created: 2026-06-01
updated: 2026-06-01
superseded: false
---
- the sql server port fact body in its original pre-supersede harness form here.
EOF
# Stub schema checker: stands in for the vault's real scripts/check-frontmatter.sh. Contract under
# test: the worker runs the CLONE'S OWN checker and HOLDs the fact leg when it fails.
cat > "$vseed/scripts/check-frontmatter.sh" <<'EOF'
#!/usr/bin/env bash
if grep -rq 'SCHEMA-BAD' "$1" 2>/dev/null; then
  echo "stub-checker: schema violation (SCHEMA-BAD marker) under $1" >&2
  exit 1
fi
exit 0
EOF
chmod +x "$vseed/scripts/check-frontmatter.sh"
git -C "$vseed" add -A
git -C "$vseed" commit -q -m "vault seed"
git -C "$vseed" push -q origin HEAD:main

# A stand-in for the owner's live vault tree (clean clone): the worker best-effort ff-pulls it.
vlive="$root/vault-live"
git clone -q "$vault_origin" "$vlive" 2>/dev/null
git -C "$vlive" config user.email test@example.com
git -C "$vlive" config user.name  test

vclone="$root/vclone"   # the worker-owned automation clone (worker creates it on first run)

# --- PATH shims: gh + claude + a distill shim that writes fixtures per DISTILL_WRITE_MODE ------------
shim_dir="$root/bin"; mkdir -p "$shim_dir"
cat > "$shim_dir/gh" <<'EOF'
#!/usr/bin/env bash
if [ "${GH_MODE:-fail}" = "succeed" ]; then
  echo "gh $*" >> "${GH_CALL_LOG:?}"
  exit 0
fi
echo "gh-shim: simulated failure" >&2
exit 1
EOF
printf '#!/usr/bin/env bash\nexit 0\n' > "$shim_dir/claude"
# Distill shim: the worker execs LEARNING_DISTILL_PYTHON with the distill script path; this shim
# ignores the script and instead writes the fixture the case asks for (simulating the LLM's edit).
cat > "$shim_dir/vault-python" <<'EOF'
#!/usr/bin/env bash
case "${DISTILL_WRITE_MODE:-none}" in
  fact-ok)
    cat > "${LEARNING_VAULT_DIR:?}/memory/sql-port.md" <<'FACT'
---
name: sql-port
description: sql server port fact for the vault-live harness
type: reference
area: work
source: harness
created: 2026-06-01
updated: 2026-07-02
superseded: false
---
- the sql server port fact body superseded by the distill shim in this harness run.
FACT
    ;;
  fact-outscope)
    mkdir -p "${LEARNING_VAULT_DIR:?}/areas"
    printf -- '- an out of scope vault write that the fact leg gate must hold right here.\n' \
      > "${LEARNING_VAULT_DIR:?}/areas/evil.md"
    ;;
  fact-subdir)
    # SCHEMA-VALID fact in a memory/ SUBDIRECTORY: the case glob crosses '/', so only the
    # worker's flat-lane depth check can hold this (adversarial finding adv-1).
    mkdir -p "${LEARNING_VAULT_DIR:?}/memory/work"
    cat > "${LEARNING_VAULT_DIR:?}/memory/work/subfact.md" <<'FACT'
---
name: subfact
description: schema-valid fact filed in a subdirectory of the flat lane
type: reference
area: work
source: harness
created: 2026-07-01
updated: 2026-07-01
superseded: false
---
- a schema-valid fact that still must be held because the lane is flat by contract.
FACT
    ;;
  fact-badschema)
    cat > "${LEARNING_VAULT_DIR:?}/memory/sql-port.md" <<'FACT'
---
name: sql-port
description: sql server port fact for the vault-live harness
type: reference
area: work
source: harness
created: 2026-06-01
updated: 2026-07-03
superseded: false
---
- SCHEMA-BAD marker body that the clone's own schema checker must reject right here.
FACT
    ;;
  os-memory)
    mkdir -p memory
    printf -- '- a repo local memory write that the narrowed rules-only scope must hold here.\n' \
      > memory/leak.md
    ;;
esac
exit 0
EOF
chmod +x "$shim_dir/gh" "$shim_dir/claude" "$shim_dir/vault-python"

WORKER="$work/scripts/learning-worker.sh"

# One unique capture per case (unique text: no recurrence class ever reaches count 2).
run_worker() { # $1=case-tag $2=DISTILL_WRITE_MODE ; env GH_CALL_LOG must be set by the caller
  q="$root/q-$1.tsv"; a="$root/a-$1.tsv"; m="$root/m-$1.tsv"
  printf '2026-07-01T00:00:00Z\tcorrection\tunique capture for case %s about a value here\n' "$1" > "$q"
  : > "$m"
  (cd "$work" && PATH="$shim_dir:$PATH" GH_MODE=succeed DISTILL_WRITE_MODE="$2" \
    LEARNING_QUEUE="$q" LEARNING_ARCHIVE="$a" LEARNING_GATE_DRAFTED="$m" \
    LEARNING_DISTILL_PYTHON="$shim_dir/vault-python" \
    LEARNING_VAULT_DIR="$vclone" LEARNING_VAULT_REMOTE="$vault_origin" LEARNING_VAULT_LIVE="$vlive" \
    bash "$WORKER" 2>&1)
}

os_main_before="$(git -C "$work" rev-parse origin/main)"

# ============ CASE 1 - clean fact proposal lands on VAULT main only =================================
v_before="$(git -C "$vseed" ls-remote "$vault_origin" refs/heads/main | awk '{print $1}')"
log1="$root/gh-1.log"; : > "$log1"
out1="$(GH_CALL_LOG="$log1" run_worker c1 fact-ok)"
check "$?" 0 "fact-ok: worker exits 0"
check_contains "$out1" "PROMOTED a clean fact" "fact-ok: prints the fact-promotion confirmation"
v_after="$(git -C "$vseed" ls-remote "$vault_origin" refs/heads/main | awk '{print $1}')"
if [ "$v_after" != "$v_before" ]; then pass=$((pass+1)); echo "ok   fact-ok: vault main advanced"
else echo "FAIL fact-ok: vault main did not advance" >&2; fail=$((fail+1)); fi
check "$(git -C "$vclone" show --name-only --format= "$v_after" 2>/dev/null | grep -c 'memory/sql-port.md')" 1 \
  "fact-ok: landed commit touches the fact file"
check "$(git -C "$vclone" status --porcelain 2>/dev/null | grep -c .)" 0 "fact-ok: clone left clean"
check "$(git -C "$vlive" rev-parse HEAD)" "$v_after" "fact-ok: live vault tree ff-pulled to the landed fact"
check "$(git -C "$work" rev-parse origin/main)" "$os_main_before" "fact-ok: schnapp-os main untouched"
check "$([ -s "$root/q-c1.tsv" ] && echo nonempty || echo empty)" "empty" "fact-ok: queue drained"

# ============ CASE 2 - no vault write -> vault leg clean no-op ======================================
v_before="$v_after"
log2="$root/gh-2.log"; : > "$log2"
out2="$(GH_CALL_LOG="$log2" run_worker c2 none)"
check "$?" 0 "no-write: worker exits 0"
check_contains "$out2" "no fact change" "no-write: prints the vault no-op message"
check "$(git -C "$vseed" ls-remote "$vault_origin" refs/heads/main | awk '{print $1}')" "$v_before" \
  "no-write: vault main unchanged"

# ============ CASE 3 - out-of-scope vault write -> HELD (nothing lands, clone reset, issue) =========
log3="$root/gh-3.log"; : > "$log3"
out3="$(GH_CALL_LOG="$log3" run_worker c3 fact-outscope)"
check "$?" 0 "outscope: worker exits 0"
check_contains "$out3" "HELD vault fact" "outscope: prints the vault-hold message"
check "$(git -C "$vseed" ls-remote "$vault_origin" refs/heads/main | awk '{print $1}')" "$v_before" \
  "outscope: vault main unchanged"
check "$(git -C "$vclone" status --porcelain 2>/dev/null | grep -c .)" 0 "outscope: clone reset clean"
check "$(grep -c 'issue create' "$log3")" 1 "outscope: review issue filed"

# ============ CASE 4 - clone schema-checker failure -> HELD the same way ============================
log4="$root/gh-4.log"; : > "$log4"
out4="$(GH_CALL_LOG="$log4" run_worker c4 fact-badschema)"
check "$?" 0 "badschema: worker exits 0"
check_contains "$out4" "HELD vault fact" "badschema: prints the vault-hold message"
check "$(git -C "$vseed" ls-remote "$vault_origin" refs/heads/main | awk '{print $1}')" "$v_before" \
  "badschema: vault main unchanged"
check "$(grep -c 'issue create' "$log4")" 1 "badschema: review issue filed"

# ============ CASE 5 - repo-local memory/ write in schnapp-os -> HELD (rules-only scope) ============
os_head_before="$(git -C "$work" rev-parse HEAD)"
log5="$root/gh-5.log"; : > "$log5"
out5="$(GH_CALL_LOG="$log5" run_worker c5 os-memory)"
check "$?" 0 "os-memory: worker exits 0"
check_contains "$out5" "HELD self-edit" "os-memory: schnapp-os leg holds the memory/ write"
check "$(git -C "$work" rev-parse HEAD)"        "$os_head_before" "os-memory: local HEAD unchanged (reset)"
check "$(git -C "$work" rev-parse origin/main)" "$os_main_before" "os-memory: schnapp-os main untouched"
check "$(grep -c 'issue create' "$log5")" 1 "os-memory: review issue filed"

# ============ CASE 6 - vault clone prep failure aborts BEFORE distill; queue preserved ==============
q6="$root/q-c6.tsv"; a6="$root/a-c6.tsv"; m6="$root/m-c6.tsv"
printf '2026-07-01T00:00:00Z\tcorrection\tunique capture for case c6 about a value here\n' > "$q6"
: > "$m6"
out6="$(cd "$work" && PATH="$shim_dir:$PATH" GH_MODE=succeed \
  LEARNING_QUEUE="$q6" LEARNING_ARCHIVE="$a6" LEARNING_GATE_DRAFTED="$m6" \
  LEARNING_DISTILL_PYTHON="$shim_dir/vault-python" \
  LEARNING_VAULT_DIR="$root/fresh-clone" LEARNING_VAULT_REMOTE="$root/nonexistent.git" \
  LEARNING_VAULT_LIVE="$vlive" \
  bash "$WORKER" 2>&1)"
check "$?" 1 "prep-fail: worker exits 1"
check_contains "$out6" "vault clone prep" "prep-fail: names the vault clone prep"
check "$([ -s "$q6" ] && echo nonempty || echo empty)" "nonempty" "prep-fail: queue preserved (not drained)"
check "$([ -s "$a6" ] && echo nonempty || echo empty)" "empty" "prep-fail: nothing archived"

# ============ CASE 7 - SCHEMA-VALID fact in a memory/ subdir -> HELD (flat-lane contract) ===========
# adv-1 regression: the scope glob crosses '/' and a schema checker may not recurse, so the worker
# itself must refuse any fact that is not a DIRECT child of memory/.
v_before="$(git -C "$vseed" ls-remote "$vault_origin" refs/heads/main | awk '{print $1}')"
log7="$root/gh-7.log"; : > "$log7"
out7="$(GH_CALL_LOG="$log7" run_worker c7 fact-subdir)"
check "$?" 0 "subdir: worker exits 0"
check_contains "$out7" "HELD vault fact" "subdir: prints the vault-hold message"
check "$(git -C "$vseed" ls-remote "$vault_origin" refs/heads/main | awk '{print $1}')" "$v_before" \
  "subdir: vault main unchanged (schema-valid subdir fact did NOT land)"
check "$(git -C "$vclone" status --porcelain 2>/dev/null | grep -c .)" 0 "subdir: clone reset clean"
check "$(grep -c 'issue create' "$log7")" 1 "subdir: review issue filed"

# ============ CASE 8 - LEARNING_VAULT_DIR inside the repo checkout -> abort, queue preserved ========
q8="$root/q-c8.tsv"; a8="$root/a-c8.tsv"; m8="$root/m-c8.tsv"
printf '2026-07-01T00:00:00Z\tcorrection\tunique capture for case c8 about a value here\n' > "$q8"
: > "$m8"
out8="$(cd "$work" && PATH="$shim_dir:$PATH" GH_MODE=succeed \
  LEARNING_QUEUE="$q8" LEARNING_ARCHIVE="$a8" LEARNING_GATE_DRAFTED="$m8" \
  LEARNING_DISTILL_PYTHON="$shim_dir/vault-python" \
  LEARNING_VAULT_DIR="$work/.vault-clone" LEARNING_VAULT_REMOTE="$vault_origin" \
  LEARNING_VAULT_LIVE="$vlive" \
  bash "$WORKER" 2>&1)"
check "$?" 1 "vault-dir-in-repo: worker exits 1"
check_contains "$out8" "must not live inside" "vault-dir-in-repo: names the misconfiguration"
check "$([ -s "$q8" ] && echo nonempty || echo empty)" "nonempty" "vault-dir-in-repo: queue preserved"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
