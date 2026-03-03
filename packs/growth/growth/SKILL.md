---
name: growth
description: |
  Growth and marketing orchestrator: SEO, ads, CRO, analytics, pricing,
  launches, referrals, competitor analysis, and pSEO generation. Covers
  the full growth stack from baseline SEO to scaled paid acquisition.
  Use when optimizing conversions, running campaigns, or planning launches.
disable-model-invocation: true
---

# GROWTH

Full growth stack: SEO, ads, CRO, analytics, pricing, launches, distribution.

## Absorbed Skills

This skill consolidates: `marketing-ops`, `marketing-dashboard`, `marketing-status`,
`marketing-psychology`, `github-marketing`, `virality`, `cro`, `launch-strategy`,
`product-hunt-kit`, `growth-at-scale`, `growth-sprint`, `referral-program`, `paid-ads`,
`free-tool-strategy`, `competitor-alternatives`, `ab-test-setup`, `pricing-strategy`,
`analytics-tracking`, `seo-audit`, `seo-baseline`, `schema-markup`, `programmatic-seo`,
`pseo-generator`.

---

## Quick Start

```bash
# SEO baseline check (15 min)
/growth seo-baseline [url]

# Full SEO audit
/growth seo-audit [url]

# Conversion optimization
/growth cro [funnel-stage]

# Marketing dashboard
/growth dashboard [--period 30d]

# Launch strategy
/growth launch [product]

# Product Hunt prep
/growth product-hunt [product-name]

# A/B test design
/growth ab-test [hypothesis]

# Pricing strategy
/growth pricing

# Competitor pages
/growth alternatives [competitor]

# Growth sprint (weekly ritual)
/growth sprint

# Programmatic SEO
/growth pseo [pattern]
```

---

## SEO

### SEO Baseline (15 min)
Essential checks every page needs:
- Title tag (exists, good length, keyword)
- Meta description
- H1 structure
- Image alt text
- Internal linking
- Mobile-friendly
- Page speed basics
- Canonical URL
- robots.txt / sitemap.xml

Reference: `references/seo-baseline-checklist.md`

### Full SEO Audit
Comprehensive analysis:
1. **Technical**: crawlability, indexation, site speed, mobile, Core Web Vitals
2. **On-page**: title tags, meta descriptions, headings, content quality, keyword targeting
3. **Content**: thin content, duplicate content, content gaps
4. **Links**: internal linking structure, broken links
5. **Structured data**: JSON-LD implementation, rich result eligibility

### Schema Markup
Implement schema.org JSON-LD for rich results:
- Product, Article, FAQ, HowTo, BreadcrumbList
- Organization, LocalBusiness, Event
- Review, AggregateRating
- SoftwareApplication, WebApplication

### Programmatic SEO
Build SEO pages at scale:
1. Identify keyword pattern (e.g., "[tool] alternative", "[tool] vs [tool]")
2. Design template with unique value per page
3. Generate data (research, comparisons, features)
4. Build pages with proper internal linking
5. Validate: no thin content, no duplicates, proper canonicals

### pSEO Generator CLI
```bash
./scripts/generate.py init --pattern comparison
./scripts/generate.py generate --data ./data.json --template comparison --output ./pages/
./scripts/generate.py sitemap --output ./public/sitemap.xml
./scripts/generate.py validate
```

Patterns: comparison, alternatives, best-for-persona, integration, location.

---

## CRO (Conversion Rate Optimization)

Route by conversion context:

| Context | Focus | Reference |
|---------|-------|-----------|
| Signup flow | Form optimization, friction reduction | `references/cro-signup.md` |
| Onboarding | Activation, aha moment | `references/cro-onboarding.md` |
| Pricing page | Plan selection, upgrade | `references/cro-page.md` |
| Paywall | Trial conversion, feature gating | `references/cro-paywall.md` |
| Popup/modal | Timing, copy, targeting | `references/cro-popup.md` |
| Form | Field reduction, validation, UX | `references/cro-form.md` |

### CRO Process
1. Identify the conversion funnel stage
2. Audit current state (screenshots, analytics)
3. Identify friction points and drop-off
4. Propose changes with rationale
5. Design A/B test
6. Implement winning variant

---

## Analytics Tracking

### Implementation Priorities
1. **Conversion events**: signup, purchase, key actions
2. **Funnel stages**: awareness -> interest -> decision -> action
3. **Attribution**: UTM parameters, referrer tracking
4. **Engagement**: page views, time on site, feature usage

### Tools
- PostHog: product analytics, feature flags, session replay
- Google Analytics 4: traffic, acquisition, behavior
- Google Search Console: search performance, indexation
- Google Tag Manager: tag deployment

### Tracking Plan
Define for each event: name, trigger, properties, implementation.

---

## A/B Testing

### Test Design
1. **Hypothesis**: "If we [change], then [metric] will [improve] because [reason]"
2. **Primary metric**: one metric that determines success
3. **Sample size**: calculate required sample for statistical significance
4. **Duration**: minimum 1-2 full business cycles
5. **Segmentation**: who sees which variant

