# Context Anti-Patterns

Failure modes in context engineering. Use this to diagnose degraded agent
performance before assuming the model is at fault.

## Context Rot

**Symptom:** Agent references outdated information or contradicts recent changes.

**Cause:** Cached context (system prompts, reference docs, few-shot examples)
becomes stale as the codebase or domain evolves.

**Fix:**
- Version context artifacts alongside code
- Invalidate caches when underlying sources change
- Include "last verified" dates in reference documents
- Prefer dynamic retrieval over static embedding for fast-moving domains

## Context Poisoning

**Symptom:** Agent confidently produces wrong answers, citing "information"
that doesn't exist in any source.

**Cause:** Hallucinated content from a previous turn re-enters context
(via scratchpads, memory writes, or summarization) and becomes
self-reinforcing. The hallucination becomes "ground truth."

**Fix:**
- Validate agent-written artifacts before re-ingesting them
- Cross-reference agent summaries against source material
- Use deterministic graders (code execution, exact match) over
  LLM-as-judge for factual claims
- Don't let agents edit their own system prompts or memory without review

## Context Distraction

**Symptom:** Agent ignores key instructions or produces unfocused output.

**Cause:** Irrelevant bulk in the context window dilutes signal.
The model's attention spreads across noise instead of concentrating on
the task. Common with "kitchen sink" system prompts.

**Fix:**
- Measure signal density: what percentage of context is relevant to *this* task?
- Load references just-in-time, not all-at-once
- Progressive disclosure: summary → detail on demand
- Remove completed task context before starting new tasks

**Empirical signal:** Performance degrades when context exceeds ~60% of
window capacity, even if the relevant information is present. Less
context with higher relevance beats more context with lower relevance.

## Context Confusion

**Symptom:** Agent oscillates between contradictory behaviors or
picks the wrong instruction from competing directives.

**Cause:** Multiple instruction sources give conflicting guidance.
Common when system prompt, tool descriptions, and reference docs
were written by different people at different times.

**Fix:**
- Single source of truth per concern (don't define output format
  in system prompt AND tool description AND reference doc)
- Explicit precedence: "If instructions conflict, prefer [X]"
- Audit all instruction sources as a unit, not individually
- Test with the full assembled context, not isolated pieces

## Context Clash

**Symptom:** Agent makes contradictory tool calls or flip-flops
between approaches within a single turn.

**Cause:** Tool results return conflicting information (e.g., two
APIs disagree on current state) and the agent has no resolution strategy.

**Fix:**
- Design tools to return consistent, timestamped data
- Add a "source of truth" hierarchy when multiple tools cover same domain
- Include conflict resolution instructions in the system prompt
- Prefer single authoritative tools over multiple overlapping ones

## Over-Compression in High-Stakes Domains

**Symptom:** Agent makes correct decisions in testing but misses
critical details in production.

**Cause:** Aggressive context compression discards details that
seemed redundant but were actually load-bearing (edge cases, error
conditions, compliance requirements).

**Fix:**
- Domain-aware compression: flag security, compliance, and financial
  content as "never compress"
- Preserve all error messages and failure modes verbatim
- Test with compressed context, not just full context
- Graduated compression: summarize general content aggressively,
  domain-critical content conservatively

## Encyclopedia CLAUDE.md

**Symptom:** Agent forgets or ignores instructions that are clearly
present in CLAUDE.md.

**Cause:** CLAUDE.md exceeds ~200 meaningful lines. Instruction density
drops, model attention disperses, and later instructions compete with
earlier ones for influence.

**Fix:**
- CLAUDE.md is a routing table, not an encyclopedia
- Keep body under 200 lines; defer to reference files
- Front-load identity and high-frequency instructions
- Audit: is every line exercised weekly? If not, demote to reference
- Use progressive disclosure: body → references → sub-references

## Eval-Prompt Drift

**Symptom:** Evals pass but production quality degrades, or vice versa.

**Cause:** The prompt used in evals diverges from the prompt used in
production. Someone updates one but not the other.

**Fix:**
- Single source for prompt text, imported by both eval and production
- CI check that eval context matches production context
- Include "context fingerprint" (hash of assembled prompt) in logs
- Test evals against the full production context assembly, including
  tool descriptions and reference loading
