# Reviewer Policy

## Product posture

1. Keep user-exposed reviewer configuration minimal at first.
2. Preserve simplicity as a primary product value.

## Reviewer posture

1. Reviewer prompts should be adversarial by default:
- challenge assumptions
- search for edge cases
- look for regressions and hidden coupling
2. Multiple agentic reviewers are the adversarial layer.
3. Do not force rigid evidence templates; allow free-form findings + inline comments.

## Gate posture

1. Deterministic gates stay mandatory (lint/type/test/build/security).
2. Agentic review complements deterministic gates; it does not replace them.
3. Runtime safety (monitoring, Sentry, incident response, support channels) is a separate mandatory layer.

## Architecture ownership

1. The review engine owns review semantics and prompt strategy.
2. The orchestration layer owns policy routing, quotas, billing, and integrations.
3. Avoid duplicating review logic in orchestration services.
