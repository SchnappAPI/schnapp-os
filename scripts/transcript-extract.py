#!/usr/bin/env python3
"""transcript-extract.py - filtered mirror of local Claude Code transcripts.

Reads ~/.claude/projects/**/*.jsonl (session transcripts) and writes one markdown
file per session into a mirror repo: ONLY user/assistant message TEXT (what was
said), never tool_use/tool_result payloads, attachments, or sidechain (subagent)
chatter. That exclusion is the primary security boundary: the 2026-06-17 leak
class lived in tool outputs echoing secret values. Residual text is additionally
masked against the BLOCK patterns from scan-secrets.sh (single-source: fetched at
runtime via --block-re, never duplicated here).

Incremental: a state file (dest/.sync-state.json) maps source relpath -> (mtime,
size); unchanged sources are skipped. Deleted sources are kept in the mirror
(archive semantics: the cloud copy outlives local cleanup - the point of the sync).

Usage:
  transcript-extract.py --src DIR --dest DIR [--block-re-file FILE]
Prints one dest-relative path per changed/written file to stdout (the sync worker
scans exactly those). Exit 0 = ok (possibly nothing changed), 2 = error.
"""
import argparse
import json
import os
import re
import sys


def load_block_patterns(path):
    pats = []
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if line:
                pats.append(re.compile(line))
    return pats


def mask(text, patterns):
    for pat in patterns:
        text = pat.sub("[SECRET-REDACTED]", text)
    return text


def message_text(obj):
    """Text a human said/read: str content, or text blocks only. No tool blobs."""
    msg = obj.get("message") or {}
    content = msg.get("content")
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict) and block.get("type") == "text":
                txt = (block.get("text") or "").strip()
                if txt:
                    parts.append(txt)
        return "\n\n".join(parts)
    return ""


def extract_session(src_path, patterns):
    turns = []
    first_ts = last_ts = ""
    with open(src_path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            try:
                obj = json.loads(line)
            except ValueError:
                continue
            if obj.get("type") not in ("user", "assistant"):
                continue
            if obj.get("isSidechain"):
                continue
            text = message_text(obj)
            if not text:
                continue
            ts = obj.get("timestamp") or ""
            if ts:
                first_ts = first_ts or ts
                last_ts = ts
            turns.append((obj["type"], ts, mask(text, patterns)))
    return turns, first_ts, last_ts


def render(rel, turns, first_ts, last_ts):
    out = [
        "---",
        "generated: transcript-extract.py (do not edit)",
        f"source: {rel}",
        f"first: {first_ts}",
        f"last: {last_ts}",
        f"turns: {len(turns)}",
        "---",
        "",
    ]
    for role, ts, text in turns:
        out.append(f"## {role} @ {ts}")
        out.append("")
        out.append(text)
        out.append("")
    return "\n".join(out) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True)
    ap.add_argument("--dest", required=True)
    ap.add_argument("--block-re-file", required=True,
                    help="file holding scan-secrets.sh --block-re output, one regex per line")
    args = ap.parse_args()

    patterns = load_block_patterns(args.block_re_file)
    if not patterns:
        print("no block patterns loaded - refusing to run unmasked", file=sys.stderr)
        return 2

    state_path = os.path.join(args.dest, ".sync-state.json")
    state = {}
    if os.path.exists(state_path):
        with open(state_path, encoding="utf-8") as fh:
            state = json.load(fh)

    changed = []
    for root, _dirs, files in os.walk(args.src):
        for name in files:
            if not name.endswith(".jsonl"):
                continue
            src_path = os.path.join(root, name)
            rel = os.path.relpath(src_path, args.src)
            st = os.stat(src_path)
            sig = [st.st_mtime, st.st_size]
            if state.get(rel) == sig:
                continue
            turns, first_ts, last_ts = extract_session(src_path, patterns)
            state[rel] = sig
            if not turns:
                continue
            dest_rel = os.path.join("projects", os.path.splitext(rel)[0] + ".md")
            dest_path = os.path.join(args.dest, dest_rel)
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            body = render(rel, turns, first_ts, last_ts)
            if os.path.exists(dest_path):
                with open(dest_path, encoding="utf-8") as fh:
                    if fh.read() == body:
                        continue
            with open(dest_path, "w", encoding="utf-8") as fh:
                fh.write(body)
            changed.append(dest_rel)

    os.makedirs(args.dest, exist_ok=True)
    with open(state_path, "w", encoding="utf-8") as fh:
        json.dump(state, fh)

    for rel in changed:
        print(rel)
    return 0


if __name__ == "__main__":
    sys.exit(main())
