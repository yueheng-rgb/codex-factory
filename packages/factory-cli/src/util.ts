import { createHash, randomUUID } from "node:crypto";
import {
  appendFileSync,
  closeSync,
  existsSync,
  mkdirSync,
  openSync,
  readFileSync,
  realpathSync,
  renameSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { dirname, relative, resolve } from "node:path";

export function nowIso(): string {
  return new Date().toISOString();
}

export function newId(prefix: string): string {
  return prefix + "-" + randomUUID();
}

export function sha256(value: string | Buffer): string {
  return createHash("sha256").update(value).digest("hex");
}

export function stableStringify(value: unknown): string {
  if (value === null || typeof value !== "object") {
    return JSON.stringify(value);
  }
  if (Array.isArray(value)) {
    return "[" + value.map(stableStringify).join(",") + "]";
  }
  const entries = Object.entries(value as Record<string, unknown>)
    .filter(([, item]) => item !== undefined)
    .sort(([left], [right]) => left.localeCompare(right));
  return (
    "{" +
    entries
      .map(([key, item]) => JSON.stringify(key) + ":" + stableStringify(item))
      .join(",") +
    "}"
  );
}

export function ensureDirectory(path: string): void {
  mkdirSync(path, { recursive: true });
}

export function readJson<T>(path: string): T {
  return JSON.parse(readFileSync(path, "utf8")) as T;
}

export function writeJsonAtomic(path: string, value: unknown): void {
  ensureDirectory(dirname(path));
  const temporaryPath = path + ".tmp-" + process.pid + "-" + randomUUID();
  writeFileSync(temporaryPath, JSON.stringify(value, null, 2) + "\n", "utf8");
  renameSync(temporaryPath, path);
}

export function appendJsonLine(path: string, value: unknown): void {
  ensureDirectory(dirname(path));
  appendFileSync(path, JSON.stringify(value) + "\n", "utf8");
}

export function assertWithinRoot(root: string, candidate: string): string {
  const absoluteRoot = resolve(root);
  const absoluteCandidate = resolve(candidate);
  const rel = relative(absoluteRoot, absoluteCandidate);
  if (rel.startsWith("..") || rel === ".." || resolve(absoluteRoot, rel) !== absoluteCandidate) {
    throw new Error("Path escapes project root: " + candidate);
  }
  if (!existsSync(absoluteRoot)) throw new Error("Project root does not exist: " + absoluteRoot);
  const realRoot = realpathSync.native(absoluteRoot);
  let existingAncestor = absoluteCandidate;
  while (!existsSync(existingAncestor)) {
    const parent = dirname(existingAncestor);
    if (parent === existingAncestor) {
      throw new Error("Could not resolve an existing ancestor for path: " + candidate);
    }
    existingAncestor = parent;
  }
  const realAncestor = realpathSync.native(existingAncestor);
  const realRelative = relative(realRoot, realAncestor);
  if (
    realRelative === ".." ||
    realRelative.startsWith(".." + requirePathSeparator()) ||
    resolve(realRoot, realRelative) !== realAncestor
  ) {
    throw new Error("Path escapes project root through a symlink or junction: " + candidate);
  }
  return absoluteCandidate;
}

function requirePathSeparator(): string {
  return process.platform === "win32" ? "\\" : "/";
}

export function withFileLock<T>(lockPath: string, operation: () => T): T {
  ensureDirectory(dirname(lockPath));
  const attempts = 80;
  const waitBuffer = new Int32Array(new SharedArrayBuffer(4));
  const ownerToken = randomUUID();

  for (let attempt = 0; attempt < attempts; attempt += 1) {
    let handle: number | undefined;
    let created = false;
    try {
      handle = openSync(lockPath, "wx");
      created = true;
      writeFileSync(
        handle,
        JSON.stringify({ token: ownerToken, pid: process.pid, acquired_at: nowIso() }),
        "utf8",
      );
      closeSync(handle);
      handle = undefined;
      try {
        return operation();
      } finally {
        removeLockOnlyIfOwned(lockPath, ownerToken);
      }
    } catch (error) {
      if (handle !== undefined) {
        closeSync(handle);
      }
      if (created) {
        removeLockOnlyIfOwned(lockPath, ownerToken);
      }
      const code = (error as NodeJS.ErrnoException).code;
      if (code !== "EEXIST") {
        throw error;
      }
      if (existsSync(lockPath)) {
        const owner = readLockOwner(lockPath);
        if (owner && !isProcessAlive(owner.pid)) {
          removeLockOnlyIfOwned(lockPath, owner.token);
          continue;
        }
        // A malformed lock is never allowed to create split-brain merely because a
        // valid operation ran longer than a fixed timeout. It is recoverable only
        // after a long quarantine and only if its exact bytes are unchanged.
        let ageMs: number;
        try {
          ageMs = Date.now() - statSync(lockPath).mtimeMs;
        } catch (statError) {
          if ((statError as NodeJS.ErrnoException).code === "ENOENT") continue;
          throw statError;
        }
        if (!owner && ageMs > 300_000) {
          removeMalformedLockOnlyIfUnchanged(lockPath);
          continue;
        }
      }
      Atomics.wait(waitBuffer, 0, 0, 25);
    }
  }
  throw new Error("Timed out waiting for lock: " + lockPath);
}

interface FileLockOwner {
  token: string;
  pid: number;
}

function readLockOwner(lockPath: string): FileLockOwner | undefined {
  try {
    const parsed = JSON.parse(readFileSync(lockPath, "utf8")) as Record<string, unknown>;
    if (
      typeof parsed.token !== "string" ||
      parsed.token.length < 8 ||
      typeof parsed.pid !== "number" ||
      !Number.isSafeInteger(parsed.pid) ||
      parsed.pid <= 0
    ) {
      return undefined;
    }
    return { token: parsed.token, pid: parsed.pid };
  } catch {
    return undefined;
  }
}

function isProcessAlive(pid: number): boolean {
  if (pid === process.pid) return true;
  try {
    process.kill(pid, 0);
    return true;
  } catch (error) {
    return (error as NodeJS.ErrnoException).code !== "ESRCH";
  }
}

function removeLockOnlyIfOwned(lockPath: string, token: string): void {
  const current = readLockOwner(lockPath);
  if (current?.token === token) {
    rmSync(lockPath, { force: true });
  }
}

function removeMalformedLockOnlyIfUnchanged(lockPath: string): void {
  let observed: string;
  try {
    observed = readFileSync(lockPath, "utf8");
  } catch {
    return;
  }
  if (readLockOwner(lockPath)) return;
  try {
    if (readFileSync(lockPath, "utf8") === observed) {
      rmSync(lockPath, { force: true });
    }
  } catch {
    // A concurrent cleanup won the race; the next exclusive create will decide.
  }
}

export function slugifyProjectId(input: string): string {
  const normalized = input
    .normalize("NFKC")
    .trim()
    .toLowerCase()
    .replace(/[^\p{Letter}\p{Number}]+/gu, "-")
    .replace(/^-+|-+$/g, "");
  return normalized || "factory-project";
}

export function parseBoolean(value: string | undefined, fallback = false): boolean {
  if (value === undefined) return fallback;
  return ["1", "true", "yes", "on", "enabled"].includes(value.toLowerCase());
}
