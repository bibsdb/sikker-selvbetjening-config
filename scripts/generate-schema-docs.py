#!/usr/bin/env python3
"""Generate static HTML documentation for JSON Schema files.

This script uses json-schema-for-humans to render one page per schema and
creates a simple index page linking all generated schema docs.
"""

from __future__ import annotations

from dataclasses import dataclass
from html import escape
from pathlib import Path

from json_schema_for_humans.generate import generate_from_filename


@dataclass(frozen=True)
class SchemaDoc:
    schema_path: Path
    output_path: Path
    title: str
    description: str


def build_doc_list(root_schema: Path, sections_dir: Path, output_dir: Path) -> list[SchemaDoc]:
    docs: list[SchemaDoc] = [
        SchemaDoc(
            schema_path=root_schema,
            output_path=output_dir / "group-vars.html",
            title="Group Vars Root Schema",
            description="Top-level schema for group_vars overlay files.",
        )
    ]

    for section_schema in sorted(sections_dir.glob("*.json")):
        stem = section_schema.stem.replace(".schema", "")
        docs.append(
            SchemaDoc(
                schema_path=section_schema,
                output_path=output_dir / f"{stem}.html",
                title=f"Section: {stem}",
                description=f"Schema documentation for the {stem} section.",
            )
        )

    return docs


def write_index(output_dir: Path, docs: list[SchemaDoc]) -> None:
    lines = [
        "<!doctype html>",
        "<html lang=\"en\">",
        "<head>",
        "  <meta charset=\"utf-8\">",
        "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
        "  <title>Schema Documentation</title>",
        "  <style>",
        "    body { font-family: ui-sans-serif, system-ui, sans-serif; margin: 2rem auto; max-width: 62rem; line-height: 1.5; padding: 0 1rem; }",
        "    h1 { margin-bottom: 0.5rem; }",
        "    p { color: #333; }",
        "    ul { padding-left: 1.25rem; }",
        "    li { margin: 0.4rem 0; }",
        "    a { color: #0b57d0; text-decoration: none; }",
        "    a:hover { text-decoration: underline; }",
        "  </style>",
        "</head>",
        "<body>",
        "  <h1>Schema Documentation</h1>",
        "  <p>Generated from JSON Schema files in the repository.</p>",
        "  <ul>",
    ]

    for doc in docs:
        rel = doc.output_path.name
        lines.append(
            f"    <li><a href=\"{escape(rel)}\">{escape(doc.title)}</a> - {escape(doc.description)}</li>"
        )

    lines.extend(["  </ul>", "</body>", "</html>"])
    (output_dir / "index.html").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    root_schema = repo_root / "schemas" / "group-vars.schema.json"
    sections_dir = repo_root / "schemas" / "sections"
    output_dir = repo_root / "site"
    output_dir.mkdir(parents=True, exist_ok=True)

    if not root_schema.exists():
        raise SystemExit(f"Missing root schema: {root_schema}")

    docs = build_doc_list(root_schema, sections_dir, output_dir)
    for doc in docs:
        generate_from_filename(str(doc.schema_path), str(doc.output_path))

    write_index(output_dir, docs)
    print(f"Generated {len(docs)} schema documents in {output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
