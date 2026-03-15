#!/usr/bin/env python3
"""
Validate AI/LLM configuration for common issues.

Usage:
    python validate_llm_config.py <project_directory>
    python validate_llm_config.py ./src

Returns JSON with detected issues and recommendations.
"""

import sys
import os
import re
import json
from pathlib import Path


def scan_file(file_path: Path) -> list:
    """Scan a single file for LLM anti-patterns."""
    findings = []
    content = file_path.read_text()
    lines = content.split('\n')
    uses_openrouter = "openrouter" in content.lower()

    # Pattern 1: Hardcoded API keys
    key_patterns = [
        (r'["\']sk-[a-zA-Z0-9]{20,}["\']', 'OpenAI API key'),
        (r'["\']sk-ant-[a-zA-Z0-9-]+["\']', 'Anthropic API key'),
        (r'OPENAI_API_KEY\s*=\s*["\'][^"\']+["\']', 'OpenAI key assignment'),
        (r'ANTHROPIC_API_KEY\s*=\s*["\'][^"\']+["\']', 'Anthropic key assignment'),
    ]
    for pattern, desc in key_patterns:
        for match in re.finditer(pattern, content):
            line_num = content[:match.start()].count('\n') + 1
            findings.append({
                "file": str(file_path),
                "line": line_num,
                "pattern": "hardcoded_api_key",
                "severity": "critical",
                "message": f"Possible hardcoded {desc} - use environment variables",
                "code": "[REDACTED]"
            })

    # Pattern 2: Missing structured output (JSON.parse on LLM response)
    json_parse_pattern = r'JSON\.parse\s*\(\s*(?:response|result|output|completion)'
    for match in re.finditer(json_parse_pattern, content, re.IGNORECASE):
        line_num = content[:match.start()].count('\n') + 1
        # Check if structured output is used nearby
        context_start = max(0, match.start() - 500)
        context = content[context_start:match.end() + 200]
        if 'response_format' not in context and 'json_schema' not in context:
            findings.append({
                "file": str(file_path),
                "line": line_num,
                "pattern": "manual_json_parsing",
                "severity": "medium",
                "message": "Manual JSON.parse on LLM response - use structured outputs instead",
                "code": match.group()
            })

    # Pattern 2b: Structured outputs without OpenRouter hardening
    if uses_openrouter and "response_format" in content and "json_schema" in content:
        if "require_parameters" not in content:
            findings.append({
                "file": str(file_path),
                "line": 1,
                "pattern": "structured_outputs_missing_require_parameters",
                "severity": "low",
                "message": "OpenRouter structured outputs without provider.require_parameters - providers may ignore schema; add provider: { require_parameters: true }",
                "code": ""
            })
        if "response-healing" not in content:
            findings.append({
                "file": str(file_path),
                "line": 1,
                "pattern": "structured_outputs_missing_response_healing",
                "severity": "low",
                "message": "OpenRouter structured outputs without response-healing plugin - consider plugins: [{ id: 'response-healing' }] for best-effort JSON repair",
                "code": ""
            })
        if not re.search(r'\bmodels\s*:', content):
            findings.append({
                "file": str(file_path),
                "line": 1,
                "pattern": "missing_model_fallbacks",
                "severity": "low",
                "message": "No OpenRouter model fallbacks detected - consider models: [...] for automatic failover",
                "code": ""
            })

    # Pattern 2c: Possibly unsupported sampling params for GPT-5 models
    if uses_openrouter and re.search(r'openai/gpt-5', content) and re.search(r'\btemperature\b', content):
        findings.append({
            "file": str(file_path),
            "line": 1,
            "pattern": "possible_unsupported_temperature",
            "severity": "medium",
            "message": "OpenRouter GPT-5 model + temperature detected - verify model supported_parameters; some GPT-5 variants do not support temperature",
            "code": ""
        })

    # Pattern 3: Deprecated model names
    deprecated_models = [
        ('gpt-4-turbo', 'Use gpt-4o or check current leaderboard'),
        ('gpt-4-0613', 'Deprecated - use gpt-4o or newer'),
        ('gpt-3.5-turbo', 'Consider gpt-4o-mini for better quality at similar cost'),
        ('claude-2', 'Deprecated - use claude-sonnet-4 or newer'),
        ('claude-instant', 'Deprecated - use claude-haiku or newer'),
        ('text-davinci-003', 'Deprecated - use gpt-4o-mini'),
    ]
    for model, rec in deprecated_models:
        if model in content.lower():
            for i, line in enumerate(lines, 1):
                if model in line.lower():
                    findings.append({
                        "file": str(file_path),
                        "line": i,
                        "pattern": "deprecated_model",
                        "severity": "high",
                        "message": f"Deprecated model '{model}' - {rec}",
                        "code": line.strip()[:80]
                    })

    # Pattern 4: No error handling for LLM calls
    llm_call_pattern = r'await\s+(?:openai|anthropic|llm|ai)\.\w+\('
    for match in re.finditer(llm_call_pattern, content, re.IGNORECASE):
        # Check if wrapped in try-catch
        context_start = max(0, match.start() - 300)
        context = content[context_start:match.start()]
        if 'try' not in context and 'catch' not in context[-200:]:
            line_num = content[:match.start()].count('\n') + 1
            findings.append({
                "file": str(file_path),
                "line": line_num,
                "pattern": "missing_error_handling",
                "severity": "medium",
                "message": "LLM call without visible try-catch - add error handling with retries",
                "code": match.group()
            })

    # Pattern 5: No max_tokens limit
    if re.search(r'(?:openai|anthropic|llm)\.\w+\(', content, re.IGNORECASE):
        if 'max_tokens' not in content and 'maxTokens' not in content:
            findings.append({
                "file": str(file_path),
                "line": 1,
                "pattern": "missing_token_limit",
                "severity": "low",
                "message": "No max_tokens limit found - consider adding to control costs",
                "code": ""
            })

    # Pattern 6: No caching for static content
    if 'system' in content and 'messages' in content:
        if 'cache' not in content.lower() and len(content) > 2000:
            findings.append({
                "file": str(file_path),
                "line": 1,
                "pattern": "missing_prompt_caching",
                "severity": "low",
                "message": "Large file with system prompts but no caching - consider prompt caching",
                "code": ""
            })

    # Pattern 7: Manual CoT for reasoning models
    cot_pattern = r'(?:think step by step|let\'s think|reason through)'
    if re.search(cot_pattern, content, re.IGNORECASE):
        # Check if using reasoning model
        if re.search(r'o[134]-|o[134]_', content):
            for i, line in enumerate(lines, 1):
                if re.search(cot_pattern, line, re.IGNORECASE):
                    findings.append({
                        "file": str(file_path),
                        "line": i,
                        "pattern": "cot_with_reasoning_model",
                        "severity": "medium",
                        "message": "Manual CoT prompt with reasoning model (o1/o3/o4) - remove, it degrades performance",
                        "code": line.strip()[:80]
                    })

    return findings


