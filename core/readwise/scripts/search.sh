#!/usr/bin/env bash
# Search Readwise Reader library by keyword across title and summary.
# Usage: search.sh <query> [location] [category] [limit]
# Examples:
#   search.sh "context engineering"
#   search.sh "prompt" later article
#   search.sh "AI agents" archive "" 50

set -euo pipefail

QUERY="${1:?Usage: search.sh <query> [location] [category] [limit]}"
LOCATION="${2:-}"
CATEGORY="${3:-}"
LIMIT="${4:-100}"

# Source token if not already in env
if [ -z "${READWISE_ACCESS_TOKEN:-}" ] && [ -f ~/.secrets ]; then
  eval "$(grep READWISE_ACCESS_TOKEN ~/.secrets)"
fi
: "${READWISE_ACCESS_TOKEN:?Set READWISE_ACCESS_TOKEN or add to ~/.secrets}"

PARAMS="limit=$LIMIT"
[ -n "$LOCATION" ] && PARAMS="$PARAMS&location=$LOCATION"
[ -n "$CATEGORY" ] && PARAMS="$PARAMS&category=$CATEGORY"

CURSOR=""
RESULTS="[]"

while true; do
  PAGE_PARAMS="$PARAMS"
  [ -n "$CURSOR" ] && PAGE_PARAMS="$PAGE_PARAMS&pageCursor=$CURSOR"

  RESPONSE=$(curl -s "https://readwise.io/api/v3/list/?$PAGE_PARAMS" \
    -H "Authorization: Token $READWISE_ACCESS_TOKEN")

  # Filter matches and append
  PAGE_MATCHES=$(echo "$RESPONSE" | jq --arg q "$QUERY" '
    [.results[] | select(
      (.title // "") + " " + (.summary // "") + " " + (.notes // "")
      | test($q; "i")
    ) | {title, source_url, category, location, summary, word_count, reading_progress, saved_at}]
  ')
  RESULTS=$(echo "$RESULTS $PAGE_MATCHES" | jq -s 'add')

  CURSOR=$(echo "$RESPONSE" | jq -r '.nextPageCursor // empty')
  [ -z "$CURSOR" ] && break
done

COUNT=$(echo "$RESULTS" | jq 'length')
echo "$RESULTS" | jq -r --argjson count "$COUNT" '
  if $count == 0 then "No results found."
  else "\($count) result(s):\n" + (
    to_entries[] | "\(.key + 1). \(.value.title)\n   \(.value.source_url)\n   \(.value.category)/\(.value.location) | \(.value.word_count // 0) words | saved \(.value.saved_at // "unknown")\n   \(.value.summary // "(no summary)" | .[0:200])\n"
  ) end
'
