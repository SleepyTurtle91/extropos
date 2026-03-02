#!/usr/bin/env python3
"""Split reports_screen_view_widgets.dart into smaller parts."""

import re
from pathlib import Path

VIEW = Path('lib/screens/reports_screen_view_widgets.dart')
MAIN = Path('lib/screens/reports_screen.dart')

METHOD_SIG = re.compile(r'^\s+Widget\s+(\w+)\s*\(')


def extract_methods(lines):
    methods = {}
    i = 0
    while i < len(lines):
        line = lines[i]
        match = METHOD_SIG.search(line)
        if match:
            name = match.group(1)
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


def write_part(path, extension, methods, lines):
    out = [
        "part of 'reports_screen.dart';",
        "",
        f"extension {extension} on _ReportsScreenState {{",
    ]
    for name in methods:
        m = methods_map.get(name)
        if not m:
            continue
        out.extend(lines[m['start']:m['end'] + 1])
        out.append("")
    out.append("}")
    out.append("")
    Path(path).write_text('\n'.join(out), encoding='utf-8')


def update_main_parts():
    lines = MAIN.read_text(encoding='utf-8', errors='ignore').splitlines()
    if any("reports_screen_view_widgets_part1.dart" in line for line in lines):
        return
    updated = []
    for line in lines:
        updated.append(line)
        if line.strip() == "part 'reports_screen_view_widgets.dart';":
            updated.append("part 'reports_screen_view_widgets_part1.dart';")
            updated.append("part 'reports_screen_view_widgets_part2.dart';")
    MAIN.write_text('\n'.join(updated), encoding='utf-8')


lines = VIEW.read_text(encoding='utf-8', errors='ignore').splitlines()
methods_map = extract_methods(lines)

# Split by method names
part1_methods = ['_buildBasicReportsView']
part2_methods = ['_buildAdvancedReportsView', '_buildCustomerContent']

write_part('lib/screens/reports_screen_view_widgets_part1.dart', 'ReportsScreenViewWidgetsPart1', part1_methods, lines)
write_part('lib/screens/reports_screen_view_widgets_part2.dart', 'ReportsScreenViewWidgetsPart2', part2_methods, lines)

# Rewrite original as stub
VIEW.write_text(
    "part of 'reports_screen.dart';\n\n// View widgets split into smaller parts.\nextension ReportsScreenViewWidgets on _ReportsScreenState {}\n",
    encoding='utf-8',
)

update_main_parts()
print('Split reports_screen_view_widgets.dart into 2 parts.')
