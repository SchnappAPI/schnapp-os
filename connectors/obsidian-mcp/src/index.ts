#!/usr/bin/env node
/**
 * obsidian-mcp-server — remote MCP that serves the owner's Obsidian vault.
 *
 * Reads the vault from a git copy (clones VAULT_REPO, or uses a mounted VAULT_DIR),
 * so it works with the Mac off and needs NO Obsidian app / Local REST API plugin.
 * Transport: streamable HTTP (stateless JSON), bearer-protected — same shape as the
 * op-mcp connector. Read-only: search / read / list / health, no write tools.
 */
import express, { type Request, type Response } from "express";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { SERVER_NAME, SERVER_VERSION } from "./constants.js";
import { bearerAuth } from "./auth.js";
import { registerTools } from "./tools.js";
import { ensureVault, vaultHealth } from "./vault.js";

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    console.error(`FATAL: ${name} is required but not set. Refusing to start.`);
    process.exit(1);
  }
  return value;
}

function buildServer(): McpServer {
  const server = new McpServer({ name: SERVER_NAME, version: SERVER_VERSION });
  registerTools(server);
  return server;
}

async function main(): Promise<void> {
  // The endpoint serves private vault contents — never run it open.
  const authToken = requireEnv("CONNECTOR_AUTH_TOKEN");

  // Make the vault available before accepting traffic. Non-fatal: if the clone
  // fails (e.g. transient network), tools still report it via vault_health.
  try {
    await ensureVault();
    const h = await vaultHealth();
    console.error(`${SERVER_NAME}: vault ready — ${h.noteCount} notes at ${h.dir} (git=${h.managedByGit})`);
  } catch (error) {
    console.error(`${SERVER_NAME}: vault not ready at boot (will retry on demand):`, error);
  }

  const app = express();
  app.use(express.json());

  // Unauthenticated liveness probe (no vault contents).
  app.get("/health", (_req: Request, res: Response) => {
    res.json({ status: "ok", server: SERVER_NAME, version: SERVER_VERSION });
  });

  // MCP endpoint — bearer-protected, stateless (new transport per request).
  app.post("/mcp", bearerAuth(authToken), async (req: Request, res: Response) => {
    const transport = new StreamableHTTPServerTransport({
      sessionIdGenerator: undefined,
      enableJsonResponse: true,
    });
    res.on("close", () => {
      void transport.close();
    });
    const server = buildServer();
    await server.connect(transport);
    await transport.handleRequest(req, res, req.body);
  });

  const port = parseInt(process.env.PORT ?? "3000", 10);
  app.listen(port, () => {
    console.error(`${SERVER_NAME} v${SERVER_VERSION} listening on :${port} (POST /mcp, GET /health)`);
  });
}

main().catch((error) => {
  console.error("Server failed to start:", error);
  process.exit(1);
});
