// Unit tests for the memory_write frontmatter + index invariants (the 2026-07-13 corruption class).
// Run: node --test test/  (needs dist/ built: npx tsc)
import { test } from "node:test";
import assert from "node:assert/strict";
import {
  splitFrontmatter, setFmLine, buildNewFactFm, renderFact,
  descriptionFromIndexLine, upsertIndexLine,
} from "../dist/tools.js";

const FACT = `---
name: demo-fact
description: "The original description: kept verbatim"
type: reference
area: global
source: "decisions/0001"
created: 2026-06-03
updated: 2026-07-01
superseded: false
---

Original body.
`;

test("supersede-in-place preserves every untouched key", () => {
  const parsed = splitFrontmatter(FACT);
  assert.ok(parsed);
  let fm = setFmLine(parsed.fmLines, "updated", "2026-07-13");
  fm = setFmLine(fm, "source", JSON.stringify("new-session"));
  const out = renderFact(fm, "New body.");
  assert.match(out, /^---\nname: demo-fact\n/);
  assert.ok(out.includes('description: "The original description: kept verbatim"'));
  assert.ok(out.includes("type: reference"));
  assert.ok(out.includes("created: 2026-06-03"));
  assert.ok(out.includes("updated: 2026-07-13"));
  assert.ok(out.includes('source: "new-session"'));
  assert.ok(out.includes("superseded: false"));
  assert.ok(out.endsWith("New body.\n"));
  assert.ok(!out.includes("metadata:"), "must never write the legacy nested block");
  assert.ok(!out.includes("scope:"), "must never append non-schema keys");
});

test("legacy nested block is not parsed (falls through to a full flat rebuild)", () => {
  const legacy = "---\nname: x\nmetadata:\n  node_type: memory\n---\n\nBody.\n";
  assert.equal(splitFrontmatter(legacy), null);
});

test("new fact gets the full flat 8-key schema in order", () => {
  const fm = buildNewFactFm({
    slug: "new-fact", description: "hook text", type: "project", area: "global",
    source: "s (supersedes old-fact)", today: "2026-07-13", updated: "2026-07-13",
  });
  assert.deepEqual(fm.map((l) => l.split(":")[0]),
    ["name", "description", "type", "area", "source", "created", "updated", "superseded"]);
});

test("descriptionFromIndexLine handles em-dash and hyphen hooks", () => {
  assert.equal(descriptionFromIndexLine("- [T](s.md) — the hook"), "the hook");
  assert.equal(descriptionFromIndexLine("- [T](s.md) - the hook"), "the hook");
});

test("upsertIndexLine replaces in place and dedupes duplicates", () => {
  const idx = "# MEMORY\n\n## Index\n- [A](a.md) - a\n- [B](b.md) - stale\n- [B](b.md) - dupe\n- [C](c.md) - c";
  const out = upsertIndexLine(idx, "b", "- [B](b.md) - fresh");
  const lines = out.split("\n").filter((l) => l.includes("](b.md)"));
  assert.deepEqual(lines, ["- [B](b.md) - fresh"]);
  assert.ok(out.indexOf("](a.md)") < out.indexOf("](b.md)"));
  assert.ok(out.indexOf("](b.md)") < out.indexOf("](c.md)"));
});

test("upsertIndexLine inserts new slugs under the Index header", () => {
  const out = upsertIndexLine("# M\n\n## Index\n- [A](a.md) - a", "z", "- [Z](z.md) - z");
  assert.ok(out.includes("## Index\n- [Z](z.md) - z\n- [A](a.md) - a"));
});
