#!/usr/bin/env python3
"""Spellbook semantic search.

Self-contained: fetches the current Spellbook catalog from GitHub, generates a
local embeddings cache on first use, and reuses that cache until the catalog
changes or the cache ages out.

Usage:
    python3 search.py "payment webhook integration"
    python3 search.py --project-dir /path/to/project
    python3 search.py "query" --top 10 --type skill

Requires: GEMINI_API_KEY or GOOGLE_API_KEY for both query and corpus
embedding generation.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from search_core import (
    MODEL,
    cosine_similarity,
    embed_query,
    embed_texts,
    synthesize_project_context,
)

REPO = "phrazzld/spellbook"
BRANCH = "master"
RAW = f"https://raw.githubusercontent.com/{REPO}/{BRANCH}"
CACHE_TTL = 86400  # 24 hours
FORMAT_VERSION = 1
DEFAULT_TOP = 15
DEFAULT_DIMS = 768
BATCH_SIZE = 20


def spellbook_cache_root() -> Path:
    override = os.environ.get("SPELLBOOK_CACHE_DIR")
    if override:
        return Path(override).expanduser()

    codex_home = os.environ.get("CODEX_HOME")
    if codex_home:
        return Path(codex_home).expanduser() / "cache" / "spellbook"

    xdg_cache = os.environ.get("XDG_CACHE_HOME")
    if xdg_cache:
        return Path(xdg_cache).expanduser() / "spellbook"

    return Path.home() / ".cache" / "spellbook"


def cache_paths() -> tuple[Path, Path]:
    cache_dir = spellbook_cache_root() / "discovery"
    return cache_dir / "embeddings.json", cache_dir / "embeddings-meta.json"


EMBEDDINGS_FILE, METADATA_FILE = cache_paths()


def cache_ttl_seconds() -> int:
    raw = os.environ.get("SPELLBOOK_EMBEDDINGS_TTL_SECONDS")
    if not raw:
        return CACHE_TTL
    try:
        return int(raw)
    except ValueError:
        return CACHE_TTL


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def is_stale(path: Path) -> bool:
    if not path.exists():
        return True
    return time.time() - path.stat().st_mtime > cache_ttl_seconds()


def metadata_matches(metadata: dict, *, dims: int, index_sha256: str, registry_sha256: str) -> bool:
    return (
        metadata.get("format_version") == FORMAT_VERSION
        and metadata.get("model") == MODEL
        and metadata.get("dimensions") == dims
        and metadata.get("index_sha256") == index_sha256
        and metadata.get("registry_sha256") == registry_sha256
    )


def github_headers() -> dict:
    headers = {"Accept": "application/vnd.github.v3+json"}
    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        try:
            result = subprocess.run(
                ["gh", "auth", "token"],
                capture_output=True,
                text=True,
                check=False,
            )
            if result.returncode == 0:
                token = result.stdout.strip()
        except FileNotFoundError:
            pass
    if token:
        headers["Authorization"] = f"token {token}"
    return headers


def fetch_text(url: str, label: str) -> str:
    req = Request(url, headers={"User-Agent": "spellbook-focus"})
    with urlopen(req, timeout=30) as resp:
        return resp.read().decode("utf-8")


def github_get(url: str) -> dict | list | None:
    req = Request(url, headers=github_headers())
    try:
        with urlopen(req, timeout=15) as resp:
            return json.loads(resp.read())
    except HTTPError as e:
        if e.code == 404:
            return None
        print(f"  GitHub API error {e.code}: {url}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"  Fetch error: {e}", file=sys.stderr)
        return None


def github_raw(source: str, path: str) -> str | None:
    for branch in ("main", "master"):
        url = f"https://raw.githubusercontent.com/{source}/{branch}/{path}"
        req = Request(url, headers=github_headers())
        try:
            with urlopen(req, timeout=15) as resp:
                return resp.read().decode("utf-8")
        except Exception:
            continue
    return None


def parse_frontmatter(text: str) -> dict:
    match = re.match(r"^---\s*\n(.*?)\n---", text, re.DOTALL)
    if not match:
        return {}

    fm = {}
    for line in match.group(1).split("\n"):
        if ":" in line and not line.startswith(" ") and not line.startswith("\t"):
            key, _, val = line.partition(":")
            val = val.strip().strip('"').strip("'")
            if val:
                fm[key.strip()] = val

    if "description" not in fm or fm["description"] == "|":
        desc_match = re.search(
            r"description:\s*\|?\s*\n((?:[ \t]+.+\n)+)",
            match.group(1),
        )
        if desc_match:
            lines = desc_match.group(1).split("\n")
            fm["description"] = " ".join(l.strip() for l in lines if l.strip())
    return fm


def parse_index_text(text: str) -> dict:
    try:
        import yaml  # type: ignore

        return yaml.safe_load(text) or {}
    except ImportError:
        pass

    data = {"skills": [], "agents": []}
    section = None
    current = None

    for raw_line in text.splitlines():
        line = raw_line.rstrip()
        stripped = line.strip()

        if stripped in {"skills:", "agents:"}:
            if current and section:
                data[section].append(current)
                current = None
            section = stripped[:-1]
            continue

        if not section or not stripped or stripped.startswith("#"):
            continue

        if line.startswith("  - name: "):
            if current:
                data[section].append(current)
            current = {"name": line.split(": ", 1)[1].strip()}
            continue

        if current and line.startswith("    description: "):
            value = line.split(": ", 1)[1].strip()
            if value.startswith('"') and value.endswith('"'):
                value = value[1:-1].replace('\\"', '"')
            current["description"] = value

    if current and section:
        data[section].append(current)

    return data


def parse_registry_text(text: str) -> dict:
    try:
        import yaml  # type: ignore

        return yaml.safe_load(text) or {}
    except ImportError:
        pass

    sources = []
    in_sources = False
    current = {}
    for line in text.split("\n"):
        stripped = line.strip()
        if stripped == "sources:":
            in_sources = True
            continue
        if in_sources:
            indent = len(line) - len(line.lstrip())
            if indent == 0 and stripped and not stripped.startswith("#"):
                break
            if stripped.startswith("- repo:"):
                if current:
                    sources.append(current)
                current = {"repo": stripped.split(":", 1)[1].strip()}
            elif stripped.startswith("layout:") and current:
                current["layout"] = stripped.split(":", 1)[1].strip()
            elif stripped.startswith("skills_path:") and current:
                current["skills_path"] = stripped.split(":", 1)[1].strip()
    if current:
        sources.append(current)
    return {"sources": sources}


def synthesize_search_document(name: str, description: str, kind: str, source: str) -> str:
    parts = [f"Name: {name}.", f"Source: {source}."]
    parts.append("Type: agent skill." if kind == "skill" else "Type: agent persona.")
    if description:
        parts.append(f"Description: {description}")
    return " ".join(parts)


def collect_index_items(index_text: str) -> list[dict]:
    index = parse_index_text(index_text)
    items = []

    for kind in ("skills", "agents"):
        item_type = "skill" if kind == "skills" else "agent"
        for entry in index.get(kind, []):
            name = entry.get("name")
            description = entry.get("description", "")
            if not name or not description:
                continue
            items.append({
                "type": item_type,
                "name": name,
                "source": REPO,
                "fqn": f"{REPO}@{name}",
                "description": description,
                "search_document": synthesize_search_document(
                    name,
                    description,
                    item_type,
                    REPO,
                ),
            })
    return items


def collect_external_source(src: dict) -> list[dict]:
    source = src["repo"]
    if source == REPO:
        return []

    layout = src.get("layout", "flat")
    items = []

    print(f"  Fetching {source}...", file=sys.stderr)

    if layout == "root":
        text = github_raw(source, "SKILL.md")
        if not text:
            return items
        fm = parse_frontmatter(text)
        name = fm.get("name", source.split("/")[-1])
        description = fm.get("description", "")
        if description:
            items.append({
                "type": "skill",
                "name": name,
                "source": source,
                "fqn": f"{source}@{name}",
                "description": description,
                "search_document": synthesize_search_document(
                    name,
                    description,
                    "skill",
                    source,
                ),
            })
        return items

    if layout == "multi-root":
        entries = github_get(f"https://api.github.com/repos/{source}/contents/")
        if not entries or not isinstance(entries, list):
            return items
        for dirname in sorted(
            d["name"]
            for d in entries
            if d.get("type") == "dir" and not d["name"].startswith(".")
        ):
            text = github_raw(source, f"{dirname}/SKILL.md")
            if not text:
                continue
            fm = parse_frontmatter(text)
            name = fm.get("name", dirname)
            description = fm.get("description", "")
            if not description:
                continue
            items.append({
                "type": "skill",
                "name": name,
                "source": source,
                "fqn": f"{source}@{name}",
                "description": description,
                "search_document": synthesize_search_document(
                    name,
                    description,
                    "skill",
                    source,
                ),
            })
        return items

    skills_path = src.get("skills_path", "skills")
    dirs = github_get(f"https://api.github.com/repos/{source}/contents/{skills_path}")
    if not dirs or not isinstance(dirs, list):
        return items

    for skill_name in sorted(d["name"] for d in dirs if d.get("type") == "dir"):
        text = github_raw(source, f"{skills_path}/{skill_name}/SKILL.md")
        if not text:
            continue
        fm = parse_frontmatter(text)
        name = fm.get("name", skill_name)
        description = fm.get("description", "")
        if not description:
            continue
        items.append({
            "type": "skill",
            "name": name,
            "source": source,
            "fqn": f"{source}@{name}",
            "description": description,
            "search_document": synthesize_search_document(
                name,
                description,
                "skill",
                source,
            ),
        })

    return items


def build_embeddings(index_text: str, registry_text: str, dims: int) -> tuple[dict, dict]:
    index_items = collect_index_items(index_text)
    registry = parse_registry_text(registry_text)
    items = list(index_items)

    sources = []
    for src in registry.get("sources", []):
        repo = src.get("repo")
        if not repo:
            continue
        sources.append(repo)
        items.extend(collect_external_source(src))

    deduped = []
    seen = set()
    for item in items:
        if item["fqn"] in seen:
            continue
        seen.add(item["fqn"])
        deduped.append(item)
    items = deduped

    print(f"  Embedding {len(items)} items locally...", file=sys.stderr)
    all_embeddings = []
    for i in range(0, len(items), BATCH_SIZE):
        batch = items[i : i + BATCH_SIZE]
        texts = [item["search_document"] for item in batch]
        all_embeddings.extend(embed_texts(texts, dims, "RETRIEVAL_DOCUMENT"))
        if i + BATCH_SIZE < len(items):
            time.sleep(0.5)

    for item, embedding in zip(items, all_embeddings):
        item["embedding"] = embedding

    generated = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    data = {
        "format_version": FORMAT_VERSION,
        "model": MODEL,
        "dimensions": dims,
        "sources": sources,
        "generated": generated,
        "count": len(items),
        "items": items,
    }
    metadata = {
        "format_version": FORMAT_VERSION,
        "model": MODEL,
        "dimensions": dims,
        "index_sha256": sha256_text(index_text),
        "registry_sha256": sha256_text(registry_text),
        "generated": generated,
        "count": len(items),
    }
    return data, metadata


def ensure_embeddings(dims: int) -> dict:
    EMBEDDINGS_FILE.parent.mkdir(parents=True, exist_ok=True)

    try:
        index_text = fetch_text(f"{RAW}/index.yaml", "index.yaml")
        registry_text = fetch_text(f"{RAW}/registry.yaml", "registry.yaml")
    except Exception as e:
        if EMBEDDINGS_FILE.exists():
            print(f"  Catalog fetch failed ({e}), using stale cache", file=sys.stderr)
            return json.loads(EMBEDDINGS_FILE.read_text(encoding="utf-8"))
        print(f"  Error fetching Spellbook catalog: {e}", file=sys.stderr)
        sys.exit(1)

    index_sha256 = sha256_text(index_text)
    registry_sha256 = sha256_text(registry_text)

    if EMBEDDINGS_FILE.exists() and METADATA_FILE.exists():
        metadata = json.loads(METADATA_FILE.read_text(encoding="utf-8"))
        if metadata_matches(
            metadata,
            dims=dims,
            index_sha256=index_sha256,
            registry_sha256=registry_sha256,
        ) and not is_stale(EMBEDDINGS_FILE):
            return json.loads(EMBEDDINGS_FILE.read_text(encoding="utf-8"))

    print("  Local embeddings cache missing or stale. Rebuilding...", file=sys.stderr)
    try:
        data, metadata = build_embeddings(index_text, registry_text, dims)
    except Exception as e:
        if EMBEDDINGS_FILE.exists():
            print(f"  Rebuild failed ({e}), using stale cache", file=sys.stderr)
            return json.loads(EMBEDDINGS_FILE.read_text(encoding="utf-8"))
        raise

    EMBEDDINGS_FILE.write_text(json.dumps(data, indent=2), encoding="utf-8")
    METADATA_FILE.write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    return data


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
        print("Usage: search.py <query> | --project-dir <path>", file=sys.stderr)
        print("  --top N        Number of results (default 15)", file=sys.stderr)
        print("  --type skill   Filter by type (skill|agent)", file=sys.stderr)
        print("  --json         Output as JSON", file=sys.stderr)
        sys.exit(1)

    data = ensure_embeddings(DEFAULT_DIMS)
    items = data["items"]
    dims = data["dimensions"]

    if type_filter:
        items = [item for item in items if item["type"] == type_filter]

    if project_dir:
        query_text = synthesize_project_context(project_dir)
        if not output_json:
            print(f"  Analyzing project ({len(query_text)} chars)...", file=sys.stderr)
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
    else:
        header = query_text[:80] if query else f"project: {project_dir}"
        print(f"\nTop {top_n} matches for: {header}{'...' if len(str(header)) > 80 else ''}\n")
        for rank, (score, item) in enumerate(scored[:top_n], 1):
            marker = "*" if score > 0.7 else " " if score > 0.5 else "."
            print(f"  {marker} {rank:2d}. [{item['type']:5s}] {item['fqn']}")
            print(f"       score: {score:.4f}  — {item['description'][:100]}")
            print()


if __name__ == "__main__":
    main()
