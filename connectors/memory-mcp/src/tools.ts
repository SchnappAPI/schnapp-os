import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { CHARACTER_LIMIT, MEMORY_DIR, INDEX_FILE, REPO, BRANCH } from "./constants.js";
import {
  readFile,
  tryReadFile,
  listDir,
  putFile,
  deleteFile,
  health,
  type DirEntry,
} from "./github.js";

/** Turn any thrown value into one actionable error result. */
function errorResult(error: unknown, hint?: string) {
  const message = error instanceof Error ? error.message : String(error);
  return {
    isError: true,
    content: [{ type: "text" as const, text: `Error: ${message}${hint ? ` ${hint}` : ""}` }],
  };
}

const SLUG = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const slugField = z
  .string()
  .regex(SLUG, "kebab-case only: lowercase letters, digits, single hyphens (e.g. 'op-wrap-token-unquoted').")
  .describe("The fact's slug = its filename without .md (one fact, one file).");

function factPath(slug: string): string {
  return `${MEMORY_DIR}/${slug}.md`;
}

function todayUTC(): string {
  return new Date().toISOString().slice(0, 10);
}

/** Build a per-fact file body to the vault agents.md frontmatter convention. */
function buildFact(opts: {
  slug: string;
  scope: string;
  source: string;
  updated: string;
  supersedes: string;
  body: string;
}): string {
  const fm = [
    "---",
    `name: ${opts.slug}`,
    "metadata:",
    "  node_type: memory",
    `  scope: ${opts.scope}`,
    `  source: ${JSON.stringify(opts.source)}`,
    `  updated: ${opts.updated}`,
    `  supersedes: ${JSON.stringify(opts.supersedes)}`,
    "---",
    "",
  ].join("\n");
  return `${fm}${opts.body.trimEnd()}\n`;
}

/** Replace the index line for a slug, or insert it under the "## Index" header. */
function upsertIndexLine(indexText: string, slug: string, line: string): string {
  const lines = indexText.split("\n");
  const needle = `](${slug}.md)`;
  const existing = lines.findIndex((l) => l.includes(needle));
  if (existing >= 0) {
    lines[existing] = line;
    return lines.join("\n");
  }
  const header = lines.findIndex((l) => l.trim().toLowerCase() === "## index");
  if (header >= 0) {
    lines.splice(header + 1, 0, line);
    return lines.join("\n");
  }
  // No index header - append at end.
  return `${indexText.trimEnd()}\n${line}\n`;
}

