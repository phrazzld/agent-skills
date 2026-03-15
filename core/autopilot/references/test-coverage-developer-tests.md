# Developer Tests

Prefer developer tests over mock-heavy unit tests.

Core rules:

- Test module exports and public behavior
- Couple tests to behavior, decouple them from structure
- Mock only external systems and nondeterminism
- Treat call-order assertions and internal collaborator checks as smells

Good developer tests are:

- Fast
- Deterministic
- Isolated
- Specific on failure
- Behavioral
- Structure-insensitive
- Cheap to read and change

Red flags:

- Refactoring changes tests without changing behavior
- `>3` mocks in one test
- Assertions about which internal object called which method
- Tests that mirror source structure line-for-line
