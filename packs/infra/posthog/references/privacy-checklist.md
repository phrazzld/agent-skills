# PostHog Privacy Checklist

When implementing PostHog, ensure these privacy protections are in place.

## Required Configuration

```typescript
posthog.init(POSTHOG_KEY, {
  api_host: '/ingest', // Use proxy to avoid ad blockers

  // User profiles only for authenticated users
  person_profiles: 'identified_only',

  // PRIVACY: Required masking
  mask_all_text: true, // Prevent autocapture text leakage

  // PRIVACY: Session recording masking
  session_recording: {
    maskAllInputs: true, // Mask all input values
    maskTextSelector: '*', // Mask all text in recordings
  },

  // Pageview handling
  capture_pageview: false, // Manual for SPA
  capture_pageleave: true,

  // Autocapture (restricted or disabled)
  autocapture: false, // Prefer explicit tracking

  // Respect Do Not Track
  respect_dnt: true,
});
```

## User Identification

### CORRECT: ID only, no PII

```typescript
if (user) {
  posthog.identify(user.id);
} else {
  posthog.reset();
}
```

### WRONG: Sending PII

```typescript
// ❌ NEVER DO THIS
posthog.identify(user.id, {
  email: user.email,     // ❌ PII
  name: user.fullName,   // ❌ PII
  phone: user.phone,     // ❌ PII
});
```

**Rule:** Only send `user.id` for identification. No email, name, or other PII.

## Privacy Settings Rationale

| Setting | Purpose |
|---------|---------|
| `mask_all_text: true` | Prevents autocapture from sending button/link text that might contain PII |
| `maskAllInputs: true` | Session replays show `***` instead of actual input values |
| `person_profiles: 'identified_only'` | Don't create person profiles for anonymous users |
| `respect_dnt: true` | Honor browser Do Not Track preference |
| `autocapture: false` | Prevents accidental capture of sensitive UI elements |

## Common Privacy Mistakes

### 1. Sending PII to identify()

```typescript
// ❌ WRONG
posthog.identify(userId, { email, name });

// ✓ RIGHT
posthog.identify(userId);
```

### 2. Missing mask_all_text

Text content can leak via autocapture elements. Always set `mask_all_text: true`.

### 3. Missing maskAllInputs

Session replays expose form data without this setting.

### 4. Using direct PostHog host

Direct connections get blocked by ad blockers and expose tracking to third parties.

```typescript
// ❌ WRONG
api_host: 'https://us.i.posthog.com'

// ✓ RIGHT
api_host: '/ingest'
```

### 5. Tracking sensitive data in events

```typescript
// ❌ WRONG
trackEvent("form_submitted", {
  email: formData.email,
  password: formData.password,
});

// ✓ RIGHT
trackEvent("form_submitted", {
  form_type: "signup",
  field_count: Object.keys(formData).length,
});
```

### 6. Missing consent for session recording

In EU/GDPR contexts, session recording requires explicit consent.

```typescript
// Check consent before enabling
if (hasRecordingConsent) {
  posthog.startSessionRecording();
}
```

## Verification Steps

After setup, verify in PostHog dashboard:

1. **Events** — Check that event properties don't contain PII
2. **Session Replays** — Verify inputs show `***` not actual values
3. **Persons** — Profiles should only show user ID, not email/name
4. **Live Events** — No sensitive data visible in event stream

## GDPR Compliance

For EU users:

1. **Cookie consent** — Get consent before initializing PostHog
2. **Data export** — PostHog supports data export for GDPR requests
3. **Data deletion** — Use PostHog API to delete user data on request
4. **Session recording opt-in** — Require explicit consent for recordings

```typescript
// Only init after consent
if (hasAnalyticsConsent) {
  initPostHog();
}

// Only record after recording consent
if (hasRecordingConsent) {
  posthog.startSessionRecording();
}
```

## Environment Variables

Never log or expose these:

```
POSTHOG_API_KEY (server-side)
POSTHOG_PERSONAL_API_KEY (for API access)
```

Safe to expose (in NEXT_PUBLIC_*):

```
NEXT_PUBLIC_POSTHOG_KEY (public project key)
NEXT_PUBLIC_POSTHOG_HOST (API endpoint)
```
