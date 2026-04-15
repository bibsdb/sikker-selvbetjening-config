#!/usr/bin/env python3
"""Validate cross-field constraints for group_vars YAML files.

JSON Schema cannot portably enforce that printer.default_printer matches one of
the dynamic keys under printer.no_ppd or printer.with_ppd. This script enforces
that rule.
"""

from __future__ import annotations

import argparse
import glob
import sys
from pathlib import Path

import yaml


def _collect_ids(printer_section: dict) -> set[str]:
    ids: set[str] = set()
    for bucket_name in ("no_ppd", "with_ppd"):
        bucket = printer_section.get(bucket_name)
        if isinstance(bucket, dict):
            ids.update(str(key) for key in bucket.keys())
    return ids


def validate_file(path: Path) -> list[str]:
    errors: list[str] = []

    try:
        data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    except Exception as exc:
        return [f"{path}: failed to parse YAML: {exc}"]

    if not isinstance(data, dict):
        return [f"{path}: top-level document must be a mapping"]

    printer = data.get("printer")
    if not isinstance(printer, dict):
        return errors

    default_printer = printer.get("default_printer")
    if default_printer is None:
        return errors

    available_ids = _collect_ids(printer)
    if not available_ids:
        errors.append(
            f"{path}: printer.default_printer is set to '{default_printer}', "
            "but no printer IDs exist under printer.no_ppd or printer.with_ppd"
        )
        return errors

    if str(default_printer) not in available_ids:
        ordered = ", ".join(sorted(available_ids))
        errors.append(
            f"{path}: printer.default_printer '{default_printer}' does not match "
            f"any known printer ID ({ordered})"
        )

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate cross-field rules for group_vars files."
    )
    parser.add_argument(
        "paths",
        nargs="*",
        default=["group_vars/*.yml"],
        help="Files or glob patterns to validate (default: group_vars/*.yml)",
    )
    args = parser.parse_args()

    files: list[Path] = []
    for pattern in args.paths:
        matches = [Path(p) for p in glob.glob(pattern)]
        if matches:
            files.extend(matches)
        else:
            files.append(Path(pattern))

    seen: set[Path] = set()
    ordered_files: list[Path] = []
    for file_path in files:
        resolved = file_path.resolve()
        if resolved in seen:
            continue
        seen.add(resolved)
        ordered_files.append(file_path)

    all_errors: list[str] = []
    for file_path in ordered_files:
        if not file_path.exists():
            all_errors.append(f"{file_path}: file does not exist")
            continue
        all_errors.extend(validate_file(file_path))

    if all_errors:
        for error in all_errors:
            print(error, file=sys.stderr)
        return 1

    print("group_vars validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
