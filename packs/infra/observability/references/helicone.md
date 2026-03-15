# Helicone Observability

Route LLM API calls through Helicone for cost tracking, latency monitoring, and per-user attribution across all products.

## Architecture

```
App → Helicone Gateway (proxy) → LLM Provider (Anthropic, OpenAI, etc.)
                ↓
    Helicone Dashboard (cost, latency, properties)
```

Helicone is a transparent proxy. One URL + header change per provider. No SDK lock-in.

## Multi-Product Strategy

Helicone has ONE dashboard per account. Segmentation is via custom properties, not separate projects.

**Mandatory properties for every LLM call:**

| Header | Purpose | Example |
|--------|---------|---------|
| `Helicone-Property-Product` | Which product/repo | `moneta`, `adminifi`, `vox` |
| `Helicone-Property-Environment` | Deploy stage | `production`, `staging`, `development` |
| `Helicone-Property-Feature` | What triggered the call | `chat`, `upload`, `classification` |
| `Helicone-User-Id` | Per-user cost attribution | User ID from auth |

**Optional properties (add as needed):**

| Header | Purpose |
|--------|---------|
| `Helicone-Session-Id` | Group multi-turn conversations |
| `Helicone-Session-Path` | Hierarchical session path |
| `Helicone-Property-Model` | Override for model routing analysis |
| `Helicone-Property-TaxYear` | Domain-specific segmentation |

## Integration: Vercel AI SDK + Anthropic

### Provider Setup

```typescript
// lib/ai-provider.ts
import { createAnthropic } from "@ai-sdk/anthropic";

export const anthropic = createAnthropic({
  baseURL: "https://anthropic.helicone.ai/v1",
  headers: {
    "Helicone-Auth": `Bearer ${process.env.HELICONE_API_KEY}`,
    "Helicone-Property-Product": "your-product-name",
    "Helicone-Property-Environment": process.env.NODE_ENV ?? "development",
  },
});
```

### Per-Request Properties

```typescript
import { streamText } from "ai";
import { anthropic } from "@/lib/ai-provider";

const result = streamText({
  model: anthropic("claude-sonnet-4-6"),
  system: "...",
  messages,
  headers: {
    "Helicone-User-Id": userId,
    "Helicone-Property-Feature": "chat",
    "Helicone-Session-Id": conversationId,
    "Helicone-Session-Path": "/chat",
  },
});
```

### Other Providers

```typescript
// OpenAI
import { createOpenAI } from "@ai-sdk/openai";
const openai = createOpenAI({
  baseURL: "https://oai.helicone.ai/v1",
  headers: {
    "Helicone-Auth": `Bearer ${process.env.HELICONE_API_KEY}`,
    "Helicone-Property-Product": "your-product-name",
  },
});

// Google Gemini
import { createGoogleGenerativeAI } from "@ai-sdk/google";
const google = createGoogleGenerativeAI({
  baseURL: "https://gateway.helicone.ai/v1beta",
  headers: {
    "Helicone-Auth": `Bearer ${process.env.HELICONE_API_KEY}`,
    "Helicone-Target-URL": "https://generativelanguage.googleapis.com",
    "Helicone-Property-Product": "your-product-name",
  },
});
```

## Caching

Enable for deterministic prompts (system prompt caching, repeated queries):

```typescript
const anthropic = createAnthropic({
  baseURL: "https://anthropic.helicone.ai/v1",
  headers: {
    "Helicone-Auth": `Bearer ${process.env.HELICONE_API_KEY}`,
    "Helicone-Cache-Enabled": "true",
    "Cache-Control": "max-age=604800",
  },
});
```

Per-user cache isolation:
```typescript
headers: {
  "Helicone-Cache-Seed": userId,
}
```

## Environment Variables

```bash
HELICONE_API_KEY=sk-helicone-...
```

API key location: `~/.secrets` (line: `export HELICONE_API_KEY=...`)

## Pricing

| Tier | Requests/mo | Retention | Cost |
|------|-------------|-----------|------|
| Free | 10,000 | 1 month | $0 |
| Growth | Unlimited | 3 months | $20/seat/mo |
| Self-host | Unlimited | Unlimited | Infra cost |

## Audit Checklist

- [ ] `HELICONE_API_KEY` in `.env.local` and deployment env vars
- [ ] Provider `baseURL` points to Helicone gateway
- [ ] `Helicone-Auth` header on every provider
- [ ] `Helicone-Property-Product` set
- [ ] `Helicone-Property-Environment` set
- [ ] `Helicone-User-Id` passed on every user-facing request
- [ ] `Helicone-Property-Feature` distinguishes call types
- [ ] Requests visible in Helicone dashboard after deploy

## Anti-Patterns

- Setting only `Helicone-Auth` without custom properties (unsegmented noise)
- Using `Helicone-Property-*` in client-side code (leaks API key)
- Forgetting `Helicone-Property-Product` (can't distinguish products)
- Enabling cache for non-deterministic chat completions (stale responses)
- Hardcoding API keys instead of using env vars
