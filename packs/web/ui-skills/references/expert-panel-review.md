# Expert Panel Review

**Mandatory quality gate for all design outputs.** Before returning any design to the user, it must pass expert panel review with 90+ average score.

## The Panel

Simulate 10 world-class advertorial experts:

| Expert | Domain | Focus Areas |
|--------|--------|-------------|
| **David Ogilvy** | Advertising | Headlines, value props, persuasion |
| **Dieter Rams** | Industrial Design | Simplicity, function, timelessness |
| **Paula Scher** | Typography/Branding | Type hierarchy, visual identity |
| **Joanna Wiebe** | Conversion Copywriting | CTA clarity, friction reduction |
| **Peep Laja** | CRO | Conversion optimization, testing |
| **Aarron Walter** | UX/Emotional Design | User delight, personality |
| **Robert Cialdini** | Persuasion Psychology | Social proof, scarcity, authority |
| **Jony Ive** | Product Design | Refinement, materials, craft |
| **Luke Wroblewski** | Mobile/Forms | Mobile-first, form optimization |
| **Debbie Millman** | Brand Strategy | Brand voice, consistency, meaning |

## Review Process

For each design output, have each expert:

1. **Score (0-100):** Rate the design in their domain
2. **Specific Feedback:** 2-3 concrete improvements tied to their score
3. **Critical Issue:** One thing that would most improve the rating

### Scoring Guide

| Score | Meaning |
|-------|---------|
| 90-100 | Excellence. Ship it. Minor polish only. |
| 80-89 | Good. A few meaningful improvements needed. |
| 70-79 | Acceptable. Multiple issues need addressing. |
| 60-69 | Weak. Significant rework required. |
| <60 | Failing. Fundamental problems. |

## Quality Gate

**Threshold: 90+ average across all 10 experts.**

If average < 90:
1. Collect all expert feedback
2. Prioritize by impact (lowest scores first)
3. Implement improvements
4. Re-run panel review
5. Repeat until 90+ achieved

## Output Format

```markdown
## Expert Panel Review

### Scores

| Expert | Score | Critical Issue |
|--------|-------|----------------|
| Ogilvy | 88 | Headline doesn't lead with benefit |
| Rams | 92 | Minor: reduce visual noise in footer |
| Scher | 85 | Type hierarchy unclear at h3 level |
| Wiebe | 82 | CTA copy too generic ("Get Started") |
| Laja | 78 | No social proof above fold |
| Walter | 91 | Good emotional resonance |
| Cialdini | 84 | Missing urgency/scarcity element |
| Ive | 93 | Clean, refined execution |
| Wroblewski | 89 | Form fields need better labels |
| Millman | 87 | Brand voice slightly inconsistent |

**Average: 86.9 / 100** ❌ Below threshold

### Priority Improvements

1. **Laja (78):** Add customer testimonial or logo bar above fold
2. **Wiebe (82):** Change CTA to "Start Free 14-Day Trial"
3. **Cialdini (84):** Add "Join 5,000+ teams" social proof
4. **Scher (85):** Increase h3 size, add more weight contrast

### Re-review Required

Implementing top 4 improvements and re-submitting...
```

## Integration Points

### Design Exploration
Add after Phase 5 (Direction Selection), before Phase 6 (Output & Handoff):

```
### 5.5. Expert Panel Review

Before presenting selected direction:
1. Run expert panel review on final design
2. If average < 90, implement feedback and iterate
3. Only proceed to handoff when 90+ achieved
```

### Fix-Landing
Add after Step 3 (Execute Fix), before Step 4 (Verify):

```
### 3.5. Expert Panel Review

After implementing fix:
1. Run expert panel review on affected sections
2. If average < 90, refine implementation
3. Only proceed when quality threshold met
```

### Frontend Design / UI Skills
Add as final step before returning any component:

```
### Final Review

Before returning design:
1. Expert panel reviews the component/page
2. Score must average 90+
3. Iterate until threshold met
```

## Why This Matters

- **Consistency:** Every design meets the same high bar
- **Specificity:** Feedback is actionable, not vague
- **Iteration:** Forces refinement before delivery
- **Expertise:** Multiple perspectives catch blind spots
- **Accountability:** Clear pass/fail threshold

## Anti-Patterns

- ❌ Skipping review for "quick fixes"
- ❌ Accepting 85+ as "close enough"
- ❌ Ignoring low-scoring experts
- ❌ Generic feedback ("make it better")
- ❌ Reviewing without implementing feedback

## Quick Reference

```
Before returning design:
1. Simulate 10 expert reviews
2. Each scores 0-100 + specific feedback
3. Calculate average
4. If < 90 → implement feedback → re-review
5. If ≥ 90 → proceed to delivery
```
