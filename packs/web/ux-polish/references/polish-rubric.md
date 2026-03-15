# Polish Rubric

Use this to choose one small UX fix that has outsized user value.

## Good Candidate Types

- **Clarity** — labels, CTA text, hierarchy, affordance, destructive-action framing
- **Feedback** — success, error, validation, loading, progress, or save-state visibility
- **Recovery** — empty states, retry paths, inline guidance, next actions after failure
- **Ergonomics** — touch targets, density, spacing, safe-area handling, focus order
- **Accessibility** — non-color feedback, keyboard reachability, screen-reader-visible status

## Scoring

Score each candidate from `0-3` on the first five dimensions. Subtract risk at the end.

| Dimension | 0 | 1 | 2 | 3 |
|-----------|---|---|---|---|
| **User impact** | Cosmetic only | Nice improvement | Noticeably reduces friction | Removes likely confusion or failure on a meaningful path |
| **Frequency / importance** | Rare edge case | Occasional path | Common path or key state | High-traffic or high-stakes path |
| **Scope fit** | Multi-flow redesign | Large surface | One route with spillover | One route, component, or interaction seam |
| **Proof path** | Hard to verify | Subjective only | Visual or behavioral proof exists | Can verify visually and behaviorally today |
| **Accessibility / ergonomics** | No clear gain | Minor gain | Fixes a real usability gap | Fixes a gap likely affecting completion or confidence |
| **Risk / churn** | 0 = trivial | 1 = moderate | 2 = meaningful | 3 = likely to reopen design or behavior assumptions |

`total = impact + frequency + scope fit + proof path + accessibility - risk`

Prefer the highest-scoring candidate that stays inside one coherent user surface.
If nothing scores at least `8`, the area may not be worth a dedicated polish pass.

## Selection Rules

- Reject "grab bag" polish lists unless every item solves the same root friction
- Prefer fixes at decision points, state transitions, and recovery moments over decorative cleanup
- Prefer user-facing clarity over animation, ornament, or generic modernization
- If repeated inconsistencies point to missing tokens, component debt, or broader visual drift, escalate to `../design/SKILL.md`
- If the root problem is tangled state, pass-through logic, or module sprawl, escalate to `../simplify/SKILL.md`

## Grounded Heuristics

Use current platform guidance as the tie-breaker:

- Keep errors identifiable and close to the relevant action or field
- Make status changes perceivable without relying on color alone
- Ensure interactive targets are generous enough for touch use
- Give empty and failure states one clear next step
- Prefer immediate local feedback over delayed or detached messaging

These heuristics align with current W3C accessibility guidance and platform layout guidance.

## Worthy Wins

- Move validation copy under the offending field and focus it after submit
- Replace a blank loading gap with a structural skeleton that preserves layout
- Add a clear empty-state CTA instead of passive copy
- Expand a cramped mobile action target and add safe-area padding
- Clarify destructive actions with explicit consequence language and an alert dialog

## Anti-Patterns

- "Make it feel more premium"
- Tweaking unrelated spacing issues across five pages
- Adding animation because the screen feels static
- Introducing a new component or feature and calling it polish
- Using polish to avoid naming the real architectural problem
