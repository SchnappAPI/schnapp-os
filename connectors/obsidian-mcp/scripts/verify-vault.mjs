// Local verification of the vault layer against VAULT_DIR (no network, no clone).
// Usage: VAULT_DIR=/tmp/obs-test node scripts/verify-vault.mjs
import { ensureVault, vaultHealth, searchVault, listNotes, readNote } from "../dist/vault.js";

await ensureVault();
console.log("health:", JSON.stringify(await vaultHealth()));

const notes = await listNotes();
console.log("listNotes:", notes.length, "->", notes.slice(0, 5));

const contentHits = await searchVault("claude", "content", undefined, 5);
console.log("search content 'claude':", contentHits.length, contentHits.map((h) => `${h.path}:${h.line}`));

const nameHits = await searchVault("note", "filename", undefined, 5);
console.log("search filename 'note':", nameHits.length, nameHits.map((h) => h.path));

if (notes[0]) {
  const text = await readNote(notes[0]);
  console.log(`readNote ${notes[0]}: ${text.length} chars`);
}

// Path-traversal guard must reject escapes.
try {
  await readNote("../../../../etc/passwd");
  console.log("TRAVERSAL NOT BLOCKED ❌");
} catch (e) {
  console.log("traversal blocked ✓:", e.message);
}

// Non-md read must be refused.
try {
  await readNote("notavault.txt");
  console.log("NON-MD NOT BLOCKED ❌");
} catch (e) {
  console.log("non-md refused ✓:", e.message);
}
