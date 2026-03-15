# Prompt Quality Audit Checklist

Based on the `context-engineering` skill's instruction design principles.

## The Core Test

> "Would I give these instructions to a senior engineer?"

If you'd be embarrassed to hand a colleague a 700-line runbook for a simple task, don't give it to the LLM either.

## Good Prompt Pattern: Role + Objective + Latitude

```
Role: Who is the LLM in this context?
Objective: What's the end goal?
Latitude: How much freedom do they have?
```

**Example:**
```
You're a senior engineer reviewing this PR.     # Role
Find bugs, security issues, and code smells.    # Objective
Be direct. If it's fine, say so briefly.        # Latitude
```

## Anti-Pattern Detection

### 1. Over-Prescriptive Instructions

**Red flags:**
- "Step 1:", "Step 2:", etc.
- Numbered lists of exact actions
- Pseudo-code disguised as instructions
- 100+ lines of instructions

**Grep pattern:**
```bash
grep -rE "Step [0-9]+:|First,.*Then,.*Finally," prompts/ src/*prompt*
```

**Bad:**
```
Step 1: Parse the user's input
Step 2: Identify the intent
Step 3: If intent is X, respond with Y
Step 4: If intent is Z, respond with W
...
```

**Good:**
```
Help users accomplish their goals.
Be direct and efficient.
```

### 2. Excessive Hand-Holding

**Red flags:**
- Many if/then conditions
- Trying to enumerate every case
- Decision trees in natural language

**Grep pattern:**
```bash
grep -rE "If the user|If they|When the user" prompts/ src/*prompt*
```

**Bad:**
```
If the user says X, do Y.
If the user says Z, do W.
Handle edge case A by doing B.
Handle edge case C by doing D.
```

**Good:**
```
Respond appropriately to user requests.
Use your judgment for edge cases.
```

### 3. Defensive Over-Specification

**Red flags:**
- IMPORTANT:, WARNING:, CRITICAL:, NEVER:
- Multiple emphatic instructions
- Lots of negative constraints

**Grep pattern:**
```bash
grep -rE "(IMPORTANT|WARNING|CRITICAL|NEVER|ALWAYS|MUST NOT|DO NOT)" prompts/ src/*prompt*
```

**Bad:**
```
IMPORTANT: Do NOT do X.
WARNING: Never do Y.
CRITICAL: Always remember to Z.
NEVER mention competitors.
ALWAYS be polite.
```

**Good:**
```
Be helpful and professional.
Focus on our product's strengths.
```

## Audit Checklist

For each prompt found in the codebase:

### Structure
- [ ] Uses Role + Objective + Latitude pattern
- [ ] Under 50 lines (ideally under 20)
- [ ] No numbered step-by-step instructions
- [ ] No decision trees

### Tone
- [ ] Goal-oriented, not prescriptive
- [ ] Trusts the model's judgment
- [ ] No defensive warnings (IMPORTANT, NEVER, etc.)
- [ ] Reads like instructions to a senior engineer

### Content
- [ ] States what to accomplish, not how
- [ ] Provides necessary context only
- [ ] No redundant instructions
- [ ] No obvious instructions (be helpful, be accurate)

### Maintainability
- [ ] Version controlled in prompts/ directory
- [ ] Has associated eval tests
- [ ] Documented purpose
- [ ] Easy to understand and modify

## Severity Levels

### Critical (fix immediately)
- 500+ line prompts
- Prompts that treat LLM like a bash script
- Severe over-specification that limits capability

### High (fix this session)
- Step-by-step instructions where goals would suffice
- 10+ defensive warnings
- Excessive edge case enumeration

### Medium (fix soon)
- Minor over-specification
- Could be more concise
- Missing Role/Objective/Latitude structure

### Low (nice to have)
- Style improvements
- Better organization
- More idiomatic phrasing

## Refactoring Examples

### Example 1: Customer Support Bot

**Before (bad):**
```
You are a customer support agent for Acme Corp.

IMPORTANT: Always greet the customer warmly.
IMPORTANT: Always thank them for contacting us.
WARNING: Never say "I don't know."
WARNING: Never make promises you can't keep.
CRITICAL: Never mention competitors.
CRITICAL: Always escalate billing issues.

Step 1: Read the customer's message carefully.
Step 2: Identify their intent (question, complaint, request).
Step 3: If it's a question, provide a helpful answer.
Step 4: If it's a complaint, apologize and offer solutions.
Step 5: If it's a request, try to fulfill it or explain limitations.
Step 6: Always end with asking if there's anything else.

If the customer is angry, be extra patient.
If the customer mentions legal action, escalate immediately.
If the customer asks about pricing, refer to the pricing page.
...
```

**After (good):**
```
You're a support agent for Acme Corp.

Help customers resolve their issues efficiently.
Escalate billing disputes and legal mentions to human agents.
Be professional and solution-oriented.
```

### Example 2: Code Review Bot

**Before (bad):**
```
You are a code review assistant.

Step 1: Analyze the code for bugs.
Step 2: Check for security vulnerabilities.
Step 3: Look for performance issues.
Step 4: Evaluate code style.
Step 5: Suggest improvements.

IMPORTANT: Be constructive, not critical.
IMPORTANT: Provide specific line numbers.
WARNING: Don't suggest changes that break tests.
CRITICAL: Flag any hardcoded secrets immediately.
...
```

**After (good):**
```
You're a senior engineer reviewing this code.

Find bugs, security issues, and code smells.
Be direct—if it's fine, say so briefly.
Prioritize issues that could cause production problems.
```

## Remember

The L in LLM stands for Language. Talk to it like a colleague, not a compiler.
