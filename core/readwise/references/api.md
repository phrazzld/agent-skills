# Readwise Reader API Reference

Base URL: `https://readwise.io/api/v3/`
Auth: `Authorization: Token $READWISE_ACCESS_TOKEN`
Validation: `GET https://readwise.io/api/v2/auth/` → 204 if valid

## Document LIST

`GET /list/`

| Parameter | Type | Notes |
|-----------|------|-------|
| id | string | Single document lookup |
| updatedAfter | string | ISO 8601 date |
| location | string | `new`, `later`, `shortlist`, `archive`, `feed` |
| category | string | `article`, `email`, `rss`, `highlight`, `note`, `pdf`, `epub`, `tweet`, `video` |
| tag | string | Up to 5; empty value = untagged |
| limit | integer | 1-100 (default: 100) |
| pageCursor | string | Pagination cursor |
| withHtmlContent | boolean | Include `html_content` field |
| withRawSourceUrl | boolean | S3 link, valid 1 hour |

Response fields per document:

```json
{
  "id": "01gwfvp9pyaabcdgmx14f6ha0",
  "url": "https://readwise.io/feed/read/...",
  "source_url": "https://example.com/article",
  "title": "Article Title",
  "author": "Author Name",
  "source": "Source Name",
  "category": "rss",
  "location": "feed",
  "tags": {},
  "site_name": "Site Name",
  "word_count": 819,
  "reading_time": "4 mins",
  "created_at": "2023-03-26T21:02:51.618751+00:00",
  "updated_at": "2023-03-26T21:02:55.453827+00:00",
  "notes": "",
  "published_date": "2023-03-22",
  "summary": "Document summary...",
  "image_url": "https://example.com/image.jpg",
  "parent_id": null,
  "reading_progress": 0.15,
  "first_opened_at": null,
  "last_opened_at": null,
  "saved_at": "2023-03-26T21:02:51.618751+00:00",
  "last_moved_at": "2023-03-27T21:03:52.118752+00:00"
}
```

Highlights and notes have `parent_id` set to source document ID.
Rate limit: 20/min.

## Document CREATE

`POST /save/`

| Parameter | Type | Required | Notes |
|-----------|------|----------|-------|
| url | string | Yes | Unique; can be fabricated |
| html | string | No | If omitted, URL is scraped |
| should_clean_html | boolean | No | Auto-clean + parse metadata |
| title | string | No | |
| author | string | No | |
| summary | string | No | |
| published_date | date | No | ISO 8601 |
| image_url | string | No | |
| location | string | No | `new`, `later`, `archive`, `feed` (default: `new`) |
| category | string | No | |
| saved_using | string | No | Source identifier |
| tags | list | No | `["tag1", "tag2"]` |
| notes | string | No | Top-level note |

Returns `201` (new) or `200` (exists). Rate limit: 50/min.

## Document UPDATE

`PATCH /update/{document_id}/`

All fields optional (omitted = unchanged): `title`, `author`, `summary`, `published_date`, `image_url`, `seen` (boolean), `location`, `category`, `tags` (replaces all), `notes`.

Rate limit: 50/min.

## Document BULK UPDATE

`PATCH /bulk_update/`

Body: `{"updates": [{"id": "...", ...}, ...]}` — max 50 items per request.
Same fields as single update, `id` required per item.
Returns `200` (all ok) or `207` (partial failure). Rate limit: 10/min.

## Document DELETE

`DELETE /delete/{document_id}/` → 204. Rate limit: 20/min.

## Tag LIST

`GET /tags/` — paginated with `pageCursor`. Rate limit: 20/min.

```json
{"count": 2, "nextPageCursor": null, "results": [{"key": "first-tag", "name": "First tag"}]}
```

## Rate Limiting

Per-access-token. On `429 Too Many Requests`, check `Retry-After` header for seconds to wait.
