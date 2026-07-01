---
name: content-hash-cache-pattern
description: Use when caching the result of expensive, repeated file processing (PDF parse, OCR, text/image extraction) and the same files recur across runs. Triggers on "cache the parsed output", "skip reprocessing unchanged files", "add a --cache flag". Not for data that must always be fresh.
---

# content-hash-cache-pattern

Cache expensive file-processing results keyed by the SHA-256 of the file's
*contents*, not its path. A rename or move is a cache hit; an edit
auto-invalidates. No index file: each entry is `{hash}.json`, an O(1) lookup.
This composes the read-once / cache-expensive-reads principles in
[speed-by-default](../../rules/global/speed-by-default.md) for the file-processing
case; for hot in-memory reads see the `latency-critical-systems` skill.

## When it fits

- Processing cost is high and the same files recur (PDF parse, OCR, extraction).
- You want a `--cache / --no-cache` switch.
- You want caching without touching the pure processing function.

Do not use for always-fresh feeds, results that depend on params beyond file
content (different extraction configs), or entries too large to sit on disk.

## Pattern

Three pieces: a content hash, a keyed JSON store, and a service wrapper that
keeps the processing function pure.

```python
import hashlib, json
from pathlib import Path

CHUNK = 65536  # hash large files in chunks; don't load whole file into memory

def file_hash(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(CHUNK), b""):
            h.update(chunk)
    return h.hexdigest()

def extract_with_cache(path: Path, *, use_cache=True, cache_dir=Path(".cache")) -> dict:
    if not use_cache:
        return extract(path)              # pure function, knows nothing about caching
    key = file_hash(path)
    entry = cache_dir / f"{key}.json"
    if entry.is_file():
        try:
            return json.loads(entry.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, ValueError):
            pass                          # corruption -> treat as miss, reprocess
    result = extract(path)
    cache_dir.mkdir(parents=True, exist_ok=True)
    entry.write_text(json.dumps(result, ensure_ascii=False), encoding="utf-8")
    return result
```

## Design decisions

| Decision | Why |
|---|---|
| SHA-256 of content as key | path-independent; auto-invalidates on edit |
| `{hash}.json` per entry | O(1) lookup, no index file to keep in sync |
| Service wrapper, not inline | processing stays pure (single responsibility) |
| Corruption returns a miss | graceful degradation; never crash on a bad cache file |
| Lazy `mkdir` on first write | no setup step |

## Anti-patterns

```python
cache = {"/path/to/file.pdf": result}        # path key: breaks on move/rename

def extract(path, use_cache=False, cache_dir=None):  # cache logic inside the
    if use_cache: ...                                 # pure function: two jobs, untestable
```
