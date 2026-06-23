/** Shared constants for the memory-mcp server. */

export const SERVER_NAME = "memory-mcp-server";
export const SERVER_VERSION = "1.0.0";

// The git-tracked memory lane this server fronts. GitHub origin is the source of
// truth; every surface reconciles to it (decisions/0011 #5/#6). Overridable by env
// so the same image can front a fork / a different lane without a rebuild.
export const REPO = process.env.MEMORY_REPO ?? "SchnappAPI/schnapp-os";
export const BRANCH = process.env.MEMORY_BRANCH ?? "main";
export const MEMORY_DIR = process.env.MEMORY_DIR ?? "memory";
export const INDEX_FILE = `${MEMORY_DIR}/MEMORY.md`;

export const GITHUB_API = "https://api.github.com";
export const USER_AGENT = `${SERVER_NAME}/${SERVER_VERSION}`;

// Cap list/search/markdown payloads so a huge lane never floods the agent context.
export const CHARACTER_LIMIT = 25000;
