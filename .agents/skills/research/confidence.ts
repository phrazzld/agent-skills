import type { SearchMeta, SearchRequest, SearchResult } from "./provider-adapter";
import { inferRecencyDays, isTimeSensitiveQuery } from "./query-utils";

export interface ConfidenceAssessment {
  confidence: SearchMeta["confidence"];
  uncertainty: string | null;
}

export function assessConfidence(
  request: SearchRequest,
  results: SearchResult[]
): ConfidenceAssessment {
  if (results.length === 0) {
    return {
      confidence: "low",
      uncertainty: "No sources returned from configured providers.",
    };
  }

  if (results.length === 1) {
    return {
      confidence: "medium",
      uncertainty: "Only one source found. Cross-check before relying on it.",
    };
  }

  const timeSensitive = isTimeSensitiveQuery(request.query, request.command);
  if (!timeSensitive) {
    return {
      confidence: results.length >= 4 ? "high" : "medium",
      uncertainty: results.length >= 4 ? null : "Limited source count.",
    };
  }

  const recencyDays = inferRecencyDays(request) ?? 30;
  const recentCount = results.filter((result) =>
    isRecentEnough(result.published_at, recencyDays)
  ).length;

  if (recentCount === 0) {
    return {
      confidence: "low",
      uncertainty: `No clearly recent sources found within ~${recencyDays} days.`,
    };
  }

  if (recentCount < 2) {
    return {
      confidence: "medium",
      uncertainty: `Only ${recentCount} recent source found within ~${recencyDays} days.`,
    };
  }

  return {
    confidence: "high",
    uncertainty: null,
  };
}

function isRecentEnough(publishedAt: string | null, recencyDays: number): boolean {
  const publishedMs = parsePublishedAtToMs(publishedAt);
  if (publishedMs === null) {
    return false;
  }

  const maxAgeMs = recencyDays * 24 * 60 * 60 * 1000;
  return Date.now() - publishedMs <= maxAgeMs;
}

function parsePublishedAtToMs(value: string | null): number | null {
  if (!value) {
    return null;
  }

  const direct = Date.parse(value);
  if (Number.isFinite(direct)) {
    return direct;
  }

  const trimmed = value.trim().toLowerCase();
  if (trimmed === "yesterday") {
    return Date.now() - 24 * 60 * 60 * 1000;
  }

  const agoMatch = trimmed.match(/(\d+)\s+(minute|hour|day|week|month|year)s?\s+ago/);
  if (!agoMatch) {
    return null;
  }

  const valueNum = Number(agoMatch[1]);
  const unit = agoMatch[2];
  const unitMs =
    unit === "minute"
      ? 60 * 1000
      : unit === "hour"
      ? 60 * 60 * 1000
      : unit === "day"
      ? 24 * 60 * 60 * 1000
      : unit === "week"
      ? 7 * 24 * 60 * 60 * 1000
      : unit === "month"
      ? 30 * 24 * 60 * 60 * 1000
      : 365 * 24 * 60 * 60 * 1000;

  return Date.now() - valueNum * unitMs;
}
