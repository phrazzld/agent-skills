# QA and Demo Artifacts

Patterns for manual QA, demo artifact generation, and observability instrumentation.

## Browser QA (Web Apps)

### Starting the dev server

Before QA, verify the dev server is running:

```bash
# Check if already running
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/

# Start if not
bun dev &   # or npm run dev, pnpm dev, etc.
sleep 5     # wait for compilation
```

### Playwright MCP (headless, automated)

Use Playwright MCP for structured, repeatable QA:
- Navigate to affected routes
- Fill forms, click buttons, verify outcomes
- Take full-page screenshots for evidence
- Check for console errors and failed network requests
- Generate traces for debugging if something fails

Best for: regression testing, form flows, multi-step workflows.

### Chrome MCP (live browser, interactive)

Use claude-in-chrome for exploratory QA and demo recording:
- Navigate to the running app in Chrome
- Interact with the feature as a user would
- Record a GIF walkthrough via gif_creator
- Read console messages for errors
- Check network requests for failed calls

Best for: exploratory testing, visual verification, demo artifact capture.

### QA Checklist

For each user-facing change:
- [ ] Happy path works end-to-end
- [ ] Key edge cases from oracle criteria verified
- [ ] No console errors on affected pages
- [ ] No failed network requests
- [ ] Loading/empty/error states render correctly
- [ ] Mobile viewport works (if applicable)

## CLI QA

Run the changed commands with representative inputs:

```bash
# Capture output for evidence
your-cli command --args > /tmp/demo-slug/cli-output.txt 2>&1

# Verify exit code
echo "Exit code: $?"

# Diff against expected output if available
diff expected-output.txt /tmp/demo-slug/cli-output.txt
```

## API QA

```bash
# Hit the endpoint, capture response
curl -s http://localhost:3000/api/endpoint | jq . > /tmp/demo-slug/api-response.json

# Verify status code
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/endpoint

# POST with body
curl -s -X POST http://localhost:3000/api/endpoint \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}' | jq .
```

## Demo Artifact Generation

### GIFs (default for anything visual)

Use chrome MCP's gif_creator for web UI walkthroughs:
1. Navigate to the starting state
2. Start GIF recording
3. Perform the feature walkthrough (capture extra frames before/after actions)
4. Stop recording
5. Name meaningfully: `feature-name-walkthrough.gif`

For CLI demos, use `script` or `asciinema` to record terminal sessions,
then convert to GIF with ffmpeg or a similar tool.

### Screenshots

For single-state evidence (not flows):
- Playwright: full-page screenshot
- Chrome MCP: upload_image after navigating

### Output capture

For non-visual changes:
```bash
mkdir -p /tmp/demo-{slug}

# Before/after test diff
git stash && npm test > /tmp/demo-{slug}/before.txt 2>&1 && git stash pop
npm test > /tmp/demo-{slug}/after.txt 2>&1
diff /tmp/demo-{slug}/before.txt /tmp/demo-{slug}/after.txt > /tmp/demo-{slug}/test-diff.txt
```

## Observability Instrumentation

### Canary integration

If the project uses Canary SDK:
- Register error monitors for new code paths
- Add health probes for new endpoints
- Verify webhook delivery for new event types

### Sentry

- Verify error boundaries wrap new components/routes
- Check that exceptions propagate (no silent catches)
- Verify source maps are configured for new files

### PostHog

- Verify analytics events fire for new user flows
- Check feature flag integration if applicable
- Verify any new funnels are instrumented

### Logging checklist

For each new code path, ask: "If this broke in production at 3am, would I
know from the logs?" If not, add the signal that would tell you.

- Error paths: log with enough context to diagnose (not just "error occurred")
- State transitions: log before/after for critical operations
- External calls: log request/response for debugging
- Not: verbose trace logging, PII, secrets, or high-cardinality fields
