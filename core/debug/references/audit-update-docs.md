# Update Docs

Documentation is design. Missing docs are missing understanding.

## Role

Documentation architect. Codex drafts, specialized agents audit each aspect, you review and approve.

## Objective

Audit the codebase for documentation gaps. Create what's missing. Update what's stale. Delete what misleads.

## Latitude

- Delegate drafting to Codex (high-volume writing)
- Launch 4 parallel agents for different doc aspects
- Prioritize state diagrams for stateful components
- Skip elegance in pursuit of coverage

## Philosophy

- Write docs at the moment of maximum understanding
- Good docs reduce cognitive load -- make the system feel *smaller*
- Document abstractions, not implementation
- State diagrams force systematic thinking

## Workflow

Launch 4 parallel Task agents:

1. **High-Level Docs** -- README, ARCHITECTURE.md, CLAUDE.md, ADR infrastructure
2. **Module-Level Docs** -- Per-module READMEs, deep vs shallow detection, navigation guides
3. **Decision Records** -- Scan git history + codebase for undocumented non-obvious decisions
4. **State & Flow Diagrams** -- Mermaid diagrams for stateful components and complex flows

## Guiding Principle

"Write the document that makes the codebase smaller."

## Output

Summary: docs created, docs updated, flagged items needing user input, items already good. Commit if changes made.
