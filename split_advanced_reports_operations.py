#!/usr/bin/env python3
"""Split advanced_reports_screen_operations.dart into smaller parts."""

import re
from pathlib import Path

OPS_PATH = Path('lib/screens/advanced_reports_screen_operations.dart')
MAIN_PATH = Path('lib/screens/advanced_reports_screen.dart')


def extract_methods(lines):
    methods = []
    i = 0
    while i < len(lines):
        line = lines[i]
        match = re.search(r'^\s+(Future<[^>]+>|Future|void|String)\s+(_\w+)\s*\(', line)
        if match:
            start = i
            depth = line.count('{') - line.count('}')
            i += 1
            while i < len(lines) and depth > 0:
                depth += lines[i].count('{') - lines[i].count('}')
                i += 1
            end = i - 1
            methods.append({'start': start, 'end': end})
            continue
        i += 1
    return methods


def group_methods(methods, max_lines=450):
    groups = []
    current = []
    current_lines = 0

    for m in methods:
        size = m['end'] - m['start'] + 1
        if current and current_lines + size > max_lines:
            groups.append(current)
            current = []
            current_lines = 0
        current.append(m)
        current_lines += size

    if current:
        groups.append(current)

    return groups


def write_part_files(lines, groups):
    part_files = []

    for idx, group in enumerate(groups, start=1):
        part_name = f'advanced_reports_screen_operations_part{idx}.dart'
        part_files.append(part_name)

        out_lines = [
            "// Part of advanced_reports_screen.dart",
            "// Auto-split Operations",
            "",
            "part of 'advanced_reports_screen.dart';",
            "",
            f"extension AdvancedReportsOperationsPart{idx} on _AdvancedReportsScreenState {{",
        ]

        for m in group:
            out_lines.extend(lines[m['start']:m['end'] + 1])
            out_lines.append("")

        out_lines.append("}")
        out_lines.append("")

        Path(f'lib/screens/{part_name}').write_text('\n'.join(out_lines), encoding='utf-8')

    return part_files


def rewrite_ops_stub():
    OPS_PATH.write_text(
        "// Part of advanced_reports_screen.dart\n// Operations split into smaller parts\n\npart of 'advanced_reports_screen.dart';\n\nextension AdvancedReportsOperationsStub on _AdvancedReportsScreenState {}\n",
        encoding='utf-8',
    )


def update_main_parts(part_files):
    main_lines = MAIN_PATH.read_text(encoding='utf-8', errors='ignore').splitlines()
    new_lines = []
    inserted = False

    for line in main_lines:
        new_lines.append(line)
        if not inserted and line.strip() == "part 'advanced_reports_screen_operations.dart';":
            for part in part_files:
                new_lines.append(f"part '{part}';")
            inserted = True

    MAIN_PATH.write_text('\n'.join(new_lines), encoding='utf-8')


def main():
    lines = OPS_PATH.read_text(encoding='utf-8', errors='ignore').splitlines()
    methods = extract_methods(lines)
    if not methods:
        print('No methods found to split.')
        return

    groups = group_methods(methods, max_lines=450)
    part_files = write_part_files(lines, groups)
    rewrite_ops_stub()
    update_main_parts(part_files)

    print(f"Split operations into {len(part_files)} parts.")


if __name__ == '__main__':
    main()
