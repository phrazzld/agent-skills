---
name: agentic-ui-contract
user-invocable: false
description: |
  Design and implement agentic product flows using the contract:
  model decides what to do, tools decide how it is done, UI schema decides
  how it is rendered. Use for chat-first apps, tool-calling agents,
  generative UI systems, and planner/tool architecture decisions.
  Keywords: agentic UX, tool calling, planner, generative UI, function tools.
---

# Agentic UI Contract

Use this when building or refactoring toward agentic product behavior.

## Core Contract

1. Model decides WHAT to do.
2. Tools decide HOW it is done.
3. UI schema decides HOW it is rendered.

This gives open-ended behavior without fragile freeform execution.

## Architecture Shape

- Planner layer (LLM): intent interpretation + tool selection + sequencing.
- Tool layer (deterministic): typed side effects and data reads.
- UI contract layer (typed blocks): constrained rendering catalog.
- Control layer: auth, guardrails, tracing, evals, fallback.

## Rules

- Never let model write directly to persistence.
- Never trust model-generated metrics; compute metrics deterministically.
- Keep tool interfaces deep (few, meaningful tools), avoid tiny tool explosions.
- Keep UI blocks strict and versionable.
- Treat planner failure as recoverable; fallback to deterministic behavior.

## Implementation Workflow

1. Define typed block schema first.
2. Define deep tool surface second.
3. Implement server planner tool loop third.
4. Keep client thin: send messages, render blocks, apply client actions.
5. Add traces and eval fixtures before widening scope.

## Multi-Turn Conversation (CRITICAL)

The model needs structured memory of what tools ran and what they returned.
Without this, subsequent turns re-execute previous tool calls.

### The Pattern (AI SDK)

```typescript
import { type ModelMessage } from 'ai';

let messages: ModelMessage[] = [];

// User sends message
messages.push({ role: 'user', content: userText });

// Model processes, calls tools, generates response
const result = await streamText({ model, tools, messages });
const response = await result.response;

// Append ALL response messages — includes tool-call + tool-result parts
messages.push(...response.messages);

// Next turn: model sees full tool interaction history
```

### Anti-Patterns

- Flattening conversation to `{role, content: string}` pairs — destroys tool context.
- Suppressing assistant text after tool calls — removes the only context the model
  has about what happened (when tool results aren't in history).
- Storing "display text" as "conversation text" — these serve different purposes.
  Display can be empty; conversation history must be rich.
- Rebuilding tool context from UI state — fragile, partial, wrong layer.

### Rules

- Conversation state = `ModelMessage[]`, not simplified strings.
- `response.messages` is the source of truth for what happened in a turn.
- Never suppress, truncate, or flatten tool results in conversation history.
- Display concerns (hiding text, showing blocks) are UI-layer decisions.
  Never let display logic affect what the model sees on subsequent turns.

## Readiness Checklist

- [ ] Tool args validated with schema.
- [ ] Tool outputs deterministic and structured.
- [ ] Planner cannot bypass tools for data claims.
- [ ] UI renders only whitelisted block types.
- [ ] Planner + tool traces available per turn.
- [ ] Deterministic fallback path exists.
- [ ] Conversation history preserves tool-call and tool-result message parts.
- [ ] Assistant text is not suppressed or flattened for model context.
- [ ] Multi-turn tool context: model can reference previous tool results.

## Anti-Patterns

- Regex parser as primary intelligence layer.
- Model directly composing arbitrary UI markup/components.
- Over-fragmented tools that mirror internal implementation.
- Allowing model narration to replace data tool calls.
- No eval harness for prompt/tool regressions.
- Adding deterministic NLP/parsing libraries when the LLM already handles the task
  (e.g., chrono-node for time parsing when the agent can infer "last week" from context).
- Pre-computing fixed insight categories when the LLM can reason over rich data.
- Building classifiers, entity extractors, or intent parsers alongside an LLM agent.

## The Capability Test

Before proposing any new feature for an agentic product:

> "Does the application already have an LLM in the loop that can do this?"

If yes: improve the prompt, expand tool data access, or add a tool parameter.
If no: write code.

**Model territory:** intent parsing, NL understanding, synthesis, insight generation,
flexible input interpretation — anything where the value IS the intelligence.

**Code territory:** data access, metrics computation, schema validation, security,
rendering, mechanical operations — anything requiring correctness guarantees.

