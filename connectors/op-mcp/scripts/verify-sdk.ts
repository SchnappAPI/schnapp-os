/**
 * Proves the 1Password SDK actually runs in this Node environment and that the
 * Service Account token authenticates. Reads NO secret values unless you pass a
 * reference to resolve.
 *
 *   OP_SERVICE_ACCOUNT_TOKEN=... npx tsx scripts/verify-sdk.ts
 *   OP_SERVICE_ACCOUNT_TOKEN=... npx tsx scripts/verify-sdk.ts "op://Vault/Item/field"
 *
 * With a reference it prints only the value's length, never the value.
 */
import { listVaults, listItems, resolveSecret } from "../src/onepassword.js";

async function main(): Promise<void> {
  console.log("Authenticating to 1Password via Service Account...");
  const vaults = await listVaults();
  console.log(`OK: SDK ran and authenticated. ${vaults.length} vault(s) visible:`);
  for (const v of vaults.slice(0, 10)) console.log(`  - ${v.title} (${v.id})`);

  if (vaults[0]) {
    const items = await listItems(vaults[0].id);
    console.log(`First vault "${vaults[0].title}" has ${items.length} active item(s).`);
  }

  const ref = process.argv[2];
  if (ref) {
    const value = await resolveSecret(ref);
    console.log(`Resolved ${ref}: OK (length ${value.length}, value not printed).`);
  }
  console.log("VERIFY PASS.");
}

main().catch((error) => {
  console.error("VERIFY FAIL:", error instanceof Error ? error.message : error);
  process.exit(1);
});
