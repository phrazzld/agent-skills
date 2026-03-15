---
name: llm-infrastructure
description: |
  Audit and maintain LLM-powered features. Model currency, prompt quality, evals,
  gateway routing, observability, CI/CD. Ensures all AI features follow best practices.
  CRITICAL: Training data lags months. ALWAYS web search before LLM decisions.
argument-hint: "[focus area, e.g. 'models' or 'evals' or 'prompts' or 'routing']"
---

# /llm-infrastructure

Rigorous audit of all LLM-powered features. Model currency, prompt quality, eval coverage, gateway routing, observability, CI/CD integration -- every time.

## Philosophy

**Models go stale FAST.** What was SOTA 6 months ago is legacy today. Always web search.

**Prompts are code.** Version control, testing, review, documentation.

**Evals are tests.** Ship prompts without evals = shipping untested code.

**Observe everything.** Every LLM call should be traceable.

**Default to OpenRouter + Langfuse.** OpenRouter gives cheap routing and observability-friendly metadata. Langfuse gives prompt, trace, and cost visibility.

**Don't tweak in the dark.** Review real traces before changing prompts, tools, or skills.

## Process

### 1. Audit

#### Model Currency Check

**CRITICAL: Do not trust your training data about model names.**

**Step 1:** ALWAYS invoke `/research web-search` before making model recommendations. Training data lags months behind releases. Web search current SOTA models for each provider in your codebase.
**Step 2:** Scan codebase for ALL model references:
```bash
grep -rE "(gpt-|claude-|gemini-|llama-|mistral-|deepseek-)" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" \
  --include="*.yaml" --include="*.yml" --include="*.json" --include="*.env*" \
  . 2>/dev/null | grep -v node_modules
```
**Step 3:** Verify EACH model against web search results.
**Step 4:** Determine correct models for each use case (fast, reasoning, coding, long context).

#### Prompt Quality Audit

Reference `context-engineering` principles. Key patterns:
- Role + Objective + Latitude pattern
- Goal-oriented, not step-prescriptive
- Trust the model to figure out how

Anti-patterns: over-prescriptive steps, excessive hand-holding, defensive over-specification.

#### Agent Security Posture
- Agent security posture (see `references/agent-security.md`)

#### Eval Coverage Audit

Check for promptfoo config, test cases, security tests, red team config.

#### Gateway & Routing Audit

If using a gateway (OpenRouter, LiteLLM):
- Verify supported parameters per model
- Check fallback chains configured
- Confirm cost tracking active
- Validate model version pinning

Prefer OpenRouter by default unless there is a clear reason not to.

#### Observability Audit

Check for tracing (Langfuse, Phoenix), user ID attachment, token usage capture.

#### Trace Review Loop

Run a few representative tasks, then inspect real traces:
- Read prompts actually sent in production/dev
- Look for irrelevant prompt bulk, repeated warnings, and dead instructions
- Review tool calls, latency, failure paths, and reasoning metadata if available
- Promote interesting failures/confusions into eval cases

### 2. Plan

**Critical:** Deprecated models, mismatched models, no evals, severe prompt anti-patterns.
**High:** Missing red team tests, incomplete eval coverage, no CI gate, no tracing.
**Medium:** Missing documentation, hardcoded model strings.

### 3. Execute

Update models (env vars, not hardcoded), rewrite poor prompts, create eval suite, add observability, add CI gate, and trim irrelevant prompt jank found in traces.

### 4. Verify

Run full eval suite, security scan, verify tracing, verify CI gate triggers.

## References

| Focus | Reference | Content |
|-------|-----------|---------|
| Models | `references/model-research-required.md` | MANDATORY before any model recommendation |
| Models | `references/model-selection.md` | Framework and decision tree |
| Models | `references/model-verification-hook.md` | Pre-commit hook for model currency |
| Architecture | `references/architecture-patterns.md` | Complexity ladder, RAG, tool use, caching, harness engineering |
| Production | `references/production-checklist.md` | Cost, security, observability, caching economics, autonomy checklist |
| Evaluation | `references/evaluation.md` | Promptfoo setup, agent evals, grader hierarchy, saturation |
| Security | `references/agent-security.md` | Lethal trifecta, 6 defense patterns, guardrails |
| Tools | `references/tool-design.md` | Poka-yoke design, semantic returns, tool eval |
| Multi-Agent | `references/multi-agent-patterns.md` | Workflow patterns, state management, when NOT to |
| Prompts | `references/prompt-audit-checklist.md` | Audit process and severity levels |
| Routing | `references/gateway-routing.md` | OpenRouter, LiteLLM, routing strategies |
| Observability | `references/trace-review-loop.md` | Langfuse trace review process |
| Alternatives | `references/alternatives.md` | Framework and platform comparison |

> For prompt/context quality principles, see `context-engineering` skill.
