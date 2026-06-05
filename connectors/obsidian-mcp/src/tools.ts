import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { CHARACTER_LIMIT, DEFAULT_LIMIT, MAX_LIMIT } from "./constants.js";
import {
  listNotes,
  readNote,
  searchVault,
  vaultHealth,
  type Hit,
  type SearchType,
} from "./vault.js";

const COLD_START_NOTE =
  "COLD START: this connector's host sleeps when idle. The FIRST call after idle can take ~50s or " +
  "return one transient error — wait and retry once before treating it as a failure.";

/** Turn any thrown value into one actionable error result. */
function errorResult(error: unknown, hint?: string) {
  const message = error instanceof Error ? error.message : String(error);
  return {
    isError: true,
    content: [{ type: "text" as const, text: `Error: ${message}${hint ? ` ${hint}` : ""}` }],
  };
}

function clampLimit(limit: number | undefined): number {
  if (!limit || limit < 1) return DEFAULT_LIMIT;
  return Math.min(limit, MAX_LIMIT);
}

/** Cap a text payload so a huge vault never floods the agent context. */
function capText(text: string, note: string): string {
  if (text.length <= CHARACTER_LIMIT) return text;
  return text.slice(0, CHARACTER_LIMIT) + `\n\n…truncated at ${CHARACTER_LIMIT} chars. ${note}`;
}

export function registerTools(server: McpServer): void {
  // ---- vault_search -------------------------------------------------------
  const SearchInput = z
    .object({
      query: z.string().min(1).describe("Text to find in note contents and/or filenames."),
      search_type: z
        .enum(["content", "filename", "both"])
        .default("both")
        .describe("Where to look: 'content', 'filename', or 'both' (default)."),
      path: z
        .string()
        .optional()
        .describe("Optional vault-relative subfolder to limit the search (e.g. 'claude-archive/repo')."),
      limit: z.number().int().positive().optional().describe(`Max hits (default ${DEFAULT_LIMIT}, max ${MAX_LIMIT}).`),
    })
    .strict();

  server.registerTool(
    "vault_search",
    {
      title: "Search the Obsidian vault",
      description: `Search the owner's Obsidian vault notes by content and/or filename. Reads the vault
files directly (a git copy), so it works with the Mac off and needs no Obsidian app.

Args:
  - query (string): text to match (case-insensitive).
  - search_type ("content"|"filename"|"both"): default "both".
  - path (string, optional): a vault-relative subfolder to scope the search.
  - limit (number, optional): max hits (default ${DEFAULT_LIMIT}, max ${MAX_LIMIT}).

Returns: { "count": number, "hits": [{ "path": string, "line"?: number, "snippet"?: string }] }
Use the returned path with vault_read to open the full note.

${COLD_START_NOTE}`,
      inputSchema: SearchInput.shape,
      annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: true },
    },
    async ({ query, search_type, path, limit }) => {
      try {
        const hits: Hit[] = await searchVault(query, search_type as SearchType, path, clampLimit(limit));
        const output = { count: hits.length, hits };
        const lines = [
          `# Search "${query}" (${hits.length} hit${hits.length === 1 ? "" : "s"})`,
          "",
          ...hits.map((h) => `- ${h.path}${h.line ? `:${h.line}` : ""}${h.snippet ? `\n    ${h.snippet}` : ""}`),
        ];
        return {
          content: [{ type: "text", text: capText(lines.join("\n"), "Narrow with `path` or a more specific query.") }],
          structuredContent: output,
        };
      } catch (error) {
        return errorResult(error, "Check the vault is reachable (vault_health).");
      }
    },
  );

  // ---- vault_read ---------------------------------------------------------
  const ReadInput = z
    .object({
      path: z.string().min(1).describe("Vault-relative path to a markdown note, e.g. 'claude-archive/repo/PLAN.md'."),
    })
    .strict();

  server.registerTool(
    "vault_read",
    {
      title: "Read a vault note",
      description: `Read one markdown note from the vault by its vault-relative path (from vault_search or vault_list).

Args:
  - path (string): a vault-relative .md path. Paths that escape the vault are rejected.

Returns: the note's markdown text (capped at ${CHARACTER_LIMIT} chars).

${COLD_START_NOTE}`,
      inputSchema: ReadInput.shape,
      annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: true },
    },
    async ({ path }) => {
      try {
        const text = await readNote(path);
        return { content: [{ type: "text", text: capText(text, "Note truncated; read a narrower file.") }] };
      } catch (error) {
        return errorResult(error, "Verify the path with vault_search or vault_list.");
      }
    },
  );

  // ---- vault_list ---------------------------------------------------------
  const ListInput = z
    .object({
      path: z.string().optional().describe("Optional vault-relative subfolder to list (default: whole vault)."),
      limit: z.number().int().positive().optional().describe(`Max notes (default ${DEFAULT_LIMIT}, max ${MAX_LIMIT}).`),
    })
    .strict();

  server.registerTool(
    "vault_list",
    {
      title: "List vault notes",
      description: `List markdown notes in the vault, optionally under a subfolder.

Args:
  - path (string, optional): a vault-relative subfolder (e.g. 'claude-archive/repo/decisions').
  - limit (number, optional): max notes (default ${DEFAULT_LIMIT}, max ${MAX_LIMIT}).

Returns: { "count": number, "truncated": boolean, "notes": string[] }

${COLD_START_NOTE}`,
      inputSchema: ListInput.shape,
      annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: true },
    },
    async ({ path, limit }) => {
      try {
        const all = await listNotes(path);
        const max = clampLimit(limit);
        const notes = all.slice(0, max);
        const output = { count: all.length, truncated: all.length > notes.length, notes };
        const header = `# Notes${path ? ` in ${path}` : ""} (${notes.length}/${all.length})`;
        return {
          content: [{ type: "text", text: [header, "", ...notes.map((n) => `- ${n}`)].join("\n") }],
          structuredContent: output,
        };
      } catch (error) {
        return errorResult(error, "Check the subfolder path.");
      }
    },
  );

  // ---- vault_health -------------------------------------------------------
  server.registerTool(
    "vault_health",
    {
      title: "Check the vault connector",
      description: `Confirm the vault is present and report its size + last sync. No note contents.
Good first call to wake the host and verify the chain before searching.

Returns: { "vaultPresent": boolean, "noteCount": number, "dir": string, "branch": string, "lastSync": string|null, "managedByGit": boolean }

${COLD_START_NOTE}`,
      inputSchema: z.object({}).strict().shape,
      annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: true },
    },
    async () => {
      try {
        const output = await vaultHealth();
        return {
          content: [{ type: "text", text: JSON.stringify(output) }],
          structuredContent: output as unknown as Record<string, unknown>,
        };
      } catch (error) {
        return errorResult(error, "Check VAULT_REPO / GITHUB_TOKEN / VAULT_DIR on the host.");
      }
    },
  );
}
