#!/usr/bin/env python3
"""Further extract large methods from advanced_reports_screen_widgets.dart"""

import re

with open('lib/screens/advanced_reports_screen_widgets.dart', 'r', encoding='utf-8') as f:
    content = f.read()
    lines = content.split('\n')

print('=' * 80)
print('PARSING advanced_reports_screen_widgets.dart (SECOND PASS)')
print('=' * 80)
print(f'Input: {len(lines)} lines\n')

# Find all Widget method signatures in extension (4-space indent for extension methods)
method_pattern = r'^  Widget\s+(_\w+)\s*\('
methods = []

for i, line in enumerate(lines):
    m = re.match(method_pattern, line)
    if m:
        method_name = m.group(1)
        methods.append({
            'line': i,
            'name': method_name,
        })

print(f'Found {len(methods)} Widget methods in extension')

if not methods:
    print('No methods found - file may already be optimized')
    exit(0)

# Find method ends
def find_method_end(line_num):
    """Find end of method by tracking brace balance"""
    brace_count = 0
    in_method = False
    
    for i in range(line_num, len(lines)):
        line = lines[i]
        
        for char in line:
            if char == '{':
                brace_count += 1
                in_method = True
            elif char == '}':
                brace_count -= 1
                if in_method and brace_count == 0:
                    return i
    
    return len(lines) - 1

for method in methods:
    method['end'] = find_method_end(method['line'])
    method['size'] = method['end'] - method['line'] + 1

# Sort by size
methods_by_size = sorted(methods, key=lambda x: x['size'], reverse=True)

print('\nTop 10 largest methods:')
for m in methods_by_size[:10]:
    print(f'  {m["name"]}: {m["size"]} lines')

# Split large and small methods
large_methods = [m for m in methods if m['size'] > 100]
small_methods = [m for m in methods if m['size'] <= 100]

print(f'\nLarge (>100 lines): {len(large_methods)} methods, {sum(m["size"] for m in large_methods)} lines')
print(f'Small (≤100 lines): {len(small_methods)} methods, {sum(m["size"] for m in small_methods)} lines')

if not large_methods:
    print('\n✓ All methods already optimized (<100 lines)')
    exit(0)

# Create file for large widgets
print('\nExtracting large widgets...')
large_content = []
large_lines_count = 0

large_content.append('// Part of advanced_reports_screen.dart')
large_content.append('// Large widget builders (detail screens) extracted from main widgets extension')
large_content.append('')
large_content.append("part of 'advanced_reports_screen.dart';")
large_content.append('')
large_content.append('extension AdvancedReportsLargeWidgets on _AdvancedReportsScreenState {')

for m in large_methods:
    start = m['line']
    end = m['end'] + 1
    large_content.extend(lines[start:end])
    large_content.append('')
    large_lines_count += m['size']

large_content.append('}')
large_content.append('')

with open('lib/screens/advanced_reports_screen_large_widgets.dart', 'w', encoding='utf-8') as f:
    f.write('\n'.join(large_content))

print(f'✓ Created advanced_reports_screen_large_widgets.dart: {large_lines_count} lines')

# Rebuild widgets file with only small widgets
print('Updating widgets file...')
small_content = []

# Copy header
header_lines = []
for line in lines:
    if line.strip().startswith('Widget '):
        break
    header_lines.append(line)

small_content.extend(header_lines)

# Add modified extension with small methods only
for m in small_methods:
    start = m['line']
    end = m['end'] + 1
    small_content.extend(lines[start:end])
    small_content.append('')

small_content.append('}')
small_content.append('')

with open('lib/screens/advanced_reports_screen_widgets.dart', 'w', encoding='utf-8') as f:
    f.write('\n'.join(small_content))

print(f'✓ Updated widgets file: {len(lines)} → {len(small_content)} lines')

# Update main file to include new part
print('\nUpdating main file with new part directive...')
with open('lib/screens/advanced_reports_screen.dart', 'r', encoding='utf-8') as f:
    main_lines = f.readlines()

# Find where to insert new part directive (after widgets part)
for i, line in enumerate(main_lines):
    if "part 'advanced_reports_screen_widgets.dart'" in line:
        main_lines.insert(i + 1, "part 'advanced_reports_screen_large_widgets.dart';\n")
        break

with open('lib/screens/advanced_reports_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(main_lines)

print('✓ Updated main file')

print()
print('=' * 80)
print('SECOND PASS COMPLETE')
print('=' * 80)
print(f'Widgets part: {len(lines)} → {len(small_content)} lines')
print(f'New large widgets part: {large_lines_count} lines')
print()
