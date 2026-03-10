import { describe, expect, test } from "bun:test";

import { assessConfidence } from "../confidence";
import type { SearchRequest, SearchResult } from "../provider-adapter";

const BASE_REQUEST: SearchRequest = {
  query: "latest ai news",
  command: "web-news",
};

const nowIso = new Date().toISOString();
const staleIso = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString();

function result(url: string, published_at: string | null): SearchResult {
  return {
    title: url,
    url,
    snippet: "",
    published_at,
    score: 1,
    source_provider: "exa",
  };
}

describe("assessConfidence", () => {
  test("returns low confidence when no results", () => {
    const output = assessConfidence(BASE_REQUEST, []);
    expect(output.confidence).toBe("low");
    expect(output.uncertainty).toContain("No sources");
  });

  test("returns low confidence for time-sensitive query without recent sources", () => {
    const output = assessConfidence(BASE_REQUEST, [
      result("https://a.example", staleIso),
      result("https://b.example", staleIso),
    ]);
    expect(output.confidence).toBe("low");
    expect(output.uncertainty).toContain("No clearly recent");
  });

  test("returns high confidence for multiple recent sources", () => {
    const output = assessConfidence(BASE_REQUEST, [
      result("https://a.example", nowIso),
      result("https://b.example", nowIso),
      result("https://c.example", nowIso),
    ]);
    expect(output.confidence).toBe("high");
    expect(output.uncertainty).toBeNull();
  });

  test("returns medium confidence for non-time-sensitive low source count", () => {
    const request: SearchRequest = { query: "typescript utility types", command: "web" };
    const output = assessConfidence(request, [
      result("https://a.example", null),
      result("https://b.example", null),
    ]);
    expect(output.confidence).toBe("medium");
  });
});
