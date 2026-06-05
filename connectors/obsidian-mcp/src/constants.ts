/** Shared constants for the obsidian-mcp server. */

export const SERVER_NAME = "obsidian-mcp-server";
export const SERVER_VERSION = "1.0.0";

// Cap search/list/note payloads so a huge vault never floods the agent context.
export const CHARACTER_LIMIT = 25000;

// Default + max number of hits/notes a single call returns.
export const DEFAULT_LIMIT = 30;
export const MAX_LIMIT = 200;

// Snippet length around a content match (characters).
export const SNIPPET_RADIUS = 160;

// How long a freshly-pulled vault is considered current before the next
// search/read triggers another `git fetch` (ms). Avoids pulling every call.
export const SYNC_TTL_MS = 60_000;
