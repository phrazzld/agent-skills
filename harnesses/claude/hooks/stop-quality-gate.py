#!/usr/bin/env python3
"""
End-of-turn quality gate.

Stop hook that runs full quality checks before Claude finishes responding.
STRICT mode: blocks completion (exit 2) on any type/lint/test failure.
Claude must fix issues before being allowed to complete.

This implements the Boris Cherny pattern: "Give Claude a way to verify its work."
"""
import subprocess
import sys
import os
import json

def get_hook_input():
    """Parse hook input from stdin."""
    try:
        return json.loads(sys.stdin.read())
    except:
        return {}

def detect_project(cwd):
    """Detect project type based on config files."""
    if os.path.exists(os.path.join(cwd, "package.json")):
        return "node"
    if os.path.exists(os.path.join(cwd, "pyproject.toml")):
        return "python"
    if os.path.exists(os.path.join(cwd, "Cargo.toml")):
        return "rust"
    if os.path.exists(os.path.join(cwd, "go.mod")):
        return "go"
    return None

def has_command(cmd):
    """Check if a command exists."""
    try:
        subprocess.run(
            ["which", cmd],
            capture_output=True,
            check=True
        )
        return True
    except:
        return False

def run_checks(project_type, cwd):
    """
    Run quality checks in order: type check -> lint -> test.
    Short-circuit on first failure.
    Returns (success, failed_check_name, output)
    """
    checks = []

    if project_type == "node":
        # Just use pnpm test - let package.json handle the test runner flags
        # This avoids issues where package.json already includes 'vitest run'
        # and we'd end up with 'vitest run --run --passWithNoTests'
        checks = [
            ("Type check", ["pnpm", "tsc", "--noEmit"]),
            ("Lint", ["pnpm", "lint"]),
            ("Test", ["pnpm", "test"]),
        ]
    elif project_type == "python":
        checks = [
            ("Type check", ["pyright"]),
            ("Lint", ["ruff", "check", "."]),
            ("Test", ["pytest", "-x", "--tb=short"]),
        ]
    elif project_type == "rust":
        checks = [
            ("Check", ["cargo", "check"]),
            ("Clippy", ["cargo", "clippy", "--", "-D", "warnings"]),
            ("Test", ["cargo", "test"]),
        ]
    elif project_type == "go":
        checks = [
            ("Vet", ["go", "vet", "./..."]),
            ("Test", ["go", "test", "-v", "./..."]),
        ]

    for name, cmd in checks:
        # Skip if command doesn't exist
        if not has_command(cmd[0]):
            continue

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=120,
                cwd=cwd,
                env={**os.environ, "CI": "true"}
            )
            if result.returncode != 0:
                output = result.stdout + result.stderr
                return (False, name, output.strip())
        except subprocess.TimeoutExpired:
            return (False, name, f"{name} timed out after 120s")
        except FileNotFoundError:
            continue  # Skip if command not found

    return (True, None, None)

def check_for_web_project(cwd):
    """Check if this is a web project that needs UI verification."""
    next_config_js = os.path.exists(os.path.join(cwd, "next.config.js"))
    next_config_ts = os.path.exists(os.path.join(cwd, "next.config.ts"))
    next_config_mjs = os.path.exists(os.path.join(cwd, "next.config.mjs"))

    if next_config_js or next_config_ts or next_config_mjs:
        # Check if dev server is running
        try:
            import urllib.request
            urllib.request.urlopen("http://localhost:3000", timeout=2)
            return True
        except:
            pass
    return False

def main():
    hook_input = get_hook_input()
    cwd = hook_input.get("cwd", os.getcwd())

    project_type = detect_project(cwd)

    if not project_type:
        # Not a recognized project - allow completion
        sys.exit(0)

    success, failed_check, output = run_checks(project_type, cwd)

    if not success:
        # STRICT: Block completion, Claude must fix
        print(f"[stop-quality-gate] {failed_check} FAILED", file=sys.stderr)
        print(f"\n{output}", file=sys.stderr)
        print(f"\nFix these issues before completing.", file=sys.stderr)
        sys.exit(2)  # Exit 2 = block stoppage

    # Check if UI verification is needed (informational)
    if check_for_web_project(cwd):
        print("[stop-quality-gate] Web project detected with dev server running.")
        print("Consider using Chrome MCP to verify UI changes visually.")

    print("[stop-quality-gate] All quality checks passed")
    sys.exit(0)

if __name__ == "__main__":
    main()
