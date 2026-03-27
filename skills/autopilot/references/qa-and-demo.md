# QA and Demo Artifacts

These capabilities are now standalone composable skills:

- **`/qa`** — browser-based QA, exploratory testing, evidence capture, bug reporting
- **`/demo`** — demo artifact generation, video composition, narration, PR evidence upload

Autopilot invokes them in steps 5-6. They can also be invoked independently
outside the autopilot pipeline (e.g., after manually shipping, or to iterate
on demo artifacts for an existing PR).

## Observability Instrumentation

This section stays here because it's specific to autopilot's ship workflow.

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
