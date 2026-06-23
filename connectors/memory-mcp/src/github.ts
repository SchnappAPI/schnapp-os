/**
 * Thin GitHub Contents API client. The memory lane lives in a git repo and GitHub
 * origin is the source of truth, so every read/write goes straight to the API — no
 * local clone, no Mac dependency. Reads return decoded text + blob sha; writes are
 * single commits on the configured branch. Uses Node's global fetch (Node >= 18).
 *
 * Auth: a GitHub token in GITHUB_TOKEN with contents read/write on the repo. A
 * fine-grained PAT scoped to just this repo's contents is the least-privilege choice
 * (see DEPLOY.md); a classic PAT works too. The value is a host env var (never baked
 * into the image), canonical home op://web-variables/<item>/token.
 */
import { GITHUB_API, REPO, BRANCH, MEMORY_DIR, USER_AGENT } from "./constants.js";

function token(): string {
  const t = process.env.GITHUB_TOKEN;
  if (!t) {
    throw new Error("GITHUB_TOKEN is not set. The memory server cannot reach GitHub.");
  }
  return t;
}

function headers(): Record<string, string> {
  return {
    Authorization: `Bearer ${token()}`,
    Accept: "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
    "User-Agent": USER_AGENT,
  };
}

function contentsUrl(path: string): string {
  // Encode each path segment but keep the slashes.
  const safe = path.split("/").map(encodeURIComponent).join("/");
  return `${GITHUB_API}/repos/${REPO}/contents/${safe}`;
}

async function ghError(res: Response, action: string): Promise<string> {
  let detail = "";
  try {
    const j = (await res.json()) as { message?: string };
    if (j?.message) detail = `: ${j.message}`;
  } catch {
    /* body not JSON */
  }
  if (res.status === 401 || res.status === 403) {
    return `GitHub auth failed (${res.status}) on ${action}${detail}. Check GITHUB_TOKEN has contents read/write on ${REPO}.`;
  }
  if (res.status === 429 || (res.status === 403 && detail.includes("rate limit"))) {
    return `GitHub rate-limited (${res.status}) on ${action}${detail}. Wait and retry.`;
  }
  return `GitHub API error ${res.status} on ${action}${detail}.`;
}

export interface FileContent {
  text: string;
  sha: string;
  path: string;
}

export interface DirEntry {
  name: string;
  path: string;
  sha: string;
  type: string;
}

export async function readFile(path: string): Promise<FileContent> {
  const res = await fetch(`${contentsUrl(path)}?ref=${encodeURIComponent(BRANCH)}`, {
    headers: headers(),
  });
  if (res.status === 404) throw new Error(`Not found: ${path} (on ${REPO}@${BRANCH}).`);
  if (!res.ok) throw new Error(await ghError(res, `read ${path}`));
  const data = (await res.json()) as {
    content?: string;
    encoding?: string;
    sha: string;
    type: string;
    path: string;
  };
  if (data.type !== "file" || data.content === undefined) {
    throw new Error(`${path} is not a file (it may be a directory).`);
  }
  const text = Buffer.from(data.content, (data.encoding as BufferEncoding) ?? "base64").toString("utf8");
  return { text, sha: data.sha, path: data.path };
}

/** Like readFile but returns null on 404 instead of throwing. */
export async function tryReadFile(path: string): Promise<FileContent | null> {
  try {
    return await readFile(path);
  } catch (e) {
    if (e instanceof Error && e.message.startsWith("Not found:")) return null;
    throw e;
  }
}

export async function listDir(path: string): Promise<DirEntry[]> {
  const res = await fetch(`${contentsUrl(path)}?ref=${encodeURIComponent(BRANCH)}`, {
    headers: headers(),
  });
  if (res.status === 404) throw new Error(`Directory not found: ${path} (on ${REPO}@${BRANCH}).`);
  if (!res.ok) throw new Error(await ghError(res, `list ${path}`));
  const data = await res.json();
  if (!Array.isArray(data)) throw new Error(`${path} is not a directory.`);
  return (data as DirEntry[]).map((e) => ({ name: e.name, path: e.path, sha: e.sha, type: e.type }));
}

export interface CommitResult {
  commitSha: string;
  path: string;
  htmlUrl: string;
}

export async function putFile(
  path: string,
  text: string,
  message: string,
  sha?: string,
): Promise<CommitResult> {
  const body: Record<string, unknown> = {
    message,
    content: Buffer.from(text, "utf8").toString("base64"),
    branch: BRANCH,
  };
  if (sha) body.sha = sha;
  const res = await fetch(contentsUrl(path), {
    method: "PUT",
    headers: headers(),
    body: JSON.stringify(body),
  });
  if (res.status === 409) {
    throw new Error(`Conflict writing ${path}: stale blob sha. Re-read the file and retry.`);
  }
  if (!res.ok) throw new Error(await ghError(res, `write ${path}`));
  const data = (await res.json()) as {
    commit: { sha: string; html_url: string };
    content: { path: string };
  };
  return { commitSha: data.commit.sha, path: data.content.path, htmlUrl: data.commit.html_url };
}

export async function deleteFile(path: string, message: string, sha: string): Promise<CommitResult> {
  const res = await fetch(contentsUrl(path), {
    method: "DELETE",
    headers: headers(),
    body: JSON.stringify({ message, branch: BRANCH, sha }),
  });
  if (!res.ok) throw new Error(await ghError(res, `delete ${path}`));
  const data = (await res.json()) as { commit: { sha: string; html_url: string } };
  return { commitSha: data.commit.sha, path, htmlUrl: data.commit.html_url };
}

export interface HealthInfo {
  authenticated: boolean;
  repo: string;
  branch: string;
  memoryFileCount: number;
}

/** Wake + verify the chain: lists the memory dir (fails if the token can't reach the repo). */
export async function health(): Promise<HealthInfo> {
  const entries = await listDir(MEMORY_DIR);
  const count = entries.filter((e) => e.type === "file" && e.name.endsWith(".md")).length;
  return { authenticated: true, repo: REPO, branch: BRANCH, memoryFileCount: count };
}
