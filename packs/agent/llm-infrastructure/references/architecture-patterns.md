# AI Architecture Patterns

## Complexity Ladder (Start at Bottom)

```
1. Single LLM Call
   ↓ (only if single call insufficient)
2. Sequential LLM Calls (workflow)
   ↓ (only if static workflow insufficient)
3. LLM with Tools (function calling)
   ↓ (only if pre-defined tools insufficient)
4. Agentic System (LLM controls flow)
   ↓ (only if single agent insufficient)
5. Multi-Agent System

⚠️ 80% of use cases stop at level 1-2
```

**Rule**: Add complexity only when simpler approach fails

## RAG Pattern (Retrieval-Augmented Generation)

**Modern RAG Pipeline**:
```
1. Index: Store documents in Postgres with pgvector
2. Query: Convert user question to embedding
3. Search: Hybrid search (vector + keyword/BM25)
4. Re-rank: Cross-encoder for precision (optional but recommended)
5. Generate: LLM with retrieved context
```

**Postgres pgvector implementation**:
```sql
-- Create table with vector column
CREATE TABLE documents (
  id SERIAL PRIMARY KEY,
  content TEXT,
  embedding VECTOR(1536)
);

-- Create vector index
CREATE INDEX ON documents
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Hybrid search
SELECT id, content,
  (embedding <=> query_embedding) as vector_distance,
  ts_rank(to_tsvector(content), query) as keyword_rank
FROM documents
WHERE to_tsvector(content) @@ query
ORDER BY (vector_distance * 0.7 + (1 - keyword_rank) * 0.3)
LIMIT 10;
```

**Key insight**: Hybrid search (vector + keyword) outperforms pure vector similarity by 15-25%

## Tool Use / Function Calling

**Pattern**: LLM selects and calls functions dynamically

```typescript
const tools = [
  {
    name: "search_docs",
    description: "Search documentation for information",
    parameters: {
      query: { type: "string", description: "Search query" }
    }
  },
  {
    name: "create_ticket",
    description: "Create support ticket",
    parameters: {
      title: { type: "string" },
      priority: { type: "string", enum: ["low", "medium", "high"] }
    }
  }
];

const response = await llm.chat({
  messages,
  tools,
  tool_choice: "auto" // Let model decide
});

if (response.tool_calls) {
  for (const call of response.tool_calls) {
    const result = await executeTool(call.name, call.arguments);
    // Continue conversation with result
  }
}
```

**Best practices**:
- Clear, unambiguous tool descriptions
- Strict parameter validation
- Parallel tool calls when possible (3.7x speedup)
- Timeout and error handling for each tool

## Caching Strategy (Multi-Layer)

1. **Prompt caching**: System instructions, reference docs (60-90% cost reduction)
2. **Response caching**: Repeated/similar queries → stored answers (latency + cost)
3. **Embedding caching**: Cache computed embeddings for reuse (RAG workflows)

```typescript
// Response caching example
const cacheKey = hashPrompt(messages);
const cached = await cache.get(cacheKey);
if (cached && isFresh(cached)) return cached;

const response = await llm.complete(messages);
await cache.set(cacheKey, response, ttl: '15m');
return response;
```

## Vector Storage Decision Tree

```
How many vectors?
├─ <1M → Postgres pgvector (Neon) or Convex
├─ 1-10M → Postgres pgvector (Supabase/Neon)
├─ 10-50M → Postgres pgvectorscale extension
└─ >50M + <10ms latency → Dedicated (Qdrant, Weaviate, Milvus)

Already using Convex? → Use Convex vector search
Already using Postgres? → Add pgvector extension
Need ACID + vectors? → Postgres (only option)
```

## Opinionated Stack Defaults

### For TypeScript/Next.js Projects

**SDK**: Vercel AI SDK
- Streaming by default
- React hooks integration
- OpenAI-compatible (works with any provider)
- Built-in prompt caching support

**Model Provider**: OpenRouter
- Single API, 400+ models
- Test multiple providers easily
- No vendor lock-in
- Automatic fallbacks

**Vector Storage**: Postgres with pgvector
- Default choice for 95% of use cases
- Use Neon (serverless) or Supabase (full backend)
- $20-50/month typical cost

**Alternative vector storage**: Convex
- If already using for full-stack app
- Built-in vector indexes
- <1M vectors sweet spot

**Observability**: Langfuse (self-hosted) or simple logging

### Anti-Recommendations

❌ **LangChain** - Over-engineered, steep learning curve
❌ **Pinecone by default** - Expensive ($70-200+/month) when Postgres handles most needs
❌ **Building multi-agent systems first** - Start simple

## Harness Engineering

The paradigm where engineers design environments, and agents write code.

### CI/Linters/Tests as Agent Feedback Loops
Agents learn from automated feedback faster than human review:

```
Agent writes code → Pre-commit hooks → Type checker → Tests → CI
                    ↑                                        ↓
                    └──── Agent reads errors, self-corrects ←┘
```

**Design feedback for agent consumption:**
- Error messages should include file path, line number, and fix suggestion
- Test output should show expected vs actual, not just "FAIL"
- Lint rules should explain *why*, not just flag violations
- CI should surface the first meaningful error, not a cascade

### Documentation as Machine-Readable Artifacts
CLAUDE.md, AGENTS.md, and README files are not just for humans — they're
the primary configuration interface for coding agents.

**Design principles:**
- Structure with headers and lists (agents parse these efficiently)
- Include runnable commands (agents will execute them)
- State conventions as rules, not suggestions
- Keep current — stale docs cause agent errors

### Environment-as-Product
Treat the development environment (tooling, config, docs, CI) as a
product whose users are AI agents.

**Measure:** How many attempts does an agent need to complete a standard
task? If >1, improve the environment, not the agent's instructions.

### Session Management
- One feature per session (bounded scope)
- Session initialization: pwd, git status, progress file, feature registry
- Handoff artifacts: written notes for next session
- Define "done" before starting

### Dependency Layer Enforcement
Mechanical enforcement of architectural boundaries:
```
Types → Config → Repo → Service → Runtime → UI
  ↑ can import from left, ❌ cannot import from right
```

Structural tests or lint rules that fail when boundaries are violated
are more reliable than agent instructions about what not to import.
