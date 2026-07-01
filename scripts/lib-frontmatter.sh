#!/usr/bin/env bash
# lib-frontmatter.sh — shared YAML-frontmatter helpers for memory-lane detectors
# (check-memory-frontmatter.sh, check-stale-facts.sh). Sourced, not executed.
# Pure bash + awk (BSD + GNU). No side effects, no top-level work.

# fm_block <file> — frontmatter block: lines between the leading `---` and the next `---`.
fm_block() {
  awk 'NR==1 && $0!="---"{exit} NR==1{next} /^---[[:space:]]*$/{exit} {print}' "$1"
}

# fm_value <file> <key> — trimmed value of `key:` (top-level OR indented; first match).
# Strips surrounding whitespace + surrounding quotes only (internal spaces preserved).
fm_value() {
  fm_block "$1" | grep -E "^[[:space:]]*$2:" | head -1 \
    | sed -E "s/^[[:space:]]*$2:[[:space:]]*//; s/[[:space:]]*$//; s/^[\"']//; s/[\"']$//"
}

# fm_has <file> <key> — exit 0 if `key:` present in frontmatter, else 1.
fm_has() {
  fm_block "$1" | grep -qE "^[[:space:]]*$2:"
}
