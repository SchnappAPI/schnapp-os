import type { Request, Response, NextFunction } from "express";

/**
 * Bearer-token gate for the MCP endpoint.
 *
 * The connector reads secrets, so the endpoint MUST be protected. The simplest
 * portable gate is a static bearer token (a long random string) checked in
 * constant-ish time. For claude.ai registration you can either:
 *   - put this server behind Cloudflare Access / an OAuth proxy (recommended), or
 *   - pass `Authorization: Bearer <token>` from clients that allow custom headers
 *     (Claude Code / Cowork mcp config support this).
 *
 * Set OP_MCP_BEARER in the host environment. If it is unset the server
 * refuses to start (see index.ts) — we never run an open secrets endpoint.
 */
export function bearerAuth(expectedToken: string) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const header = req.header("authorization") ?? "";
    const match = header.match(/^Bearer\s+(.+)$/i);
    const presented = match?.[1]?.trim();

    if (!presented || !timingSafeEqual(presented, expectedToken)) {
      res.status(401).json({
        jsonrpc: "2.0",
        error: { code: -32001, message: "Unauthorized: missing or invalid bearer token." },
        id: null,
      });
      return;
    }
    next();
  };
}

/** Length-then-XOR compare to avoid leaking the token via early-exit timing. */
function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}
