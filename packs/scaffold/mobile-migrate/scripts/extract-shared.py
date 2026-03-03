#!/usr/bin/env python3
"""
Identify code that can move from apps/web/src to packages/shared.

Heuristic rules:
- Reject React, Next, React Native, Expo, and DOM-coupled files.
- Categorize shareable files into: types, utils, api, constants.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

SOURCE_EXTS = {".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs"}

DISALLOWED_IMPORT_PREFIXES = (
    "react",
    "react-dom",
    "next",
    "react-native",
    "expo",
    "@expo/",
    "@react-navigation/",
    "framer-motion",
)

DOM_USAGE_RE = re.compile(
    r"\b(window|document|navigator|localStorage|sessionStorage|HTMLElement|EventTarget)\b"
)

TYPE_DECL_RE = re.compile(r"\b(type|interface|enum)\s+[A-Z][A-Za-z0-9_]*")
UPPER_CONST_RE = re.compile(r"\bexport\s+const\s+[A-Z0-9_]{2,}\b|\bconst\s+[A-Z0-9_]{2,}\s*=")
EXPORT_FN_RE = re.compile(
    r"\bexport\s+(async\s+)?function\b|\bexport\s+const\s+[a-zA-Z0-9_]+\s*=\s*(async\s*)?\("
)
API_HINT_RE = re.compile(r"\b(fetch|axios|graphql-request|ky|trpc|supabase)\b")
JSX_RE = re.compile(r"</?[A-Za-z][A-Za-z0-9]*\b")


@dataclass
class Finding:
    path: Path
    category: str
    reasons: list[str]

    def to_dict(self) -> dict:
        return {
            "path": str(self.path),
            "category": self.category,
            "reasons": self.reasons,
        }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Report shareable code candidates from apps/web/src."
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=Path.cwd(),
        help="Monorepo root (default: current directory).",
    )
    parser.add_argument(
        "--web-src",
        type=Path,
        default=None,
        help="Override web src path (default: <root>/apps/web/src).",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit JSON instead of human-readable report.",
    )
    return parser.parse_args()


def iter_source_files(root: Path) -> Iterable[Path]:
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix not in SOURCE_EXTS:
            continue
        yield path


def extract_imports(text: str) -> list[str]:
    modules: list[str] = []
    for line in text.splitlines():
        line = line.strip()
        if not line.startswith("import"):
            continue
        # Matches: import x from "mod" OR import "mod"
        m = re.search(r"""from\s+['"]([^'"]+)['"]""", line)
        if not m:
            m = re.search(r"""import\s+['"]([^'"]+)['"]""", line)
        if m:
            modules.append(m.group(1))
    return modules


def has_disallowed_import(modules: Iterable[str]) -> tuple[bool, list[str]]:
    bad: list[str] = []
    for mod in modules:
        for prefix in DISALLOWED_IMPORT_PREFIXES:
            if mod == prefix or mod.startswith(prefix):
                bad.append(mod)
                break
    return (len(bad) > 0, bad)


def has_jsx(path: Path, text: str) -> bool:
    if path.suffix not in {".tsx", ".jsx"}:
        return False
    return JSX_RE.search(text) is not None


def is_shareable(path: Path, text: str) -> tuple[bool, list[str]]:
    reasons: list[str] = []
    modules = extract_imports(text)
    disallowed, bad_mods = has_disallowed_import(modules)
    if disallowed:
        reasons.append(f"disallowed imports: {', '.join(sorted(set(bad_mods)))}")
    if DOM_USAGE_RE.search(text):
        reasons.append("DOM globals detected")
    if has_jsx(path, text):
        reasons.append("JSX detected")
    return (len(reasons) == 0, reasons)


def categorize(path: Path, text: str) -> tuple[str, list[str]]:
    parts = {p.lower() for p in path.parts}
    stem = path.stem.lower()

    # Types: directory hints or explicit type declarations.
    if "types" in parts or stem.endswith("types"):
        return ("types", ["path suggests types module"])
    type_hits = len(TYPE_DECL_RE.findall(text))
    if type_hits >= 2:
        return ("types", [f"type declarations: {type_hits}"])

    # Constants: constants/config dirs or uppercase exports.
    if "constants" in parts or "config" in parts or stem.endswith("constants"):
        return ("constants", ["path suggests constants/config"])
    if UPPER_CONST_RE.search(text):
        return ("constants", ["uppercase constant exports"])

    # API: directory hints or API client keywords.
    if {"api", "client", "clients", "services", "sdk"} & parts:
        return ("api", ["path suggests API client/service"])
    if API_HINT_RE.search(text):
        return ("api", ["API client keywords detected"])

    # Utils: utility dirs or exported functions.
    if {"utils", "lib", "helpers"} & parts:
        return ("utils", ["path suggests utilities"])
    if EXPORT_FN_RE.search(text):
        return ("utils", ["exported functions detected"])

    return ("utils", ["defaulted to utils"])


def analyze(web_src: Path) -> tuple[list[Finding], dict[str, int], int]:
    findings: list[Finding] = []
    skipped = 0

    for path in iter_source_files(web_src):
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            skipped += 1
            continue

        shareable, reject_reasons = is_shareable(path, text)
        if not shareable:
            skipped += 1
            continue

        category, reasons = categorize(path, text)
        findings.append(Finding(path=path, category=category, reasons=reasons))

    counts = {k: 0 for k in ("types", "utils", "api", "constants")}
    for f in findings:
        counts[f.category] += 1

    return findings, counts, skipped


def render_text_report(
    root: Path, web_src: Path, findings: list[Finding], counts: dict[str, int], skipped: int
) -> str:
    lines: list[str] = []
    lines.append("Shared Code Extraction Report")
    lines.append(f"root: {root}")
    lines.append(f"web src: {web_src}")
    lines.append(f"shareable files: {len(findings)}")
    lines.append(f"skipped files: {skipped}")
    lines.append("")

    for category in ("types", "constants", "api", "utils"):
        items = [f for f in findings if f.category == category]
        lines.append(f"[{category}] ({counts[category]})")
        if not items:
            lines.append("  (none)")
            lines.append("")
            continue
        for f in sorted(items, key=lambda x: str(x.path)):
            rel = f.path.relative_to(root)
            lines.append(f"  - {rel} :: {', '.join(f.reasons)}")
        lines.append("")

    lines.append("Next:")
    lines.append("  - Move low-risk types/constants first.")
    lines.append("  - Re-run after each extraction.")
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    root: Path = args.root.resolve()
    web_src = (args.web_src or (root / "apps" / "web" / "src")).resolve()

    if not web_src.exists():
        print(f"ERROR: web src not found: {web_src}", file=sys.stderr)
        return 2

    findings, counts, skipped = analyze(web_src)

    if args.json:
        payload = {
            "root": str(root),
            "web_src": str(web_src),
            "counts": counts,
            "skipped": skipped,
            "findings": [f.to_dict() for f in findings],
        }
        print(json.dumps(payload, indent=2))
        return 0

    print(render_text_report(root, web_src, findings, counts, skipped))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
