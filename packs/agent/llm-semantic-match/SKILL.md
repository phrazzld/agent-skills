---
name: llm-semantic-match
description: Use LLM sub-calls to resolve user intent to one item from a finite set. Replace all fuzzy/substring string matching in agent tools with this pattern.
---

# LLM-as-Semantic-Matcher

## When to Use

Any agent tool that maps user-provided text to one item from a known set:
- Exercise name → existing exercise library
- Product → catalog SKU
- Category label → taxonomy node
- Account name → customer record

## Why Not Fuzzy/Substring Matching

Deterministic matchers always fail on cases the author didn't anticipate. They have no semantic understanding:
- `"crunches".includes("run")` → false positive
- "bench" → "Bench Press", "Incline Bench", or "Decline Bench"? No right answer without context.

An LLM has semantic understanding. "ran 30 minutes" → it knows this is "Run", not "Crunches."

## Implementation Pattern

```typescript
// 1. Context carries an optional resolver (dependency injection)
interface ToolContext {
  resolveItem?: (query: string, candidates: Item[]) => Promise<Item | null>;
}

// 2. Tool uses it after exact match fails
async function ensureItem(ctx: ToolContext, name: string, items: Item[]) {
  const exact = items.find(i => normalize(i.name) === normalize(name));
  if (exact) return exact; // always try exact first (free)

  if (ctx.resolveItem) {
    const match = await ctx.resolveItem(name, items);
    if (match) return match;
  }

  return createItem(name); // no match → create new
}

// 3. Production: real LLM call
const resolveItem = async (query: string, candidates: Item[]): Promise<Item | null> => {
  const list = candidates.map(i => `"${i.name}"`).join(", ");
  const { text } = await generateText({
    model: fastModel,
    messages: [{ role: "user", content:
      `User described: "${query}"\nOptions: ${list}\n` +
      `Reply with ONLY the exact option name if it matches, or "none".`
    }]
  });
  const picked = text.trim().replace(/^["']|["']$/g, "");
  return picked.toLowerCase() === "none"
    ? null
    : candidates.find(i => i.name === picked) ?? null;
};

// 4. Tests: mock — no LLM calls
const ctx = { resolveItem: async () => null };
```

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Inject resolver, don't import | Testable; route handler owns the model |
| Exact match before LLM | Avoid token cost for the common case |
| Return `null` for no match | Better to create new than force a wrong match |
| Fast/cheap model | Simple constrained task; runs inline in tool call |
| Strip quotes from response | Models sometimes return `"Exercise Name"` |

## Prompt Template

```
User described: "${query}"
Existing options: ${list}
Reply with ONLY the exact option name from the list if it clearly matches (same concept, different spelling/abbreviation is fine). Reply "none" if no option is a good semantic match.
```

Keep it this short. Longer prompts cause the model to reason aloud instead of returning a clean answer.
