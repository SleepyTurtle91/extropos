#!/usr/bin/env python3
"""Extract reports_screen.dart methods into parts (operations, views, helpers)."""

import re
from pathlib import Path

MAIN = Path('lib/screens/reports_screen.dart')

PARTS = {
    'reports_screen_operations.dart': {
        'extension': 'ReportsScreenOperations',
        'methods': [
            'initState',
            '_loadReport',
            '_loadAdvancedReport',
            '_exportReport',
            '_exportBasicReport',
            '_exportAdvancedReport',
            '_printReport',
            '_getDefaultPrinter',
        ],
    },
    'reports_screen_view_widgets.dart': {
        'extension': 'ReportsScreenViewWidgets',
        'methods': [
            '_buildBasicReportsView',
            '_buildAdvancedReportsView',
            '_buildCustomerContent',
        ],
    },
    'reports_screen_ui_helpers.dart': {
        'extension': 'ReportsScreenUiHelpers',
        'methods': [
            '_buildReconciliationRow',
            '_formatDuration',
            '_formatTime',
        ],
    },
}

METHOD_SIG = re.compile(
    r'^\s+(Widget|Future<[^>]+>|Future|void|String|int|double|bool|List<[^>]+>|Map<[^>]+>)\s+(\w+)\s*\('
)


def _extract_methods(lines):
    methods = {}
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
            methods[name] = {'start': start, 'end': end}
            continue
        i += 1
    return methods


def _write_part(part_name, extension, method_names, lines, methods):
    part_lines = [
        "part of 'reports_screen.dart';",
        "",
        f"extension {extension} on _ReportsScreenState {{",
    ]

    for name in method_names:
        if name not in methods:
            continue
        start = methods[name]['start']
        end = methods[name]['end']
        part_lines.extend(lines[start:end + 1])
        part_lines.append("")

    part_lines.append("}")
    part_lines.append("")

    Path(f'lib/screens/{part_name}').write_text('\n'.join(part_lines), encoding='utf-8')


def _remove_methods(lines, methods, remove_names):
    remove_ranges = []
    for name in remove_names:
        if name in methods:
            remove_ranges.append((methods[name]['start'], methods[name]['end']))

    remove_ranges.sort()

    new_lines = []
    i = 0
    idx = 0

    while i < len(lines):
        if idx < len(remove_ranges) and i == remove_ranges[idx][0]:
            i = remove_ranges[idx][1] + 1
            idx += 1
            continue
        new_lines.append(lines[i])
        i += 1

    return new_lines


def _add_part_directives(lines):
    part_lines = [
        "part 'reports_screen_content.dart';",
        "part 'reports_screen_operations.dart';",
        "part 'reports_screen_view_widgets.dart';",
        "part 'reports_screen_ui_helpers.dart';",
        "part 'reports_screen_content_part1.dart';",
        "part 'reports_screen_content_part2.dart';",
    ]

    if any("part 'reports_screen_operations.dart'" in line for line in lines):
        return lines

    output = []
    inserted = False
    for line in lines:
        if not inserted and line.startswith('part '):
            output.extend(part_lines)
            inserted = True
            continue
        if not inserted and line.startswith('enum ReportFormat'):
            output.extend(part_lines)
            output.append('')
            inserted = True
        output.append(line)

    return output


def main():
    lines = MAIN.read_text(encoding='utf-8', errors='ignore').splitlines()
    methods = _extract_methods(lines)

    remove_names = []
    for part_name, data in PARTS.items():
        _write_part(part_name, data['extension'], data['methods'], lines, methods)
        remove_names.extend(data['methods'])

    updated = _remove_methods(lines, methods, remove_names)
    updated = _add_part_directives(updated)

    MAIN.write_text('\n'.join(updated), encoding='utf-8')
    print(f"Extracted {len(remove_names)} methods into parts.")


if __name__ == '__main__':
    main()
