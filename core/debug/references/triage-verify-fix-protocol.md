# Verify Fix Protocol

Absorbed from the `verify-fix` skill.

## Philosophy

A fix is just a hypothesis until proven by metrics. "That should fix it" is not
verification.

## When to Use

- After applying ANY fix to a production incident
- Before declaring an incident resolved
- When someone says "I think that fixed it"

## Protocol

### 1. Define Observable Success Criteria

Before testing, explicitly state expectations:

```
SUCCESS CRITERIA:
- [ ] Log entry: "[specific log message]"
- [ ] Metric change: [metric] goes from [X] to [Y]
- [ ] Database state: [field] = [expected value]
- [ ] API response: [endpoint] returns [expected response]
```

### 2. Trigger Test Event

```bash
# Webhook issues
stripe events resend [event_id] --webhook-endpoint [endpoint_id]

# API issues
curl -X POST [endpoint] -d '[test payload]'

# Auth issues
# Log in as test user, perform action
```

### 3. Observe Results

```bash
# Real-time logs
vercel logs [app] --json | grep [pattern]
npx convex logs --prod | grep [pattern]

# Check metrics
stripe events retrieve [event_id] | jq '.pending_webhooks'
```

### 4. Verify Database State

```bash
npx convex run --prod [query] '{"id": "[affected_id]"}'
```

### 5. Document Evidence

```
VERIFICATION EVIDENCE:
- Timestamp: [when]
- Test performed: [what we did]
- Log entry observed: [paste relevant log]
- Metric before: [value]
- Metric after: [value]
- Database state confirmed: [yes/no]

VERDICT: [VERIFIED / NOT VERIFIED]
```

## Red Flags (Fix NOT Verified)

- "The code looks right now"
- "The config is correct"
- "It should work"
- "Let's wait and see"
- No log entry observed
- Metrics unchanged
- Can't reproduce original symptom

## If Verification Fails

1. Don't panic -- fix hypothesis was wrong
2. Revert if fix made things worse
3. Loop back to observation phase
4. Question assumptions -- what did we miss?
