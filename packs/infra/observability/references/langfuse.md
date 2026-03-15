# Langfuse Observability

Query traces, prompts, and metrics from Langfuse. Requires env vars:
- `LANGFUSE_SECRET_KEY`
- `LANGFUSE_PUBLIC_KEY`
- `LANGFUSE_HOST` (e.g., `https://us.cloud.langfuse.com`)

## Quick Start

### List Recent Traces
```bash
npx tsx scripts/fetch-traces.ts --limit 10
npx tsx scripts/fetch-traces.ts --name "quiz-generation" --limit 5
npx tsx scripts/fetch-traces.ts --user-id "user_abc123" --limit 10
```

### Get Single Trace Details
```bash
npx tsx scripts/fetch-trace.ts <trace-id>
```

### Get Prompt
```bash
npx tsx scripts/list-prompts.ts --name scry-intent-extraction
npx tsx scripts/list-prompts.ts --name scry-intent-extraction --label production
```

### Get Metrics Summary
```bash
npx tsx scripts/get-metrics.ts --limit 50
npx tsx scripts/get-metrics.ts --name "quiz-generation" --limit 100
```

## Output Formats

All scripts output JSON to stdout.

### Trace List Output
```json
[
  {
    "id": "trace-abc123",
    "name": "quiz-generation",
    "userId": "user_xyz",
    "input": {"prompt": "..."},
    "output": {"concepts": [...]},
    "latencyMs": 3200,
    "createdAt": "2025-12-09T..."
  }
]
```

### Metrics Output
```json
{
  "totalTraces": 50,
  "successCount": 48,
  "errorCount": 2,
  "avgLatencyMs": 2850,
  "totalTokens": 125000,
  "byName": {"quiz-generation": 30, "phrasing-generation": 20}
}
```

## Common Workflows

### Debug Failed Generation
```bash
npx tsx scripts/fetch-traces.ts --limit 10
npx tsx scripts/fetch-trace.ts <trace-id>
```

### Monitor Token Usage
```bash
npx tsx scripts/get-metrics.ts --limit 100
```

## Cost Tracking

### Calculate Costs

```typescript
const pricing = {
  "claude-3-5-sonnet": { input: 3.0, output: 15.0 },
  "gpt-4o": { input: 2.5, output: 10.0 },
  "gpt-4o-mini": { input: 0.15, output: 0.6 },
};

function calculateCost(model: string, inputTokens: number, outputTokens: number) {
  const p = pricing[model] || { input: 1, output: 1 };
  return (inputTokens * p.input + outputTokens * p.output) / 1_000_000;
}
```

## Production Best Practices

### 1. Trace Everything

```typescript
import { Langfuse } from "langfuse";

const langfuse = new Langfuse({
  publicKey: process.env.LANGFUSE_PUBLIC_KEY,
  secretKey: process.env.LANGFUSE_SECRET_KEY,
});

async function tracedLLMCall(name: string, messages: Message[]) {
  const trace = langfuse.trace({
    name,
    userId: currentUser.id,
    metadata: { environment: process.env.NODE_ENV },
  });

  const generation = trace.generation({
    name: "chat",
    model: selectedModel,
    input: messages,
  });

  try {
    const response = await llm.chat({ model: selectedModel, messages });
    generation.end({
      output: response.choices[0].message,
      usage: {
        promptTokens: response.usage.prompt_tokens,
        completionTokens: response.usage.completion_tokens,
      },
    });
    return response;
  } catch (error) {
    generation.end({ level: "ERROR", statusMessage: error.message });
    throw error;
  }
}
```

### 2. Add Context

```typescript
const trace = langfuse.trace({
  name: "user-query",
  userId: user.id,
  sessionId: session.id,
  metadata: { userPlan: user.plan, feature: "chat", version: "v2.1" },
  tags: ["production", "chat-feature"],
});
```

### 3. Score Outputs

```typescript
generation.score({ name: "user-feedback", value: userRating });
generation.score({ name: "response-length", value: response.content.length < 500 ? 1 : 0 });
```

### 4. Flush Before Exit

```typescript
await langfuse.flushAsync();
```

## Promptfoo Integration

### Trace to Eval Case Workflow

1. Find interesting traces in Langfuse (failures, edge cases)
2. Export as test cases for Promptfoo
3. Add to regression suite

### Langfuse Callback in Promptfoo

```yaml
# promptfooconfig.yaml
defaultTest:
  options:
    callback: langfuse
    callbackConfig:
      publicKey: ${LANGFUSE_PUBLIC_KEY}
      secretKey: ${LANGFUSE_SECRET_KEY}
```

## Alternatives Comparison

| Feature | Langfuse | Helicone | LangSmith |
|---------|----------|----------|-----------|
| Open Source | Yes | Yes | No |
| Self-Host | Yes | Yes | No |
| Free Tier | Generous | 10K/mo | Limited |
| Prompt Mgmt | Yes | No | Yes |
| Tracing | Yes | Yes | Yes |

**Choose Langfuse when**: Self-hosting needed, cost-conscious, want prompt management.
**Choose Helicone when**: Proxy-based setup preferred, simple integration.
**Choose LangSmith when**: LangChain ecosystem, enterprise support needed.
