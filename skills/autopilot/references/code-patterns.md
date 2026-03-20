# Code Patterns

Code-level rules that sit between module design (Ousterhout) and process gates (CI/review). Apply after architecture is settled, before shipping.

## State Discipline

**Discriminated unions over boolean flags / optional fields.**
Boolean flags create implicit state machines with impossible combinations. A union makes every state explicit and every transition visible.

```typescript
// ❌ Boolean soup — what does loading + error mean?
{ loading: boolean; error: string | null; data: T | null }

// ✅ One state at a time
{ status: "idle" } | { status: "loading" } | { status: "error"; error: string } | { status: "ok"; data: T }
```

**Exhaustive handling with failure on unknown type.**
Switch on discriminated unions. Default case throws — compiler and runtime both enforce completeness.

```typescript
// ❌ Silently ignores new variants
if (event.type === "click") { ... }

// ✅ Exhaustive — adding a variant forces a handler
switch (event.type) {
  case "click": return handleClick(event);
  case "hover": return handleHover(event);
  default: throw new Error(`Unhandled event: ${(event as never).type}`);
}
```

**Trust types — no defensive code.**
If the type says it's there, use it. Defensive null checks on non-nullable fields add noise and hide real bugs.

**Asserts at data-loading boundaries, not try/catch or defaults.**
Validate when data enters the system (API responses, file reads, config). After that, trust the validated shape. Don't scatter defensive checks through business logic.

**Required params are required — no false optionals.**
If every caller passes it, it's not optional. `?` on always-present fields weakens the type and forces pointless null handling downstream.

## Code Shape

**Skimmable, simple, not clever.**
A reader should grasp intent in one pass. Prefer boring idioms over compact tricks. Indirection costs more than repetition.

**Fewer lines of code.**
Less code = fewer bugs, faster reviews, cheaper changes. Delete before adding. If a function exists only to wrap another function, inline it.

**Early returns over deep nesting.**
Guard clauses flatten logic. Three levels of nesting means the structure is wrong.

**Don't over-extract into many small functions.**
A 30-line function that reads top-to-bottom beats five 6-line helpers that force the reader to jump around. Extract when there's a real abstraction, not just line count.

## Interface Discipline

**Minimize argument count; no gratuitous overrides.**
More args = more coupling. If a function takes >3 params, consider whether it's doing too much or whether a config object hides the real interface.

**Remove changes that aren't strictly required.**
Every diff line is review cost and regression surface. If it doesn't serve the PR's goal, revert it.

**Asserts over try/catch when you expect something to exist.**
`try/catch` means "this might fail and I'll handle it." An assert means "this must be true or something is deeply wrong." Use the one that matches your intent.
