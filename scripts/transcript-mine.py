#!/usr/bin/env python3
"""transcript-mine.py - deterministic fire-rate miner over Claude Code transcripts (ADR 0037 P1).

Scans transcript JSONL files (default: ~/.claude/projects/**/*.jsonl) and counts, per artifact:
  - skill:<name>  - Skill-tool invocations
  - agent:<type>  - Agent-tool dispatches (subagent_type, default "general-purpose")
  - hook:<label>  - hook firings (best-effort: "<Label> hook success" strings in tool/system text)

Output: TSV to stdout - kind, name, fires, sessions, last_ts - sorted by fires desc.
Zero-fire detection is the CONSUMER's job (diff this table against CATALOG.md).

Usage: transcript-mine.py [--root DIR] [--since DAYS]
  --root DIR    transcript root (default ~/.claude/projects); a single .jsonl path also works
  --since DAYS  only count entries newer than DAYS days (default: all)

Read-only, stdlib-only, no network. Malformed lines are skipped, never fatal.
"""
import argparse
import collections
import datetime
import json
import pathlib
import re
import sys

HOOK_RE = re.compile(r"([A-Za-z]+(?::[a-z_-]+)?) hook (?:success|additional context)")


def iter_files(root: pathlib.Path):
    if root.is_file():
        yield root
    else:
        yield from root.rglob("*.jsonl")


def walk_strings(node):
    """Yield every string in a nested JSON structure (for hook-marker matching)."""
    if isinstance(node, str):
        yield node
    elif isinstance(node, dict):
        for v in node.values():
            yield from walk_strings(v)
    elif isinstance(node, list):
        for v in node:
            yield from walk_strings(v)


def mine(root: pathlib.Path, since: datetime.datetime | None):
    fires = collections.Counter()
    sessions = collections.defaultdict(set)
    last_ts = {}

    def hit(key, session, ts):
        fires[key] += 1
        sessions[key].add(session)
        if ts and (key not in last_ts or ts > last_ts[key]):
            last_ts[key] = ts

    for path in iter_files(root):
        session = path.stem
        try:
            lines = path.read_text(errors="replace").splitlines()
        except OSError:
            continue
        for line in lines:
            # cheap pre-filter: parse only lines that can contain a countable event
            has_tool = '"tool_use"' in line
            has_hook = " hook success" in line or " hook additional context" in line
            if not (has_tool or has_hook):
                continue
            try:
                obj = json.loads(line)
            except (json.JSONDecodeError, ValueError):
                continue
            ts = obj.get("timestamp") or ""
            if since and ts:
                try:
                    when = datetime.datetime.fromisoformat(ts.replace("Z", "+00:00"))
                    if when < since:
                        continue
                except ValueError:
                    pass
            content = obj.get("message", {}).get("content")
            if isinstance(content, list):
                for block in content:
                    if not (isinstance(block, dict) and block.get("type") == "tool_use"):
                        continue
                    name = block.get("name", "")
                    inp = block.get("input") or {}
                    if name == "Skill" and inp.get("skill"):
                        hit(("skill", inp["skill"]), session, ts)
                    elif name in ("Agent", "Task"):
                        hit(("agent", inp.get("subagent_type") or "general-purpose"), session, ts)
            # hook markers live in tool-result / system text anywhere in the entry
            for s in walk_strings(obj):
                for m in HOOK_RE.finditer(s):
                    hit(("hook", m.group(1)), session, ts)

    return fires, sessions, last_ts


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=str(pathlib.Path.home() / ".claude" / "projects"))
    ap.add_argument("--since", type=int, default=0, help="window in days (0 = all)")
    args = ap.parse_args()
    since = None
    if args.since:
        since = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=args.since)
    root = pathlib.Path(args.root).expanduser()
    if not root.exists():
        print(f"transcript-mine: root not found: {root}", file=sys.stderr)
        return 1
    fires, sessions, last_ts = mine(root, since)
    print("kind\tname\tfires\tsessions\tlast_ts")
    for (kind, name), n in fires.most_common():
        print(f"{kind}\t{name}\t{n}\t{len(sessions[(kind, name)])}\t{last_ts.get((kind, name), '')}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
