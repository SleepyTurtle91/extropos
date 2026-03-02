#!/usr/bin/env python3
"""Comprehensive scan for files >500 lines to support three-layer refactoring."""

import os
from pathlib import Path
from collections import defaultdict

lib_dir = Path('lib')
files_by_size = []
stats_by_dir = defaultdict(lambda: {'count': 0, 'total_lines': 0, 'files': []})

for file in lib_dir.rglob('*.dart'):
    # Skip generated files
    if '.g.dart' in file.name or '.freezed.dart' in file.name:
        continue
    
    try:
        lines = len(file.read_text(encoding='utf-8', errors='ignore').splitlines())
        relative_path = file.relative_to('lib')
        dir_name = relative_path.parts[0] if len(relative_path.parts) > 1 else 'root'
        
        if lines > 500:
            files_by_size.append((str(relative_path), lines, dir_name))
            stats_by_dir[dir_name]['count'] += 1
            stats_by_dir[dir_name]['total_lines'] += lines
            stats_by_dir[dir_name]['files'].append((str(relative_path), lines))
    except Exception as e:
        pass

# Sort by size
files_by_size.sort(key=lambda x: x[1], reverse=True)

print('=== FILES >500 LINES (Top 40) ===')
for i, (path, lines, dir_name) in enumerate(files_by_size[:40], 1):
    indicator = 'X' if lines >= 1000 else '!' if lines >= 800 else '*'
    print(f'{i:2}. [{indicator}] {path}: {lines} lines')

print(f'\n=== SUMMARY BY DIRECTORY ===')
for dir_name in sorted(stats_by_dir.keys(), key=lambda x: stats_by_dir[x]['total_lines'], reverse=True):
    stats = stats_by_dir[dir_name]
    avg = stats['total_lines'] // stats['count']
    print(f'{dir_name}/: {stats["count"]} files, {stats["total_lines"]:,} lines (avg: {avg} lines/file)')

print(f'\n=== REFACTORING SCOPE ===')
print(f'Total files >500 lines: {len(files_by_size)}')
print(f'Total lines to refactor: {sum(x[1] for x in files_by_size):,}')
print(f'Files >=1000 lines: {len([x for x in files_by_size if x[1] >= 1000])}')
print(f'Files 800-999 lines: {len([x for x in files_by_size if 800 <= x[1] < 1000])}')
print(f'Files 500-799 lines: {len([x for x in files_by_size if 500 <= x[1] < 800])}')

# Export list for processing
print(f'\n=== PRIORITY REFACTORING TARGETS (>=1000 lines) ===')
critical = [x for x in files_by_size if x[1] >= 1000]
for path, lines, dir_name in critical:
    print(f'  {path}: {lines} lines')
