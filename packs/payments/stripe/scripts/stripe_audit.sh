#!/bin/bash
# Stripe Integration Audit Script
# Architecture-aware audit for Stripe integrations
#
# Understands that in Next.js + Convex projects:
# - Stripe SDK runs in Next.js (Vercel), NOT Convex
# - For Next.js webhook handlers that call Convex actions: Convex needs CONVEX_WEBHOOK_TOKEN to validate calls
# - Webhooks hit Next.js API routes; handlers call Convex mutations/actions
#
# Usage:
#   stripe_audit.sh                  # Full audit with Stripe CLI
#   stripe_audit.sh --local-only     # Skip Stripe CLI checks
#   stripe_audit.sh --quiet          # Minimal output (pass/fail only)
#   stripe_audit.sh --strict         # Treat warnings as failures

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Flags
LOCAL_ONLY=false
QUIET=false
STRICT=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --local-only)
      LOCAL_ONLY=true
      ;;
    --quiet)
      QUIET=true
      ;;
    --strict)
      STRICT=true
      ;;
  esac
done

# Counters
PASS=0
WARN=0
FAIL=0

# Logging functions
log_pass() {
  ((PASS++))
  if [ "$QUIET" = false ]; then
    echo -e "${GREEN}✓${NC} $1"
  fi
}

log_warn() {
  ((WARN++))
  if [ "$QUIET" = false ]; then
    echo -e "${YELLOW}⚠${NC} $1"
  fi
}

log_fail() {
  ((FAIL++))
  echo -e "${RED}✗${NC} $1"
}

log_info() {
  if [ "$QUIET" = false ]; then
    echo -e "${BLUE}ℹ${NC} $1"
  fi
}

log_section() {
  if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${BLUE}━━━ $1 ━━━${NC}"
  fi
}

# Detect project structure and return search paths
detect_source_dirs() {
  local dirs=""
  # Next.js App Router
  [ -d "app" ] && dirs="$dirs app/"
  # Next.js Pages Router or general
  [ -d "src" ] && dirs="$dirs src/"
  # Lib directory
  [ -d "lib" ] && dirs="$dirs lib/"
  # Convex directory
  [ -d "convex" ] && dirs="$dirs convex/"
  # Components
  [ -d "components" ] && dirs="$dirs components/"

  if [ -z "$dirs" ]; then
    echo "."
  else
    echo "$dirs"
  fi
}

# Detect project type and architecture
detect_project_type() {
  if [ -d "convex" ]; then
    echo "nextjs-convex"
  elif [ -f "vercel.json" ] || [ -f ".vercel/project.json" ]; then
    echo "vercel"
  elif [ -f "package.json" ]; then
    echo "node"
  else
    echo "unknown"
  fi
}

# Check if Stripe SDK is installed
check_stripe_sdk() {
  log_section "Stripe SDK Detection"

  if grep -q '"stripe"' package.json 2>/dev/null; then
    local version
    version=$(grep '"stripe"' package.json | head -1 | sed 's/.*"\^*\([0-9.]*\)".*/\1/')
    log_pass "Stripe SDK found: v${version}"
    return 0
  else
    log_fail "Stripe SDK not found in package.json"
    return 1
  fi
}

