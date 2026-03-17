#!/usr/bin/env python3
"""Generate embeddings index for Spellbook skill/agent discovery.

Reads local skills/agents AND fetches from external GitHub sources.
Embeds with Gemini Embedding 2, writes embeddings.json.

Usage:
    python3 scripts/generate-embeddings.py [--dimensions 768] [--dry-run]

Requires: GEMINI_API_KEY or GOOGLE_API_KEY env var.
Optional: GITHUB_TOKEN for higher rate limits on external sources.
"""

import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import HTTPError

REPO_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_ROOT / "skills"
AGENTS_DIR = REPO_ROOT / "agents"
REGISTRY_FILE = REPO_ROOT / "registry.yaml"
OUTPUT_FILE = REPO_ROOT / "embeddings.json"
LOCAL_SOURCE = "phrazzld/spellbook"
MODEL = "gemini-embedding-2-preview"
DEFAULT_DIMS = 768
BATCH_SIZE = 20


def load_external_sources() -> list[dict]:
    """Read external sources from registry.yaml (single source of truth)."""
    try:
        import yaml

        registry = yaml.safe_load(REGISTRY_FILE.read_text(encoding="utf-8"))
    except ImportError:
        # Fallback: minimal YAML parsing for our simple list format
        registry = _parse_registry_minimal(REGISTRY_FILE.read_text(encoding="utf-8"))

    sources = []
    for src in registry.get("sources", []):
        repo = src.get("repo", "")
        if repo == LOCAL_SOURCE:
            continue  # Skip self — local skills are collected separately
        entry = {"source": repo, "layout": src.get("layout", "flat")}
        if "skills_path" in src:
            entry["skills_path"] = src["skills_path"]
        sources.append(entry)
    return sources


def _parse_registry_minimal(text: str) -> dict:
    """Parse registry.yaml sources without pyyaml."""
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
                break  # Left sources section
            if stripped.startswith("- repo:"):
                if current:
                    sources.append(current)
                current = {"source": stripped.split(":", 1)[1].strip()}
            elif stripped.startswith("layout:") and current:
                current["layout"] = stripped.split(":", 1)[1].strip()
            elif stripped.startswith("skills_path:") and current:
                current["skills_path"] = stripped.split(":", 1)[1].strip()
            elif stripped.startswith("default:"):
                if current:
                    current["default"] = stripped.split(":", 1)[1].strip() == "true"
    if current:
        sources.append(current)
    return {"sources": sources}


def github_headers() -> dict:
    headers = {"Accept": "application/vnd.github.v3+json"}
    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        # Try gh CLI
        try:
            result = subprocess.run(
                ["gh", "auth", "token"], capture_output=True, text=True
            )
            if result.returncode == 0:
                token = result.stdout.strip()
        except FileNotFoundError:
            pass
    if token:
        headers["Authorization"] = f"token {token}"
    return headers


def github_get(url: str) -> dict | list | None:
    """Fetch JSON from GitHub API with auth if available."""
    headers = github_headers()
    req = Request(url, headers=headers)
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
    """Fetch raw file content from GitHub."""
    url = f"https://raw.githubusercontent.com/{source}/main/{path}"
    req = Request(url, headers=github_headers())
    try:
        with urlopen(req, timeout=15) as resp:
            return resp.read().decode("utf-8")
    except HTTPError:
        # Try master branch
        url2 = f"https://raw.githubusercontent.com/{source}/master/{path}"
        req2 = Request(url2, headers=github_headers())
        try:
            with urlopen(req2, timeout=15) as resp:
                return resp.read().decode("utf-8")
        except Exception:
            return None
    except Exception:
        return None


def parse_frontmatter(text: str) -> dict:
    """Extract YAML frontmatter from markdown text."""
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
    # Handle multiline description
    if "description" not in fm or fm["description"] == "|":
        desc_match = re.search(
            r"description:\s*\|?\s*\n((?:[ \t]+.+\n)+)", match.group(1)
        )
        if desc_match:
            lines = desc_match.group(1).split("\n")
            fm["description"] = " ".join(l.strip() for l in lines if l.strip())
    return fm


def parse_frontmatter_file(path: Path) -> dict:
    return parse_frontmatter(path.read_text(encoding="utf-8"))


