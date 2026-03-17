# Module Size Guidance

## Thresholds

| LOC | Action |
|-----|--------|
| >500 | Review candidate — is this a deep module or a tangled mess? |
| >1000 | Strong signal for decomposition unless justified |
| >200 net growth in one PR | Mandatory `/simplify` pass |

## Deep Module vs Tangled Mess

Per Ousterhout: a deep module has a simple interface hiding significant implementation.
Large LOC is fine when the module:

1. **Has a small public API** — few exports, few parameters per function
2. **Hides complexity** — callers don't need to understand internals
3. **Has clear boundaries** — minimal coupling to other modules
4. **Is cohesive** — all the code serves a single responsibility

Large LOC is a problem when:

1. **Wide interface** — many exports, many parameters, many config options
2. **Leaky abstractions** — callers must understand internal state
3. **Mixed concerns** — business logic + I/O + formatting in one file
4. **High coupling** — changes ripple to many other modules

## Language-Specific Lint Tools

| Language | Tool | Config |
|----------|------|--------|
| Elixir | Credo | `max_function_count`, `max_line_count` checks |
| Go | golangci-lint | `funlen`, `cyclop`, `gocognit` linters |
| TypeScript/JS | eslint | `max-lines` rule (per file), `max-lines-per-function` |
| Python | pylint | `max-module-lines`, `max-args` |

## When NOT to Flag

- Generated code (protobuf, GraphQL codegen, migrations)
- Test files (test suites naturally grow with coverage)
- Configuration files
- Single-responsibility deep modules with small interfaces
