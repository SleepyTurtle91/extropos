#!/usr/bin/env python3
"""Extract PDF builder methods from advanced_reports_screen.dart into part files."""

import re
from pathlib import Path

MAIN_PATH = Path('lib/screens/advanced_reports_screen.dart')
PART_PREFIX = 'advanced_reports_screen_pdf_part'


def extract_methods(lines):
    methods = []
    i = 0
    while i < len(lines):
        line = lines[i]
        match = re.search(r'^\s+pw\.Widget\s+(_build\w+PDF)\s*\(', line)
        if match:
            name = match.group(1)
            start = i
            depth = line.count('{') - line.count('}')
            i += 1
            while i < len(lines) and depth > 0:
                depth += lines[i].count('{') - lines[i].count('}')
                i += 1
            end = i - 1
            methods.append({'name': name, 'start': start, 'end': end})
            continue
        i += 1
    return methods


def group_methods(lines, methods, max_lines=450):
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
        part_name = f'{PART_PREFIX}{idx}.dart'
        part_files.append(part_name)
        out_lines = ["// Part of advanced_reports_screen.dart", "", "part of 'advanced_reports_screen.dart';", "", f"extension AdvancedReportsPdfPart{idx} on _AdvancedReportsScreenState {{"]

        for m in group:
            out_lines.extend(lines[m['start']:m['end'] + 1])
            out_lines.append("")

        out_lines.append("}")
        out_lines.append("")

        Path(f'lib/screens/{part_name}').write_text('\n'.join(out_lines), encoding='utf-8')

    return part_files


def update_main_file(lines, methods, part_files):
    # Remove extracted methods
    remove_ranges = {(m['start'], m['end']) for m in methods}
    new_lines = []
    i = 0

    while i < len(lines):
        skip = False
        for start, end in remove_ranges:
            if i == start:
                i = end + 1
                skip = True
                break
        if skip:
            continue
        new_lines.append(lines[i])
        i += 1

    # Insert part directives after existing part list
    inserted = False
    final_lines = []
    for line in new_lines:
        final_lines.append(line)
        if not inserted and line.startswith("part 'advanced_reports_screen_ui_helpers.dart';"):
            for part in part_files:
                final_lines.append(f"part '{part}';")
            inserted = True

    MAIN_PATH.write_text('\n'.join(final_lines), encoding='utf-8')


def main():
    lines = MAIN_PATH.read_text(encoding='utf-8', errors='ignore').splitlines()
    methods = extract_methods(lines)

    if not methods:
        print('No PDF methods found to extract.')
        return

    groups = group_methods(lines, methods, max_lines=450)
    part_files = write_part_files(lines, groups)
    update_main_file(lines, methods, part_files)

    print(f"Extracted {len(methods)} PDF methods into {len(part_files)} part files:")
    for part in part_files:
        print(f"  - {part}")


if __name__ == '__main__':
    main()
