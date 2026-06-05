/**
 * Vault source layer: keep a local copy of the Obsidian vault git repo and serve
 * read-only search/read/list over its markdown notes. No Obsidian app or Local
 * REST API plugin is involved — this reads files, so it works off-Mac.
 *
 * Source resolution:
 *   - If VAULT_DIR already contains a git checkout (or a mounted vault with files),
 *     it is used as-is. Otherwise the repo is cloned from VAULT_REPO.
 *   - Refreshes are `git fetch` + hard reset to the remote branch, rate-limited by
 *     SYNC_TTL_MS so back-to-back tool calls do not hammer the remote.
 *
 * Auth for a PRIVATE repo: GITHUB_TOKEN is woven into the clone/fetch URL at runtime
 * and never logged. It lives only in the host environment (an op:// reference at
 * deploy time), never in a committed file.
 */
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { readFile, readdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join, resolve, relative, sep } from "node:path";
import { SNIPPET_RADIUS, SYNC_TTL_MS } from "./constants.js";

const execFileAsync = promisify(execFile);

const VAULT_DIR = resolve(process.env.VAULT_DIR ?? "/data/vault");
const VAULT_REPO = process.env.VAULT_REPO ?? ""; // e.g. "SchnappAPI/obsidian-vault"
const VAULT_BRANCH = process.env.VAULT_BRANCH ?? "main";
const GITHUB_TOKEN = process.env.GITHUB_TOKEN ?? "";

let lastSync = 0;

export type SearchType = "content" | "filename" | "both";

export interface Hit {
  path: string;
  line?: number;
  snippet?: string;
}

export interface VaultHealth {
  vaultPresent: boolean;
  noteCount: number;
  dir: string;
  branch: string;
  lastSync: string | null;
  managedByGit: boolean;
}

function authedUrl(): string {
  if (!VAULT_REPO) throw new Error("VAULT_REPO is not set (expected 'owner/repo').");
  const auth = GITHUB_TOKEN ? `x-access-token:${encodeURIComponent(GITHUB_TOKEN)}@` : "";
  return `https://${auth}github.com/${VAULT_REPO}.git`;
}

function isGitCheckout(): boolean {
  return existsSync(join(VAULT_DIR, ".git"));
}

/** Clone the vault if it is not already present. Idempotent; safe to call on boot. */
export async function ensureVault(): Promise<void> {
  if (isGitCheckout()) return;
  // A mounted vault (files present, no .git) is used as-is — do not clone over it.
  if (existsSync(VAULT_DIR)) {
    const entries = await readdir(VAULT_DIR).catch(() => [] as string[]);
    if (entries.length > 0) return;
  }
  if (!VAULT_REPO) {
    throw new Error("Vault not present and VAULT_REPO unset — nothing to clone.");
  }
  await execFileAsync("git", [
    "clone",
    "--depth",
    "1",
    "--branch",
    VAULT_BRANCH,
    authedUrl(),
    VAULT_DIR,
  ]);
  lastSync = Date.now();
}

/** Refresh from the remote, rate-limited. No-op for a mounted (non-git) vault. */
export async function syncVault(force = false): Promise<void> {
  if (!isGitCheckout()) return;
  if (!force && Date.now() - lastSync < SYNC_TTL_MS) return;
  try {
    await execFileAsync("git", ["-C", VAULT_DIR, "remote", "set-url", "origin", authedUrl()]);
    await execFileAsync("git", ["-C", VAULT_DIR, "fetch", "--depth", "1", "origin", VAULT_BRANCH]);
    await execFileAsync("git", ["-C", VAULT_DIR, "reset", "--hard", `origin/${VAULT_BRANCH}`]);
    lastSync = Date.now();
  } catch {
    // A failed refresh is non-fatal: serve the last-good copy rather than erroring.
  }
}

/** Reject any path that escapes the vault root or is not a markdown note. */
function safeNotePath(rel: string): string {
  const full = resolve(VAULT_DIR, rel);
  const root = resolve(VAULT_DIR);
  if (full !== root && !full.startsWith(root + sep)) {
    throw new Error("Path escapes the vault.");
  }
  return full;
}

/** All markdown notes under `start`, as vault-relative paths. Skips dotfolders. */
async function walkNotes(start: string, acc: string[] = []): Promise<string[]> {
  let entries: import("node:fs").Dirent[];
  try {
    entries = await readdir(start, { withFileTypes: true });
  } catch {
    return acc;
  }
  for (const entry of entries) {
    if (entry.name.startsWith(".")) continue; // .git, .obsidian, .github, .remember
    const full = join(start, entry.name);
    if (entry.isDirectory()) {
      await walkNotes(full, acc);
    } else if (entry.name.toLowerCase().endsWith(".md")) {
      acc.push(relative(VAULT_DIR, full));
    }
  }
  return acc;
}

function noteRoot(subpath?: string): string {
  return subpath ? safeNotePath(subpath) : VAULT_DIR;
}

/** List markdown notes, optionally under a subfolder. */
export async function listNotes(subpath?: string): Promise<string[]> {
  await syncVault();
  const notes = await walkNotes(noteRoot(subpath));
  return notes.sort();
}

/** Read one markdown note by vault-relative path. */
export async function readNote(rel: string): Promise<string> {
  await syncVault();
  if (!rel.toLowerCase().endsWith(".md")) {
    throw new Error("Only markdown (.md) notes can be read.");
  }
  return readFile(safeNotePath(rel), "utf8");
}

/** Search note filenames and/or contents. Returns at most `limit` hits. */
export async function searchVault(
  query: string,
  searchType: SearchType,
  subpath: string | undefined,
  limit: number,
): Promise<Hit[]> {
  await syncVault();
  const notes = await walkNotes(noteRoot(subpath));
  const needle = query.toLowerCase();
  const hits: Hit[] = [];

  for (const rel of notes) {
    if (hits.length >= limit) break;

    if (searchType !== "content" && rel.toLowerCase().includes(needle)) {
      hits.push({ path: rel });
      continue;
    }
    if (searchType !== "filename") {
      let text: string;
      try {
        text = await readFile(safeNotePath(rel), "utf8");
      } catch {
        continue;
      }
      const idx = text.toLowerCase().indexOf(needle);
      if (idx >= 0) {
        const line = text.slice(0, idx).split("\n").length;
        const from = Math.max(0, idx - SNIPPET_RADIUS);
        const to = Math.min(text.length, idx + needle.length + SNIPPET_RADIUS);
        const snippet = (from > 0 ? "…" : "") + text.slice(from, to).trim() + (to < text.length ? "…" : "");
        hits.push({ path: rel, line, snippet });
      }
    }
  }
  return hits;
}

export async function vaultHealth(): Promise<VaultHealth> {
  const present = existsSync(VAULT_DIR);
  const notes = present ? await walkNotes(VAULT_DIR) : [];
  return {
    vaultPresent: present,
    noteCount: notes.length,
    dir: VAULT_DIR,
    branch: VAULT_BRANCH,
    lastSync: lastSync ? new Date(lastSync).toISOString() : null,
    managedByGit: isGitCheckout(),
  };
}
