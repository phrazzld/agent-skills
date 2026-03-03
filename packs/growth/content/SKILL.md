---
name: content
description: |
  Content creation and optimization: copywriting, copy editing, social media,
  launch announcements, email sequences, and AI-writing cleanup. Covers the
  full content lifecycle from first draft to polished, on-brand output.
  Use when writing, editing, or publishing any marketing or product content.
disable-model-invocation: true
---

# CONTENT

Full content lifecycle: write, edit, publish, humanize.

## Absorbed Skills

This skill consolidates: `copywriting`, `copy-editing`, `copy-lab`,
`social-content`, `post`, `announce`, `email-sequence`, `humanizer`.

---

## Quick Start

```bash
# Write marketing copy for a page
/content write [page-type]

# Edit/polish existing copy
/content edit [file-or-text]

# Generate social posts
/content post [product] "message"

# Launch announcements for all platforms
/content announce [url] [description]

# Design email sequence
/content email [sequence-type]

# Remove AI writing patterns
/content humanize [file-or-text]

# Copy exploration lab (5 distinct approaches)
/content lab [brief]
```

---

## Copywriting

### Before Writing

Gather context (ask if not provided):
1. **Page purpose**: type, primary action, secondary action
2. **Audience**: ideal customer, problem, objections, their language
3. **Product/Offer**: what, differentiator, key transformation, proof points
4. **Context**: traffic source, prior knowledge, upstream messaging

### Core Principles
- **Clarity over cleverness** -- if you must choose, choose clear
- **Benefits over features** -- connect features to outcomes
- **Specificity over vagueness** -- "Cut reporting from 4 hours to 15 minutes"
- **Customer language** -- mirror voice-of-customer
- **One idea per section** -- build a logical flow

### Writing Style
1. Simple over complex ("use" not "utilize")
2. Specific over vague (avoid "streamline", "optimize", "innovative")
3. Active over passive
4. Confident over qualified (remove "almost", "very", "really")
5. Show over tell (describe outcomes, not adverbs)
6. Honest over sensational (never fabricate stats)

### Page Structure Framework

**Above the fold:** headline + subheadline + primary CTA + supporting visual

**Headline formulas:**
- {Achieve outcome} without {pain point}
- The {opposite} way to {outcome}
- Never {unpleasant event} again
- {Feature} for {audience} to {use case}
- Turn {input} into {outcome}
- Stop {pain}. Start {pleasure}.

**Section flow (strong page):**
1. Hero with clear value prop
2. Social proof bar
3. Problem/pain section
4. How it works (3 steps)
5. Key benefits (2-3, not 10)
6. Testimonial
7. Use cases or personas
8. Comparison to alternatives
9. FAQ
10. Final CTA with guarantee

**CTA formula:** [Action Verb] + [What They Get] + [Qualifier]

---

## Copy Editing (Seven Sweeps)

Systematic editing through seven sequential passes:

1. **Clarity** -- can the reader understand? Confusing structures, unclear references, jargon
2. **Voice & Tone** -- consistent formality, personality, brand alignment
3. **So What** -- every claim answers "why should I care?" Features connect to benefits
4. **Prove It** -- claims supported with evidence, specific social proof, no unearned superlatives
5. **Specificity** -- vague words replaced with concrete (numbers, timeframes, examples)
6. **Heightened Emotion** -- copy evokes feeling, pain points feel real, aspirations achievable
7. **Zero Risk** -- barriers to action removed, objections addressed, trust signals present

After each sweep, loop back to verify previous sweeps aren't compromised.

### Quick-Pass Checks

**Cut:** very, really, just, actually, basically, in order to, things, stuff
**Replace:** utilize->use, implement->set up, leverage->use, facilitate->help, robust->strong
**Watch:** adverbs, passive voice, nominalizations

---

## Copy Lab (Exploration)

Design-lab pattern for copy. Five distinct approaches, not word variants.

1. **Brief** -- gather page purpose, audience, product, context
2. **Generate 5 approaches** -- each differs on 2+ axes: persona framing, core promise, proof angle, objection strategy, tone, structure
3. **Review each** through copy-reviewer lenses, score per-lens + composite
4. **Iterate until all 5 hit 90+** -- revise using review findings, keep distinct
5. **Present catalog** -- approach name, strategy, final copy, scores, rationale
6. **User selects** -- pick or mix, synthesize final draft, re-review

---

## Social Content

### Platform Strategy

| Platform | Best For | Frequency | Format |
|----------|----------|-----------|--------|
| LinkedIn | B2B, thought leadership | 3-5x/week | Stories, contrarian takes, carousels |
| Twitter/X | Tech, real-time, community | 3-10x/day | Hot takes, threads, engagement |
| Instagram | Visual brands, lifestyle | 1-2 feed + 3-10 Stories/day | Reels, carousels |
| TikTok | Brand awareness, younger | 1-4x/day | Native, trending, educational |
| Facebook | Communities, local, older | 1-2x/day | Groups, live video, discussions |

### Content Pillars
Build around 3-5 pillars: industry insights (30%), behind-scenes (25%),
educational (25%), personal (15%), promotional (5%).

