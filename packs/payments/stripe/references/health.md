# Stripe Webhook Health Check

## Diagnostic Steps

### 1. Check Webhook Endpoints
```bash
stripe webhook_endpoints list | jq '.data[] | {id, url, status, enabled_events}'
```
Red flags: multiple endpoints for same URL, status != "enabled", missing critical events.

### 2. Check for Redirects (CRITICAL)
```bash
curl -s -I -X POST "$WEBHOOK_URL" | head -5
```
Must return 4xx/5xx, NOT 3xx. Stripe won't deliver to redirecting URLs.

### 3. Check Recent Event Delivery
```bash
stripe events list --limit 5 | jq '.data[] | {id, type, created: (.created | todate), pending_webhooks}'
```
pending_webhooks > 0 for old events = delivery failing.

### 4. Test Live Delivery
```bash
RECENT_EVENT=$(stripe events list --limit 1 --type checkout.session.completed | jq -r '.data[0].id')
ENDPOINT_ID=$(stripe webhook_endpoints list | jq -r '.data[0].id')
stripe events resend "$RECENT_EVENT" --webhook-endpoint "$ENDPOINT_ID"
```

## Common Issues
| Symptom | Cause | Fix |
|---------|-------|-----|
| pending_webhooks stays high | Redirect or wrong URL | Update to canonical domain |
| Duplicate endpoints | Created twice | Delete older one |
| Signature verification fails | Wrong secret in env | Get secret from dashboard |
