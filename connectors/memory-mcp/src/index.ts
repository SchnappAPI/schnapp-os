#!/usr/bin/env node
/**
 * memory-mcp-server — remote MCP fronting the git-tracked memory lane.
 *
 * Makes the schnapp-os memory/ lane reachable from every surface (claude.ai web,
 * iPhone, Cowork, Code) with GitHub origin as the single source of truth: reads and
 * writes go straight to the GitHub Contents API, so hookless surfaces see and update
 * the SAME canonical memory the Code-on-Mac freshness gate reconciles to. No local
 * clone, no Mac dependency. (decisions/0011 #5/#6.)
 *
 * Transport: streamable HTTP (stateless JSON). Protect /mcp with a bearer; it can write.
 */
import express, { type Request, type Response } from "express";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { SERVER_NAME, SERVER_VERSION } from "./constants.js";
import { bearerAuth } from "./auth.js";
import { registerTools } from "./tools.js";

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
  // Both must be present: the GitHub token (lane access) and the bearer gate.
  // We never run an open, writable endpoint.
  requireEnv("GITHUB_TOKEN");
  const authToken = requireEnv("MEMORY_MCP_BEARER");

  const app = express();
  app.use(express.json());

  // Unauthenticated liveness probe (no GitHub calls, no secrets).
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
