#!/usr/bin/env python3
"""Analyze reports_screen.dart for extraction into logic/widgets/helpers."""

import re
from pathlib import Path

path = Path('lib/screens/reports_screen.dart')
lines = path.read_text(encoding='utf-8', errors='ignore').splitlines()

methods = []
current = None
brace = 0
in_method = False

sig = re.compile(r'^\s+(Widget|Future<[^>]+>|Future|void|String|int|double|bool|List<[^>]+>|Map<[^>]+>)\s+(\w+)\s*\(')

for i, line in enumerate(lines, 1):
    if sig.search(line):
        if current is None:
            match = sig.search(line)
            if match:
                current = {
                    'name': match.group(2),
                    'return': match.group(1),
                    'start': i,
                }
                brace = line.count('{') - line.count('}')
                in_method = True
                continue
    if in_method:
        brace += line.count('{') - line.count('}')
        if brace == 0:
            current['end'] = i
            current['lines'] = current['end'] - current['start'] + 1
            methods.append(current)
            current = None
            in_method = False

print(f"Total lines: {len(lines)}")
print(f"Methods found: {len(methods)}")

largest = sorted(methods, key=lambda x: x['lines'], reverse=True)[:15]
print("\nTop 15 methods:")
for m in largest:
    print(f"  {m['name']}: {m['lines']} ({m['return']})")

# Categorize
widgets = [m for m in methods if m['return'] == 'Widget']
futures = [m for m in methods if 'Future' in m['return']]
voids = [m for m in methods if m['return'] == 'void']
helpers = [m for m in methods if m not in widgets + futures + voids]

print("\nCounts:")
print(f"  Widget: {len(widgets)}")
print(f"  Future: {len(futures)}")
print(f"  void: {len(voids)}")
print(f"  helpers: {len(helpers)}")

print("\nEstimated extractable lines:")
print(sum(m['lines'] for m in methods))
