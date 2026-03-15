#!/usr/bin/env python3
"""
Fetch current models from OpenRouter API.

Usage:
    python fetch-openrouter-models.py [--providers PRESET] [--filter FILTER] [--top N] [--task TASK]

Examples:
    python fetch-openrouter-models.py --providers major --top 20
    python fetch-openrouter-models.py --providers frontier --task coding
    python fetch-openrouter-models.py --providers open --task reasoning --top 15
    python fetch-openrouter-models.py --filter deepseek --top 10
    python fetch-openrouter-models.py --task long_context --top 10

Provider Presets:
    major    - anthropic, openai, google, meta, mistral, deepseek, qwen (default)
    frontier - anthropic, openai, google (current SOTA)
    open     - meta, mistral, deepseek, qwen, nous, phind (open-weight)
    all      - no filter

Environment:
    OPENROUTER_API_KEY: Required. Get from https://openrouter.ai/keys

Output:
    JSON with current model information including pricing, context length, and capabilities.
"""

import os
import sys
import json
import re
import argparse
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError


# Provider presets - patterns for common groupings
PROVIDER_PRESETS = {
    "major": r"anthropic|openai|google|meta|mistral|deepseek|qwen",
    "frontier": r"anthropic|openai|google",
    "open": r"meta|mistral|deepseek|qwen|nous|phind",
    "all": None,
}


def fetch_models(api_key: str) -> list:
    """Fetch all models from OpenRouter API."""
    url = "https://openrouter.ai/api/v1/models"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    req = Request(url, headers=headers)

    try:
        with urlopen(req, timeout=30) as response:
            data = json.loads(response.read().decode())
            return data.get("data", [])
    except HTTPError as e:
        print(json.dumps({"error": f"HTTP {e.code}: {e.reason}"}), file=sys.stderr)
        sys.exit(1)
    except URLError as e:
        print(json.dumps({"error": f"Network error: {e.reason}"}), file=sys.stderr)
        sys.exit(1)


def filter_models(models: list, filter_pattern: str = None) -> list:
    """Filter models by provider/name pattern."""
    if not filter_pattern:
        return models

    pattern = re.compile(filter_pattern, re.IGNORECASE)
    return [m for m in models if pattern.search(m.get("id", ""))]


def categorize_by_task(models: list, task: str) -> list:
    """Sort/filter models by task suitability."""
    task_keywords = {
        "coding": [
            "code", "codex", "coder", "instruct",
            "deepseek", "qwen", "codestral", "starcoder", "phind",
            "devstral", "granite-code", "wizardcoder"
        ],
        "reasoning": [
            "reason", "think", "o1", "o3", "o4", "r1",
            "deepseek-r1", "qwen-qwq", "reflection"
        ],
        "chat": ["chat", "turbo", "instruct"],
        "vision": ["vision", "image", "multimodal", "pro", "4o", "4v"],
        "fast": ["flash", "mini", "haiku", "instant", "turbo", "nano"],
        "long_context": [],  # Sort by context_length
    }

    if task == "long_context":
        return sorted(models, key=lambda m: m.get("context_length", 0), reverse=True)

    keywords = task_keywords.get(task, [])
    if not keywords:
        return models

    def score(model):
        model_id = model.get("id", "").lower()
        model_name = model.get("name", "").lower()
        return sum(1 for kw in keywords if kw in model_id or kw in model_name)

    return sorted(models, key=score, reverse=True)


def format_model(model: dict) -> dict:
    """Format model for output."""
    pricing = model.get("pricing", {})
    top_provider = model.get("top_provider") or {}
    supported_parameters = model.get("supported_parameters") or []

    # Calculate cost per 1M tokens
    prompt_cost = float(pricing.get("prompt", 0)) * 1_000_000
    completion_cost = float(pricing.get("completion", 0)) * 1_000_000

    return {
        "id": model.get("id"),
        "name": model.get("name"),
        "context_length": model.get("context_length", 0),
        "max_completion_tokens": top_provider.get("max_completion_tokens"),
        "supported_parameters": supported_parameters,
        "pricing": {
            "prompt_per_1M": f"${prompt_cost:.2f}",
            "completion_per_1M": f"${completion_cost:.2f}",
        },
        "description": (model.get("description", "") or "")[:150]
    }


def main():
    parser = argparse.ArgumentParser(
        description="Fetch current OpenRouter models",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Provider Presets:
  major    - anthropic, openai, google, meta, mistral, deepseek, qwen
  frontier - anthropic, openai, google (current SOTA)
  open     - meta, mistral, deepseek, qwen, nous, phind (open-weight)
  all      - no filter (default)

Examples:
  %(prog)s --providers major --task coding --top 10
  %(prog)s --providers open --task reasoning
  %(prog)s --filter "deepseek|qwen" --top 20
        """
    )
    parser.add_argument("--providers", "-p", choices=list(PROVIDER_PRESETS.keys()),
                        default="all", help="Provider preset filter (default: all)")
    parser.add_argument("--filter", "-f", help="Additional regex filter for model ID")
    parser.add_argument("--top", "-n", type=int, default=50, help="Return top N models (default: 50)")
    parser.add_argument("--task", "-t",
                        choices=["coding", "reasoning", "chat", "vision", "fast", "long_context"],
                        help="Sort by task suitability")
    parser.add_argument("--raw", action="store_true", help="Output raw API response")
    args = parser.parse_args()

    api_key = os.environ.get("OPENROUTER_API_KEY")
    if not api_key:
        print(json.dumps({
            "error": "OPENROUTER_API_KEY not set",
            "help": "Set environment variable or get key from https://openrouter.ai/keys"
        }))
        sys.exit(1)

    # Fetch models
    models = fetch_models(api_key)
    total_available = len(models)

    # Apply provider preset filter
    provider_pattern = PROVIDER_PRESETS.get(args.providers)
    if provider_pattern:
        models = filter_models(models, provider_pattern)

    # Apply additional custom filter
    if args.filter:
        models = filter_models(models, args.filter)

    # Sort by task
    if args.task:
        models = categorize_by_task(models, args.task)

    # Limit results
    models = models[:args.top]

    # Format output
    if args.raw:
        output = models
    else:
        output = {
            "total_available": total_available,
            "returned": len(models),
            "providers": args.providers,
            "filter": args.filter,
            "task": args.task,
            "models": [format_model(m) for m in models]
        }

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
