#!/usr/bin/env python3

from __future__ import annotations

import json
import re
import sys
from hashlib import sha256
from pathlib import Path
from typing import Dict, Iterable, List, Tuple

import click

from sitemap import write_sitemap

SKILL_ROOT = Path(__file__).resolve().parent.parent
TEMPLATE_DIR = SKILL_ROOT / "templates"

TEMPLATES = {
    "comparison": "comparison.tsx",
    "alternative": "alternative.tsx",
    "best-for": "best-for.tsx",
}


def _slugify(value: str) -> str:
    value = value.lower().strip()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    return value.strip("-")


def _escape_ts_string(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def _render_template(
    template_text: str, *, page_data: Dict, title: str, description: str
) -> str:
    data_json = json.dumps(page_data, indent=2, ensure_ascii=True)
    return (
        template_text.replace("__TITLE__", _escape_ts_string(title))
        .replace("__DESCRIPTION__", _escape_ts_string(description))
        .replace("__PAGE_DATA__", data_json)
    )


def _sample_schema(pattern: str) -> Dict:
    if pattern == "comparison":
        return {
            "pattern": "comparison",
            "site": {"base_url": "https://example.com", "brand": "Acme"},
            "pages": [
                {
                    "slug": "acme-vs-rocket",
                    "title": "Acme vs Rocket: Features, Pricing, Verdict",
                    "description": "Compare Acme and Rocket across features, pricing, and best-fit use cases.",
                    "updated": "2026-01-29",
                    "x": {"name": "Acme", "summary": "Best for fast setup."},
                    "y": {"name": "Rocket", "summary": "Best for advanced controls."},
                    "features": [
                        {"name": "Setup time", "x": "5 minutes", "y": "30 minutes"},
                        {"name": "Automation", "x": "Basic", "y": "Advanced"},
                    ],
                    "pricing": {
                        "x": "$29/mo",
                        "y": "$49/mo",
                        "notes": ["Annual discounts available."],
                    },
                    "verdict": {
                        "winner": "Acme",
                        "summary": "Acme wins for teams that want speed and simplicity.",
                        "bestFor": ["Small teams", "Quick launches"],
                    },
                }
            ],
        }
    if pattern == "alternative":
        return {
            "pattern": "alternative",
            "site": {"base_url": "https://example.com", "brand": "Acme"},
            "pages": [
                {
                    "slug": "acme-alternatives",
                    "title": "Best Acme Alternatives",
                    "description": "A curated list of the top Acme alternatives and who they fit best.",
                    "updated": "2026-01-29",
                    "product": {"name": "Acme", "summary": "Great for quick onboarding."},
                    "alternatives": [
                        {
                            "name": "Rocket",
                            "summary": "More control and advanced settings.",
                            "bestFor": "Power users",
                            "pricing": "$49/mo",
                        },
                        {
                            "name": "Nimbus",
                            "summary": "Simple UI with solid defaults.",
                            "bestFor": "Lean teams",
                            "pricing": "$19/mo",
                        },
                    ],
                    "cta": {"label": "See Acme plans", "href": "/pricing"},
                }
            ],
        }
    if pattern == "best-for":
        return {
            "pattern": "best-for",
            "site": {"base_url": "https://example.com", "brand": "Acme"},
            "pages": [
                {
                    "slug": "best-crm-for-freelancers",
                    "title": "Best CRM for Freelancers",
                    "description": "Top CRM picks for freelancers who need simple pipelines and low cost.",
                    "updated": "2026-01-29",
                    "category": "CRM",
                    "persona": {
                        "name": "Freelancers",
                        "summary": "Solo operators balancing sales and delivery.",
                        "pains": ["No time to configure", "Need simple automation"],
                    },
                    "picks": [
                        {
                            "name": "SoloCRM",
                            "summary": "Lightweight CRM with fast setup.",
                            "why": ["Simple pipelines", "Email reminders"],
                            "price": "$12/mo",
                        }
                    ],
                    "methodology": ["Hands-on testing", "Pricing vs value", "Ease of setup"],
                }
            ],
        }
    raise click.ClickException(f"Unknown pattern: {pattern}")


def _load_template(name: str) -> str:
    template_file = TEMPLATE_DIR / TEMPLATES[name]
    if not template_file.exists():
        raise click.ClickException(f"Missing template: {template_file}")
    return template_file.read_text(encoding="utf-8")


def _iter_page_files(pages_dir: Path) -> Iterable[Path]:
    for path in pages_dir.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix not in {".tsx", ".jsx", ".mdx", ".html"}:
            continue
        if path.name.startswith("_"):
            continue
        yield path


def _normalize_text(text: str) -> str:
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"\{[^}]*\}", " ", text)
    text = re.sub(r"[^a-zA-Z0-9]+", " ", text)
    return " ".join(text.split()).lower()


