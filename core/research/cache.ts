import { createHash } from "node:crypto";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";

import type { SearchRequest } from "./provider-adapter";
import { normalizeQuery } from "./query-utils";

interface CacheEntry<T> {
  expiresAt: number;
  value: T;
}

type CacheStore<T> = Record<string, CacheEntry<T>>;

export interface QueryCacheOptions {
  filePath: string;
  ttlMs: number;
}

export class QueryCache<T> {
  private readonly filePath: string;
  private readonly ttlMs: number;

  constructor(options: QueryCacheOptions) {
    this.filePath = options.filePath;
    this.ttlMs = options.ttlMs;
  }

  async get(request: SearchRequest): Promise<T | null> {
    const key = cacheKey(request);
    const store = await this.load();
    const entry = store[key];
    if (!entry) {
      return null;
    }

    if (Date.now() >= entry.expiresAt) {
      delete store[key];
      await this.save(store);
      return null;
    }

    return entry.value;
  }

  async set(request: SearchRequest, value: T): Promise<void> {
    const key = cacheKey(request);
    const store = await this.load();
    store[key] = {
      expiresAt: Date.now() + this.ttlMs,
      value,
    };
    await this.save(store);
  }

  private async load(): Promise<CacheStore<T>> {
    try {
      const raw = await readFile(this.filePath, "utf8");
      return JSON.parse(raw) as CacheStore<T>;
    } catch {
      return {};
    }
  }

  private async save(store: CacheStore<T>): Promise<void> {
    await mkdir(path.dirname(this.filePath), { recursive: true });
    await writeFile(this.filePath, `${JSON.stringify(store, null, 2)}\n`, "utf8");
  }
}

function cacheKey(request: SearchRequest): string {
  const normalizedQuery = normalizeQuery(request.query);
  const key = [
    "v2",
    request.command,
    normalizedQuery,
    request.limit ?? "",
    request.recencyDays ?? "",
  ].join(":");
  return createHash("sha256").update(key).digest("hex");
}