def scan_directory(project_dir: str) -> dict:
    """Scan project directory for LLM anti-patterns."""
    results = {
        "scanned_files": 0,
        "findings": [],
        "summary": {
            "critical": 0,
            "high": 0,
            "medium": 0,
            "low": 0
        }
    }

    project_path = Path(project_dir)

    if not project_path.exists():
        results["error"] = f"Directory does not exist: {project_dir}"
        return results

    # Scan TypeScript and JavaScript files
    patterns = ["**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx"]

    for pattern in patterns:
        for file_path in project_path.glob(pattern):
            # Skip node_modules and other common excludes
            if 'node_modules' in str(file_path) or '.next' in str(file_path):
                continue

            results["scanned_files"] += 1
            try:
                findings = scan_file(file_path)
                results["findings"].extend(findings)
            except Exception as e:
                results["findings"].append({
                    "file": str(file_path),
                    "line": 0,
                    "pattern": "scan_error",
                    "severity": "low",
                    "message": f"Could not scan file: {str(e)}",
                    "code": ""
                })

    # Update summary
    for finding in results["findings"]:
        severity = finding.get("severity", "medium")
        results["summary"][severity] = results["summary"].get(severity, 0) + 1

    return results


def main():
    if len(sys.argv) < 2:
        print(json.dumps({
            "error": "Usage: validate_llm_config.py <project_directory>",
            "scanned_files": 0,
            "findings": [],
            "summary": {}
        }))
        sys.exit(1)

    project_dir = sys.argv[1]
    results = scan_directory(project_dir)

    print(json.dumps(results, indent=2))

    # Exit with error code if critical issues found
    if results["summary"].get("critical", 0) > 0:
        sys.exit(2)
    elif results["summary"].get("high", 0) > 0:
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
