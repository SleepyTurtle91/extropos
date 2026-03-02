#!/usr/bin/env python3
"""Integrate modern_reports_dashboard part files into main file and remove duplicates."""

import re
from pathlib import Path

MAIN = Path('lib/screens/modern_reports_dashboard.dart')
PARTS = [
    Path('lib/screens/modern_reports_dashboard_operations.dart'),
    Path('lib/screens/modern_reports_dashboard_futures.dart'),
    Path('lib/screens/modern_reports_dashboard_helpers.dart'),
    Path('lib/screens/modern_reports_dashboard_medium_widgets.dart'),
    Path('lib/screens/modern_reports_dashboard_small_widgets.dart'),
]


def _collect_method_names(part_paths):
    names = set()
    sig = re.compile(r'^\s+(Widget|Future<[^>]+>|Future|void|String|int|double|bool|List<[^>]+>|Map<[^>]+>)\s+(\w+)\s*\(')

    for path in part_paths:
        if not path.exists():
            continue
        lines = path.read_text(encoding='utf-8', errors='ignore').splitlines()
        for line in lines:
            match = sig.search(line)
            if match:
                names.add(match.group(2))
    return names


def _remove_methods(lines, method_names):
    new_lines = []
    i = 0
    sig = re.compile(r'^\s+(Widget|Future<[^>]+>|Future|void|String|int|double|bool|List<[^>]+>|Map<[^>]+>)\s+(\w+)\s*\(')

    while i < len(lines):
        line = lines[i]
        match = sig.search(line)
        if match:
            name = match.group(2)
            if name in method_names and name != 'build':
                depth = line.count('{') - line.count('}')
                i += 1
                while i < len(lines) and depth > 0:
                    depth += lines[i].count('{') - lines[i].count('}')
                    i += 1
                continue
        new_lines.append(line)
        i += 1

    return new_lines


def _add_part_directives(lines):
    part_lines = [
        "part 'modern_reports_dashboard_operations.dart';",
        "part 'modern_reports_dashboard_futures.dart';",
        "part 'modern_reports_dashboard_helpers.dart';",
        "part 'modern_reports_dashboard_medium_widgets.dart';",
        "part 'modern_reports_dashboard_small_widgets.dart';",
    ]

    if any("part 'modern_reports_dashboard" in line for line in lines):
        return lines

    output = []
    inserted = False
    for line in lines:
        if not inserted and line.startswith('enum TimeRange'):
            for part in part_lines:
                output.append(part)
            output.append('')
            inserted = True
        output.append(line)

    return output


def main():
    lines = MAIN.read_text(encoding='utf-8', errors='ignore').splitlines()
    method_names = _collect_method_names(PARTS)

    updated = _remove_methods(lines, method_names)
    updated = _add_part_directives(updated)

    MAIN.write_text('\n'.join(updated), encoding='utf-8')
    print(f"Removed {len(method_names)} methods from main file and added part directives.")


if __name__ == '__main__':
    main()