export function registerTools(server: McpServer): void {
  // ---- memory_health ------------------------------------------------------
  server.registerTool(
    "memory_health",
    {
      title: "Check the memory connector",
      description: `Verify the server can reach the memory lane on GitHub. Returns NO secret values.
Good first call to wake the host and confirm the chain before reads/writes.

Returns: { "authenticated": true, "repo": string, "branch": string, "memoryFileCount": number }
COLD START: the host sleeps when idle; the first call after idle can take ~50s or error once - retry before treating as failure.`,
      inputSchema: z.object({}).strict().shape,
      annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: true },
    },
    async () => {
      try {
        const output = await health();
        return { content: [{ type: "text", text: JSON.stringify(output) }], structuredContent: { ...output } };
      } catch (error) {
        return errorResult(error, "Check GITHUB_TOKEN on the host and that the repo/branch exist.");
      }
    },
  );

  // ---- memory_index -------------------------------------------------------
  server.registerTool(
    "memory_index",
    {
      title: "Read the memory index (MEMORY.md)",
      description: `Read MEMORY.md - the thin index of every fact in the lane (one line per fact).
ALWAYS read this first: it is the map. Pick a slug from it, then memory_read that slug for the full fact.

Returns: { "path": string, "text": string } - the raw MEMORY.md.
COLD START: the host sleeps when idle; the first call after idle can take ~50s or error once - retry before treating as failure.`,
      inputSchema: z.object({}).strict().shape,
      annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: true },
    },
    async () => {
      try {
        const f = await readFile(INDEX_FILE);
        const output = { path: f.path, text: f.text };
        return { content: [{ type: "text", text: f.text }], structuredContent: output };
      } catch (error) {
        return errorResult(error);
      }
    },
  );

  // ---- memory_list --------------------------------------------------------
  server.registerTool(
    "memory_list",
    {
      title: "List memory fact files",
      description: `List the per-fact files in the lane (slugs), excluding MEMORY.md and README.md.

Returns: { "count": number, "slugs": string[] }
Use memory_index for the annotated one-liners; use this for a bare slug list.`,
      inputSchema: z.object({}).strict().shape,
      annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: true },
    },
    async () => {
      try {
        const entries = await listDir(MEMORY_DIR);
        const slugs = entries
          .filter((e: DirEntry) => e.type === "file" && e.name.endsWith(".md"))
          .map((e: DirEntry) => e.name.replace(/\.md$/, ""))
          .filter((s) => s !== "MEMORY" && s !== "README")
          .sort();
        const output = { count: slugs.length, slugs };
        return { content: [{ type: "text", text: JSON.stringify(output) }], structuredContent: output };
      } catch (error) {
        return errorResult(error);
      }
    },
  );

  // ---- memory_read --------------------------------------------------------
  const ReadInput = z.object({ slug: slugField }).strict();
  server.registerTool(
    "memory_read",
    {
      title: "Read one memory fact",
      description: `Read a single fact file (memory/<slug>.md) — frontmatter + body.

Args:
  - slug (string): the fact slug from memory_index / memory_list.

Returns: { "slug": string, "path": string, "text": string }
Errors: "Not found" if the slug does not exist (check memory_index for the right slug).`,
      inputSchema: ReadInput.shape,
      annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: true },
    },
    async ({ slug }) => {
      try {
        const f = await readFile(factPath(slug));
        const output = { slug, path: f.path, text: f.text };
        return { content: [{ type: "text", text: f.text }], structuredContent: output };
      } catch (error) {
        return errorResult(error, "Use memory_index to find the right slug.");
      }
    },
  );

  // ---- memory_search ------------------------------------------------------
  const SearchInput = z
    .object({
      query: z.string().min(2).describe("Case-insensitive substring to search for across fact files."),
    })
    .strict();
  server.registerTool(
    "memory_search",
    {
      title: "Search memory facts",
      description: `Case-insensitive substring search across all fact files (fetches and scans the lane).

Args:
  - query (string): the substring to find.

Returns: { "count": number, "matches": [{ "slug": string, "lines": string[] }] }
Best for small/medium lanes; for the whole index just read memory_index.`,
      inputSchema: SearchInput.shape,
      annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: true },
    },
    async ({ query }) => {
      try {
        const entries = await listDir(MEMORY_DIR);
        const files = entries.filter(
          (e: DirEntry) => e.type === "file" && e.name.endsWith(".md") && e.name !== "MEMORY.md",
        );
        const q = query.toLowerCase();
        const matches: { slug: string; lines: string[] }[] = [];
        for (const e of files) {
          const f = await readFile(e.path);
          const hit = f.text.split("\n").filter((l) => l.toLowerCase().includes(q));
          if (hit.length) matches.push({ slug: e.name.replace(/\.md$/, ""), lines: hit.slice(0, 5) });
        }
        const output = { count: matches.length, matches };
        let text = JSON.stringify(output, null, 2);
        if (text.length > CHARACTER_LIMIT) {
          text = text.slice(0, CHARACTER_LIMIT) + "\n\n[truncated - narrow the query]";
        }
        return { content: [{ type: "text", text }], structuredContent: output };
      } catch (error) {
        return errorResult(error);
      }
    },
  );

  // ---- memory_write -------------------------------------------------------
  const WriteInput = z
    .object({
      slug: slugField,
      body: z.string().min(1).describe("The fact, terse. Markdown. Link related facts with [[other-slug]]. No frontmatter - the server writes it."),
      index_line: z
        .string()
        .regex(/^- \[.+\]\(.+\.md\)/, "Must be a MEMORY.md index bullet: '- [Title](slug.md) — hook'.")
        .describe("The one-line MEMORY.md index entry for this fact: '- [Title](<slug>.md) — short hook'."),
      source: z.string().min(1).describe("Where this came from: a session id, 'correction', a decision doc, etc."),
      scope: z.enum(["global", "project"]).default("global").describe("Memory lane scope."),
      supersedes: z.string().regex(SLUG).optional().describe("Slug of an earlier fact this replaces (sets frontmatter; delete the old one with memory_delete)."),
      updated: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().describe("ISO date; defaults to today (UTC)."),
    })
    .strict();
  server.registerTool(
    "memory_write",
    {
      title: "Write or supersede a memory fact",
      description: `Create or replace a fact file and update the MEMORY.md index - in two commits to ${REPO}@${BRANCH}.
Enforces the vault agents.md discipline: ONE fact per file; SUPERSEDE, don't append (writing an existing
slug REPLACES its body - never leave a contradicting copy); frontmatter carries source + updated.

Args:
  - slug (string): kebab slug = filename. Writing an existing slug overwrites it (supersede).
  - body (string): the fact (markdown, no frontmatter - the server adds it).
  - index_line (string): the MEMORY.md bullet, '- [Title](<slug>.md) — hook'.
  - source (string), scope ('global'|'project', default global), supersedes (slug, optional), updated (ISO, optional).

Returns: { "slug": string, "factCommit": string, "indexCommit": string|null, "path": string }
On a cross-slug supersede, also call memory_delete on the old slug (supersede-not-append).
COLD START: first call after idle may take ~50s - retry once.`,
      inputSchema: WriteInput.shape,
      annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: true },
    },
    async ({ slug, body, index_line, source, scope, supersedes, updated }) => {
      try {
        const content = buildFact({
          slug,
          scope,
          source,
          updated: updated ?? todayUTC(),
          supersedes: supersedes ?? "",
          body,
        });
        const existing = await tryReadFile(factPath(slug));
        const factCommit = await putFile(
          factPath(slug),
          content,
          `memory: ${existing ? "update" : "add"} ${slug}`,
          existing?.sha,
        );

        // Update the index line in a second commit.
        let indexCommitSha: string | null = null;
        const index = await readFile(INDEX_FILE);
        const newIndex = upsertIndexLine(index.text, slug, index_line);
        if (newIndex !== index.text) {
          const indexCommit = await putFile(INDEX_FILE, newIndex, `memory: index ${slug}`, index.sha);
          indexCommitSha = indexCommit.commitSha;
        }
        const output = {
          slug,
          factCommit: factCommit.commitSha,
          indexCommit: indexCommitSha,
          path: factCommit.path,
        };
        return { content: [{ type: "text", text: JSON.stringify(output) }], structuredContent: output };
      } catch (error) {
        return errorResult(error, "If a 'stale blob sha' conflict, another write landed first - retry.");
      }
    },
  );

  // ---- memory_delete ------------------------------------------------------
  const DeleteInput = z.object({ slug: slugField }).strict();
  server.registerTool(
    "memory_delete",
    {
      title: "Delete a memory fact",
      description: `Delete a fact file and remove its MEMORY.md index line - in two commits to ${REPO}@${BRANCH}.
Use for a fact that turned out wrong, or the OLD slug after a cross-slug supersede. Git history retains it.

Args:
  - slug (string): the fact to delete.

Returns: { "slug": string, "factCommit": string, "indexCommit": string|null }`,
      inputSchema: DeleteInput.shape,
      annotations: { readOnlyHint: false, destructiveHint: true, idempotentHint: false, openWorldHint: true },
    },
    async ({ slug }) => {
      try {
        const f = await readFile(factPath(slug));
        const factCommit = await deleteFile(factPath(slug), `memory: remove ${slug}`, f.sha);
        let indexCommitSha: string | null = null;
        const index = await readFile(INDEX_FILE);
        const filtered = index.text.split("\n").filter((l) => !l.includes(`](${slug}.md)`)).join("\n");
        if (filtered !== index.text) {
          const indexCommit = await putFile(INDEX_FILE, filtered, `memory: de-index ${slug}`, index.sha);
          indexCommitSha = indexCommit.commitSha;
        }
        const output = { slug, factCommit: factCommit.commitSha, indexCommit: indexCommitSha };
        return { content: [{ type: "text", text: JSON.stringify(output) }], structuredContent: output };
      } catch (error) {
        return errorResult(error, "Use memory_list to confirm the slug exists.");
      }
    },
  );
}
