# Context Lifecycle

Managing context through four phases: Write, Select, Compress, Isolate.

## Write: Creating Context That Doesn't Exist Yet

Not all context pre-exists. Agents must create artifacts that persist
across turns and sessions.

**Scratchpads and working memory:**
- Todo files for multi-step plans (agent writes, reads, updates)
- Progress files for session handoff ("here's where I left off")
- Structured notes that survive context compression

**External memory:**
- File-based memory systems (write findings to disk, read later)
- Git commits as memory (commit messages document decisions)
- Conversation summaries written to persistent storage

**Key principle:** If the agent will need information later, write it down
*now* — don't rely on it surviving in the conversation window.

## Select: Choosing What Enters the Window

Context windows are finite. Selection is the highest-leverage decision.

**Just-in-time loading:**
- Load reference files only when the agent signals it needs them
- Tool results as context delivery (instructions arrive with data)
- Progressive file discovery (read directory → read file → read function)

**Hybrid retrieval:**
- Vector similarity + keyword search (15-25% improvement over pure vector)
- Structured metadata filters before semantic search
- Recency weighting for fast-moving codebases

**What to prioritize (in order):**
1. Task-specific instructions (what to do right now)
2. Relevant code/data (what to work with)
3. Constraints and policies (what not to do)
4. Examples (how it should look)
5. Background knowledge (why it matters)

## Compress: Fitting More Signal in Fixed Space

**Compaction strategies:**
- Summarize conversation history, preserving decisions and open questions
- Drop successful tool results after the agent has acted on them
- Replace verbose code blocks with file references ("see src/auth.ts:45-80")
- Compress "I tried X, it failed because Y" into "X fails (Y)" in summaries

**What to preserve during compression:**
- Architectural decisions and their rationale
- Error messages and failure modes discovered
- User preferences and corrections
- Outstanding questions and unknowns

**What to discard:**
- Redundant tool output (file contents already processed)
- Successful intermediate steps (keep the result, drop the journey)
- Exploratory dead ends (unless the insight matters)

## Isolate: Preventing Context Contamination

**Sub-agent isolation:**
- Each sub-agent gets a clean context with only its task
- Sub-agent returns 1-2K tokens max — a summary, not raw output
- Parent agent never sees sub-agent's full internal reasoning

**State boundaries:**
- Separate "trusted" context (system prompt, verified docs) from
  "untrusted" context (user input, web results, tool output)
- Don't let one task's context leak into another task's window
- Clean context between unrelated tasks in the same session

**Google's `temp:` prefix pattern:**
- Mark turn-scoped data that should not persist: `temp:search_results`
- Session state manager can auto-expire prefixed entries
- Prevents stale results from contaminating future turns

## Prompt Caching Economics

Modern providers cache repeated context prefixes for significant savings.

**Design for caching:**
- Place stable content first (system prompt, reference docs)
- Append-only message history after cached prefix
- Avoid reordering messages (breaks cache)

**Cache-aware context placement:**
```
[System prompt - 2K tokens]     ← CACHED (stable across requests)
[Reference docs - 8K tokens]   ← CACHED (stable across session)
[Conversation - variable]      ← NOT CACHED (changes each turn)
[Current query]                ← NOT CACHED
```

**Economics:**
- Cache write: 25% premium on first request
- Cache read: 90% discount on subsequent requests
- Break-even: 2nd request. ROI increases with every subsequent hit.
- Typical hit rates: 80-92% for well-designed prefixes
- Net cost reduction: 60-90% for conversation workloads

**Anti-pattern:** Inserting dynamic content (timestamps, request IDs) into
the cached prefix. This busts the cache on every request.
