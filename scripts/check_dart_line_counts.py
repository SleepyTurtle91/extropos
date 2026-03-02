#!/usr/bin/env python3
"""Enforce Dart file line count limits for lib/.

Hard rule: every .dart file under lib/ must be between 500 and 1000 lines.
"""

from __future__ import annotations

from pathlib import Path
import sys

MIN_LINES = 500
MAX_LINES = 1000
TARGET_ROOT = Path("lib")


def count_lines(file_path: Path) -> int:
    with file_path.open("r", encoding="utf-8", errors="ignore") as handle:
        return sum(1 for _ in handle)


def main() -> int:
    if not TARGET_ROOT.exists():
        print("Missing lib/ directory; nothing to check.")
        return 0

    dart_files = sorted(TARGET_ROOT.rglob("*.dart"))
    if not dart_files:
        print("No Dart files found under lib/.")
        return 0

    violations: list[tuple[Path, int]] = []
    for file_path in dart_files:
        line_count = count_lines(file_path)
        if line_count < MIN_LINES or line_count > MAX_LINES:
            violations.append((file_path, line_count))

    if not violations:
        print("Dart line count check passed.")
        return 0

    print("Dart line count violations:")
    for file_path, line_count in violations:
        relative_path = file_path.as_posix()
        print(f"- {relative_path}: {line_count} lines")

    print(
        f"\nRequired range: {MIN_LINES}-{MAX_LINES} lines for every lib/ .dart file."
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
