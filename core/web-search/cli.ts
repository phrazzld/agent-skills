import path from "node:path";

import { QueryCache } from "./cache";
import { assessConfidence } from "./confidence";
import { WebSearchOrchestrator } from "./orchestrator";
import {
  Context7Provider,
  BraveProvider,
  ExaProvider,
  PerplexitySynthesisProvider,
} from "./providers";
import type { ProviderAdapter, SearchResponse, WebCommand } from "./provider-adapter";
import {
  inferRecencyDays,
  isDocsLookup,
  isTimeSensitiveQuery,
  normalizeQuery,
} from "./query-utils";

interface CliInput {
  command: WebCommand;
  query: string;
}

async function main(): Promise<void> {
  const input = parseArgs(process.argv.slice(2));
  const configDir = process.env.PI_CONFIG_DIR ?? path.resolve(process.cwd(), "..", "..");
  const cacheTtlMs = Number(process.env.WEB_SEARCH_TTL_MS) || 30 * 60 * 1000;
  const limit = Number(process.env.WEB_SEARCH_MAX_RESULTS) || 5;

  const request = {
    query: input.query,
    command: input.command,
    limit,
    recencyDays: inferRecencyDays({
      query: input.query,
      command: input.command,
      limit,
    }),
  };

  const providers: ProviderAdapter[] = [];
  const useContext7 = Boolean(process.env.CONTEXT7_API_KEY) && isDocsLookup(input.query, input.command);
  if (useContext7) {
    providers.push(new Context7Provider(process.env.CONTEXT7_API_KEY!));
  }
  if (process.env.EXA_API_KEY) {
    providers.push(new ExaProvider(process.env.EXA_API_KEY));
  }
  if (process.env.BRAVE_API_KEY) {
    providers.push(new BraveProvider(process.env.BRAVE_API_KEY));
  }

  if (providers.length === 0) {
    throw new Error(
      "no retrieval providers configured; set CONTEXT7_API_KEY and/or EXA_API_KEY and/or BRAVE_API_KEY"
    );
  }

  const cache = new QueryCache({
    filePath: path.join(configDir, "cache", "web-search-cache.json"),
    ttlMs: cacheTtlMs,
  });

  const orchestrator = new WebSearchOrchestrator(providers, {
    cache,
    logPath: path.join(configDir, "logs", "web-search.ndjson"),
  });

  const { results, meta } = await orchestrator.searchWithMeta(request);
  const confidence = assessConfidence(request, results);

  let synthesis: SearchResponse["synthesis"] = null;
  if (input.command === "web-deep" && process.env.PERPLEXITY_API_KEY && results.length > 0) {
    const synthesizer = new PerplexitySynthesisProvider(process.env.PERPLEXITY_API_KEY);
    const generated = await synthesizer.synthesize(input.query, results);
    synthesis = generated.citations.length > 0 ? generated : null;
  }

  const response: SearchResponse = {
    results,
    meta: {
      query: input.query,
      normalized_query: normalizeQuery(input.query),
      command: input.command,
      provider_chain: meta.providerChain,
      provider_used: meta.providerUsed,
      cache_hit: meta.cacheHit,
      time_sensitive: isTimeSensitiveQuery(input.query, input.command),
      recency_days: request.recencyDays ?? null,
      confidence: confidence.confidence,
      uncertainty: confidence.uncertainty,
    },
    synthesis,
  };

  process.stdout.write(`${JSON.stringify(response, null, 2)}\n`);
}

function parseArgs(args: string[]): CliInput {
  if (args.length < 2) {
    throw new Error("usage: web-search <web|web-deep|web-news|web-docs> <query>");
  }

  const [command, ...queryParts] = args;
  if (
    command !== "web" &&
    command !== "web-deep" &&
    command !== "web-news" &&
    command !== "web-docs"
  ) {
    throw new Error("command must be one of: web, web-deep, web-news, web-docs");
  }

  const query = queryParts.join(" ").trim();
  if (!query) {
    throw new Error("query must not be empty");
  }

  return {
    command,
    query,
  };
}

main().catch((error) => {
  process.stderr.write(`${String(error)}\n`);
  process.exit(1);
});
