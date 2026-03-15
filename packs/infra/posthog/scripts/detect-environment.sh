#!/usr/bin/env bash
# PostHog environment detection script
# Checks configuration parity across environments

set -euo pipefail

echo "=== PostHog Environment Detection ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass() { echo -e "${GREEN}✓${NC} $1"; }
check_fail() { echo -e "${RED}✗${NC} $1"; }
check_warn() { echo -e "${YELLOW}⚠${NC} $1"; }

errors=0
warnings=0

echo "1. Checking local environment..."
echo "--------------------------------"

# Check for PostHog key in various locations
if [ -f ".env.local" ]; then
  if grep -q "NEXT_PUBLIC_POSTHOG_KEY" .env.local 2>/dev/null; then
    KEY=$(grep "NEXT_PUBLIC_POSTHOG_KEY" .env.local | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    if [[ "$KEY" == phc_* ]]; then
      check_pass "NEXT_PUBLIC_POSTHOG_KEY found (${KEY:0:10}...)"
    else
      check_fail "NEXT_PUBLIC_POSTHOG_KEY has invalid format (should start with phc_)"
      ((errors++))
    fi
  else
    check_fail "NEXT_PUBLIC_POSTHOG_KEY not found in .env.local"
    ((errors++))
  fi

  if grep -q "NEXT_PUBLIC_POSTHOG_HOST" .env.local 2>/dev/null; then
    HOST=$(grep "NEXT_PUBLIC_POSTHOG_HOST" .env.local | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    check_pass "NEXT_PUBLIC_POSTHOG_HOST: $HOST"
  else
    check_warn "NEXT_PUBLIC_POSTHOG_HOST not set (will default to us.i.posthog.com)"
    ((warnings++))
  fi
else
  check_fail ".env.local not found"
  ((errors++))
fi

echo ""
echo "2. Checking package.json..."
echo "---------------------------"

if [ -f "package.json" ]; then
  if grep -q '"posthog-js"' package.json 2>/dev/null; then
    VERSION=$(grep -o '"posthog-js": *"[^"]*"' package.json | cut -d'"' -f4)
    check_pass "posthog-js installed: $VERSION"
  else
    check_fail "posthog-js not found in package.json"
    ((errors++))
  fi

  # Check for posthog-node for server-side
  if grep -q '"posthog-node"' package.json 2>/dev/null; then
    VERSION=$(grep -o '"posthog-node": *"[^"]*"' package.json | cut -d'"' -f4)
    check_pass "posthog-node installed: $VERSION (server-side tracking available)"
  else
    check_warn "posthog-node not installed (no server-side tracking)"
    ((warnings++))
  fi
else
  check_fail "package.json not found"
  ((errors++))
fi

echo ""
echo "3. Checking SDK initialization..."
echo "---------------------------------"

# Look for PostHog provider/initialization
INIT_FILES=$(find . -type f \( -name "*.ts" -o -name "*.tsx" \) -not -path "./node_modules/*" -exec grep -l "posthog.init\|initPostHog\|PostHogProvider" {} \; 2>/dev/null | head -5)

if [ -n "$INIT_FILES" ]; then
  check_pass "PostHog initialization found in:"
  echo "$INIT_FILES" | while read -r file; do
    echo "         - $file"
  done
else
  check_fail "No PostHog initialization found"
  ((errors++))
fi

# Check for privacy settings
PRIVACY_CHECK=$(find . -type f \( -name "*.ts" -o -name "*.tsx" \) -not -path "./node_modules/*" -exec grep -l "mask_all_text\|maskAllInputs" {} \; 2>/dev/null | head -1)

if [ -n "$PRIVACY_CHECK" ]; then
  check_pass "Privacy masking configured"
else
  check_warn "Privacy masking not found (mask_all_text, maskAllInputs)"
  ((warnings++))
fi

echo ""
echo "4. Checking reverse proxy (ad blocker bypass)..."
echo "-------------------------------------------------"

if [ -f "next.config.js" ] || [ -f "next.config.mjs" ] || [ -f "next.config.ts" ]; then
  CONFIG_FILE=$(ls next.config.* 2>/dev/null | head -1)
  if grep -q "ingest\|posthog.com" "$CONFIG_FILE" 2>/dev/null; then
    check_pass "Reverse proxy configured in $CONFIG_FILE"
  else
    check_warn "No reverse proxy found (events may be blocked by ad blockers)"
    ((warnings++))
  fi
else
  check_warn "No next.config found to check for reverse proxy"
  ((warnings++))
fi

echo ""
echo "5. Checking Vercel environment (if available)..."
echo "-------------------------------------------------"

if command -v vercel &> /dev/null; then
  if vercel env ls --environment=production 2>/dev/null | grep -q "POSTHOG"; then
    check_pass "PostHog env vars found in Vercel production"
  else
    check_warn "Could not verify Vercel production env vars"
    ((warnings++))
  fi
else
  check_warn "Vercel CLI not installed (cannot check production env)"
  ((warnings++))
fi

echo ""
echo "=== Summary ==="
if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
  echo -e "${GREEN}All checks passed!${NC}"
  exit 0
elif [ $errors -eq 0 ]; then
  echo -e "${YELLOW}Passed with $warnings warning(s)${NC}"
  exit 0
else
  echo -e "${RED}$errors error(s), $warnings warning(s)${NC}"
  exit 1
fi
