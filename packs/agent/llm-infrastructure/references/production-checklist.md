# Production Readiness

## Cost Optimization

**Model Routing** (small → large):
```typescript
async function routeToModel(query: string) {
  const complexity = analyzeComplexity(query);

  if (complexity === 'simple') {
    return "gpt-4o-mini"; // $0.15 per 1M tokens
  } else if (complexity === 'medium') {
    return "gemini-2.5-flash"; // $0.17 per 1M tokens
  } else {
    return "claude-sonnet-4.5"; // $3 per 1M tokens
  }
}
```

**Token Limits**:
```typescript
const config = {
  max_tokens: 500, // Don't let model ramble
  temperature: 0.7,
  top_p: 0.9
};
```

**Result**: $100/month → $20/month typical optimization

## Error Handling

**Retry with Exponential Backoff**:
```typescript
async function callWithRetry(fn, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (error.status === 429) { // Rate limit
        await sleep(Math.pow(2, i) * 1000);
      } else if (error.status >= 500) { // Server error
        await sleep(1000);
      } else {
        throw error; // Don't retry client errors
      }
    }
  }
  throw new Error('Max retries exceeded');
}
```

**Fallback Models**:
```typescript
const fallbackChain = [
  "anthropic/claude-sonnet-4.5",
  "openai/gpt-5",
  "google/gemini-2.5-pro"
];

for (const model of fallbackChain) {
  try {
    return await llm.complete({ model, messages });
  } catch (error) {
    console.log(`${model} failed, trying next...`);
  }
}
```

## Security

**Input Sanitization**:
```typescript
function sanitizeInput(userInput: string): string {
  return userInput
    .replace(/<\|im_start\|>|<\|im_end\|>/g, '')
    .replace(/\[SYSTEM\]|\[\/SYSTEM\]/gi, '')
    .trim();
}
```

**Output Validation**:
```typescript
function validateOutput(response: string): boolean {
  const piiPatterns = [/\b\d{3}-\d{2}-\d{4}\b/, /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i];
  return !piiPatterns.some(pattern => pattern.test(response));
}
```

**Rate Limiting**:
```typescript
const limiter = new RateLimiter({
  tokensPerInterval: 100,
  interval: 'hour'
});

await limiter.removeTokens(1);
```

## Observability

**Minimal setup** (OpenTelemetry + logging):
```typescript
import { trace } from '@opentelemetry/api';

async function tracedLLMCall(messages) {
  const span = trace.getTracer('llm').startSpan('llm.complete');

  const startTime = Date.now();
  try {
    const response = await llm.complete(messages);

    span.setAttributes({
      'llm.model': response.model,
      'llm.input_tokens': response.usage.prompt_tokens,
      'llm.output_tokens': response.usage.completion_tokens,
      'llm.latency_ms': Date.now() - startTime,
      'llm.cost_usd': calculateCost(response.usage)
    });

    return response;
  } finally {
    span.end();
  }
}
```

**What to log**:
```typescript
{
  timestamp: new Date().toISOString(),
  model: "claude-sonnet-4.5",
  prompt_tokens: 150,
  completion_tokens: 200,
  total_tokens: 350,
  cost_usd: 0.00105,
  latency_ms: 1234,
  user_id: "user_123",
  success: true,
  error: null
}
```

**Alerts to set**:
- Cost spike: >2x daily average
- Error rate: >5% of requests
- Latency: p95 >5 seconds
- Token usage: Approaching rate limits

## Evaluation & Testing

### LLM-as-Judge

**Implementation**:
```typescript
const judgePrompt = `
Evaluate the response on these criteria:
1. Accuracy - Is information factually correct?
2. Relevance - Does it answer the question?
3. Completeness - Are all aspects addressed?
4. Clarity - Is it easy to understand?

Rate each 1-10 and provide brief justification.

Question: ${question}
Response: ${response}
`;

const judgment = await llm.complete(judgePrompt, {
  response_format: { type: "json_schema", schema: ratingSchema }
});
```

### Testing Strategy

1. **Create test dataset**: Representative samples covering edge cases
2. **Define success metrics**: Quantitative + qualitative
3. **Automated scoring**: LLM-as-judge for scale
4. **A/B test prompts**: Compare variations side-by-side
5. **Monitor production**: Sample real traffic

## Production Deployment Checklist

**Before Launch**:
- [ ] Prompt caching enabled for static content
- [ ] Structured outputs for critical responses
- [ ] Error handling: retries, fallbacks, circuit breaker
- [ ] Rate limiting per user
- [ ] Input sanitization and output validation
- [ ] Cost tracking and alerts configured
- [ ] Logging/observability in place
- [ ] Test dataset with success metrics defined
- [ ] A/B testing infrastructure ready

**Post-Launch**:
- [ ] Monitor latency (p50, p95, p99)
- [ ] Track cost per user/request
- [ ] Sample evaluation on production traffic
- [ ] Alert thresholds configured (cost, errors, latency)
- [ ] Iteration plan based on metrics

## Prompt Caching Economics

**Stable prefix design:**
- Place system prompt and reference docs at the start (cacheable)
- Append-only conversation history after cached prefix
- Never insert dynamic content (timestamps, IDs) into cached prefix

**Cache-aware context placement:**
```
[System instructions — 2K tokens]    ← CACHED (stable across requests)
[Reference docs — 8K tokens]        ← CACHED (stable across session)
[Conversation history — variable]   ← NOT CACHED (changes each turn)
[Current query]                     ← NOT CACHED
```

**Economics:**
- Cache write: ~25% premium on first request
- Cache read: ~90% discount on subsequent requests
- Typical hit rates: 80-92% for well-designed prefixes
- Net cost reduction: 60-90% achievable for conversation workloads
- Break-even on 2nd request; ROI compounds with every hit

**Anti-pattern:** Varying system prompt content between requests (user-specific
customization in the cached prefix) — this busts the cache.

## Progressive Autonomy Checklist

Before granting an agent more autonomy, verify:

**HITL → HOTL (human monitors, agent acts):**
- [ ] Agent succeeds >90% on eval suite for this task type
- [ ] All failure modes identified and documented
- [ ] Monitoring dashboards show agent behavior in real-time
- [ ] Alert thresholds configured for anomalous behavior
- [ ] Human can intervene within [defined SLA]

**HOTL → HOOL (fully autonomous):**
- [ ] Agent succeeds >95% on eval suite
- [ ] Failure modes are all recoverable (no catastrophic failures)
- [ ] Automated rollback mechanism exists
- [ ] Cost bounds enforced (per-request and per-day caps)
- [ ] Audit trail captures all autonomous decisions
- [ ] Regular eval refresh prevents capability regression

## Error Feedback Pattern

When a tool call or operation fails, feed the error back to the LLM for
reformulation — don't blindly retry the same call.

```typescript
async function executeWithFeedback(agent, task, maxAttempts = 3) {
  let context = task;
  for (let i = 0; i < maxAttempts; i++) {
    const action = await agent.plan(context);
    const result = await execute(action);

    if (result.success) return result;

    // Feed error back to agent for reformulation
    context = {
      ...task,
      previousAttempt: action,
      error: result.error,
      instruction: "The previous approach failed. Analyze the error and try a different strategy."
    };
  }
  throw new Error('Agent exhausted retry budget');
}
```

**Key distinction:** Retry = same action again. Feedback = inform agent of
failure so it can adapt. Feedback >> retry for agents.
