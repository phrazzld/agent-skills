# Alternative Lenses

Load when Phase 2 exploration is producing variations on the same theme
instead of genuinely different architectures.

## Structural Lenses

Pick one lens. Generate a full alternative through it.

| Lens | Question |
|------|----------|
| **Inversion** | What if the control flow went the opposite direction? |
| **Deletion** | What if we deleted the entire module and started over? What's the minimum? |
| **Monolith** | What if this was one file? What would that look like? |
| **Split** | What if every concern was its own service/module? |
| **Data-first** | What if we designed the data model first and let code follow? |
| **Event-sourced** | What if all state changes were events? |
| **Functional core** | What if all business logic was pure functions, side effects at edges? |
| **Capabilities** | What if we designed around capabilities/permissions, not entities? |
| **API-first** | What if we designed the public API first and worked backward? |
| **User-backward** | What if we started from the ideal user experience and worked to implementation? |

## Process

1. Name the current architectural frame in one sentence
2. Pick the lens that feels most uncomfortable (that's the one with new information)
3. Generate a complete alternative through that lens — not a sketch, a real design
4. Ask: is this genuinely simpler, or just different?

## Rules

- One lens at a time. Don't combine.
- The goal is to find an architecture that's actually simpler, not just novel.
- If the lens produces something worse, that's useful — it confirms the current approach.
- If the lens produces something clearly better, that's the breakthrough.
- If every lens produces something worse, the current architecture is probably right.
