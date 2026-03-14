---
name: readwise
description: |
  Search and retrieve saved articles, highlights, and documents from Readwise Reader.
  Use when: researching a topic and the user's reading list may have relevant material,
  looking up saved articles, finding highlights on a subject, "check my readwise",
  "what have I saved about X", "find articles on", "search my reading list",
  "any saved reading on", browsing recent saves, pulling reference material.
argument-hint: "[search topic or command: list, search, tags, recent]"
allowed-tools:
  - Bash(curl:*)
---

# Readwise Reader

Query the user's Readwise Reader library for saved articles, highlights, and documents.

## Authentication

Token is in `$READWISE_ACCESS_TOKEN`. If not in env, source it:
```bash
eval "$(grep READWISE_ACCESS_TOKEN ~/.secrets)"
```

All requests use header: `Authorization: Token $READWISE_ACCESS_TOKEN`

Validate before first use:
```bash
curl -s -o /dev/null -w "%{http_code}" https://readwise.io/api/v2/auth/ \
  -H "Authorization: Token $READWISE_ACCESS_TOKEN"
# 204 = valid
```

## Core Operations

### Search by Topic

No full-text search endpoint exists. Strategy: fetch documents, filter client-side.

```bash
curl -s "https://readwise.io/api/v3/list/?category=article&location=later" \
  -H "Authorization: Token $READWISE_ACCESS_TOKEN" \
  | jq '[.results[] | select(.title + " " + (.summary // "") | test("TOPIC"; "i"))]
        | .[] | {title, source_url, summary, reading_progress, word_count, saved_at}'
```

For broader search, omit `category` and `location` filters. Search across `new`, `later`, and `archive`.

### List Recent Saves

```bash
curl -s "https://readwise.io/api/v3/list/?location=new&limit=20" \
  -H "Authorization: Token $READWISE_ACCESS_TOKEN" \
  | jq '.results[] | {title, category, source_url, summary, saved_at, word_count}'
```

### List by Category

Categories: `article`, `email`, `rss`, `highlight`, `note`, `pdf`, `epub`, `tweet`, `video`

### List by Location

Locations: `new`, `later`, `shortlist`, `archive`, `feed`

### List Tags

```bash
curl -s "https://readwise.io/api/v3/tags/" \
  -H "Authorization: Token $READWISE_ACCESS_TOKEN" \
  | jq '.results[] | .name'
```

### Filter by Tag

```bash
curl -s "https://readwise.io/api/v3/list/?tag=TAG_NAME&limit=20" \
  -H "Authorization: Token $READWISE_ACCESS_TOKEN" \
  | jq '.results[] | {title, source_url, summary}'
```

Up to 5 `tag` params allowed. Empty `tag=` finds untagged documents.

### Get Full Content

```bash
curl -s "https://readwise.io/api/v3/list/?id=DOCUMENT_ID&withHtmlContent=1" \
  -H "Authorization: Token $READWISE_ACCESS_TOKEN" \
  | jq '.results[0].html_content'
```

### Get Highlights

Highlights are documents with `parent_id` pointing to the source document.

```bash
curl -s "https://readwise.io/api/v3/list/?category=highlight&limit=100" \
  -H "Authorization: Token $READWISE_ACCESS_TOKEN" \
  | jq '[.results[] | select(.parent_id == "DOCUMENT_ID")]
        | .[] | {title, summary, notes}'
```

## Pagination

Response includes `nextPageCursor`. Loop until null:

```bash
CURSOR=""
while true; do
  PARAMS="limit=100"
  [ -n "$CURSOR" ] && PARAMS="$PARAMS&pageCursor=$CURSOR"
  RESPONSE=$(curl -s "https://readwise.io/api/v3/list/?$PARAMS" \
    -H "Authorization: Token $READWISE_ACCESS_TOKEN")
  echo "$RESPONSE" | jq '.results[]'
  CURSOR=$(echo "$RESPONSE" | jq -r '.nextPageCursor // empty')
  [ -z "$CURSOR" ] && break
done
```

## Rate Limits

| Endpoint | Limit |
|----------|-------|
| LIST | 20/min |
| CREATE/UPDATE | 50/min |
| BULK UPDATE | 10/min |
| DELETE | 20/min |

On `429`, check `Retry-After` header.

## Workflow Patterns

### Research a Topic
1. Search across all locations for topic keywords
2. Prioritize `shortlist` and `later` (user-curated intent)
3. For promising hits, fetch full content with `withHtmlContent=1`
4. Synthesize findings for the user

### Save Something for Later
```bash
curl -s -X POST "https://readwise.io/api/v3/save/" \
  -H "Authorization: Token $READWISE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"url": "URL", "location": "later", "tags": ["tag1"]}'
```

### Triage Reading List
1. List `new` items
2. Present summaries to user
3. Bulk update locations based on user decisions

For full API details (update, bulk update, delete, webhooks), see `references/api.md`.
