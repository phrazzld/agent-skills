#!/bin/bash
# Generic Stripe environment detection (works for any project)
# Detects mismatches between app configuration and CLI profiles

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
QUIET=false
CHECK_ONLY=false
for arg in "$@"; do
  case $arg in
    --quiet|-q)
      QUIET=true
      ;;
    --check)
      CHECK_ONLY=true
      ;;
  esac
done

log() {
  if [ "$QUIET" = false ]; then
    echo -e "$1"
  fi
}

# Load secret key from environment or .env.local
load_stripe_key() {
  if [ -n "${STRIPE_SECRET_KEY:-}" ]; then
    echo "$STRIPE_SECRET_KEY"
    return
  fi

  if [ -f ".env.local" ]; then
    local key
    key=$(grep '^STRIPE_SECRET_KEY=' .env.local 2>/dev/null | cut -d= -f2 | tr -d '"' | tr -d "'" || true)
    if [ -n "$key" ]; then
      echo "$key"
      return
    fi
  fi

  echo ""
}

# Get account ID from API key
get_account_from_key() {
  local key="$1"
  if [ -z "$key" ]; then
    echo ""
    return
  fi

  local response
  response=$(curl -s --max-time 5 https://api.stripe.com/v1/account -u "$key:" 2>/dev/null || echo '{"error": true}')

  if echo "$response" | grep -q '"error"'; then
    echo ""
  else
    echo "$response" | grep -o '"id": *"[^"]*"' | head -1 | sed 's/"id": *"\([^"]*\)"/\1/'
  fi
}

# Determine key mode (test vs live)
get_key_mode() {
  local key="$1"
  if echo "$key" | grep -q "^sk_live_"; then
    echo "LIVE"
  elif echo "$key" | grep -q "^sk_test_"; then
    echo "TEST"
  else
    echo "UNKNOWN"
  fi
}

# Get CLI profile account ID
get_cli_profile_account() {
  local profile="$1"
  stripe -p "$profile" config --list 2>&1 | grep "account_id" | cut -d= -f2 | tr -d ' ' || echo ""
}

# Main detection
main() {
  local exit_code=0

  log ""
  log "${BLUE}=== Stripe Environment Detection ===${NC}"
  log ""

  # Get app configuration
  local stripe_key
  stripe_key=$(load_stripe_key)

  if [ -z "$stripe_key" ]; then
    log "${RED}✗${NC} STRIPE_SECRET_KEY not found in environment or .env.local"
    exit 1
  fi

  local app_mode
  app_mode=$(get_key_mode "$stripe_key")

  log "Fetching account info from API..."
  local app_account
  app_account=$(get_account_from_key "$stripe_key")

  if [ -z "$app_account" ]; then
    log "${RED}✗${NC} Could not fetch account from STRIPE_SECRET_KEY (invalid key or network error)"
    exit 1
  fi

  log ""
  log "${BLUE}App Configuration:${NC}"
  log "  Account ID: ${GREEN}$app_account${NC}"
  log "  Key mode:   ${app_mode}"

  # Get CLI profiles
  log ""
  log "${BLUE}CLI Profiles:${NC}"

  local sandbox_account
  sandbox_account=$(get_cli_profile_account "sandbox")
  if [ -n "$sandbox_account" ]; then
    log "  sandbox:    $sandbox_account"
  else
    log "  sandbox:    ${YELLOW}not configured${NC}"
  fi

  local prod_account
  prod_account=$(get_cli_profile_account "production")
  if [ -n "$prod_account" ]; then
    log "  production: $prod_account"
  else
    log "  production: ${YELLOW}not configured${NC}"
  fi

  # Check for match
  log ""
  log "${BLUE}Environment Match:${NC}"

  local matched_profile=""

  if [ "$app_account" = "$sandbox_account" ]; then
    matched_profile="sandbox"
    log "  ${GREEN}✓${NC} App matches CLI ${GREEN}sandbox${NC} profile"
  elif [ "$app_account" = "$prod_account" ]; then
    matched_profile="production"
    if [ "$app_mode" = "LIVE" ]; then
      log "  ${YELLOW}⚠${NC} App matches CLI ${YELLOW}production${NC} profile (LIVE MODE)"
    else
      log "  ${GREEN}✓${NC} App matches CLI ${GREEN}production${NC} profile (test mode)"
    fi
  else
    log "  ${RED}✗${NC} MISMATCH: App account doesn't match any CLI profile"
    log ""
    log "${RED}WARNING: Resources created via CLI won't be visible to your app!${NC}"
    log "  App account:     $app_account"
    log "  CLI sandbox:     ${sandbox_account:-not set}"
    log "  CLI production:  ${prod_account:-not set}"
    log ""
    log "Fix: Use the correct CLI profile or update .env.local:"
    log "  stripe -p sandbox login      # If using sandbox account"
    log "  stripe -p production login   # If using main account"
    exit_code=1
  fi

  # Show recommended usage
  if [ -n "$matched_profile" ] && [ "$QUIET" = false ]; then
    log ""
    log "${BLUE}CLI Usage:${NC}"
    log "  Always use: stripe -p $matched_profile <command>"
    log ""
    log "  Example:"
    log "    stripe -p $matched_profile products list"
    log "    stripe -p $matched_profile prices list"
    log "    stripe -p $matched_profile webhook_endpoints list"
  fi

  # For --check mode, just return exit code
  if [ "$CHECK_ONLY" = true ]; then
    exit $exit_code
  fi

  log ""
  exit $exit_code
}

main
