# Readwise Reader

Query the user's Readwise Reader library for saved articles, highlights, and documents.

## Authentication

Source the token, then validate:
```bash
eval "$(grep READWISE_ACCESS_TOKEN ~/.secrets)"
curl -s -o /dev/null -w "%{http_code}" https://readwise.io/api/v2/auth/ \
  -H "Authorization: Token $READWISE_ACCESS_TOKEN"
# 204 = valid
```

All requests use header: `Authorization: Token $READWISE_ACCESS_TOKEN`

## Core Operations

### Search by Topic

No full-text search endpoint exists. Strategy: fetch documents, filter client-side.

```bash
curl -s "https://readwise.io/api/v3/list/?limit=100" \
  -H "Authorization: Token $READWISE_ACCESS_TOKEN" \
  | jq '[.results[] | select(((.title // "") + " " + (.summary // "")) | test("TOPIC"; "i"))]
        | .[] | {title: (.title // "(untitled)"), source_url, summary: (.summary // ""), reading_progress, word_count, saved_at}'
```

Searches all locations by default. Add `&location=later` or `&category=article` to narrow.

### List Recent Saves

```bash
curl -s "https://readwise.io/api/v3/list/?location=new&limit=20" \
  -H "Authorization: Token $READWISE_ACCESS_TOKEN" \
  | jq '.results[] | {title: (.title // "(untitled)"), category, source_url, summary: (.summary // ""), saved_at, word_count}'
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
  | jq '.results[] | {title: (.title // "(untitled)"), source_url, summary: (.summary // "")}'
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
        | .[] | {title: (.title // "(untitled)"), summary: (.summary // ""), notes: (.notes // "")}'
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
