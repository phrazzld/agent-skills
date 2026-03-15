# Tool Design for Agents

How to design tools that LLMs use effectively. Based on Anthropic's tool
design research and production patterns across agent frameworks.

## Core Principles

### Deep Tools Over Many Thin Tools
Consolidate related operations into fewer, more capable tools.
A single `manage_database` tool with an `action` parameter beats
five separate `create_table`, `insert_row`, `query`, `update`, `delete` tools.

**Why:** Each tool competes for the model's attention. Fewer tools means
better selection accuracy. Deep tools with clear parameters outperform
a sprawl of shallow wrappers.

### Namespace by Service
```
✅ stripe_list_charges, stripe_create_refund, github_create_issue
❌ list_charges, create_refund, create_issue
```
Namespacing prevents ambiguity when multiple services expose similar
operations (every service has a "list" and "create").

### Poka-Yoke Design (Make Misuse Structurally Impossible)
- Required parameters for destructive operations
- Enums over free-text for categorical inputs
- Confirmation parameters for irreversible actions (`confirm_delete: true`)
- Default to safe operations (read-only, dry-run)

```
❌ delete_records(query: string)           // Could delete everything
✅ delete_records(ids: string[], confirm_delete: boolean)  // Bounded, explicit
```

### Zero Functional Overlap
If two tools can accomplish the same task, the model wastes tokens
deciding which to use and sometimes calls both. Each tool should have
a unique, non-overlapping responsibility.

**Audit:** For each tool, ask "Is there another tool that could do this?"
If yes, consolidate or clearly differentiate in descriptions.

## Tool Descriptions

Write descriptions like you're explaining to a new team member:
- What the tool does (one sentence)
- When to use it vs alternatives (decision criteria)
- What the parameters mean (with examples for non-obvious ones)
- What the response contains (so the agent knows what to expect)

```json
{
  "name": "search_codebase",
  "description": "Search for code patterns across the repository. Use this for finding function definitions, usage patterns, or specific strings. For finding files by name, use list_files instead. Returns matching lines with file paths and line numbers.",
  "parameters": {
    "pattern": {
      "type": "string",
      "description": "Regex pattern to search for. Example: 'async function \\w+Auth'"
    },
    "file_glob": {
      "type": "string",
      "description": "Optional file pattern to narrow search. Example: '*.ts' or 'src/**/*.py'"
    }
  }
}
```

## Semantic Returns

Tool responses should return **actionable data**, not raw dumps.

```
❌ Return entire 500-line file when agent asked about one function
✅ Return the function + 5 lines context + file path + line number

❌ Return raw API response with metadata the agent won't use
✅ Return structured result with fields the agent needs for next step

❌ Return "Error" or "Failed"
✅ Return "Permission denied: API key lacks 'write' scope.
   To fix: regenerate key with 'read,write' scopes at settings/api-keys"
```

### Actionable Error Messages
Every error should tell the agent:
1. What failed (specific operation)
2. Why it failed (root cause, not just status code)
3. How to fix it (concrete next step)

### Response Format Control
For tools that can return varying amounts of data, add a `detail_level`
parameter:

```json
{
  "detail_level": {
    "type": "string",
    "enum": ["summary", "standard", "detailed"],
    "description": "summary: counts and names only. standard: key fields. detailed: full records."
  }
}
```

## Evaluation

Test tools with multi-step realistic tasks, measuring:
- **Runtime**: Total time to complete task
- **Tool call count**: Fewer calls = better tool design (model understood tools)
- **Token consumption**: Efficient tools reduce back-and-forth
- **Error recovery**: Does the agent recover from tool errors?
- **Task completion rate**: Does the agent finish successfully?

**Benchmark pattern:** Create 20-50 realistic tasks that require 3-8 tool
calls each. Measure pass@1 and total tool calls. Better tool design shows
up as higher pass@1 with fewer calls.

## Anti-Patterns

### The Thin Wrapper
```
❌ A tool that just proxies to an API with no value-add
```
If the tool doesn't simplify, filter, format, or add context beyond
what a raw API call provides, it's not earning its budget slot.

### The God Tool
```
❌ execute(action: string, params: any)  // Too generic
```
The model can't reason about a tool with unbounded inputs. Tools need
typed, constrained parameters that communicate intent.

### The Silent Failure
```
❌ Tool returns empty response on error
✅ Tool returns explicit error with recovery guidance
```
Agents can't debug what they can't see. Always surface errors clearly.
