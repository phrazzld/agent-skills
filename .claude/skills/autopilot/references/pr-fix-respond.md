
# Respond to PR Review Feedback

You're a senior engineer responding to code review feedback on a PR. Your job is to analyze, decide, act, and **document everything publicly in the PR**.

## Core Philosophy: Radical Transparency

**Never work silently.** Every judgment, decision, categorization, and action must be documented in PR comments. The PR comment history should tell the complete story of how feedback was handled and why.

Why this matters:
- Reviewers see their feedback was heard and considered
- Future readers understand the reasoning behind decisions
- Rubber-ducking improves decision quality
- Creates institutional memory

## Workflow

## Bounded Shell Output (MANDATORY)

- Count first; fetch details second
- Use bounded pages (`per_page`, `page`) instead of raw dumps
- Truncate body previews during triage
- Process newest 50 first, then continue page-by-page

### 1. Gather All Feedback

Collect from all three GitHub comment sources:
- Review comments (inline on code)
- Issue comments (general discussion)
- Review summaries (top-level review state)

Use pagination. Don't miss anything.

Bounded collection pattern:

```bash
OWNER="$(gh repo view --json owner --jq .owner.login)"
REPO="$(gh repo view --json name --jq .name)"

REVIEW_COUNT="$(gh api "repos/$OWNER/$REPO/pulls/$PR/comments?per_page=100" --paginate --jq '.[] | 1' | wc -l | tr -d ' ')"
ISSUE_COUNT="$(gh api "repos/$OWNER/$REPO/issues/$PR/comments?per_page=100" --paginate --jq '.[] | 1' | wc -l | tr -d ' ')"
SUMMARY_COUNT="$(gh api "repos/$OWNER/$REPO/pulls/$PR/reviews?per_page=100" --paginate --jq '.[] | 1' | wc -l | tr -d ' ')"

gh api "repos/$OWNER/$REPO/pulls/$PR/comments?per_page=50&page=1" \
  --jq '.[] | {id,user:.user.login,path,line,body:(.body|gsub("\n";" ")|.[0:200])}'
```

### 2. Post Initial Acknowledgment

**MANDATORY**: Before any analysis, post a comment acknowledging receipt:

```bash
gh pr comment <PR_NUMBER> --body "$(cat <<'EOF'
## 📋 Review Feedback Received

I'm analyzing feedback from this PR. Will post my assessment shortly.

**Found:**
- X review comments
- Y issue comments
- Z review summaries

Working through categorization and will respond to each item.
EOF
)"
```

### 3. Analyze and Categorize (with Second Opinions)

For each piece of feedback:
1. Assess technical merit and scope
2. **For non-trivial decisions**, get a second opinion via Task tool:
   ```
   # Get a second perspective
   Task({ subagent_type: "general-purpose", prompt: "Review this feedback: [quote]. Is this valid? Should it block merge?" })

   # Get Gemini perspective for architectural questions
   gemini "Analyze this architectural suggestion: [quote]. What are the tradeoffs?"
   ```
3. Document your reasoning

Categories:
- **Critical/Merge-blocking**: Must fix before merge
- **In-scope improvements**: Valid, fits this PR's purpose
- **Follow-up work**: Valid, but separate concern
- **Declined**: Not addressing, with explicit reasoning

### 4. Post Categorization Summary

**MANDATORY**: Post your categorized assessment as a PR comment:

```bash
gh pr comment <PR_NUMBER> --body "$(cat <<'EOF'
## 📊 Feedback Analysis

### Critical/Merge-blocking (X items)
| Feedback | Source | My Assessment |
|----------|--------|---------------|
| [quote] | @reviewer | Valid - will fix. [reasoning] |

### In-scope Improvements (X items)
| Feedback | Source | My Assessment |
|----------|--------|---------------|
| [quote] | @reviewer | Agreed - implementing. [reasoning] |

### Follow-up Work (X items)
| Feedback | Issue Created | Rationale for Deferring |
|----------|---------------|-------------------------|
| [quote] | #123 | [why not in this PR] |

### Declined (X items)
| Feedback | Source | Why Not Addressing |
|----------|--------|-------------------|
| [quote] | @reviewer | [explicit reasoning] |

---
*Consulted: Codex (for X), Gemini (for Y)*
EOF
)"
```

### 5. Implement Fixes (Narrating as You Go)

For each fix, post a comment explaining what you're doing:

```bash
gh pr comment <PR_NUMBER> --body "$(cat <<'EOF'
### Addressing: [feedback summary]

**What I'm changing:**
- [specific change 1]
- [specific change 2]

**Why this approach:**
[reasoning]

Will commit shortly.
EOF
)"
```

Then implement using pr-comment-resolver agents or directly.

### 6. Post Resolution Summary

After all fixes are committed:

```bash
gh pr comment <PR_NUMBER> --body "$(cat <<'EOF'
## ✅ Feedback Resolution Complete

### Changes Made
- [commit hash]: [what it fixed]
- [commit hash]: [what it fixed]

### Issues Created
- #123: [deferred item]

### Still Open
- [anything that needs reviewer re-review]

Ready for another look when you have time, @reviewer.
EOF
)"
```

### 7. Codify Learnings

Every piece of feedback represents a gap in our preventive systems. After resolving:

1. Brainstorm prevention mechanisms (hooks, agents, skills, CLAUDE.md)
2. Implement codification
3. Post what was codified:

```bash
gh pr comment <PR_NUMBER> --body "$(cat <<'EOF'
## 📚 Codified from This Review

To prevent similar feedback in future PRs:

- **[feedback pattern]** → Added to `[target]`: [what]

This class of issue should now be caught earlier.
EOF
)"
```

## Decision Framework

**When to get a second opinion (Task tool / Codex CLI):**
- Architectural suggestions
- Disagreements with reviewer
- Ambiguous requirements
- Tradeoff decisions
- Anything you're uncertain about

**When to decline feedback:**
- Out of scope for this PR (create issue instead)
- Technically incorrect (explain why)
- Already addressed elsewhere (link to it)
- Would introduce regression (explain risk)

Always explain declined feedback publicly. Never silently ignore.

## Anti-Patterns

❌ Silent fixes with no explanation
❌ Categorizing without posting rationale
❌ Making decisions without documenting reasoning
❌ Ignoring feedback without explicit comment
❌ Working through feedback without acknowledging receipt

## Remember

The PR comment thread is the permanent record. Future you, future maintainers, and future AI agents will read it. Make it tell the complete story.
