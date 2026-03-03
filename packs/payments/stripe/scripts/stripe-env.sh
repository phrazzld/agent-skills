#!/bin/bash
# Show which Stripe environment is configured for each context
#
# IMPORTANT: Stripe test mode is DEPRECATED. Two accounts exist:
#   sandbox  (acct_1SV2rGD4aITn8Hia) — development, safe to experiment
#   production (acct_1SV2rADIyumDtWyU) — real money, always --live flag
#
# sk_test_* keys from the PRODUCTION account should NEVER be used.
# Use sandbox account keys for development instead.

echo "=== Stripe Environment Map ==="
echo ""
echo "CLI Profiles:"
echo "  sandbox:    $(stripe -p sandbox config --list 2>&1 | grep account_id | cut -d= -f2 || echo 'not configured')"
echo "  production: $(stripe -p production config --list 2>&1 | grep account_id | cut -d= -f2 || echo 'not configured')"
echo ""
echo "Local Environment (.env.local):"
if [ -f .env.local ]; then
  KEY=$(grep '^STRIPE_SECRET_KEY' .env.local 2>/dev/null | cut -d= -f2)
  if [ -n "$KEY" ]; then
    echo "  STRIPE_SECRET_KEY: ${KEY:0:20}..."
    if [[ "$KEY" =~ ^sk_test_51SV2rGD ]]; then
      echo "  Environment: SANDBOX (correct for local dev)"
    elif [[ "$KEY" =~ ^sk_test_51SV2rAD ]]; then
      echo "  WARNING: PRODUCTION ACCOUNT TEST MODE KEY — DEPRECATED"
      echo "  Use sandbox account key instead: stripe -p sandbox ..."
    elif [[ "$KEY" =~ ^sk_live_ ]]; then
      echo "  Environment: PRODUCTION (live money!)"
    else
      echo "  Environment: UNKNOWN"
    fi
  else
    echo "  STRIPE_SECRET_KEY: not set"
  fi
else
  echo "  .env.local not found"
fi
