# Distribution Playbooks

## 1. Open Core Architecture
**Goal**: Free core + paid layer without forks or bad faith.
- Keep core valuable and stable
- Isolate paid features (gateway, auth, limits) in separate packages
- Avoid “open core” that removes essentials
- Use feature flags for paid tier, not hard forks
- Document boundary in README and LICENSE

## 2. README Conversion
**Goal**: turn repo views into actions.
Include:
- One-line value prop + “why different”
- 10-second quick start
- Deploy buttons (Vercel, Railway)
- Social proof (logos, stars, usage stats)
- Clear upgrade CTA and pricing link

## 3. Star → User Funnel
**Goal**: turn stars into installs.
- Pin “Getting Started” issue or discussion
- Auto-comment on star events? (keep soft)
- Show “Run in 1 command” before feature list
- Add in-product “Powered by OSS” footer

## 4. Deploy Buttons
**Goal**: reduce setup friction to one click.
Provide at least:
- Vercel deploy button
- Railway deploy button
- Optional: Render, Fly, Docker

Example:
```
[![Deploy to Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=REPO_URL)
[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/new/template?template=REPO_URL)
```

## 5. GitHub Sponsors Patterns
**Goal**: fund maintenance without resentment.
- Offer tangible perks: priority support, roadmap input
- Add sponsor badge in README + website
- Tie sponsor revenue to roadmap commitments

## 6. Show HN / Reddit Automation
**Goal**: consistent launch cadence.
- Prepare launch kit (title, tags, demo link)
- Auto-create draft posts on release
- Never spam. Ship real value, then announce.
- Use release notes as launch copy

## 7. GitHub as SEO
**Goal**: make GitHub itself rank.
- Profile README optimized for keywords
- Org README with product overview
- Use topics, tags, and clear repo descriptions
- GitHub Pages for docs + sitemap

## 8. “Powered By” Badges
**Goal**: virality inside user products.
- Lightweight badge for free tier
- Optional removal for paid
- Make it tasteful + trustworthy

## 9. Micro-Plugins for Ecosystems
**Goal**: distribution via existing platforms.
- Shopify app, Chrome extension, Slack app
- Keep scope tiny: 1 workflow, 1 value prop
- Point back to core OSS in onboarding

## 10. OSS → Newsletter → Paid
**Goal**: capture email without dark patterns.
- “Changelog” or “tips” opt-in
- Free templates, launch notes, benchmarks
- Soft CTA to paid in every 3–4 emails

## 11. Community Building
**Goal**: turn users into advocates.
- Good-first-issue pipeline
- Office hours, AMA, Discord/Slack
- Recognize contributors in release notes
