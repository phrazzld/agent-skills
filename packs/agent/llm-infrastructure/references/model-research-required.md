# MODEL RESEARCH REQUIRED

**STOP. Your training data about LLM models is WRONG.**

This document must be read by Claude before ANY task involving LLM model selection, API integration, or AI feature implementation.

## The Problem

Claude's training data is months old. In that time:
- Models have been deprecated
- New SOTA models have been released
- Pricing has changed dramatically
- New capabilities have been added
- Model names have changed

**What you "know" about current models is almost certainly outdated.**

## MANDATORY Research Steps

Before writing ANY code that references LLM models:

### Step 1: Query Current OpenRouter Models

```bash
# Get current models from major providers (recommended default)
python3 ~/.claude/skills/llm-infrastructure/scripts/fetch-openrouter-models.py \
  --providers major --top 30

# Or filter to frontier models only (Anthropic, OpenAI, Google)
python3 ~/.claude/skills/llm-infrastructure/scripts/fetch-openrouter-models.py \
  --providers frontier --top 20

# Or focus on open-weight models (Meta, Mistral, DeepSeek, Qwen)
python3 ~/.claude/skills/llm-infrastructure/scripts/fetch-openrouter-models.py \
  --providers open --top 20

# Filter by task
python3 ~/.claude/skills/llm-infrastructure/scripts/fetch-openrouter-models.py \
  --providers major --task coding --top 15

python3 ~/.claude/skills/llm-infrastructure/scripts/fetch-openrouter-models.py \
  --providers major --task reasoning --top 10

# Custom filter with regex
python3 ~/.claude/skills/llm-infrastructure/scripts/fetch-openrouter-models.py \
  --filter "deepseek|qwen" --task coding --top 10
```

**Provider presets:**
| Preset | Providers |
|--------|-----------|
| `major` | anthropic, openai, google, meta, mistral, deepseek, qwen |
| `frontier` | anthropic, openai, google |
| `open` | meta, mistral, deepseek, qwen, nous, phind |
| `all` | no filter (default) |

### Step 2: Web Search for Current SOTA

Do a web search for:
- "best LLM models [current month] [current year]"
- "[specific task] LLM benchmark 2026" (coding, reasoning, etc.)
- "[provider] latest model deprecation" (for each provider you plan to use)

Cross-reference at least 2 sources.

### Step 3: Check Deprecation Status

For EVERY model you plan to use:
- Search: "[model name] deprecated"
- Search: "[model name] end of life"
- Verify the exact model ID string is still valid

## Use OpenRouter for Flexibility

**Default to OpenRouter** for all LLM integrations:
- Single API for 400+ models
- Easy to switch models without code changes
- Automatic fallbacks
- Unified cost tracking
- No vendor lock-in

```typescript
// OpenRouter endpoint
const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";

// Headers
const headers = {
  "Authorization": `Bearer ${process.env.OPENROUTER_API_KEY}`,
  "Content-Type": "application/json",
  "HTTP-Referer": "https://your-app.com",  // For tracking
};
```

## Model Selection Framework

After research, select based on:

| Task Type | Characteristics | Research Focus |
|-----------|-----------------|----------------|
| **Fast/cheap** | High volume, simple tasks | `--task fast`, search "cheapest LLM API" |
| **Reasoning** | Complex logic, math, planning | `--task reasoning`, search "o-series vs r1 vs qwq" |
| **Coding** | Code generation, completion | `--task coding`, search "SWE-bench leaderboard" |
| **Long context** | Large documents, codebase analysis | `--task long_context` |
| **Vision** | Image understanding | `--task vision`, search "multimodal LLM" |

## Environment Variables, Not Hardcoded

**NEVER hardcode model names in source code.**

```typescript
// BAD - will go stale
const model = "gpt-4";

// GOOD - configurable
const model = process.env.LLM_MODEL;

// BETTER - task-specific with defaults from research
const MODELS = {
  fast: process.env.LLM_MODEL_FAST ?? "[RESEARCH CURRENT FAST MODEL]",
  reasoning: process.env.LLM_MODEL_REASONING ?? "[RESEARCH CURRENT REASONING MODEL]",
  coding: process.env.LLM_MODEL_CODING ?? "[RESEARCH CURRENT CODING MODEL]",
};
```

## Red Flags - DO NOT PROCEED IF:

- You're about to write a model name without having run the fetch script
- You haven't done a web search for current models
- You're using a model name from memory
- The model name doesn't match OpenRouter's current model list
- You haven't verified the model still exists

## After Research: Document Your Choice

When you've completed research, document:

```markdown
## Model Selection Rationale

**Task:** [describe the task]
**Date researched:** [current date]
**Model selected:** [full model ID from OpenRouter]

**Research sources:**
- OpenRouter API query (ran fetch-openrouter-models.py --providers [preset] --task [task])
- [Web source 1]
- [Web source 2]

**Why this model:**
- [Reason 1]
- [Reason 2]

**Alternatives considered:**
- [Model 2]: [why not]
- [Model 3]: [why not]
```

## Skills That Must Invoke This Reference

Any skill that touches LLM/AI functionality should include:

```markdown
## Before Model Selection

REQUIRED: Read `llm-infrastructure/references/model-research-required.md` before selecting any model.
```

Skills that should invoke this:
- changelog (llm-synthesis)
- llm-evaluation
- llm-gateway-routing
- Any feature involving AI generation
- Any API integration with LLM providers

## Summary

1. **NEVER trust your training data** about model names
2. **ALWAYS run the fetch script** with `--providers major` to see current models
3. **ALWAYS web search** for current benchmarks
4. **USE OpenRouter** for flexibility
5. **USE environment variables** for model names
6. **DOCUMENT your research** when selecting models