### Common Tests
- Headlines and CTAs
- Pricing page layout
- Onboarding flow steps
- Form field count
- Social proof placement
- Feature page structure

---

## Paid Ads

### Platforms

| Platform | Best For | Format |
|----------|----------|--------|
| Google Ads | Intent-based, search | Search, display, YouTube |
| Meta (FB/IG) | Awareness, retargeting | Image, video, carousel |
| LinkedIn | B2B, professional | Sponsored content, InMail |
| Twitter/X | Tech, developer | Promoted tweets |

### Process
1. Define ICP and targeting criteria
2. Research keywords/audiences
3. Write ad copy (multiple variants)
4. Set up conversion tracking
5. Launch with budget allocation
6. Optimize: pause losers, scale winners

### Key Metrics
- CPA (cost per acquisition)
- ROAS (return on ad spend)
- CTR (click-through rate)
- Quality Score / Relevance Score

---

## Launch Strategy

### Launch Types

| Type | Timeline | Effort |
|------|----------|--------|
| Soft launch | 1 week | Low |
| Feature launch | 2-3 weeks | Medium |
| Product launch | 4-8 weeks | High |
| Major launch | 8-12 weeks | Maximum |

### Phased Launch Framework
1. **Pre-launch**: build anticipation, waitlist, teaser content
2. **Launch day**: coordinated push across all channels
3. **Post-launch**: follow-up content, community engagement, iterate
4. **Ongoing**: every feature update is a mini-launch

### Product Hunt Kit
Generate complete PH launch package:
- Tagline (<=60 chars, 3 variants)
- Description (<=260 chars, 3 variants)
- Maker comment
- Gallery checklist
- Topics selection
- Hunter outreach template
- Launch timeline (week-before, day-of, day-after)

---

## Pricing Strategy

### Research Methods
- Van Westendorp price sensitivity meter
- Conjoint analysis
- Competitive benchmarking
- Value metric identification

### Pricing Models
- Freemium (free tier + paid upgrade)
- Free trial (time-limited full access)
- Usage-based (pay for what you use)
- Per-seat (charge per user)
- Tiered (good/better/best)

### Packaging Principles
- Value metric aligns with customer success
- Clear upgrade path between tiers
- Feature differentiation drives upgrades
- Pricing page reduces decision anxiety

---

## Virality & Distribution

### Social Sharing Infrastructure
- OG images for every shareable page
- Pre-filled share copy
- One-click sharing buttons
- Share-worthy milestone moments

### Referral Programs
- Incentive structure (two-sided rewards)
- Unique referral links
- Progress tracking
- Automated reward fulfillment

### GitHub Marketing
For OSS distribution:
- README optimization (hook, value prop, quick start)
- Star growth tactics
- Contributor onboarding
- Open-core monetization
- Community-led funnels

Reference: `references/github-marketing.md`

---

## Competitor & Alternative Pages

### Four formats
1. **Singular alternative**: "[Your Product]: A [Competitor] Alternative"
2. **Plural alternatives**: "Top 10 [Competitor] Alternatives in 2026"
3. **You vs Competitor**: "[You] vs [Competitor]"
4. **Competitor vs Competitor**: "[A] vs [B] (+ why [You] is better)"

### Content beyond feature tables
- Real user migration stories
- Workflow comparisons (not just feature checks)
- Pricing transparency
- Integration ecosystem comparison
- Support and community comparison

---

## Free Tool Strategy (Engineering as Marketing)

Build free tools for lead gen, SEO, and brand awareness:
1. Identify high-search-volume problems your audience has
2. Build a tool that solves one problem well
3. Gate premium features or results behind signup
4. Optimize for SEO (tool pages rank well)
5. Track: visits, signups, conversion to paid

---

## Marketing Psychology

70+ mental models for marketing application:
- Social proof, scarcity, reciprocity, anchoring
- Loss aversion, endowment effect, sunk cost
- Choice architecture, default effect, framing
- Cognitive load, processing fluency, peak-end rule

Apply ethically. Understand why people buy, influence behavior responsibly.

---

## Marketing Dashboard

```bash
./dashboard.py status          # Quick overview
./dashboard.py seo --period 30d
./dashboard.py ads --period 7d
./dashboard.py revenue --period 90d
./dashboard.py funnel
```

Three metrics that matter:
1. **Traffic source** -- where people came from
2. **Activation** -- did they do the core thing?
3. **Conversion** -- paid or email signup

---

## Growth Sprint (Weekly Ritual)

Weekly loop: Signal -> Offer -> Distribution -> Measurement -> Iterate

1. Pick one product to push
2. Check dashboard for signals
3. Create/update content
4. Distribute across channels
5. Measure results
6. Log in sprint journal

---

## Growth at Scale

**Only use after finding traction** (3+ weeks consistent growth).

Scale what's working:
- MCP server integrations for unified APIs
- Automated ad campaign management
- Newsletter automation
- Referral system at scale
- Cross-channel attribution
