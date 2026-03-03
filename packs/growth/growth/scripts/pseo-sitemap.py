#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path
from typing import Iterable, List


def _is_page_file(path: Path) -> bool:
    if not path.is_file():
        return False
    if path.suffix not in {".tsx", ".jsx", ".mdx", ".html"}:
        return False
    if path.name.startswith("_"):
        return False
    if "api" in path.parts:
        return False
    return True


def discover_routes(pages_dir: Path) -> List[str]:
    routes: List[str] = []
    for path in pages_dir.rglob("*"):
        if not _is_page_file(path):
            continue
        rel = path.relative_to(pages_dir)
        if rel.stem == "index":
            route = "" if rel.parent.as_posix() == "." else rel.parent.as_posix()
        else:
            route = rel.with_suffix("").as_posix()
        route = route.strip("/")
        routes.append(route)
    return sorted(set(routes))


def build_sitemap(urls: Iterable[str]) -> str:
    lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
    ]
    for url in urls:
        lines.append("  <url>")
        lines.append(f"    <loc>{url}</loc>")
        lines.append("  </url>")
    lines.append("</urlset>")
    return "\n".join(lines) + "\n"


def write_sitemap(*, pages_dir: Path, base_url: str, output: Path) -> None:
    routes = discover_routes(pages_dir)
    base = base_url.rstrip("/")
    urls = [f"{base}/" + r if r else f"{base}/" for r in routes]
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(build_sitemap(urls), encoding="utf-8")


__all__ = ["discover_routes", "write_sitemap"]
