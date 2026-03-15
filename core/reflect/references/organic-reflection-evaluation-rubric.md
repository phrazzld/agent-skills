# Organic Reflection Evaluation Rubric

Score each candidate artifact from 1 (low) to 5 (high) on each dimension.
Evaluate scope fit explicitly: global Pi config, repo-local config, process-only, or external/internal tool.

## Dimensions

1. **Impact**
   - How much repeated pain does this remove?

2. **Evidence strength**
   - How clearly has this need appeared in real work (not speculation)?

3. **Implementation effort**
   - Lower effort gets higher score (quick to test).

4. **Maintenance burden**
   - Lower ongoing maintenance gets higher score.

5. **Bloat risk**
   - Lower risk of command/catalog sprawl gets higher score.

6. **Reversibility**
   - How easy is it to remove if it underperforms?

7. **Opinionated default fit**
   - Higher score for low-config, sensible-default workflows.

## Recommendation bands

- **28-35**: `now` (high-confidence candidate)
- **20-27**: `next` (promising, validate in small pilot)
- **<=19**: `later` (insufficient signal or too expensive)

## Tie-breakers

Prefer candidates that:
1. Reduce repeated manual orchestration
2. Improve safety/quality signal early (before PR)
3. Stay composable and avoid one-off command proliferation
4. Reduce required user configuration via opinionated defaults