# Check for hardcoded keys
check_hardcoded_keys() {
  log_section "Hardcoded Key Scan"

  local search_dirs
  search_dirs=$(detect_source_dirs)

  local patterns=("sk_test_" "sk_live_" "pk_test_" "pk_live_" "whsec_")
  local found=false

  for pattern in "${patterns[@]}"; do
    local matches
    # shellcheck disable=SC2086
    # Exclude: node_modules, .env files, regex patterns (validation), test assertions
    matches=$(grep -r "$pattern" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" $search_dirs 2>/dev/null \
      | grep -v node_modules \
      | grep -v ".env" \
      | grep -v "pattern:" \
      | grep -v "/\^" \
      | grep -v "RegExp" \
      | grep -v "\.test\." \
      | grep -v "\.spec\." \
      | grep -v "__tests__" \
      | grep -v "expect(" \
      || true)
    if [ -n "$matches" ]; then
      log_fail "Hardcoded key pattern '$pattern' found in source code"
      if [ "$QUIET" = false ]; then
        echo "$matches" | head -3
      fi
      found=true
    fi
  done

  if [ "$found" = false ]; then
    log_pass "No hardcoded Stripe keys in source code"
  fi
}

# Check local env vars for Next.js/Vercel
check_local_env() {
  log_section "Local Environment (.env.local)"

  local required_vars=(
    "STRIPE_SECRET_KEY"
    "STRIPE_WEBHOOK_SECRET"
    "NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY"
  )

  local recommended_vars=(
    "STRIPE_PRICE_ID"
    "CONVEX_WEBHOOK_TOKEN"
  )

  if [ ! -f ".env.local" ]; then
    log_warn ".env.local not found (may be using different env file)"
    return
  fi

  for var in "${required_vars[@]}"; do
    if grep -q "^${var}=" .env.local 2>/dev/null; then
      log_pass "$var is set in .env.local"
    else
      log_fail "$var not found in .env.local"
    fi
  done

  for var in "${recommended_vars[@]}"; do
    if grep -q "^${var}=" .env.local 2>/dev/null; then
      log_pass "$var is set in .env.local"
    else
      log_warn "$var not found in .env.local (recommended)"
    fi
  done
}

# Check Convex env vars - ONLY checks what Convex actually needs
check_convex_env() {
  local use_prod=$1
  local label=$2

  log_section "Convex Environment ($label)"

  local convex_cmd=""
  if command -v bunx &> /dev/null; then
    convex_cmd="bunx convex"
  elif command -v npx &> /dev/null; then
    convex_cmd="npx convex"
  elif command -v convex &> /dev/null; then
    convex_cmd="convex"
  fi

  if [ -z "$convex_cmd" ]; then
    log_warn "Convex CLI not found, skipping Convex env check"
    return
  fi

  local cmd="$convex_cmd env list"
  if [ "$use_prod" = "true" ]; then
    cmd="$convex_cmd env list --prod"
  fi

  local env_output
  env_output=$(eval "$cmd" 2>/dev/null || echo "FAILED")

  if [ "$env_output" = "FAILED" ]; then
    log_warn "Could not list Convex env vars for $label"
    return
  fi

  local search_dirs
  search_dirs=$(detect_source_dirs)

  local webhook_auth_var=""
  # shellcheck disable=SC2086
  if grep -r "CONVEX_WEBHOOK_TOKEN" --include="*.ts" --include="*.tsx" $search_dirs 2>/dev/null | grep -v node_modules | grep -q .; then
    webhook_auth_var="CONVEX_WEBHOOK_TOKEN"
  # shellcheck disable=SC2086
  elif grep -r "CONVEX_WEBHOOK_SECRET" --include="*.ts" --include="*.tsx" $search_dirs 2>/dev/null | grep -v node_modules | grep -q .; then
    webhook_auth_var="CONVEX_WEBHOOK_SECRET"
  fi

  if [ -z "$webhook_auth_var" ]; then
    log_warn "No CONVEX_WEBHOOK_* auth var detected in source; skipping webhook auth check"
  elif echo "$env_output" | grep -q "$webhook_auth_var"; then
    log_pass "$webhook_auth_var is set in Convex $label"
  else
    log_fail "$webhook_auth_var not set in Convex $label (required for webhook auth)"
  fi

  # CLERK_JWT_ISSUER_DOMAIN is needed for Clerk auth
  if echo "$env_output" | grep -q "CLERK_JWT_ISSUER_DOMAIN"; then
    log_pass "CLERK_JWT_ISSUER_DOMAIN is set in Convex $label"
  else
    log_warn "CLERK_JWT_ISSUER_DOMAIN not set in Convex $label (needed for Clerk auth)"
  fi

  # Note: STRIPE_SECRET_KEY is NOT needed in Convex for this architecture
  if echo "$env_output" | grep -q "STRIPE_SECRET_KEY"; then
    log_info "Note: STRIPE_SECRET_KEY found in Convex (usually not needed - Stripe SDK runs in Next.js)"
  fi
}

# Check CONVEX_WEBHOOK_TOKEN parity between Vercel and Convex
# This is CRITICAL for production - Vercel webhook handler must match Convex validator
check_webhook_token_parity() {
  log_section "Webhook Token Parity"

  local convex_cmd=""
  if command -v bunx &> /dev/null; then
    convex_cmd="bunx convex"
  elif command -v npx &> /dev/null; then
    convex_cmd="npx convex"
  elif command -v convex &> /dev/null; then
    convex_cmd="convex"
  fi

  # Check if we can pull Vercel env (requires vercel CLI linked)
  local can_check_vercel=false
  local vercel_cmd=""
  if command -v vercel &> /dev/null; then
    vercel_cmd="vercel"
  elif command -v bunx &> /dev/null; then
    vercel_cmd="bunx vercel"
  elif command -v npx &> /dev/null; then
    vercel_cmd="npx vercel"
  elif command -v pnpm &> /dev/null; then
    vercel_cmd="pnpm dlx vercel"
  fi

  if [ -n "$vercel_cmd" ]; then
    # Try to pull production env
    if eval "$vercel_cmd env pull .env.vercel-parity-check --environment=production --yes" 2>/dev/null; then
      can_check_vercel=true
    fi
  fi

  if [ "$can_check_vercel" = true ]; then
    local vercel_prod_token
    vercel_prod_token=$(grep "^CONVEX_WEBHOOK_TOKEN=" .env.vercel-parity-check 2>/dev/null | cut -d= -f2 | tr -d '"' || true)
    /usr/bin/trash .env.vercel-parity-check 2>/dev/null || rm -f .env.vercel-parity-check 2>/dev/null || true

    local convex_prod_token
    convex_prod_token=$(eval "$convex_cmd env get --prod CONVEX_WEBHOOK_TOKEN" 2>/dev/null || true)

    if [ -n "$vercel_prod_token" ] && [ -n "$convex_prod_token" ]; then
      if [ "$vercel_prod_token" = "$convex_prod_token" ]; then
        log_pass "CONVEX_WEBHOOK_TOKEN matches between Vercel prod and Convex prod (critical!)"
      else
        log_fail "CONVEX_WEBHOOK_TOKEN MISMATCH between Vercel prod and Convex prod"
        log_info "  Webhooks will fail authentication in production!"
        log_info "  Fix: Ensure both platforms have identical secrets"
      fi
    else
      log_warn "Could not verify Vercel ↔ Convex production parity"
    fi
  else
    log_info "Skipping Vercel parity check (vercel CLI not linked)"
  fi

  # Local vs Convex dev check (informational only)
  if [ -f ".env.local" ]; then
    local local_token
    local_token=$(grep "^CONVEX_WEBHOOK_TOKEN=" .env.local 2>/dev/null | cut -d= -f2 || true)

    local convex_dev_token
    convex_dev_token=$(eval "$convex_cmd env get CONVEX_WEBHOOK_TOKEN" 2>/dev/null || true)

    if [ -n "$local_token" ] && [ -n "$convex_dev_token" ]; then
      if [ "$local_token" = "$convex_dev_token" ]; then
        log_pass "CONVEX_WEBHOOK_TOKEN matches between local and Convex dev"
      else
        log_info "CONVEX_WEBHOOK_TOKEN differs between local and Convex dev (check for drift)"
      fi
    fi
  fi
}

# Check webhook signature verification in code
check_webhook_verification() {
  log_section "Webhook Security"

  local search_dirs
  search_dirs=$(detect_source_dirs)

  # Look for constructEvent with various access patterns
  # Supports: stripe.webhooks.constructEvent, getStripe().webhooks.constructEvent, etc.
  local webhook_files
  # shellcheck disable=SC2086
  webhook_files=$(grep -rl "webhooks\.constructEvent\|constructEvent.*signature" --include="*.ts" --include="*.tsx" $search_dirs 2>/dev/null || true)

  if [ -n "$webhook_files" ]; then
    log_pass "Webhook signature verification found"
    if [ "$QUIET" = false ]; then
      echo "$webhook_files" | head -3 | while read -r f; do
        log_info "  → $f"
      done
    fi
  else
    log_fail "No webhook signature verification found (webhooks.constructEvent)"
  fi

  # Check for raw body handling (required for signature verification)
  # Supports: req.text(), request.text(), rawBody, getRawBody
  # shellcheck disable=SC2086
  if grep -r "\.text()\|rawBody\|getRawBody" --include="*.ts" --include="*.tsx" $search_dirs 2>/dev/null | grep -v node_modules | grep -q .; then
    log_pass "Raw body handling found (required for webhook verification)"
  else
    log_warn "Raw body handling not detected (may cause signature verification issues)"
  fi

  # Check for fail-fast env validation in webhook handler
  local webhook_route=""
  [ -f "app/api/webhooks/stripe/route.ts" ] && webhook_route="app/api/webhooks/stripe/route.ts"
  [ -f "src/app/api/webhooks/stripe/route.ts" ] && webhook_route="src/app/api/webhooks/stripe/route.ts"

  if [ -n "$webhook_route" ]; then
    if grep -q "WEBHOOK_SECRET.*not\|!.*WEBHOOK_SECRET" "$webhook_route" 2>/dev/null; then
      log_pass "Fail-fast env validation found in webhook handler"
    else
      log_warn "Consider adding fail-fast validation for STRIPE_WEBHOOK_SECRET"
    fi
  fi
}

# Check for invalid mode-dependent params
check_mode_params() {
  log_section "Mode-Dependent Parameters"

  local search_dirs
  search_dirs=$(detect_source_dirs)

  # Check for customer_creation in subscription mode (exclude test files)
  local bad_pattern
  # shellcheck disable=SC2086
  bad_pattern=$(grep -r "mode.*subscription" --include="*.ts" --include="*.tsx" -A5 $search_dirs 2>/dev/null \
    | grep -v "\.test\." \
    | grep -v "\.spec\." \
    | grep -v "__tests__" \
    | grep -v "toBeUndefined" \
    | grep "customer_creation:" || true)

  if [ -n "$bad_pattern" ]; then
    log_fail "customer_creation may be used with subscription mode (invalid)"
    if [ "$QUIET" = false ]; then
      echo "$bad_pattern" | head -3
    fi
  else
    log_pass "No invalid mode-dependent parameters detected"
  fi
}

# Check health endpoint
check_health_endpoint() {
  log_section "Health Endpoint"

  local health_file=""
  [ -f "app/api/health/route.ts" ] && health_file="app/api/health/route.ts"
  [ -f "src/app/api/health/route.ts" ] && health_file="src/app/api/health/route.ts"
  [ -f "pages/api/health.ts" ] && health_file="pages/api/health.ts"

  if [ -n "$health_file" ]; then
    if grep -qi "stripe\|STRIPE" "$health_file" 2>/dev/null; then
      log_pass "Health endpoint includes Stripe status check"
    else
      log_warn "Health endpoint exists but doesn't check Stripe configuration"
    fi
  else
    log_warn "No health endpoint found at /api/health (recommended for production)"
  fi
}

# Stripe CLI checks
check_stripe_cli() {
  if [ "$LOCAL_ONLY" = true ]; then
    return
  fi

  log_section "Stripe CLI Checks"

  if ! command -v stripe &> /dev/null; then
    log_warn "Stripe CLI not installed, skipping Dashboard verification"
    log_info "Install: brew install stripe/stripe-cli/stripe"
    return
  fi

  # Check if authenticated
  if ! stripe config --list &>/dev/null; then
    log_warn "Stripe CLI not authenticated, skipping Dashboard verification"
    log_info "Run: stripe login"
    return
  fi

  # Check webhook endpoints
  log_info "Checking webhook endpoints..."
  local webhooks
  webhooks=$(stripe webhook_endpoints list --limit 5 2>/dev/null || echo "FAILED")

  if [ "$webhooks" = "FAILED" ]; then
    log_warn "Could not fetch webhook endpoints"
  else
    local count
    count=$(echo "$webhooks" | grep -c "url:" 2>/dev/null || echo 0)
    count=${count//[^0-9]/}
    if [ "$count" -gt 0 ]; then
      log_pass "$count webhook endpoint(s) registered"
    else
      log_fail "No webhook endpoints registered in Stripe Dashboard"
    fi
  fi

  # Check recent events
  log_info "Checking recent events..."
  local events
  events=$(stripe events list --limit 5 2>/dev/null || echo "FAILED")

  if [ "$events" != "FAILED" ]; then
    log_pass "Recent events accessible via Stripe CLI"
  fi
}

# Verify price IDs
check_price_ids() {
  if [ "$LOCAL_ONLY" = true ]; then
    return
  fi

  log_section "Price ID Verification"

  if ! command -v stripe &> /dev/null; then
    return
  fi

  if ! stripe config --list &>/dev/null; then
    return
  fi

  # Get price IDs from env - check multiple possible var names
  local price_id=""

  if [ -f ".env.local" ]; then
    # Try various common naming conventions
    price_id=$(grep -E "^(STRIPE_PRICE_ID|NEXT_PUBLIC_STRIPE_PRICE_ID|NEXT_PUBLIC_STRIPE_MONTHLY_PRICE_ID)" .env.local 2>/dev/null | head -1 | cut -d= -f2 || true)
  fi

  if [ -n "$price_id" ]; then
    if stripe prices retrieve "$price_id" &>/dev/null; then
      log_pass "Price ID is valid: $price_id"
    else
      log_fail "Price ID not found in Stripe: $price_id"
    fi
  else
    log_info "No STRIPE_PRICE_ID found in .env.local"
  fi
}

# Main
main() {
  echo ""
  echo "╔════════════════════════════════════════╗"
  echo "║     Stripe Integration Audit           ║"
  echo "╚════════════════════════════════════════╝"

  PROJECT_TYPE=$(detect_project_type)
  log_info "Project type: $PROJECT_TYPE"
  log_info "Search paths: $(detect_source_dirs)"

  # Environment detection (fail fast on mismatch)
  log_section "Environment Detection"
  if [ -x "$(dirname "$0")/detect-environment.sh" ]; then
    if ! "$(dirname "$0")/detect-environment.sh" --check 2>/dev/null; then
      log_fail "CLI/App environment mismatch detected"
      log_info "Run: $(dirname "$0")/detect-environment.sh for details"
      log_info "Fix environment before continuing audit"
      if [ "$STRICT" = true ]; then
        exit 1
      fi
    else
      log_pass "CLI profile matches app configuration"
    fi
  else
    log_warn "detect-environment.sh not found, skipping environment check"
  fi


  # Run checks
  check_stripe_sdk || true
  check_hardcoded_keys
  check_local_env

  if [ "$PROJECT_TYPE" = "nextjs-convex" ]; then
    check_convex_env "false" "dev"
    check_convex_env "true" "prod"
    check_webhook_token_parity
  fi

  check_webhook_verification
  check_mode_params
  check_health_endpoint
  check_stripe_cli
  check_price_ids

  # Summary
  echo ""
  echo "╔════════════════════════════════════════╗"
  echo "║     Audit Summary                      ║"
  echo "╚════════════════════════════════════════╝"
  echo -e "  ${GREEN}Passed:${NC}  $PASS"
  echo -e "  ${YELLOW}Warnings:${NC} $WARN"
  echo -e "  ${RED}Failed:${NC}  $FAIL"
  echo ""

  local exit_code=0

  if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}Audit failed with $FAIL issue(s)${NC}"
    exit_code=1
  elif [ "$WARN" -gt 0 ]; then
    if [ "$STRICT" = true ]; then
      echo -e "${RED}Audit failed (strict mode) with $WARN warning(s)${NC}"
      exit_code=1
    else
      echo -e "${YELLOW}Audit passed with $WARN warning(s)${NC}"
    fi
  else
    echo -e "${GREEN}Audit passed!${NC}"
  fi

  # Architecture note for Next.js + Convex
  if [ "$PROJECT_TYPE" = "nextjs-convex" ] && [ "$QUIET" = false ]; then
    echo ""
    echo -e "${BLUE}Architecture Note:${NC}"
    echo "  Next.js (Vercel) needs: STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, CONVEX_WEBHOOK_TOKEN"
    echo "  Convex needs: CONVEX_WEBHOOK_TOKEN, CLERK_JWT_ISSUER_DOMAIN"
    echo "  Stripe SDK runs in Next.js API routes, not Convex."
  fi

  exit $exit_code
}

main
