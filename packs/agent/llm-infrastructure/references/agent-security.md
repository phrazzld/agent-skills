# Agent Security

Threat models and defense patterns for LLM-powered agents.

## The Lethal Trifecta (Simon Willison)

An agent becomes dangerous when it has all three:
1. **Access to private data** (databases, files, credentials)
2. **Ability to communicate externally** (email, API calls, Slack)
3. **Exposure to untrusted content** (user input, web pages, uploaded files)

**Any two of three is manageable.** All three creates prompt injection risk
where an attacker can exfiltrate private data through external channels.

**Design principle:** Remove one leg of the trifecta wherever possible.
If you can't, add defense-in-depth.

## Six Defense Patterns

### 1. Action-Selector
Hardcoded action whitelist. The LLM picks from enumerated options;
it cannot invent new actions.

```
User input → LLM → selects action from [A, B, C] → execute
```

**Use when:** Actions are finite and well-defined (routing, classification).
**Strength:** Immune to injection — attacker can't create new actions.
**Weakness:** Can't handle novel tasks.

### 2. Plan-Then-Execute
LLM creates a plan BEFORE seeing untrusted content. Plan is locked;
execution only follows plan steps.

```
Trusted context → LLM plans → Ingest untrusted data → Execute plan
```

**Use when:** Processing untrusted documents with pre-known tasks.
**Strength:** Untrusted content can't change the plan.
**Weakness:** Plan may be wrong if it depends on untrusted content.

### 3. Dual-LLM (Privileged / Quarantined)
Privileged LLM has access to tools and data. Quarantined LLM processes
untrusted content. They communicate through structured interfaces only.

```
Untrusted input → Quarantined LLM → structured output → Privileged LLM → tools
```

**Use when:** Must process untrusted content AND take privileged actions.
**Strength:** Untrusted content never touches privileged context.
**Weakness:** Complexity, latency, higher cost.

### 4. LLM Map-Reduce
Each document processed in isolation by a separate LLM call. Results
aggregated by code (not LLM). No cross-document context contamination.

```
[Doc1] → LLM₁ → Result₁ ─┐
[Doc2] → LLM₂ → Result₂ ──┤→ Code aggregator → Final result
[Doc3] → LLM₃ → Result₃ ─┘
```

**Use when:** Processing multiple untrusted documents.
**Strength:** One poisoned document can't affect others.
**Weakness:** Loses cross-document context.

### 5. Code-Then-Execute
LLM generates code/queries in a sandboxed DSL, not natural language
instructions. Code is executed in a sandbox.

```
User intent → LLM → generates SQL/code → sandbox executes → result
```

**Use when:** Task is expressible as code (data queries, transformations).
**Strength:** Sandbox limits blast radius. Code is auditable.
**Weakness:** Not all tasks are expressible as code.

### 6. Context-Minimization
Strip user prompt and unnecessary context before processing untrusted
content. The LLM operates with minimal, structured instructions only.

```
Rich context → extract structured query → minimal context + untrusted data → LLM
```

**Use when:** User prompt isn't needed during untrusted content processing.
**Strength:** Reduces attack surface for exfiltration.
**Weakness:** Loses nuance from original user intent.

## Input/Output Guardrails

Run evaluator agents concurrently with the main agent:

**Input guardrails:**
- Classify input before processing (topic, intent, safety)
- Reject out-of-scope requests before they consume compute
- Sanitize known injection patterns (role overrides, instruction ignoring)

**Output guardrails:**
- Scan responses for PII before returning to users
- Validate tool call parameters against safety policies
- Check generated code for dangerous patterns (eval, exec, system calls)

**Architecture:** Guardrails run as separate LLM calls with minimal,
focused prompts — not as part of the main agent's context (which an
attacker might manipulate).

## Tool Scope Boundaries

- Tools should have minimum necessary permissions
- Read-only tools by default; write tools require explicit grants
- Scope tools to specific resources (one database, one repo, one channel)
- Log all tool invocations with full parameters for audit
- Rate-limit tool calls to prevent resource exhaustion
- Separate tool credentials from agent credentials

## Prompt Injection Taxonomy

| Type | Vector | Mitigation |
|------|--------|------------|
| Direct | User input | Input sanitization, action whitelist |
| Indirect | Retrieved docs, web content | Dual-LLM, context minimization |
| Stored | Database content, cached results | Validate before re-ingestion |
| Multi-step | Subtle instructions across turns | Plan-then-execute, turn isolation |
