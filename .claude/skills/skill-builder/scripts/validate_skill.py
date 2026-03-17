#!/usr/bin/env python3
"""
Validate agent skill structure and frontmatter.

Usage:
    python validate_skill.py <skill_directory>
    python validate_skill.py ~/.claude/skills/my-skill

Returns JSON with validation results.
"""

import sys
import os
import json
import re
from pathlib import Path


def validate_skill(skill_path: str) -> dict:
    """Validate a skill directory and return results."""
    results = {
        "valid": True,
        "errors": [],
        "warnings": [],
        "info": []
    }

    skill_dir = Path(skill_path)

    # Check directory exists
    if not skill_dir.exists():
        results["valid"] = False
        results["errors"].append(f"Directory does not exist: {skill_path}")
        return results

    if not skill_dir.is_dir():
        results["valid"] = False
        results["errors"].append(f"Path is not a directory: {skill_path}")
        return results

    # Check SKILL.md exists
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        # Check for lowercase variant
        skill_md_lower = skill_dir / "skill.md"
        if skill_md_lower.exists():
            results["warnings"].append("Found skill.md (lowercase) - recommend SKILL.md")
            skill_md = skill_md_lower
        else:
            results["valid"] = False
            results["errors"].append("Missing SKILL.md file")
            return results

    # Read and parse SKILL.md
    content = skill_md.read_text()

    # Check frontmatter exists
    if not content.startswith("---"):
        results["valid"] = False
        results["errors"].append("Missing YAML frontmatter (must start with ---)")
        return results

    # Extract frontmatter
    parts = content.split("---", 2)
    if len(parts) < 3:
        results["valid"] = False
        results["errors"].append("Invalid frontmatter format (missing closing ---)")
        return results

    frontmatter = parts[1].strip()
    body = parts[2].strip()

    # Parse frontmatter (simple YAML parsing)
    fm_dict = {}
    current_key = None
    current_value = []

    for line in frontmatter.split("\n"):
        if line.startswith("  ") and current_key:
            # Continuation of multiline value
            current_value.append(line.strip())
        elif ":" in line:
            # Save previous key-value
            if current_key:
                fm_dict[current_key] = "\n".join(current_value) if current_value else ""
            # Start new key-value
            key, _, value = line.partition(":")
            current_key = key.strip()
            value = value.strip()
            if value == "|":
                current_value = []
            else:
                current_value = [value] if value else []

    # Save last key-value
    if current_key:
        fm_dict[current_key] = "\n".join(current_value) if current_value else ""

    # Validate required fields
    if "name" not in fm_dict:
        results["valid"] = False
        results["errors"].append("Missing required field: name")
    else:
        name = fm_dict["name"]
        # Check name format
        if len(name) > 64:
            results["valid"] = False
            results["errors"].append(f"name too long ({len(name)} chars, max 64)")
        if not re.match(r'^[a-z0-9-]+$', name):
            results["valid"] = False
            results["errors"].append("name must be lowercase letters, numbers, and hyphens only")

    if "description" not in fm_dict:
        results["valid"] = False
        results["errors"].append("Missing required field: description")
    else:
        desc = fm_dict["description"]
        if len(desc) > 1024:
            results["valid"] = False
            results["errors"].append(f"description too long ({len(desc)} chars, max 1024)")
        if len(desc) < 50:
            results["warnings"].append(f"description quite short ({len(desc)} chars) - consider adding trigger terms")

    # Warn on command-surface complexity in frontmatter hints.
    argument_hint = fm_dict.get("argument-hint", "")
    if isinstance(argument_hint, str) and argument_hint:
        argument_flags = set(re.findall(r'--[a-z0-9][a-z0-9-]*', argument_hint))
        if len(argument_flags) > 1:
            results["warnings"].append(
                "argument-hint includes multiple flags; keep happy path intent-first and reserve flags for mechanics"
            )

    # Check body length
    body_lines = len(body.split("\n"))
    if body_lines > 150:
        results["warnings"].append(f"SKILL.md body is {body_lines} lines - consider extracting to references/")

    # Warn when slash-command docs become flag-heavy.
    slash_flag_usages = re.findall(r'/[a-z][a-z-]*\s+--[a-z][a-z-]*', body)
    if len(slash_flag_usages) > 3:
        results["warnings"].append(
            f"Detected {len(slash_flag_usages)} slash-command flag examples; consider simplifying command surface"
        )

    # Check for references/ if content is heavy
    refs_dir = skill_dir / "references"
    if body_lines > 100 and not refs_dir.exists():
        results["warnings"].append("Large SKILL.md without references/ directory - consider progressive disclosure")

    # Check scripts are executable
    scripts_dir = skill_dir / "scripts"
    if scripts_dir.exists():
        for script in scripts_dir.iterdir():
            if script.is_file() and script.suffix in [".py", ".sh", ".bash"]:
                if not os.access(script, os.X_OK):
                    results["warnings"].append(f"Script not executable: {script.name} (run chmod +x)")

    # Info about structure
    if refs_dir.exists():
        ref_files = list(refs_dir.glob("*.md"))
        results["info"].append(f"Found {len(ref_files)} reference files")

    if scripts_dir.exists():
        script_files = list(scripts_dir.iterdir())
        results["info"].append(f"Found {len(script_files)} scripts")

    templates_dir = skill_dir / "templates"
    if templates_dir.exists():
        template_files = list(templates_dir.iterdir())
        results["info"].append(f"Found {len(template_files)} templates")

    return results


def main():
    if len(sys.argv) < 2:
        print(json.dumps({
            "valid": False,
            "errors": ["Usage: validate_skill.py <skill_directory>"],
            "warnings": [],
            "info": []
        }))
        sys.exit(1)

    skill_path = sys.argv[1]
    results = validate_skill(skill_path)

    print(json.dumps(results, indent=2))
    sys.exit(0 if results["valid"] else 1)


if __name__ == "__main__":
    main()
