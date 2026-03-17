#!/usr/bin/env python3
"""Quick validation script for skills."""

import sys
import re
from pathlib import Path

try:
    import yaml  # type: ignore
except ImportError:
    yaml = None


ALLOWED_PROPERTIES = {
    "name",
    "description",
    "license",
    "allowed-tools",
    "metadata",
    "user-invocable",
    "disable-model-invocation",
    "argument-hint",
}


def strip_inline_comment(value):
    """Strip YAML inline comments while preserving quoted # characters."""
    in_single = False
    in_double = False
    escaped = False
    out = []

    for ch in value:
        if escaped:
            out.append(ch)
            escaped = False
            continue
        if ch == "\\":
            escaped = True
            out.append(ch)
            continue
        if ch == "'" and not in_double:
            in_single = not in_single
            out.append(ch)
            continue
        if ch == '"' and not in_single:
            in_double = not in_double
            out.append(ch)
            continue
        if ch == "#" and not in_single and not in_double:
            break
        out.append(ch)

    return "".join(out).rstrip()


def parse_frontmatter(frontmatter_text):
    """
    Parse the small frontmatter subset used by skills.

    Supports:
    - key: value
    - key: | multiline values indented with two spaces
    """
    frontmatter = {}
    current_key = None
    multiline_buffer = []

    for raw_line in frontmatter_text.splitlines():
        line = raw_line.rstrip("\n")

        if current_key:
            if raw_line.startswith("  "):
                multiline_buffer.append(raw_line[2:])
                continue
            if not line.strip():
                multiline_buffer.append("")
                continue

            frontmatter[current_key] = "\n".join(multiline_buffer).strip()
            current_key = None
            multiline_buffer = []

        if not line.strip():
            continue

        if ":" not in line:
            return None, f"Invalid frontmatter line: {line}"

        key, value = line.split(":", 1)
        key = key.strip()
        value = strip_inline_comment(value.strip())

        if not key:
            return None, f"Invalid frontmatter line: {line}"

        if value in {"|", ""}:
            current_key = key
            multiline_buffer = []
        else:
            frontmatter[key] = value

    if current_key:
        frontmatter[current_key] = "\n".join(multiline_buffer).strip()

    return frontmatter, None


def validate_skill(skill_path):
    """Basic validation of a skill"""
    skill_path = Path(skill_path)

    # Check SKILL.md exists
    skill_md = skill_path / 'SKILL.md'
    if not skill_md.exists():
        return False, "SKILL.md not found"

    # Read and validate frontmatter
    content = skill_md.read_text()
    if not content.startswith('---'):
        return False, "No YAML frontmatter found"

    # Extract frontmatter
    match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not match:
        return False, "Invalid frontmatter format"

    frontmatter_text = match.group(1)

    # Prefer strict YAML parse when PyYAML is available.
    if yaml is not None:
        try:
            parsed_yaml = yaml.safe_load(frontmatter_text)
        except yaml.YAMLError as e:
            return False, f"Invalid YAML in frontmatter: {e}"
        if parsed_yaml is not None and not isinstance(parsed_yaml, dict):
            return False, "Frontmatter must be a YAML mapping"
        frontmatter = parsed_yaml or {}
    else:
        frontmatter, parse_error = parse_frontmatter(frontmatter_text)
        if parse_error:
            return False, parse_error

    # Check for unexpected properties (excluding nested keys under metadata)
    unexpected_keys = set(frontmatter) - ALLOWED_PROPERTIES
    if unexpected_keys:
        return False, (
            f"Unexpected key(s) in SKILL.md frontmatter: {', '.join(sorted(unexpected_keys))}. "
            f"Allowed properties are: {', '.join(sorted(ALLOWED_PROPERTIES))}"
        )

    # Check required fields
    if 'name' not in frontmatter:
        return False, "Missing 'name' in frontmatter"
    if 'description' not in frontmatter:
        return False, "Missing 'description' in frontmatter"

    # Extract name for validation
    name = frontmatter.get('name', '')
    if not isinstance(name, str):
        return False, f"Name must be a string, got {type(name).__name__}"
    name = name.strip()
    if name:
        # Check naming convention (hyphen-case: lowercase with hyphens)
        if not re.match(r'^[a-z0-9-]+$', name):
            return False, f"Name '{name}' should be hyphen-case (lowercase letters, digits, and hyphens only)"
        if name.startswith('-') or name.endswith('-') or '--' in name:
            return False, f"Name '{name}' cannot start/end with hyphen or contain consecutive hyphens"
        # Check name length (max 64 characters per spec)
        if len(name) > 64:
            return False, f"Name is too long ({len(name)} characters). Maximum is 64 characters."

    # Extract and validate description
    description = frontmatter.get('description', '')
    if not isinstance(description, str):
        return False, f"Description must be a string, got {type(description).__name__}"
    description = description.strip()
    if description:
        # Check description length (max 1024 characters per spec)
        if len(description) > 1024:
            return False, f"Description is too long ({len(description)} characters). Maximum is 1024 characters."

    return True, "Skill is valid!"

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python quick_validate.py <skill_directory>")
        sys.exit(1)

    valid, message = validate_skill(sys.argv[1])
    print(message)
    sys.exit(0 if valid else 1)
