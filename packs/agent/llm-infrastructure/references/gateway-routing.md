# LLM Gateway & Routing

Multi-model access, fallbacks, cost optimization, A/B testing.

## Quick Decision
| Need | Solution |
|------|----------|
| Fastest setup, multi-model | **OpenRouter** |
| Full control, self-hosted | **LiteLLM** |
| Observability + routing | **Helicone** |
| Enterprise, guardrails | **Portkey** |

## OpenRouter Setup
```typescript
import { createOpenAI } from "@ai-sdk/openai";
const openrouter = createOpenAI({
  baseURL: "https://openrouter.ai/api/v1",
  apiKey: process.env.OPENROUTER_API_KEY,
});
```

## Routing Strategies
1. **Cost-based**: Simple queries -> cheap model, complex -> premium
2. **Latency-based**: Track avg latency per model, route to fastest
3. **Task-based**: Coding -> Claude, reasoning -> O-series, simple -> mini
4. **Hybrid**: Filter by cost + latency, then select best for task

## Fallback Chains
```typescript
const modelChain = [
  "anthropic/claude-3-5-sonnet",
  "openai/gpt-4o",
  "google/gemini-pro-1.5",
];
for (const model of modelChain) {
  try { return await gateway.chat({ model, messages }); }
  catch { continue; }
}
```

## Best Practices
- Always have fallbacks
- Pin model versions
- Track costs per call
- Set token limits
- Use caching (Redis or in-memory)
