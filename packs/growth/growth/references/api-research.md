# Growth API Research

Comprehensive research on APIs and tools for scaling growth.

## Ad Platform APIs

### Google Ads

**API**: Google Ads API (REST)
**MCP Server**: Yes, exists
**Auth**: OAuth 2.0 + Developer Token
**Key endpoints**:
- Campaign management
- Ad groups
- Keywords
- Reporting

**CLI approach**:
```bash
# Via MCP server
mcp__google-ads__campaigns list
mcp__google-ads__campaigns create --budget 50 --type search

# Direct API
curl "https://googleads.googleapis.com/v14/customers/${CUSTOMER_ID}/campaigns" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "developer-token: ${DEV_TOKEN}"
```

### Meta Ads (Facebook/Instagram)

**API**: Marketing API
**MCP Server**: Yes, exists
**Auth**: OAuth 2.0 + App credentials
**Key endpoints**:
- Campaigns
- Ad sets
- Ads
- Insights

**CLI approach**:
```bash
# Via MCP server
mcp__meta-ads__campaigns list --account ${AD_ACCOUNT_ID}
mcp__meta-ads__insights --campaign ${CAMPAIGN_ID} --metric reach,impressions,spend

# Direct API
curl "https://graph.facebook.com/v18.0/${AD_ACCOUNT_ID}/campaigns" \
  -d "access_token=${TOKEN}"
```

### Twitter/X Ads

**API**: Ads API v2
**MCP Server**: Partial
**Auth**: OAuth 2.0
**Key endpoints**:
- Campaigns
- Line items
- Promoted tweets
- Analytics

**Limitations**:
- Approval required
- Rate limits strict
- API access separate from regular Twitter API

### LinkedIn Ads

**API**: Marketing API
**MCP Server**: No
**Auth**: OAuth 2.0
**Key endpoints**:
- Campaigns
- Creatives
- Targeting
- Analytics

**Notes**:
- Requires LinkedIn Partner approval
- Complex targeting options
- Good for B2B

### Reddit Ads

**API**: Ads API
**MCP Server**: No
**Auth**: OAuth 2.0
**Documentation**: Limited

### TikTok Ads

**API**: Marketing API
**MCP Server**: No
**Auth**: Access token
**Good for**: Younger demographics, video content

## Social Media APIs

### Twitter/X API v2

**Endpoints**:
- POST /2/tweets (create tweet)
- GET /2/users/:id/tweets (get tweets)
- POST /2/tweets/:id/retweets (retweet)

**Rate limits**: 300 tweets/15 min (app-level)

**CLI approach**:
```bash
curl -X POST "https://api.twitter.com/2/tweets" \
  -H "Authorization: Bearer ${BEARER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello world!"}'
```

### LinkedIn API

**Marketing API endpoints**:
- POST /ugcPosts (create post)
- GET /organizationalEntityShareStatistics (analytics)

**Requires**: Marketing Developer Platform approval

### Instagram (via Meta Graph API)

**Endpoints**:
- POST /${IG_USER_ID}/media (create media)
- POST /${IG_USER_ID}/media_publish (publish)

**Limitations**: Business accounts only, no direct DM API

### YouTube Data API

**Endpoints**:
- videos.insert (upload)
- videos.update (modify)
- channels.list (stats)

**Good for**: Channel management, not ads

## Unified Social APIs

### Late (getlate.dev)

**Supported platforms**: 13+
- Twitter, LinkedIn, Instagram, Facebook
- TikTok, YouTube, Pinterest
- Threads, Mastodon
- And more

**Pricing**: Generous free tier

**API**:
```bash
curl -X POST "https://api.getlate.dev/v1/posts" \
  -H "Authorization: Bearer ${LATE_API_KEY}" \
  -d '{
    "content": "Hello from all platforms!",
    "platforms": ["twitter", "linkedin", "instagram"]
  }'
```

### Buffer

**Supported platforms**: 6+
- Twitter, Facebook, Instagram
- LinkedIn, Pinterest, TikTok

**API**:
```bash
curl -X POST "https://api.bufferapp.com/1/updates/create.json" \
  -d "access_token=${TOKEN}" \
  -d "text=Hello world" \
  -d "profile_ids[]=${PROFILE_ID}"
```

### SocialPilot / ContentStudio

**Good for**: RSS-to-social automation
**Approach**: Set up RSS feed, auto-post to social

## Newsletter APIs

### Buttondown

**Best for developers**

**Endpoints**:
- POST /emails (send)
- GET /subscribers (list)
- POST /subscribers (add)

```bash
curl -X POST "https://api.buttondown.email/v1/emails" \
  -H "Authorization: Token ${BUTTONDOWN_API_KEY}" \
  -d '{"subject": "Hello", "body": "Content here"}'
```

### ConvertKit (Kit)

**Endpoints**:
- POST /broadcasts (send)
- POST /forms/${FORM_ID}/subscribe (add subscriber)

### Mailchimp

**More complex, but full-featured**

## Referral APIs

### GrowSurf

**Endpoints**:
- POST /participants (add)
- GET /participants/:id/referrals (get referrals)
- POST /rewards (process)

### Dub Partners

**Also handles**: Link tracking, analytics

### Rewardful

**Best for**: Stripe-based products
**Integration**: Direct Stripe webhooks

## Analytics APIs

### Vercel Analytics API (NOT RECOMMENDED)

**DO NOT USE.** While Vercel has a limited API, there is:
- No MCP server
- No CLI access
- No official SDK
- Extremely limited query capabilities

Use PostHog for ALL analytics needs.

### PostHog API (RECOMMENDED)

```bash
curl -X POST "https://app.posthog.com/capture/" \
  -H "Content-Type: application/json" \
  -d '{"api_key": "${POSTHOG_KEY}", "event": "page_view"}'
```

### Stripe API

```bash
# Revenue
stripe balance_transactions list --created[gte]=$(date -v-7d +%s)

# Subscriptions
stripe subscriptions list --status=active
```

### Google Analytics Data API

```bash
curl "https://analyticsdata.googleapis.com/v1beta/properties/${PROPERTY_ID}:runReport" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{"dateRanges": [{"startDate": "7daysAgo", "endDate": "today"}]}'
```

## Browser Automation Fallbacks

For platforms without APIs or with API limitations:

### Claude-in-Chrome Tools

```
mcp__claude-in-chrome__navigate
mcp__claude-in-chrome__read_page
mcp__claude-in-chrome__find
mcp__claude-in-chrome__form_input
mcp__claude-in-chrome__computer (click, type, screenshot)
mcp__claude-in-chrome__gif_creator (record workflows)
```

### Use cases:
- Substack (no API)
- Product Hunt (limited API)
- Reddit (complex auth)
- Any platform without good API access