### Hook Formulas
- **Curiosity:** "I was wrong about [common belief]."
- **Story:** "Last week, [unexpected thing] happened."
- **Value:** "How to [outcome] without [pain]:"
- **Contrarian:** "[Common advice] is wrong. Here's why:"
- **Social proof:** "We [achieved result] in [timeframe]. Here's how:"

### Post Generation (/post)
1. Load `brand-profile.yaml` or `brand.yaml` if available
2. Apply brand voice, tone, topics
3. Generate 3-5 post variants
4. Include relevant hashtags
5. Output ready-to-copy content with character counts

Flags: `--ideas` (generate from git history + brand topics), `--thread` (thread format)

### Content Repurposing
Blog post -> LinkedIn insight, carousel, Twitter thread, Instagram carousel, Reel.
Podcast/video -> Quote graphic, thread, Reel clip, TikTok, YouTube Short.

---

## Launch Announcements (/announce)

Generate platform-optimized launch posts for:

### Twitter/X
Short, punchy, visual-friendly. Variants: feature-focused, story-focused, engagement opener.

### Hacker News (Show HN)
Technical context, "Show HN:" prefix, open to questions, no marketing fluff.

### Reddit
Subreddit-specific, authentic, ask for feedback, engage with comments.

### Indie Hackers
Founder story + metrics + stack + ask. Be specific about costs.

### Product Hunt (Draft)
Tagline (<=60 chars), description (<=260 chars), maker first comment.

### Launch Checklist
1. Post to Twitter first (engage with replies)
2. Submit to HN (Tuesday-Thursday, 9am EST)
3. Post to Reddit (read subreddit rules)
4. Post to Indie Hackers (weekdays)
5. Save Product Hunt draft (schedule properly)

---

## Email Sequences

### Sequence Types

| Type | Length | Timing |
|------|--------|--------|
| Welcome/onboarding | 5-7 emails | Immediate -> Day 14 |
| Lead nurture | 5-10 emails | Day 0 -> Day 21 |
| Re-engagement | 3-5 emails | Day 30-60 inactivity |
| Post-purchase | 3-5 emails | Immediate -> Day 14 |

### Core Principles
- One email, one job, one CTA
- Value before ask
- Relevance over volume
- Clear path forward

### Subject Line Strategy
- Clear > Clever, Specific > Vague
- 40-60 characters ideal
- Patterns: question, how-to, number, direct, story tease

### Email Structure
1. **Hook**: first line grabs attention
2. **Context**: why this matters to them
3. **Value**: the useful content
4. **CTA**: what to do next
5. **Sign-off**: human, warm close

### Lifecycle Email Types
- Onboarding: new users, new customers, step reminders, invites
- Retention: upgrade prompts, review asks, proactive support, usage reports, NPS, referrals
- Billing: annual switch, failed payment recovery, cancellation survey, renewal reminders
- Usage: daily/weekly/monthly summaries, milestone notifications
- Win-back: expired trials, cancelled customers
- Campaigns: newsletters, seasonal promotions, product updates, pricing changes

---

## Humanizer (AI Writing Cleanup)

Remove signs of AI-generated writing. Based on Wikipedia's "Signs of AI writing" guide.

### Content Patterns to Fix
- Inflated significance ("pivotal moment", "testament", "evolving landscape")
- Promotional language ("groundbreaking", "nestled", "vibrant", "showcasing")
- Superficial -ing analyses ("highlighting", "underscoring", "reflecting")
- Vague attributions ("experts argue", "industry reports")
- Formulaic "challenges and future prospects" sections

### Language Patterns to Fix
- AI vocabulary: additionally, crucial, delve, enhance, fostering, intricate, landscape, pivotal, tapestry, underscore, vibrant
- Copula avoidance: "serves as"/"stands as" -> just use "is"
- Negative parallelisms: "not only...but..." overuse
- Rule of three: forced groups of three
- Synonym cycling: excessive variation to avoid repetition

### Style Patterns to Fix
- Em dash overuse (max one per message)
- Boldface overuse
- Inline-header vertical lists
- Emojis decorating headings/bullets
- Curly quotation marks

### Adding Soul
- Have opinions, don't just report
- Vary rhythm (mix short and long sentences)
- Acknowledge complexity and mixed feelings
- Use "I" when it fits
- Be specific about feelings
- Let some mess in -- perfect structure feels algorithmic

---

## Expert Panel Review (MANDATORY)

Before returning copy to user, run expert panel review.

1. Simulate 10 advertorial experts scoring 0-100 with specific feedback
2. Key reviewers: Ogilvy (headlines), Wiebe (CTA clarity), Cialdini (psychology), Millman (brand voice)
3. **If average < 90:** implement feedback, iterate
4. **Only return copy when 90+ average achieved**

---

## Brand Profile Integration

When `brand-profile.yaml` or `brand.yaml` exists:
- Match voice tone (casual, professional, playful, technical)
- Incorporate personality traits
- Skip anything in the "avoid" list
- Include primary + product hashtags
- Ensure content fits established topics
- Respect content mix ratio (e.g., 30% product / 70% valuable)