@click.group()
def cli() -> None:
    """Programmatic SEO page generator."""


@cli.command()
@click.option("--pattern", type=click.Choice(TEMPLATES.keys()), required=True)
@click.option("--output", type=click.Path(dir_okay=False, path_type=Path), default="data.json")
@click.option("--force", is_flag=True, help="Overwrite existing data.json")
def init(pattern: str, output: Path, force: bool) -> None:
    """Create starter data schema JSON."""
    if output.exists() and not force:
        raise click.ClickException(f"{output} exists. Use --force to overwrite.")
    output.write_text(json.dumps(_sample_schema(pattern), indent=2), encoding="utf-8")
    click.echo(f"Wrote {output}")


@cli.command()
@click.option("--data", type=click.Path(dir_okay=False, path_type=Path), required=True)
@click.option("--template", "template_name", type=click.Choice(TEMPLATES.keys()), required=True)
@click.option("--output", type=click.Path(file_okay=False, path_type=Path), required=True)
def generate(data: Path, template_name: str, output: Path) -> None:
    """Generate pages from JSON + template."""
    payload = json.loads(data.read_text(encoding="utf-8"))
    pages = payload.get("pages", [])
    if not isinstance(pages, list) or not pages:
        raise click.ClickException("data.json must include a non-empty 'pages' list.")
    template_text = _load_template(template_name)
    output.mkdir(parents=True, exist_ok=True)
    site = payload.get("site", {})
    written = 0
    for page in pages:
        if not isinstance(page, dict):
            continue
        slug = page.get("slug") or _slugify(page.get("title", ""))
        slug = slug or "index"
        page_data = {"site": site, **page}
        title = page_data.get("title") or slug.replace("-", " ").title()
        description = page_data.get("description") or ""
        rendered = _render_template(
            template_text, page_data=page_data, title=title, description=description
        )
        target = output / f"{slug}.tsx"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(rendered, encoding="utf-8")
        written += 1
    click.echo(f"Wrote {written} page(s) to {output}")


@cli.command()
@click.option("--output", type=click.Path(dir_okay=False, path_type=Path), required=True)
@click.option("--pages", type=click.Path(file_okay=False, path_type=Path), default="./pages")
@click.option("--base-url", default="https://example.com", show_default=True)
def sitemap(output: Path, pages: Path, base_url: str) -> None:
    """Generate a sitemap.xml from pages dir."""
    if not pages.exists():
        raise click.ClickException(f"Pages dir not found: {pages}")
    write_sitemap(pages_dir=pages, base_url=base_url, output=output)
    click.echo(f"Wrote {output}")


@cli.command()
@click.option("--data", type=click.Path(dir_okay=False, path_type=Path), default="data.json")
@click.option("--pages", type=click.Path(file_okay=False, path_type=Path), default="./pages")
@click.option("--min-words", type=int, default=200, show_default=True)
def validate(data: Path, pages: Path, min_words: int) -> None:
    """Check for duplicates and thin pages."""
    issues: List[str] = []

    if data.exists():
        payload = json.loads(data.read_text(encoding="utf-8"))
        pages_data = payload.get("pages", [])
        slugs: Dict[str, int] = {}
        titles: Dict[str, int] = {}
        for page in pages_data:
            if not isinstance(page, dict):
                continue
            slug = page.get("slug") or _slugify(page.get("title", ""))
            if slug:
                slugs[slug] = slugs.get(slug, 0) + 1
            title = page.get("title", "")
            if title:
                titles[title] = titles.get(title, 0) + 1
        for slug, count in slugs.items():
            if count > 1:
                issues.append(f"duplicate slug: {slug}")
        for title, count in titles.items():
            if count > 1:
                issues.append(f"duplicate title: {title}")

    if pages.exists():
        hashes: Dict[str, List[Path]] = {}
        thin: List[Tuple[Path, int]] = []
        for path in _iter_page_files(pages):
            raw = path.read_text(encoding="utf-8")
            if "__PAGE_DATA__" in raw or "__TITLE__" in raw:
                issues.append(f"unrendered placeholders: {path}")
            norm = _normalize_text(raw)
            words = norm.split()
            if len(words) < min_words:
                thin.append((path, len(words)))
            digest = sha256(norm.encode("utf-8")).hexdigest()
            hashes.setdefault(digest, []).append(path)
        for digest, files in hashes.items():
            if len(files) > 1:
                joined = ", ".join(str(f) for f in files)
                issues.append(f"duplicate content: {joined}")
        for path, count in thin:
            issues.append(f"thin page ({count} words): {path}")

    if issues:
        for issue in issues:
            click.secho(f"ERROR: {issue}", fg="red")
        sys.exit(1)
    click.secho("OK: no issues found", fg="green")


if __name__ == "__main__":
    cli(prog_name="pseo")
