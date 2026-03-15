# Feature Flag-Driven Development

Decouple merge from deployment for features >3 days.

## Why Feature Flags

- Merge to main continuously (no long-lived branches)
- Deploy disabled code safely
- Gradual rollout (1% → 10% → 100%)
- Instant rollback without deploy

## Implementation Pattern

```typescript
// flags.ts
export const FLAGS = {
  NEW_AUTH_FLOW: 'new-auth-flow',
  DARK_MODE: 'dark-mode',
} as const;

// usage
if (isEnabled(FLAGS.NEW_AUTH_FLOW)) {
  return <NewAuthFlow />;
}
return <LegacyAuth />;
```

## Flag Lifecycle

1. **Create**: Flag starts disabled
2. **Develop**: Merge behind flag daily
3. **Test**: Enable in staging/preview
4. **Rollout**: Gradual percentage increase
5. **Cleanup**: Remove flag after 100% stable

## Testing Both States

```typescript
describe('Auth', () => {
  it('works with new flow enabled', () => {
    enableFlag(FLAGS.NEW_AUTH_FLOW);
    // test new behavior
  });

  it('works with new flow disabled', () => {
    disableFlag(FLAGS.NEW_AUTH_FLOW);
    // test legacy behavior
  });
});
```

## Flag Services

- **LaunchDarkly**: Full-featured, enterprise
- **Split.io**: A/B testing focus
- **Unleash**: Open source, self-hosted
- **Simple**: Environment variables for small teams

## Anti-Patterns

- Flags never removed (technical debt)
- Nested flag logic (complexity explosion)
- No testing of disabled state
- Flags for permanent configuration (use config instead)
