# LLM Evaluation & Testing

Test prompts, models, and RAG systems with Promptfoo.

## Quick Start
```bash
npx promptfoo@latest init
npx promptfoo@latest eval
npx promptfoo@latest view
npx promptfoo@latest redteam run
```

## Assertion Types
- **Functional**: `contains`, `equals`, `is-json`, `regex`
- **Semantic**: `similar`, `llm-rubric`, `factuality`
- **Performance**: `cost`, `latency`
- **Security**: `moderation`, `pii-detection`

## CI/CD Integration
```yaml
name: 'Prompt Evaluation'
on:
  pull_request:
    paths: ['prompts/**', 'src/**/*prompt*']
jobs:
  evaluate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: promptfoo/promptfoo-action@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          openai-api-key: ${{ secrets.OPENAI_API_KEY }}
```

## Red Team Security Testing
```yaml
redteam:
  purpose: "Customer support chatbot"
  plugins:
    - prompt-injection
    - jailbreak
    - pii:direct
    - pii:session
    - hijacking
    - excessive-agency
  strategies:
    - jailbreak
    - prompt-injection
```

## Suite Structure
```
evals/
├── golden/        # Must-pass tests (every PR)
├── regression/    # Full suite (nightly)
├── security/      # Red team tests
└── benchmarks/    # Cost/latency tracking
```

## Agent-Specific Evaluation

### Eval-Driven Development

Build evals BEFORE building agents — like TDD for AI systems.
The eval suite defines what "working" means before implementation starts.

**Process:**
1. Collect 20-50 tasks from real usage and real failures
2. Define expected outcomes (deterministic where possible)
3. Build the simplest agent that passes
4. Add harder tasks as the agent improves
5. Migrate passing tasks to regression suite

### Grader Hierarchy (Anthropic)

Prefer graders higher in this list — they're more reliable:

1. **Deterministic** — code execution, exact match, regex, JSON schema
   validation. Use for any assertion that CAN be checked mechanically.
2. **LLM-as-Judge** — rubric-based LLM evaluation. Use for subjective
   quality, relevance, completeness. Define rubrics precisely.
3. **Human** — expert evaluation. Reserve for calibrating LLM judges
   and ambiguous cases. Expensive, doesn't scale.

**Anti-pattern:** Using LLM-as-Judge for assertions that could be
checked deterministically (e.g., "does the output contain field X?"
→ just check programmatically).

### pass@k vs pass^k

Two complementary metrics for agent reliability:

- **pass@k** — "Can it succeed?" Run k attempts, did ANY succeed?
  Measures agent capability ceiling. Good for development.
- **pass^k** — "Is it reliable?" Run k attempts, did ALL succeed?
  Measures consistency. Good for production readiness.

**Target:** pass@1 > 95% before deploying to production.
If pass@1 is low but pass@3 is high, the agent is capable but unreliable —
fix consistency before shipping.

### Agent Eval Dimensions

| Dimension | What to Measure | How |
|-----------|----------------|-----|
| Tool selection | Does agent pick the right tool? | Compare tool call sequence to golden path |
| Task completion | Does agent finish the job? | End-state assertions (file exists, test passes, PR created) |
| Efficiency | How many steps/tokens to complete? | Count tool calls, measure total tokens |
| Safety compliance | Does agent respect boundaries? | Test with adversarial inputs, verify no policy violations |
| Error recovery | Does agent recover from failures? | Inject tool errors, verify agent adapts |

### Saturation Management

Eval suites lose value over time as the agent "overfits" to known tasks.

**Signs of saturation:**
- Suite passes at 100% for 2+ weeks
- New real-world failures aren't caught by existing evals
- Adding more tasks of the same type doesn't find bugs

**Refresh strategy:**
1. Migrate saturated tasks to regression suite (run nightly, not every PR)
2. Replace with harder variants (more steps, ambiguous inputs, error injection)
3. Source new tasks from production failures and user reports
4. Rotate adversarial tasks to prevent pattern-matching