def synthesize_search_document(name: str, fm: dict, kind: str, source: str) -> str:
    """Build a rich search document optimized for asymmetric retrieval."""
    desc = fm.get("description", "")
    parts = [f"Name: {name}.", f"Source: {source}."]
    if kind == "skill":
        parts.append("Type: agent skill.")
    else:
        parts.append("Type: agent persona.")
    if desc:
        parts.append(f"Description: {desc}")
    return " ".join(parts)


def collect_local_skills() -> list[dict]:
    """Gather all local skills."""
    items = []
    if not SKILLS_DIR.exists():
        return items
    for skill_dir in sorted(SKILLS_DIR.iterdir()):
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.exists():
            continue
        name = skill_dir.name
        fm = parse_frontmatter_file(skill_md)
        if not fm.get("description"):
            print(f"  SKIP skill {name}: no description", file=sys.stderr)
            continue
        items.append({
            "type": "skill",
            "name": name,
            "source": LOCAL_SOURCE,
            "fqn": f"{LOCAL_SOURCE}@{name}",
            "description": fm["description"],
            "search_document": synthesize_search_document(
                name, fm, "skill", LOCAL_SOURCE
            ),
        })
    return items


def collect_local_agents() -> list[dict]:
    """Gather all local agents."""
    items = []
    if not AGENTS_DIR.exists():
        return items
    for agent_file in sorted(AGENTS_DIR.glob("*.md")):
        name = agent_file.stem
        fm = parse_frontmatter_file(agent_file)
        if not fm.get("description"):
            print(f"  SKIP agent {name}: no description", file=sys.stderr)
            continue
        items.append({
            "type": "agent",
            "name": name,
            "source": LOCAL_SOURCE,
            "fqn": f"{LOCAL_SOURCE}@{name}",
            "description": fm["description"],
            "search_document": synthesize_search_document(
                name, fm, "agent", LOCAL_SOURCE
            ),
        })
    return items


def collect_external_source(src: dict) -> list[dict]:
    """Fetch skill metadata from an external GitHub source."""
    source = src["source"]
    layout = src.get("layout", "flat")
    items = []

    print(f"  Fetching {source}...")

    if layout == "root":
        # Single-skill repo: SKILL.md at root
        text = github_raw(source, "SKILL.md")
        if not text:
            print(f"    No SKILL.md found at root", file=sys.stderr)
            return items
        fm = parse_frontmatter(text)
        name = fm.get("name", source.split("/")[-1])
        if not fm.get("description"):
            body = re.sub(r"^---.*?---\s*", "", text, flags=re.DOTALL).strip()
            first_para = body.split("\n\n")[0].replace("\n", " ").strip()
            if first_para.startswith("#"):
                first_para = first_para.split("\n", 1)[-1].strip() if "\n" in first_para else ""
            fm["description"] = first_para[:500] if first_para else name
        items.append({
            "type": "skill",
            "name": name,
            "source": source,
            "fqn": f"{source}@{name}",
            "description": fm.get("description", ""),
            "search_document": synthesize_search_document(
                name, fm, "skill", source
            ),
        })
        print(f"    Found 1 skill: {name}")
        return items

    if layout == "multi-root":
        # Multiple skills as top-level dirs (not under skills/)
        api_url = f"https://api.github.com/repos/{source}/contents/"
        entries = github_get(api_url)
        if not entries or not isinstance(entries, list):
            print(f"    Cannot list repo root", file=sys.stderr)
            return items
        dirs = [
            d["name"] for d in entries
            if d.get("type") == "dir" and not d["name"].startswith(".")
        ]
        for dirname in sorted(dirs):
            text = github_raw(source, f"{dirname}/SKILL.md")
            if not text:
                continue
            fm = parse_frontmatter(text)
            name = fm.get("name", dirname)
            if not fm.get("description"):
                continue
            items.append({
                "type": "skill",
                "name": name,
                "source": source,
                "fqn": f"{source}@{name}",
                "description": fm["description"],
                "search_document": synthesize_search_document(
                    name, fm, "skill", source
                ),
            })
        print(f"    Indexed {len(items)} skills with descriptions")
        return items

    # Flat layout: skills/*/SKILL.md
    skills_path = src.get("skills_path", "skills")
    api_url = f"https://api.github.com/repos/{source}/contents/{skills_path}"
    dirs = github_get(api_url)

    if not dirs or not isinstance(dirs, list):
        print(f"    No skills directory at {skills_path}", file=sys.stderr)
        return items

    skill_dirs = [d["name"] for d in dirs if d.get("type") == "dir"]
    print(f"    Found {len(skill_dirs)} skill directories")

    for skill_name in sorted(skill_dirs):
        text = github_raw(source, f"{skills_path}/{skill_name}/SKILL.md")
        if not text:
            continue
        fm = parse_frontmatter(text)
        name = fm.get("name", skill_name)
        if not fm.get("description"):
            continue
        items.append({
            "type": "skill",
            "name": name,
            "source": source,
            "fqn": f"{source}@{name}",
            "description": fm["description"],
            "search_document": synthesize_search_document(
                name, fm, "skill", source
            ),
        })

    print(f"    Indexed {len(items)} skills with descriptions")
    return items


