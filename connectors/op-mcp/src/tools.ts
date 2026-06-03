import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { CHARACTER_LIMIT } from "./constants.js";
import { resolveSecret, listVaults, listItems, health, type ItemInfo } from "./onepassword.js";

enum ResponseFormat {
  MARKDOWN = "markdown",
  JSON = "json",
}

const responseFormatField = z
  .nativeEnum(ResponseFormat)
  .default(ResponseFormat.MARKDOWN)
  .describe("Output format: 'markdown' (human-readable) or 'json' (machine-readable).");

/** Turn any thrown value into one actionable error result. */
function errorResult(error: unknown, hint?: string) {
  const message = error instanceof Error ? error.message : String(error);
  return {
    isError: true,
    content: [{ type: "text" as const, text: `Error: ${message}${hint ? ` ${hint}` : ""}` }],
  };
}

export function registerTools(server: McpServer): void {
  // ---- op_read ------------------------------------------------------------
  const ReadInput = z
    .object({
      reference: z
        .string()
        .regex(/^op:\/\/[^/]+\/[^/]+\/.+$/i, "Must be an op://vault/item/field reference.")
        .describe("Secret reference, e.g. 'op://Private/GitHub PAT/credential'."),
    })
    .strict();

  server.registerTool(
    "op_read",
    {
      title: "Read a 1Password secret",
      description: `Resolve a single 1Password secret reference to its value via the Service Account.

Args:
  - reference (string): an op://vault/item/field reference (sections allowed: op://vault/item/section/field).

Returns: { "reference": string, "value": string } — the resolved secret value.

Examples:
  - Use when: "Get the GitHub token" -> reference="op://Private/GitHub PAT/credential"
  - Don't use when: you only need to know which items exist (use op_list_items).

Errors:
  - "secret not found" if the reference does not resolve (check vault/item/field names).
  - "Unauthorized" if the Service Account lacks access to that vault.`,
      inputSchema: ReadInput.shape,
      annotations: {
        readOnlyHint: true,
        destructiveHint: false,
        idempotentHint: true,
        openWorldHint: true,
      },
    },
    async ({ reference }) => {
      try {
        const value = await resolveSecret(reference);
        const output = { reference, value };
        return {
          content: [{ type: "text", text: JSON.stringify(output) }],
          structuredContent: output,
        };
      } catch (error) {
        return errorResult(error, "Check the op:// reference and that the Service Account has vault access.");
      }
    },
  );

  // ---- op_list_vaults -----------------------------------------------------
  const ListVaultsInput = z.object({ response_format: responseFormatField }).strict();

  server.registerTool(
    "op_list_vaults",
    {
      title: "List 1Password vaults",
      description: `List the vaults the Service Account can access (no secret values).

Returns: { "count": number, "vaults": [{ "id": string, "title": string }] }

Use this first to discover vault names before calling op_list_items or op_read.`,
      inputSchema: ListVaultsInput.shape,
      annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: true },
    },
    async ({ response_format }) => {
      try {
        const vaults = await listVaults();
        const output = { count: vaults.length, vaults };
        const text =
          response_format === ResponseFormat.JSON
            ? JSON.stringify(output, null, 2)
            : [`# Vaults (${vaults.length})`, "", ...vaults.map((v) => `- ${v.title} (${v.id})`)].join("\n");
        return { content: [{ type: "text", text }], structuredContent: output };
      } catch (error) {
        return errorResult(error);
      }
    },
  );

  // ---- op_list_items ------------------------------------------------------
  const ListItemsInput = z
    .object({
      vault_id: z.string().min(1).describe("Vault ID (from op_list_vaults) to list items from."),
      response_format: responseFormatField,
    })
    .strict();

  server.registerTool(
    "op_list_items",
    {
      title: "List items in a 1Password vault",
      description: `List active items in a vault (no secret values).

Args:
  - vault_id (string): the vault ID from op_list_vaults.

Returns: { "count": number, "items": [{ "id": string, "title": string, "category": string }] }

Build an op:// reference from a returned title to read a field with op_read.`,
      inputSchema: ListItemsInput.shape,
      annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: true },
    },
    async ({ vault_id, response_format }) => {
      try {
        const items = await listItems(vault_id);
        let output: { count: number; items: ItemInfo[]; truncated?: boolean } = {
          count: items.length,
          items,
        };
        let text =
          response_format === ResponseFormat.JSON
            ? JSON.stringify(output, null, 2)
            : [`# Items in ${vault_id} (${items.length})`, "", ...items.map((i) => `- ${i.title}${i.category ? ` [${i.category}]` : ""} (${i.id})`)].join("\n");

        if (text.length > CHARACTER_LIMIT) {
          const half = Math.max(1, Math.floor(items.length / 2));
          output = { count: items.length, items: items.slice(0, half), truncated: true };
          text =
            JSON.stringify(output, null, 2) +
            `\n\nResponse truncated from ${items.length} to ${half} items. Narrow by vault.`;
        }
        return { content: [{ type: "text", text }], structuredContent: output };
      } catch (error) {
        return errorResult(error, "Verify vault_id with op_list_vaults.");
      }
    },
  );

  // ---- op_health ----------------------------------------------------------
  server.registerTool(
    "op_health",
    {
      title: "Check the connector / Service Account",
      description: `Verify the connector is authenticated to 1Password. Returns NO secret values.

Returns: { "authenticated": true, "integration": string, "vaultCount": number }`,
      inputSchema: z.object({}).strict().shape,
      annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: true },
    },
    async () => {
      try {
        const output = await health();
        return { content: [{ type: "text", text: JSON.stringify(output) }], structuredContent: output };
      } catch (error) {
        return errorResult(error, "Check OP_SERVICE_ACCOUNT_TOKEN on the host.");
      }
    },
  );
}
