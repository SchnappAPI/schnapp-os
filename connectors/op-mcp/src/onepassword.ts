import { createClient, type Client } from "@1password/sdk";
import { INTEGRATION_NAME, INTEGRATION_VERSION } from "./constants.js";

/**
 * Thin wrapper over the 1Password JS SDK.
 *
 * The SDK loads a WASM core via `fs.readFileSync` + synchronous WebAssembly
 * compile (see @1password/sdk-core/nodejs/core.js). That is why this connector
 * MUST run on a Node host, not the Cloudflare Workers edge runtime — Workers has
 * no runtime filesystem and blocks sync wasm compilation. (decisions/0004.)
 *
 * The client is created once and reused (auth + WASM init are not free).
 */
let clientPromise: Promise<Client> | null = null;

function getClient(): Promise<Client> {
  if (!clientPromise) {
    const auth = process.env.OP_SERVICE_ACCOUNT_TOKEN;
    if (!auth) {
      throw new Error(
        "OP_SERVICE_ACCOUNT_TOKEN is not set. The connector cannot authenticate to 1Password.",
      );
    }
    clientPromise = createClient({
      auth,
      integrationName: INTEGRATION_NAME,
      integrationVersion: INTEGRATION_VERSION,
    });
  }
  return clientPromise;
}

export interface VaultInfo {
  id: string;
  title: string;
}

export interface ItemInfo {
  id: string;
  title: string;
  category?: string;
  vaultId?: string;
}

/** Resolve a single `op://vault/item/field` reference to its secret value. */
export async function resolveSecret(reference: string): Promise<string> {
  const client = await getClient();
  return client.secrets.resolve(reference);
}

/** List vaults the Service Account can see. */
export async function listVaults(): Promise<VaultInfo[]> {
  const client = await getClient();
  const vaults = await client.vaults.list();
  return vaults.map((v) => ({ id: v.id, title: v.title }));
}

/** List active items in a vault. */
export async function listItems(vaultId: string): Promise<ItemInfo[]> {
  const client = await getClient();
  const items = await client.items.list(vaultId, {
    type: "ByState",
    content: { active: true, archived: false },
  });
  return items.map((i) => ({
    id: i.id,
    title: i.title,
    category: (i as { category?: string }).category,
    vaultId: (i as { vaultId?: string }).vaultId ?? vaultId,
  }));
}

/**
 * Connectivity / identity check. The SDK has no `whoami`, so we prove the
 * Service Account authenticates by listing vaults and reporting the count.
 * Returns NO secret values.
 */
export async function health(): Promise<{ authenticated: true; integration: string; vaultCount: number }> {
  const vaults = await listVaults();
  return { authenticated: true, integration: INTEGRATION_NAME, vaultCount: vaults.length };
}
