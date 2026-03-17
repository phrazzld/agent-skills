# Altitude Calibration

Choosing the right level of specificity in system prompts and instructions.

## The Altitude Spectrum

```
HIGH ALTITUDE (trust the model)
│  "Handle authentication appropriately"
│  Good for: general intelligence, classification, synthesis
│
│  "Implement OAuth 2.0 with PKCE flow"
│  Good for: specific technical requirements
│
│  "Use RS256 signing, 15-minute token expiry,
│   refresh tokens stored server-side only"
LOW ALTITUDE (specify exactly)
   Good for: security, compliance, data integrity
```

**Default to high altitude.** Only descend when the cost of model
discretion exceeds the cost of reduced adaptability.

## When to Be Specific (Low Altitude)

Descend to low altitude when mistakes are:
- **Irreversible**: data deletion, financial transactions, external communications
- **Invisible**: security vulnerabilities, data leaks, compliance violations
- **Expensive**: production outages, customer-facing errors, legal exposure

**Domains requiring low altitude:**
- Security boundaries (auth, encryption, access control)
- Compliance requirements (data handling, audit trails, retention)
- Data integrity (migrations, schema changes, transaction boundaries)
- External integrations (API contracts, webhook formats, billing)
- Safety constraints (content policy, PII handling, rate limits)

## When to Trust the Model (High Altitude)

Stay at high altitude when the model's general intelligence is the value:
- Classification and routing decisions
- Natural language understanding and generation
- Code review and bug finding
- Synthesis and summarization
- Exploratory analysis and investigation
- Creative problem-solving and refactoring

**The test:** "Am I writing instructions because the model *can't* do this,
or because I *want* it done a specific way?" If the latter, consider whether
your specific way is genuinely better than what the model would choose.

## Progressive Autonomy Ladder

Graduated trust levels for agent operations:

### HITL — Human In The Loop
Agent proposes, human approves every action.
```
Use when: new agent, untested domain, high-stakes operations
Example: "Generate PR description, wait for approval before creating"
```

### HOTL — Human On The Loop
Agent acts autonomously but human monitors and can intervene.
```
Use when: proven agent, moderate stakes, reversible operations
Example: "Create PR, human reviews before merge"
```

### HOOL — Human Out Of The Loop
Agent operates fully autonomously.
```
Use when: battle-tested agent, low stakes, comprehensive evals
Example: "Auto-fix lint errors and commit"
```

**Progression criteria:**
1. Agent succeeds >95% on eval suite for this task type
2. Failure mode analysis shows all failures are recoverable
3. Monitoring and alerting in place to catch regressions
4. Rollback mechanism exists for every autonomous action

## Few-Shot vs Zero-Shot Decision

Modern models (Claude 3.5+, GPT-4+) are highly capable zero-shot.

**Use zero-shot when:**
- Task is well-understood from description alone
- Output format is standard (JSON, code, markdown)
- Model's default behavior is acceptable
- Context budget is tight

**Use few-shot (1-3 examples) when:**
- Output requires specific formatting not captured by schema
- Tone or style must match existing corpus
- Domain has unusual conventions the model wouldn't infer
- Edge cases need explicit demonstration

**Diminishing returns:** 1-3 examples capture most benefit. More examples
consume context without proportional quality gain. If 3 examples aren't
enough, the task likely needs better instructions, not more examples.

**Negative examples** (showing what NOT to do) are high-signal:
```
✅ Good: { "status": "error", "code": "AUTH_EXPIRED" }
❌ Bad:  { "error": true, "message": "Something went wrong" }
         Why bad: Generic message, no error code, boolean error flag
```

## Temperature and Determinism

| Task Type | Temperature | Why |
|-----------|-------------|-----|
| Code generation | 0-0.2 | Correctness over creativity |
| Classification | 0 | Consistent routing decisions |
| Data extraction | 0 | Exact reproduction of source |
| Creative writing | 0.7-1.0 | Diversity and exploration |
| Brainstorming | 0.8-1.0 | Maximize idea diversity |
| Conversation | 0.5-0.7 | Natural but coherent |

**For agents:** Default to temperature 0. Agent behavior should be
predictable and reproducible. Introduce temperature only for tasks
where variation is explicitly desired.

**Caveat:** Some providers apply minimum temperature internally.
Test actual output variance, don't assume temperature=0 means deterministic.
