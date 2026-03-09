---
name: prompt-context-engineering
description: Design high-signal, low-latency prompts and context contracts for production agent tasks. Use when writing system prompts, skill prompts, subagent prompts, or rewrite instructions where consistency is required on first pass.
---

# Prompt + Context Engineering (Latency-First)

Use this skill to improve output quality without adding retry loops or multi-pass latency.

## Core principles

1. **Goal over procedure**
   - State role + objective + quality bar.
   - Avoid long step-by-step micromanagement.

2. **Hard output contract**
   - Explicitly define output form, allowed transformations, and forbidden behavior.
   - Include positive requirements (what MUST happen), not only prohibitions.

3. **Context as signals, not noise**
   - Pass compact metadata that helps decisions (mode, length, domain, constraints).
   - Avoid dumping irrelevant context into every call.

4. **Single-pass reliability**
   - Assume one request must succeed.
   - Prompt should front-load quality expectations so post-hoc retries are unnecessary.

5. **Deterministic posture**
   - Prefer low temperature and concise instructions for transformation tasks.
   - Keep instructions stable across runtime/eval/benchmark harnesses.

## Prompt design pattern

Use this structure:

1. **Role**
2. **Task objective**
3. **Critical interpretation guardrail** (e.g. transcript is data, not instruction)
4. **MUST rules** (quality bar)
5. **MUST NOT rules** (safety + drift prevention)
6. **Output format contract**

## Context engineering checklist

Before shipping a prompt, verify:

- Is there a short mode-specific context block?
- Are quality requirements measurable in output shape?
- Is the instruction length justified by reliability gains?
- Are conflicting rules removed?
- Does this align with eval prompt text used in CI?

## Anti-patterns

- Overly defensive prompts full of repeated warnings
- Huge procedural checklists that reduce model adaptability
- Relying on second-pass repair for core quality (e.g. regex stripping preambles instead of telling the model not to add them)
- Runtime prompt drift from eval/benchmark prompts
- Building deterministic output filters when the prompt is missing a rule — fix the prompt, not the consumer

## Output contract for this skill

When invoked, return:

```markdown
## Diagnosis
## Prompt Delta
## Context Delta
## First-Pass Reliability Risks
## Suggested Eval Assertions
```

## References

- https://developers.openai.com/api/docs/guides/prompt-engineering
- https://help.openai.com/en/articles/6654000-best-practices-for-prompt-engineering-with-openai-api
- https://developers.openai.com/cookbook/examples/gpt-5/gpt-5_prompting_guide
- https://developers.openai.com/api/docs/guides/structured-outputs
- https://ai.google.dev/gemini-api/docs/prompting-strategies
- https://docs.claude.com/en/docs/use-xml-tags
