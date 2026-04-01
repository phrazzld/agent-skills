# Exemplar Discovery

Find best-in-class implementations that a project should study for techniques,
not just same-domain prior art. Cross-language, cross-domain inspiration.

## The `exemplars.md` Convention

Projects maintain an `exemplars.md` at project root — a curated list of
reference implementations organized by technique, not language or domain.

```markdown
# Exemplars

## Search / Indexing
- [fff.nvim](https://github.com/dmtrKovalenko/fff.nvim) (Zig)
  **Technique:** SIMD-accelerated fuzzy finding, cache-oblivious memory layout
  **Study for:** hardware-aware search optimization
  **Key file:** `src/simd_search.zig` — core matching loop

## Concurrency
- [crossbeam](https://github.com/crossbeam-rs/crossbeam) (Rust)
  **Technique:** Lock-free data structures, epoch-based memory reclamation
  **Study for:** concurrent data structure design
  **Key file:** `crossbeam-epoch/src/internal.rs` — epoch reclamation
```

### Entry fields

- **Technique** — What it does exceptionally well. Hardware-aware optimization,
  algorithmic breakthrough, elegant API design, etc.
- **Study for** — Why it matters to *this* project. The cross-domain transfer.
- **Key file** — Where to look when cloning. Agents read this file, not the
  whole repo. One file per entry, occasionally two.

### What makes a good exemplar

- **Disproportionate performance** — much faster than it has any right to be.
  The kind of project that makes you wonder what black magic was used.
- **Hardware-aware design** — exploits modern hardware: SIMD, cache-oblivious
  algorithms, io_uring, lock-free concurrency, massive parallelism (64+ cores),
  NVMe-optimized I/O, large memory (256GB+) data structures.
- **Cross-domain transferability** — the technique teaches something applicable
  beyond the project's specific domain. A Zig fuzzy finder can teach a Rust
  search library. A Go scheduler can teach a Python task queue.
- **Readable excellence** — well-structured enough that an agent can clone it,
  read the key file, and extract the core insight in under 5 minutes.

### What is NOT an exemplar

- Popular projects that are merely competent (good but not exceptional)
- Projects valuable only for their API surface, not their implementation
- Frameworks where the value is ecosystem, not technique
- Abandoned projects with no maintenance signal

## Discovery: Exa Queries

### Find best-in-class implementations

```bash
curl -s https://api.exa.ai/search \
  -H "x-api-key: $EXA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fastest [DOMAIN] implementation [TECHNIQUE]",
    "type": "code",
    "numResults": 10,
    "useAutoprompt": true,
    "contents": { "text": { "maxCharacters": 2000 } }
  }'
```

Good query patterns:
- `"fastest [domain] implementation"` — finds performance-focused projects
- `"SIMD [domain] rust OR zig OR c++"` — finds hardware-aware implementations
- `"zero-copy [domain] implementation"` — finds allocation-conscious designs
- `"lock-free [domain]"` — finds concurrent data structures
- `"io_uring [domain]"` — finds modern I/O designs
- `"cache-oblivious [domain]"` — finds memory-hierarchy-aware algorithms

### Expand from a known exemplar

```bash
curl -s https://api.exa.ai/findSimilar \
  -H "x-api-key: $EXA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://github.com/KNOWN_EXEMPLAR",
    "numResults": 10,
    "contents": { "text": { "maxCharacters": 1000 } }
  }'
```

Use when the user provides a seed exemplar — find more projects like it.

## Discovery: xAI Social Signal

Use xAI X Search to find projects developers praise for performance:

```bash
curl -s https://api.x.ai/v1/responses \
  -H "Authorization: Bearer $XAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "grok-4.20-beta-latest-non-reasoning",
    "tools": [{"type": "x_search"}],
    "messages": [{
      "role": "user",
      "content": "What open source [DOMAIN] projects do developers praise as exceptionally fast or well-optimized? Looking for projects with disproportionate performance."
    }]
  }'
```

Social signal surfaces projects that benchmarks and READMEs miss — the ones
developers actually rave about.

## Output Format

Structure results for direct inclusion in `exemplars.md`:

```markdown
## [Technique Domain]
- [Project Name](URL) (Language)
  **Technique:** [what it does exceptionally well]
  **Study for:** [why it matters to the target project]
  **Key file:** `[path]` — [what to learn from this file]
```

When updating an existing `exemplars.md`, preserve existing entries. Add new
entries under existing sections or create new sections. Remove entries only
if the user requests it or the project is dead/archived.

## Integration with Default Fanout

When the standard `/research` fanout surfaces exemplary implementations via Exa
code search (common for queries about "how to build X" or "best approach for Y"),
format implementation-worthy results using the convention above. If
`exemplars.md` exists at project root, offer to add discoveries to it.
