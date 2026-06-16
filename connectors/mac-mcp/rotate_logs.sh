#!/bin/bash
# Truncate mac-mcp logs in place if they exceed 10 MB.
# Truncating preserves the inode so the running Python process keeps writing.
set -u
MAX_BYTES=10485760
for f in /Users/schnapp/mac-mcp/mcp.log /Users/schnapp/mac-mcp/mcp.err.log; do
  if [ -f "$f" ]; then
    size=$(stat -f%z "$f" 2>/dev/null || echo 0)
    if [ "$size" -gt "$MAX_BYTES" ]; then
      : > "$f"
      echo "$(date '+%Y-%m-%d %H:%M:%S') truncated $f (was $size bytes)" >> "$f"
    fi
  fi
done