def embed_batch(client, texts: list[str], dims: int) -> list[list[float]]:
    result = client.models.embed_content(
        model=MODEL,
        contents=texts,
        config={"output_dimensionality": dims, "task_type": "RETRIEVAL_DOCUMENT"},
    )
    return [e.values for e in result.embeddings]


def main():
    dims = DEFAULT_DIMS
    dry_run = "--dry-run" in sys.argv
    local_only = "--local-only" in sys.argv
    for i, arg in enumerate(sys.argv):
        if arg == "--dimensions" and i + 1 < len(sys.argv):
            dims = int(sys.argv[i + 1])

    print("Spellbook Embeddings Generator")
    print(f"  Model: {MODEL}")
    print(f"  Dimensions: {dims}")
    print()

    # Collect local items
    print(f"Local source: {LOCAL_SOURCE}")
    local_skills = collect_local_skills()
    local_agents = collect_local_agents()
    print(f"  {len(local_skills)} skills, {len(local_agents)} agents")
    items = local_skills + local_agents

    # Collect external items (sources from registry.yaml)
    if not local_only:
        external_sources = load_external_sources()
        print()
        print(f"External sources ({len(external_sources)} from registry.yaml):")
        for src in external_sources:
            external = collect_external_source(src)
            items.extend(external)
        print()

    # Deduplicate by FQN
    seen = set()
    deduped = []
    for item in items:
        if item["fqn"] not in seen:
            seen.add(item["fqn"])
            deduped.append(item)
    items = deduped

    # Summary by source
    sources = {}
    for item in items:
        s = item["source"]
        sources[s] = sources.get(s, 0) + 1
    print("Summary:")
    for s, count in sorted(sources.items()):
        print(f"  {s}: {count}")
    print(f"  Total: {len(items)}")

    if dry_run:
        print("\n--dry-run: would embed these items:\n")
        for item in items:
            print(f"  [{item['type']:5s}] {item['fqn']}")
        sys.exit(0)

    # Embed
    from google import genai

    api_key = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
    if not api_key:
        print("Error: GEMINI_API_KEY or GOOGLE_API_KEY required", file=sys.stderr)
        sys.exit(1)
    client = genai.Client(api_key=api_key)

    print(f"\nEmbedding {len(items)} items in batches of {BATCH_SIZE}...")
    all_embeddings = []
    for i in range(0, len(items), BATCH_SIZE):
        batch = items[i : i + BATCH_SIZE]
        texts = [item["search_document"] for item in batch]
        vectors = embed_batch(client, texts, dims)
        all_embeddings.extend(vectors)
        done = min(i + BATCH_SIZE, len(items))
        print(f"  {done}/{len(items)} embedded")
        if i + BATCH_SIZE < len(items):
            time.sleep(0.5)

    for item, embedding in zip(items, all_embeddings):
        item["embedding"] = embedding

    output = {
        "model": MODEL,
        "dimensions": dims,
        "sources": list(sources.keys()),
        "generated": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "count": len(items),
        "items": items,
    }

    OUTPUT_FILE.write_text(json.dumps(output, indent=2), encoding="utf-8")
    size_kb = OUTPUT_FILE.stat().st_size / 1024
    print(f"\nWrote {OUTPUT_FILE.name}: {len(items)} items, {size_kb:.0f} KB")


if __name__ == "__main__":
    main()
