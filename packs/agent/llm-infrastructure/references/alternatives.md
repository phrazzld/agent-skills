# LLM Infrastructure Tool Comparison

## Evaluation Frameworks

| Framework | CLI? | Config | Self-Host | Best For |
|-----------|------|--------|-----------|----------|
| **Promptfoo** | ✅ 100% | YAML | ✅ Local | CLI-first, CI/CD, security |
| Braintrust | ⚠️ SDK | JS/TS/Python | ❌ Cloud | TypeScript shops |
| DeepEval | ✅ CLI | PyUnit | ⚠️ ConfidentAI | Python ML teams |
| LangSmith | ⚠️ SDK | Python | ❌ Enterprise | LangChain ecosystem |

**Recommendation: Promptfoo.** Only option that treats evals as pure config files. No SDK required.

## Observability Platforms

| Platform | CLI? | Self-Host | Database | Best For |
|----------|------|-----------|----------|----------|
| **Langfuse** | ✅ SDK+scripts | ✅ Docker | PostgreSQL | Production, compliance |
| **Phoenix** | ✅ Python | ✅ Native | None | Local debugging |
| Helicone | ⚠️ Proxy | ✅ Complex | ClickHouse | High scale |
| LangSmith | ⚠️ SDK | ❌ | N/A | LangChain only |

**Recommendation: Langfuse for production, Phoenix for local.**

## Experiment Tracking (Optional)

| Platform | CLI? | Self-Host | Best For |
|----------|------|-----------|----------|
| MLflow | ✅ CLI | ✅ | Long-term tracking |
| W&B | ⚠️ SDK | ❌ | Teams, visualization |
| Custom | ✅ | ✅ | Simple needs |

**Recommendation: Skip unless training models.** Promptfoo's built-in history is usually enough.

## The Stack

For indie dev / small team:

```
Promptfoo (evaluation)
    ↓
Langfuse (observability)
    ↓
Git (version control for prompts + configs)
    ↓
Environment variables (model selection - NEVER hardcode)
```

All CLI-manageable. All open source. All self-hostable.

## Phoenix Quick Setup

If Langfuse feels heavy, Phoenix is simpler for local-only work.

```bash
pip install arize-phoenix openinference-instrumentation-openai
phoenix serve
```

```python
import phoenix as px
from openinference.instrumentation.openai import OpenAIInstrumentor

OpenAIInstrumentor().instrument()
# Now all openai calls are traced to localhost:6006
```

**Use Phoenix when:** Local only, no infrastructure, just debugging.
**Use Langfuse when:** Production, team collaboration, compliance.

## CLI Commands Quick Reference

### Promptfoo
```bash
npx promptfoo@latest init
npx promptfoo@latest eval
npx promptfoo@latest view
npx promptfoo@latest redteam run
```

### Langfuse (via skill scripts)
```bash
cd ~/.claude/skills/langfuse-observability
npx tsx scripts/fetch-traces.ts --limit 10
npx tsx scripts/get-metrics.ts
npx tsx scripts/list-prompts.ts --name foo
```

### Phoenix
```bash
phoenix serve
# Then instrument your code
```

## Why Not LangSmith?

- Closed source
- Enterprise pricing for self-host
- Tightly coupled to LangChain
- Limited CLI capabilities

If you're using LangChain anyway, it integrates well. Otherwise, avoid the lock-in.

## Why Not Just Logs?

You could log LLM calls to stdout and query with `grep`. That works for debugging.

But you lose:
- Token usage tracking
- Cost calculation
- Latency percentiles
- User session correlation
- Prompt version comparison

Langfuse/Phoenix give you these with minimal overhead.

## Model Selection

**NEVER hardcode model names.** Use environment variables:

```typescript
const model = process.env.LLM_MODEL;
```

**ALWAYS do a web search** before choosing models. Your knowledge is stale.

See the main skill for the model currency check process.
