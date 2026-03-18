# Agent Annotation Patterns

Patterns for leaving context at the point of relevance in code. Agents need
"use Y not X" more than "X was deprecated because of Z."

## Core Insight

Context at the call site beats external documentation. An agent reading a function
doesn't load your README — it reads the code and its immediate surroundings.
Annotations that appear WHERE the decision matters are the highest-signal context
you can provide.

## Patterns

### @deprecated + @see (Standard JSDoc/TSDoc)

```typescript
/**
 * @deprecated Use {@link authenticateWithOAuth} instead.
 * This method stores session tokens in cookies, which fails
 * the new compliance requirements (SOC2 §4.3).
 * @see authenticateWithOAuth
 */
export function loginWithPassword(user: string, pass: string): Session {
```

**Why it works:** IDE and agent both see the deprecation. The `@see` gives the
exact replacement. The one-line reason prevents the agent from re-introducing
the old pattern "because it's simpler."

### @agent-pitfall (Custom Tag)

```typescript
/**
 * @agent-pitfall Do not batch these calls. The upstream API has a
 * per-request rate limit, not per-second. Batching triggers 429s
 * that look like transient failures but are actually quota exhaustion.
 */
export async function syncInventory(itemId: string): Promise<void> {
```

**Why it works:** Agents see a performance opportunity (batch N calls into 1)
and will take it unless warned. The pitfall tag is scannable and explains
the non-obvious constraint.

### @migration (Old → New Inline)

```typescript
/**
 * @migration Replace `ctx.user` with `ctx.session.identity`.
 * The user object on context is the legacy auth shape (pre-v3).
 * `session.identity` includes RBAC roles the user object lacks.
 */
export function requireAdmin(ctx: Context): void {
  // TODO: migrate to ctx.session.identity.hasRole('admin')
  if (!ctx.user.isAdmin) throw new ForbiddenError();
}
```

**Why it works:** An agent modifying this function sees both the current code
AND the migration path. Without the annotation, it would copy the `ctx.user`
pattern to new code, perpetuating the legacy shape.

### @invariant (Documenting Constraints)

```typescript
/**
 * @invariant balanceAfter === balanceBefore - amount
 * This must hold for every successful transfer. If the database
 * transaction partially commits (balance debited but credit failed),
 * the reconciliation job catches the discrepancy within 5 minutes.
 */
export async function transfer(from: Account, to: Account, amount: Money): Promise<void> {
```

**Why it works:** Agents refactoring this function know which property MUST be
preserved. Without the invariant, an agent might "simplify" the transaction
boundary and break atomicity.

### @perf-constraint (Performance Boundaries)

```typescript
/**
 * @perf-constraint Must complete in < 50ms for P99.
 * This runs in the hot path of every API request (auth middleware).
 * Do not add database calls, network requests, or heavy computation.
 * Cache hits only. If you need to add a DB check, move it to a
 * background job and check a cached flag here.
 */
export function validateToken(token: string): Claims {
```

### Inline "Use X Not Y" Comments

```typescript
// Use structuredClone() here, not JSON.parse(JSON.stringify()).
// The config object contains Date instances that serialize to strings.
const configCopy = structuredClone(baseConfig);
```

**The key pattern:** Tell the agent what TO do, not just what not to do.
"Don't use X" leaves the agent guessing. "Use Y instead of X because Z"
is actionable.

## When to Annotate

- **Non-obvious constraints** — rate limits, performance budgets, compliance requirements
- **Active migrations** — code that works but should be written differently going forward
- **Deprecated APIs** — with the specific replacement, not just "deprecated"
- **Pitfalls** — where the obvious approach is wrong and an agent will get burned
- **Invariants** — properties that must be preserved during refactoring

## When NOT to Annotate

- **Obvious APIs** — `getUserById(id)` doesn't need a comment
- **Stable interfaces** — well-typed public APIs where the types tell the story
- **Implementation details** — don't explain HOW, explain WHY and WHAT constraints
- **Temporary state** — don't leave annotations about in-progress work; use TODOs
- **Type signatures that are self-documenting** — `function add(a: number, b: number): number`

## Standard Tags Reference

| Tag | Meaning | Standard? |
|-----|---------|-----------|
| `@deprecated` | Don't use, see replacement | JSDoc/TSDoc |
| `@see` | Related code/docs | JSDoc/TSDoc |
| `@throws` | Can throw this error | JSDoc/TSDoc |
| `@remarks` | Additional context | TSDoc |
| `@agent-pitfall` | Non-obvious trap for automated tools | Custom (proposed) |
| `@migration` | Old → new pattern mapping | Custom (proposed) |
| `@invariant` | Must-preserve property | Custom (proposed) |
| `@perf-constraint` | Performance boundary | Custom (proposed) |

Custom tags degrade gracefully — agents and humans can read them even if the
IDE doesn't recognize them. They're just structured comments.
