#!/usr/bin/env bash
# TDD harness for scripts/vault-autocommit.sh (the Phase-1 follow-up: Obsidian/obsidian-mcp
# write the vault working tree but never commit, so git truth lags manual edits).
# Scratch bare origin + clone per case; no network, no real vault.
set -uo pipefail
export LC_ALL=C

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUT="$HERE/../vault-autocommit.sh"
pass=0; fail=0

# Explicit ident + -b main everywhere: CI runners have no git ident and may default to master
# (the 2026-07-01 default-branch/ident lessons).
GITC=(git -c user.name=test -c user.email=test@test -c commit.gpgsign=false)

mk_repos() { # $1 = workdir
  local d="$1"
  mkdir -p "$d"
  git init -q --bare -b main "$d/origin.git"
  git clone -q "$d/origin.git" "$d/vault" 2>/dev/null
  ( cd "$d/vault" || exit 1
    if ! git checkout -q main 2>/dev/null; then git checkout -qb main; fi
    echo seed > seed.md
    "${GITC[@]}" add -A >/dev/null
    "${GITC[@]}" commit -qm seed
    git push -qu origin main )
}

run_sut() { # $1 vault dir, $2 quiet seconds (default 0)
  VAULT_DIR="$1" AUTOCOMMIT_QUIET_SECONDS="${2:-0}" bash "$SUT" 2>&1
}

check_rc() { # $1 desc, $2 expected_rc, $3 actual_rc
  if [ "$2" = "$3" ]; then echo "ok   $1"; pass=$((pass+1)); else echo "FAIL $1 (want rc=$2 got rc=$3)"; fail=$((fail+1)); fi
}

check_eq() { # $1 desc, $2 expected, $3 actual
  if [ "$2" = "$3" ]; then echo "ok   $1"; pass=$((pass+1)); else echo "FAIL $1 (want '$2' got '$3')"; fail=$((fail+1)); fi
}

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT

# 1. clean tree: no-op, rc 0, no new commit
mk_repos "$T/c1"
before=$(git -C "$T/c1/vault" rev-parse HEAD)
run_sut "$T/c1/vault" >/dev/null; rc=$?
check_rc "clean tree no-op" 0 "$rc"
check_eq "clean tree: HEAD unchanged" "$before" "$(git -C "$T/c1/vault" rev-parse HEAD)"

# 2. dirty tree (quiet window elapsed): commits AND lands on origin
mk_repos "$T/c2"
echo note > "$T/c2/vault/new-note.md"
run_sut "$T/c2/vault" >/dev/null; rc=$?
check_rc "dirty tree commits" 0 "$rc"
check_eq "dirty tree: pushed to origin" "2" "$(git --git-dir="$T/c2/origin.git" log --oneline main | wc -l | tr -d ' ')"

# 3. fresh edit inside quiet window: skipped (rc 0, no commit)
mk_repos "$T/c3"
echo wip > "$T/c3/vault/wip.md"
run_sut "$T/c3/vault" 3600 >/dev/null; rc=$?
check_rc "quiet-window skip rc" 0 "$rc"
check_eq "quiet window: nothing pushed" "1" "$(git --git-dir="$T/c3/origin.git" log --oneline main | wc -l | tr -d ' ')"

# 4. non-main branch: refuses, rc 1, no commit
mk_repos "$T/c4"
( cd "$T/c4/vault" && git checkout -qb scratch )
echo x > "$T/c4/vault/x.md"
run_sut "$T/c4/vault" >/dev/null; rc=$?
check_rc "non-main branch refuses" 1 "$rc"

# 5. pre-commit hook rejects: rc 2, tree stays dirty, nothing pushed
mk_repos "$T/c5"
mkdir -p "$T/c5/vault/hooks-fixture"
printf '#!/bin/sh\nexit 1\n' > "$T/c5/vault/hooks-fixture/pre-commit"
chmod +x "$T/c5/vault/hooks-fixture/pre-commit"
git -C "$T/c5/vault" config core.hooksPath hooks-fixture
echo bad > "$T/c5/vault/bad.md"
run_sut "$T/c5/vault" >/dev/null; rc=$?
check_rc "pre-commit block surfaces" 2 "$rc"
if [ -n "$(git -C "$T/c5/vault" status --porcelain)" ]; then
  echo "ok   pre-commit block: tree still dirty"; pass=$((pass+1))
else
  echo "FAIL pre-commit block: tree got cleaned"; fail=$((fail+1))
fi

# 6. remote ahead: rebases then pushes, both commits land
mk_repos "$T/c6"
git clone -q "$T/c6/origin.git" "$T/c6/other"
( cd "$T/c6/other" || exit 1
  echo remote > remote.md
  "${GITC[@]}" add -A >/dev/null
  "${GITC[@]}" commit -qm remote
  git push -q )
echo local > "$T/c6/vault/local.md"
run_sut "$T/c6/vault" >/dev/null; rc=$?
check_rc "remote-ahead rebase+push" 0 "$rc"
check_eq "remote-ahead: origin has both commits" "3" "$(git --git-dir="$T/c6/origin.git" log --oneline main | wc -l | tr -d ' ')"

