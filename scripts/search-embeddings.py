#!/usr/bin/env python3
"""Search Spellbook skills and agents by semantic similarity.

Embeds a query with Gemini Embedding 2, compares against a locally cached
embeddings corpus, and returns top matches ranked by cosine similarity.

Usage:
    python3 scripts/search-embeddings.py "payment webhook integration"
    python3 scripts/search-embeddings.py --project-dir /path/to/project
    python3 scripts/search-embeddings.py "query" --top 10 --type skill

Requires: GEMINI_API_KEY or GOOGLE_API_KEY env var.
"""

from __future__ import annotations

import json
import math
import os
import subprocess
import sys
from pathlib import Path

from embeddings_cache import (
    discovery_cache_paths,
    is_stale,
    metadata_matches,
    repo_hashes,
)
from gemini_embeddings import embed_texts

REPO_ROOT = Path(__file__).resolve().parent.parent
EMBEDDINGS_FILE, METADATA_FILE = discovery_cache_paths()
GENERATOR = REPO_ROOT / "scripts" / "generate-embeddings.py"
MODEL = "gemini-embedding-2-preview"
DEFAULT_TOP = 15
DEFAULT_DIMS = 768


def cosine_similarity(a: list[float], b: list[float]) -> float:
    dot = sum(x * y for x, y in zip(a, b))
    mag_a = math.sqrt(sum(x * x for x in a))
    mag_b = math.sqrt(sum(x * x for x in b))
    if mag_a == 0 or mag_b == 0:
        return 0.0
    return dot / (mag_a * mag_b)


def embed_query(text: str, dims: int) -> list[float]:
    return embed_texts(
        model=MODEL,
        texts=[text],
        output_dimensionality=dims,
        task_type="RETRIEVAL_QUERY",
        user_agent="spellbook-search",
    )[0]


def synthesize_project_context(project_dir: Path) -> str:
    """Read project signals and synthesize a description for embedding."""
    parts = []

    for name in ["CLAUDE.md", "README.md"]:
        f = project_dir / name
        if f.exists():
            text = f.read_text(encoding="utf-8")[:2000]
            parts.append(text)
            break

    pkg = project_dir / "package.json"
    if pkg.exists():
        try:
            data = json.loads(pkg.read_text(encoding="utf-8"))
            deps = list(data.get("dependencies", {}).keys())
            dev_deps = list(data.get("devDependencies", {}).keys())
            if deps:
                parts.append(f"Dependencies: {', '.join(deps[:30])}")
            if dev_deps:
                parts.append(f"Dev dependencies: {', '.join(dev_deps[:20])}")
        except json.JSONDecodeError:
            pass

    for manifest, label in [
        ("go.mod", "Go module"),
        ("mix.exs", "Elixir project"),
        ("Cargo.toml", "Rust project"),
        ("requirements.txt", "Python deps"),
        ("pyproject.toml", "Python project"),
    ]:
        f = project_dir / manifest
        if f.exists():
            parts.append(f"{label}: {f.read_text(encoding='utf-8')[:1000]}")

    dirs = [
        d.name
        for d in sorted(project_dir.iterdir())
        if d.is_dir() and not d.name.startswith(".")
    ][:20]
    if dirs:
        parts.append(f"Directories: {', '.join(dirs)}")

    if not parts:
        return "General software project"

    return "\n".join(parts)


def ensure_embeddings(dims: int) -> dict:
    current_hashes = repo_hashes(REPO_ROOT)

    if EMBEDDINGS_FILE.exists() and METADATA_FILE.exists():
        metadata = json.loads(METADATA_FILE.read_text(encoding="utf-8"))
        if metadata_matches(
            metadata,
            model=MODEL,
            dimensions=dims,
            index_sha256=current_hashes["index_sha256"],
            registry_sha256=current_hashes["registry_sha256"],
        ) and not is_stale(EMBEDDINGS_FILE):
            return json.loads(EMBEDDINGS_FILE.read_text(encoding="utf-8"))

    print("Embeddings cache missing or stale. Regenerating locally...", file=sys.stderr)
    cmd = [
        sys.executable,
        str(GENERATOR),
        "--dimensions",
        str(dims),
        "--output",
        str(EMBEDDINGS_FILE),
        "--metadata-path",
        str(METADATA_FILE),
    ]
    result = subprocess.run(cmd, cwd=REPO_ROOT)
    if result.returncode == 0 and EMBEDDINGS_FILE.exists():
        return json.loads(EMBEDDINGS_FILE.read_text(encoding="utf-8"))

    if EMBEDDINGS_FILE.exists():
        print("Generation failed, using stale local cache.", file=sys.stderr)
        return json.loads(EMBEDDINGS_FILE.read_text(encoding="utf-8"))

    print("Error: unable to build local embeddings cache.", file=sys.stderr)
    sys.exit(1)


def main():
    top_n = DEFAULT_TOP
    type_filter = None
    query = None
    project_dir = None
    output_json = "--json" in sys.argv

    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--top" and i + 1 < len(args):
            top_n = int(args[i + 1])
            i += 2
        elif args[i] == "--type" and i + 1 < len(args):
            type_filter = args[i + 1]
            i += 2
        elif args[i] == "--project-dir" and i + 1 < len(args):
            project_dir = Path(args[i + 1])
            i += 2
        elif args[i] == "--json":
            i += 1
        elif not args[i].startswith("-"):
            query = args[i]
            i += 1
        else:
            i += 1

    if not query and not project_dir:
        print("Usage: search-embeddings.py <query> | --project-dir <path>", file=sys.stderr)
        sys.exit(1)

    data = ensure_embeddings(DEFAULT_DIMS)
    items = data["items"]
    dims = data["dimensions"]

    if type_filter:
        items = [item for item in items if item["type"] == type_filter]

    if project_dir:
        query_text = synthesize_project_context(project_dir)
        if not output_json:
            print(f"Project context ({len(query_text)} chars):", file=sys.stderr)
            print(f"  {query_text[:200]}...", file=sys.stderr)
    else:
        query_text = query

    query_vec = embed_query(query_text, dims)

    scored = []
    for item in items:
        sim = cosine_similarity(query_vec, item["embedding"])
        scored.append((sim, item))
    scored.sort(key=lambda x: x[0], reverse=True)

    if output_json:
        results = []
        for score, item in scored[:top_n]:
            results.append({
                "score": round(score, 4),
                "type": item["type"],
                "name": item["name"],
                "source": item["source"],
                "fqn": item["fqn"],
                "description": item["description"][:200],
            })
        print(json.dumps(results, indent=2))
        return

    print(f"\nTop {top_n} matches for: {query_text[:80]}{'...' if len(query_text) > 80 else ''}\n")
    for rank, (score, item) in enumerate(scored[:top_n], 1):
        marker = "*" if score > 0.7 else " " if score > 0.5 else "."
        print(f"  {marker} {rank:2d}. [{item['type']:5s}] {item['fqn']}")
        print(f"       score: {score:.4f}  — {item['description'][:100]}")
        print()


if __name__ == "__main__":
    main()
