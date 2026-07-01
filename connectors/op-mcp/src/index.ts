#!/usr/bin/env node
/**
 * op-mcp-server - off-Mac remote MCP that resolves 1Password secrets.
 *
 * Transport: streamable HTTP (stateless JSON), so claude.ai / Cowork / Code can
 * reach it as a remote connector. Runs on a Node host (not Workers; see
 * onepassword.ts and decisions/0004). Protect the endpoint with a bearer token.
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
  // Both must be present: the 1Password SA token and the bearer gate.
  // We never run an open secrets endpoint.
  requireEnv("OP_SERVICE_ACCOUNT_TOKEN");
  const authToken = requireEnv("OP_MCP_BEARER");

  const app = express();
  app.use(express.json());

  // Unauthenticated liveness probe (no 1Password calls, no secrets).
  app.get("/health", (_req: Request, res: Response) => {
    res.json({ status: "ok", server: SERVER_NAME, version: SERVER_VERSION });
  });

  // MCP endpoint - bearer-protected, stateless (new transport per request).
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
