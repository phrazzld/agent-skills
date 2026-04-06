#!/usr/bin/env bash
set -euo pipefail

# Deterministically fetches ALL review comments and review bodies for a PR.
# Outputs every comment with full body, author, file path, and line number.
# No truncation, no summarization.
#
# Usage:
#   fetch-pr-reviews.sh [PR_NUMBER]
#   fetch-pr-reviews.sh              # infers from current branch
#
# Requires: gh CLI authenticated with repo access.

# ---------------------------------------------------------------------------
# Resolve PR
# ---------------------------------------------------------------------------

if [[ $# -ge 1 ]]; then
  PR="$1"
else
  PR=$(gh pr view --json number -q .number 2>/dev/null) || {
    echo "ERROR: No PR number provided and no PR found for current branch." >&2
    exit 1
  }
fi

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null) || {
  echo "ERROR: Could not determine repository." >&2
  exit 1
}

echo "=== PR #${PR} on ${REPO} ==="
echo ""

# ---------------------------------------------------------------------------
# Fetch review-level comments (top-level review bodies)
# ---------------------------------------------------------------------------

echo "--- REVIEWS ---"
echo ""

gh api "repos/${REPO}/pulls/${PR}/reviews" --paginate -q '
  .[] | select(.body != null and .body != "") |
  "=== Review by \(.user.login) | state=\(.state) | submitted=\(.submitted_at) ===\n\(.body)\n---\n"
' 2>/dev/null || echo "(no review-level comments)"

echo ""

# ---------------------------------------------------------------------------
# Fetch inline review comments (file-level comments with full body)
# ---------------------------------------------------------------------------

echo "--- INLINE COMMENTS ---"
echo ""

gh api "repos/${REPO}/pulls/${PR}/comments" --paginate -q '
  .[] |
  "=== \(.user.login) | \(.path):\(.line // .original_line // "N/A") | \(.created_at) ===",
  "in_reply_to: \(.in_reply_to_id // "none")",
  "",
  .body,
  "",
  "---",
  ""
' 2>/dev/null || echo "(no inline comments)"

# ---------------------------------------------------------------------------
# Fetch issue-level comments (PR conversation thread)
# ---------------------------------------------------------------------------

echo "--- PR CONVERSATION ---"
echo ""

gh api "repos/${REPO}/issues/${PR}/comments" --paginate -q '
  .[] |
  "=== \(.user.login) | \(.created_at) ===",
  "",
  .body,
  "",
  "---",
  ""
' 2>/dev/null || echo "(no conversation comments)"

echo ""
echo "=== END OF REVIEWS FOR PR #${PR} ==="
