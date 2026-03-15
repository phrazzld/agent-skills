# Model Verification Hook

A hook that triggers when LLM model names are written, forcing verification that they're current.

## The Problem

LLMs (including the one writing your code) have stale training data. When they write code with model names like `gpt-4` or `claude-3-5-sonnet`, those models may be deprecated, unavailable, or suboptimal.

The hook catches this at write-time and forces verification.

## Implementation

### Hook Script

```python
#!/usr/bin/env python3
"""
model-verification-hook.py

Triggers when code containing LLM model names is written.
Warns the user to verify models are current.
"""

import sys
import re
import json

# Patterns that indicate model names
MODEL_PATTERNS = [
    r'gpt-\d',           # gpt-4, gpt-5, etc.
    r'claude-\d',        # claude-3, claude-4, etc.
    r'gemini-\d',        # gemini-2, gemini-3, etc.
    r'llama-\d',         # llama-3, llama-4, etc.
    r'mistral-',         # mistral models
    r'deepseek-',        # deepseek models
    r'o1-',              # o1 models
    r'o3-',              # o3 models
]

def check_for_models(content: str) -> list[str]:
    """Find model name patterns in content."""
    found = []
    for pattern in MODEL_PATTERNS:
        matches = re.findall(pattern, content, re.IGNORECASE)
        found.extend(matches)
    return list(set(found))

def main():
    # Read hook input from stdin
    hook_input = json.loads(sys.stdin.read())

    tool_name = hook_input.get("tool_name", "")
    tool_input = hook_input.get("tool_input", {})

    # Only check Write and Edit tools
    if tool_name not in ["Write", "Edit"]:
        # Allow other tools
        print(json.dumps({"decision": "approve"}))
        return

    # Get content being written
    content = ""
    if tool_name == "Write":
        content = tool_input.get("content", "")
    elif tool_name == "Edit":
        content = tool_input.get("new_string", "")

    # Check for model patterns
    models_found = check_for_models(content)

    if not models_found:
        # No models found, approve
        print(json.dumps({"decision": "approve"}))
        return

    # Models found - warn user
    warning = f"""
⚠️  MODEL VERIFICATION REQUIRED

Found model references: {', '.join(models_found)}

LLM training data is stale. These models may be:
- Deprecated or unavailable
- Superseded by newer versions
- Suboptimal for this use case

Before proceeding:
1. Do a web search for current SOTA models
2. Verify each model is still available and recommended
3. Consider using environment variables instead of hardcoding

Do you want to proceed with these model names?
"""

    print(json.dumps({
        "decision": "ask",
        "message": warning.strip()
    }))

if __name__ == "__main__":
    main()
```

### Hook Configuration

Add to `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "python3 ~/.claude/hooks/model-verification-hook.py"
      }
    ]
  }
}
```

Or to project-level `.claude/settings.local.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "python3 .claude/hooks/model-verification-hook.py"
      }
    ]
  }
}
```

## How It Works

1. Hook triggers on every Write/Edit tool call
2. Scans content for model name patterns (gpt-, claude-, gemini-, etc.)
3. If models found, warns user and asks for confirmation
4. User must acknowledge they've verified the models are current

## Limitations

- Only catches hardcoded strings, not env vars (which is fine - env vars are the goal)
- Pattern-based, may have false positives/negatives
- Requires user discipline to actually verify

## Alternative: Stricter Version

For stricter enforcement, reject writes with hardcoded models entirely:

```python
if models_found:
    print(json.dumps({
        "decision": "block",
        "message": f"Hardcoded model names detected: {models_found}. Use environment variables instead."
    }))
```

This forces all model names into env vars, which is the recommended pattern.

## Integration with /llm-infrastructure

The `/llm-infrastructure` workflow will:
1. Check if this hook is installed
2. If not, recommend installing it
3. Include it in the "verify" phase

This creates defense-in-depth: the workflow audits existing code, and the hook prevents new violations.
