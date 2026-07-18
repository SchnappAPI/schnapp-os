#!/usr/bin/env bash
# test-transcript-sync.sh - self-test for the transcript cloud-sync extractor.
# Proves the security envelope: message text kept, tool_result payloads excluded,
# sidechains excluded, BLOCK-class secret values masked, scan-secrets passes on
# the output, and the incremental state skips unchanged sources.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

src="$tmp/src/-Users-test-proj"
dest="$tmp/dest"
mkdir -p "$src" "$dest"

# Fake secret assembled at runtime (prefix split) so the token pattern never
# sits assembled in this tracked file - the write-hook scanner would BLOCK it.
fake_pat="github_""pat_11ABCDEFGH0123456789_abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUV"

cat > "$src/session1.jsonl" <<EOF
{"type":"user","timestamp":"2026-07-18T01:00:00Z","message":{"role":"user","content":"hello keep this user text"}}
{"type":"assistant","timestamp":"2026-07-18T01:00:05Z","message":{"role":"assistant","content":[{"type":"text","text":"assistant text with leaked token $fake_pat inside"},{"type":"tool_use","id":"t1","name":"Bash","input":{"command":"echo SHOULD_NOT_APPEAR_TOOLUSE"}}]}}
{"type":"user","timestamp":"2026-07-18T01:00:10Z","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t1","content":"SHOULD_NOT_APPEAR_TOOLRESULT"}]}}
{"type":"assistant","isSidechain":true,"timestamp":"2026-07-18T01:00:15Z","message":{"role":"assistant","content":[{"type":"text","text":"SHOULD_NOT_APPEAR_SIDECHAIN"}]}}
{"type":"queue-operation","op":"noise"}
EOF

blockre="$tmp/block.re"
bash "$repo/scripts/scan-secrets.sh" --block-re > "$blockre"

out1="$(python3 "$repo/scripts/transcript-extract.py" --src "$tmp/src" --dest "$dest" --block-re-file "$blockre")"
md="$dest/projects/-Users-test-proj/session1.md"

fail() { echo "FAIL: $*"; exit 1; }
[ -f "$md" ] || fail "extracted markdown missing"
grep -q "keep this user text" "$md" || fail "user text lost"
grep -q "assistant text with leaked token" "$md" || fail "assistant text lost"
grep -q "SECRET-REDACTED" "$md" || fail "secret not masked"
grep -q "github_pat_" "$md" && fail "secret value survived masking"
grep -q "SHOULD_NOT_APPEAR" "$md" && fail "tool/sidechain payload leaked into output"
printf '%s\n' "$out1" | grep -q "session1.md" || fail "changed-file list missing new file"

bash "$repo/scripts/scan-secrets.sh" "$md" > /dev/null || fail "scan-secrets BLOCKs the masked output"

# Incremental: second run with no source change emits nothing.
out2="$(python3 "$repo/scripts/transcript-extract.py" --src "$tmp/src" --dest "$dest" --block-re-file "$blockre")"
[ -z "$out2" ] || fail "unchanged source re-emitted: $out2"

echo "PASS test-transcript-sync"