# 7. missing vault dir: rc 1
run_sut "$T/nope" >/dev/null; rc=$?
check_rc "missing dir refuses" 1 "$rc"

# 8. held index.lock (another git writer mid-flight): benign skip, rc 0, no false
#    "pre-commit gate" diagnosis (the 056 red-team race finding)
mk_repos "$T/c8"
echo note > "$T/c8/vault/note.md"
touch "$T/c8/vault/.git/index.lock"
out="$(run_sut "$T/c8/vault")"; rc=$?
check_rc "index.lock skip is benign" 0 "$rc"
case "$out" in *"concurrent git writer"*) echo "ok   index.lock: reported as concurrent, not pre-commit"; pass=$((pass+1));;
  *) echo "FAIL index.lock: wrong diagnosis: $out"; fail=$((fail+1));; esac
rm -f "$T/c8/vault/.git/index.lock"

# 9. two truly concurrent runs (two SessionEnd hooks): the mutex serializes them so the winner
#    sweeps all and the loser is a deterministic no-op - neither can commit concurrently (which
#    used to collide on HEAD.lock and misclassify as exit 2), tree ends clean and pushed.
mk_repos "$T/c9"
echo one > "$T/c9/vault/f1.md"
echo two > "$T/c9/vault/f2.md"
run_sut "$T/c9/vault" >/dev/null 2>&1 & p1=$!
run_sut "$T/c9/vault" >/dev/null 2>&1 & p2=$!
wait "$p1"; rc1=$?; wait "$p2"; rc2=$?
if [ "$rc1" != 2 ] && [ "$rc2" != 2 ]; then echo "ok   concurrent: no false failure (rc $rc1/$rc2)"; pass=$((pass+1));
else echo "FAIL concurrent: a run exited 2 (rc $rc1/$rc2)"; fail=$((fail+1)); fi
check_eq "concurrent: tree clean after race" "" "$(git -C "$T/c9/vault" status --porcelain)"
check_eq "concurrent: origin got the sweep" "2" "$(git --git-dir="$T/c9/origin.git" log --oneline main | wc -l | tr -d ' ')"

# 10. mutex held by another run: the loser path, exercised deterministically (no wall-clock
#     overlap needed) by pre-creating the lock dir. Benign skip (rc 0), tree untouched - the
#     lock holder is the one that sweeps it.
mk_repos "$T/c10"
echo note > "$T/c10/vault/held.md"
mkdir "$T/c10/vault/.git/vault-autocommit.lock"
out="$(run_sut "$T/c10/vault")"; rc=$?
check_rc "mutex held: loser skips benign" 0 "$rc"
case "$out" in *"holds the lock"*) echo "ok   mutex held: reported as lock-held, not pre-commit"; pass=$((pass+1));;
  *) echo "FAIL mutex held: wrong diagnosis: $out"; fail=$((fail+1));; esac
check_eq "mutex held: tree left for the holder to sweep" "?? held.md" "$(git -C "$T/c10/vault" status --porcelain)"
rmdir "$T/c10/vault/.git/vault-autocommit.lock"

# 11. stale mutex (holder crashed): a lock aged past the stale window is reclaimed, not honored
#     forever - otherwise a crash would wedge the every-5-min launchd job.
mk_repos "$T/c11"
echo note > "$T/c11/vault/x.md"
mkdir "$T/c11/vault/.git/vault-autocommit.lock"
# Backdate the lock well past the 1s stale window we pass in; touch -t needs [[CC]YY]MMDDhhmm.
touch -t 200001010000 "$T/c11/vault/.git/vault-autocommit.lock"
out="$(VAULT_DIR="$T/c11/vault" AUTOCOMMIT_QUIET_SECONDS=0 AUTOCOMMIT_LOCK_STALE_SECONDS=1 bash "$SUT" 2>&1)"; rc=$?
check_rc "stale mutex: reclaimed and commits" 0 "$rc"
check_eq "stale mutex: pushed the sweep" "2" "$(git --git-dir="$T/c11/origin.git" log --oneline main | wc -l | tr -d ' ')"

# 12. foreign writer holds git's HEAD.lock mid-commit (a non-vault-autocommit git, so our mutex
#     does not cover it): the commit fails with "cannot lock ref 'HEAD'" - the exact message that
#     used to leak to exit 2. Must classify benign (rc 0, NOT 2), tree left dirty.
mk_repos "$T/c12"
echo note > "$T/c12/vault/y.md"
: > "$T/c12/vault/.git/HEAD.lock"
out="$(run_sut "$T/c12/vault")"; rc=$?
check_rc "foreign HEAD.lock: benign not gate-fail" 0 "$rc"
if [ "$rc" = 2 ]; then echo "FAIL foreign HEAD.lock: ref-lock misread as pre-commit gate"; fail=$((fail+1)); fi
# add -A ran before the commit failed, so y.md is staged (not committed): "A  y.md".
check_eq "foreign HEAD.lock: tree left dirty" "A  y.md" "$(git -C "$T/c12/vault" status --porcelain)"
rm -f "$T/c12/vault/.git/HEAD.lock"

echo "pass=$pass fail=$fail"
[ "$fail" = "0" ]
