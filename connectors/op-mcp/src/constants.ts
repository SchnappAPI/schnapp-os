/** Shared constants for the op-mcp server. */

export const SERVER_NAME = "op-mcp-server";
export const SERVER_VERSION = "1.0.0";

// Sent to 1Password as the integration identity (shows in SA usage logs).
export const INTEGRATION_NAME = "claude-kit-op-mcp";
export const INTEGRATION_VERSION = SERVER_VERSION;

// Cap list/markdown payloads so a huge vault never floods the agent context.
export const CHARACTER_LIMIT = 25000;

// Default page size for list tools.
export const DEFAULT_LIMIT = 50;
export const MAX_LIMIT = 200;
