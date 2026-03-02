#!/usr/bin/env python3
"""Analyze retail_pos_screen_modern.dart for extraction"""

import re

with open('lib/screens/retail_pos_screen_modern.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print('=' * 80)
print('RETAIL_POS_SCREEN_MODERN.DART ANALYSIS')
print('=' * 80)
print(f'Total lines: {len(lines)}\n')

# Find all methods
methods = []
for i, line in enumerate(lines, 1):
    match = re.match(r'^  (void|Widget|Future[<\w>]*|bool|String)\s+(_?\w+)\s*\(', line)
    if match and not line.strip().startswith('@'):
        return_type = match.group(1)
        method_name = match.group(2)
        methods.append({
            'line': i,
            'type': return_type,
            'name': method_name
        })

print(f'Found {len(methods)} methods\n')

# Find method sizes
def find_method_end(start_idx):
    brace_count = 0
    in_method = False
    for i in range(start_idx - 1, len(lines)):
        for char in lines[i]:
            if char == '{':
                brace_count += 1
                in_method = True
            elif char == '}':
                brace_count -= 1
                if in_method and brace_count == 0:
                    return i + 1
    return len(lines)

for method in methods:
    end_line = find_method_end(method['line'] - 1)
    method['end'] = end_line
    method['size'] = end_line - method['line'] + 1

# Categorize
large_methods = [m for m in methods if m['size'] > 100]
medium_methods = [m for m in methods if 50 <= m['size'] <= 100]
small_methods = [m for m in methods if m['size'] < 50]

widget_methods = [m for m in methods if m['type'] == 'Widget']
void_methods = [m for m in methods if m['type'] == 'void']
future_methods = [m for m in methods if 'Future' in m['type']]

print(f'Large methods (>100 lines): {len(large_methods)}')
print(f'Medium methods (50-100 lines): {len(medium_methods)}')
print(f'Small methods (<50 lines): {len(small_methods)}\n')

print(f'Widget methods: {len(widget_methods)}')
print(f'Void methods: {len(void_methods)}')
print(f'Future methods: {len(future_methods)}\n')

print('TOP 15 LARGEST METHODS:')
for i, m in enumerate(sorted(methods, key=lambda x: x['size'], reverse=True)[:15], 1):
    print(f'{i:2}. {m["name"]:40} {m["size"]:4} lines ({m["type"]})')

total_extractable = sum(m['size'] for m in methods if m['size'] > 30)
remaining = len(lines) - total_extractable

print(f'\nExtractable (>30 lines): {total_extractable} lines')
print(f'Estimated main after extraction: {remaining} lines')

if remaining < 1000:
    print('✓ ACHIEVABLE (<1000)')
else:
    print(f'Note: Would still be {remaining} lines')

print('=' * 80)
