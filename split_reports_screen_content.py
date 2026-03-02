#!/usr/bin/env python3
"""Split reports_screen_content.dart into part files under 500 lines."""

import re
from pathlib import Path

CONTENT = Path('lib/screens/reports_screen_content.dart')

METHOD_SIG = re.compile(
    r'^\s+(Widget|Future<[^>]+>|Future|void|String|int|double|bool|List<[^>]+>|Map<[^>]+>)\s+(\w+)\s*\('
)


def extract_methods(lines):
    methods = []
    i = 0
    while i < len(lines):
        line = lines[i]
        match = METHOD_SIG.search(line)
        if match:
            name = match.group(2)
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


def write_parts(lines, groups):
    part_files = []
    for idx, group in enumerate(groups, start=1):
        part_name = f'reports_screen_content_part{idx}.dart'
        part_files.append(part_name)
        out = [
            "part of 'reports_screen.dart';",
            "",
            f"extension ReportsScreenContentPart{idx} on _ReportsScreenState {{",
        ]
        for m in group:
            out.extend(lines[m['start']:m['end'] + 1])
            out.append("")
        out.append("}")
        out.append("")
        Path(f'lib/screens/{part_name}').write_text('\n'.join(out), encoding='utf-8')
    return part_files


def write_stub():
    CONTENT.write_text(
        "part of 'reports_screen.dart';\n\n// Content builder methods moved into part files.\nextension ReportsScreenContentBuilders on _ReportsScreenState {}\n",
        encoding='utf-8',
    )


def main():
    lines = CONTENT.read_text(encoding='utf-8', errors='ignore').splitlines()
    methods = extract_methods(lines)
    if not methods:
        print('No methods found to split.')
        return

    groups = group_methods(methods, max_lines=450)
    part_files = write_parts(lines, groups)
    write_stub()

    print(f"Created {len(part_files)} content part files.")


if __name__ == '__main__':
    main()
