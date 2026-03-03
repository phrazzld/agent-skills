# App Store Submission Checklist (Manual Steps)

These steps still require human accounts, approvals, or console clicks.

## Apple Developer Program enrollment

Steps:

1. Create or use an Apple ID dedicated to the org.
2. Enroll in the Apple Developer Program as an Organization when possible.
3. Complete identity verification and D-U-N-S requirements if prompted.
4. Accept the latest agreements in App Store Connect.
5. Ensure the right team roles exist: Account Holder, Admin, Developer.

Gotcha:

- Missing agreements will block builds and submissions.

## Google Play Developer account setup

Steps:

1. Create a Google account dedicated to the org.
2. Enroll in Google Play Console.
3. Pay the one-time developer registration fee.
4. Complete identity verification.
5. Create the app entry early to unlock track configuration.

Gotcha:

- New accounts often face longer review times.

## App Store review guidelines compliance

Focus areas that cause rejections:

- Account deletion: if you support sign-up, you usually need deletion.
- Sign in with Apple: required when third-party auth is the primary sign-in.
- Subscription clarity: pricing, renewal terms, and cancellation links.
- Data use disclosure: match the privacy nutrition labels to reality.
- Broken flows: anything that looks unfinished gets rejected.

Process:

1. Read the current guidelines in both consoles before release week.
2. Run a manual “happy path + failure path” walkthrough.
3. Record a short submission video for internal review.

## Required screenshots and dimensions

Treat the consoles as the source of truth. Requirements change.

Practical minimums to prepare early:

- iOS: iPhone 6.7" class screenshots (for example 1290 × 2796).
- iOS: iPhone 6.5" class screenshots (for example 1242 × 2688).
- Android: at least one phone set (commonly 1080 × 1920 or higher).
- Tablets: often required if you claim tablet support.

Tips:

- Capture from production-like data, not blank states.
- Avoid debug UI, staging banners, and placeholder text.

## Marketing copy requirements

You will need:

- App name (brand-safe, trademark-checked).
- Subtitle (iOS) or short description (Android).
- Full description.
- Keywords (iOS).
- Promotional text (iOS, optional but useful).
- Support URL and marketing URL.

Guidance:

- Write for clarity, not hype.
- Call out the core value in the first two sentences.
- Avoid claims you cannot prove.

## Privacy policy requirements

You need:

- A public privacy policy URL.
- Policy content that matches your actual data flows.
- Store disclosures that match the policy.

Checklist:

1. List every third-party SDK and what it collects.
2. Map each data type to a user-facing purpose.
3. Confirm the policy and store disclosures say the same thing.

## App signing setup

You cannot skip this; failures show up late.

iOS:

- Ensure the correct Bundle ID exists.
- Ensure certificates and provisioning profiles exist and are valid.
- Confirm the App ID capabilities match the code (for example Push, Sign in with Apple).

Android:

- Decide on Play App Signing and stick with it.
- Ensure you have a keystore and a secure backup plan.
- Keep package name stable once published.

