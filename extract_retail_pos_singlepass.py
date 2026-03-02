#!/usr/bin/env python3
"""Single-pass extraction for retail_pos_screen_modern.dart"""

import re

with open('lib/screens/retail_pos_screen_modern.dart', 'r', encoding='utf-8') as f:
    original_lines = f.readlines()

print('=' * 80)
print('SINGLE-PASS EXTRACTION: retail_pos_screen_modern.dart')
print('=' * 80)
print(f'Input: {len(original_lines)} lines\n')

# Find header (imports, etc.)
header_end = 0
for i, line in enumerate(original_lines):
    if 'class RetailPOSScreenModern' in line or 'class _RetailPOSScreenModernState' in line:
        header_end = i
        break

header = original_lines[:header_end]
print(f'Header: {len(header)} lines\n')

# Find all methods
def find_method_end(lines, start_idx):
    brace_count = 0
    in_method = False
    for i in range(start_idx, len(lines)):
        for char in lines[i]:
            if char == '{':
                brace_count += 1
                in_method = True
            elif char == '}':
                brace_count -= 1
                if in_method and brace_count == 0:
                    return i
    return len(lines) - 1

methods = []
for i in range(header_end, len(original_lines)):
    line = original_lines[i]
    match = re.match(r'^  (void|Widget|Future[<\w>]*|bool|String)\s+(_\w+)\s*\(', line)
    if match and not line.strip().startswith('@'):
        method_type = match.group(1)
        method_name = match.group(2)
        end_idx = find_method_end(original_lines, i)
        size = end_idx - i + 1
        
        methods.append({
            'name': method_name,
            'type': method_type,
            'start_idx': i,
            'end_idx': end_idx,
            'size': size,
            'is_widget': method_type == 'Widget',
            'is_future': 'Future' in method_type,
            'is_void': method_type == 'void'
        })

print(f'Found {len(methods)} methods\n')

# Skip _buildNumberPad - it's 974 lines and has structural issues
methods_to_extract = [m for m in methods if m['name'] != '_buildNumberPad']

print(f'Excluding _buildNumberPad (974 lines - will handle separately)')
print(f'Methods to extract: {len(methods_to_extract)}\n')

# Categorize
large_widgets = [m for m in methods_to_extract if m['is_widget'] and m['size'] > 100]
medium_widgets = [m for m in methods_to_extract if m['is_widget'] and 50 <= m['size'] <= 100]
small_widgets = [m for m in methods_to_extract if m['is_widget'] and m['size'] < 50]
void_ops = [m for m in methods_to_extract if m['is_void']]
future_ops = [m for m in methods_to_extract if m['is_future']]

print(f'Large widgets (>100): {len(large_widgets)} methods')
print(f'Medium widgets (50-100): {len(medium_widgets)} methods')
print(f'Small widgets (<50): {len(small_widgets)} methods')
print(f'Void operations: {len(void_ops)} methods')
print(f'Future operations: {len(future_ops)} methods\n')

# Create part files
def make_part_content(methods, part_name, extension_name):
    content = []
    content.append('// Part of retail_pos_screen_modern.dart\n')
    content.append(f'// {part_name}\n')
    content.append('\n')
    content.append("part of 'retail_pos_screen_modern.dart';\n")
    content.append('\n')
    content.append(f'extension {extension_name} on _RetailPOSScreenModernState {{\n')
    
    for method in sorted(methods, key=lambda m: m['start_idx']):
        for i in range(method['start_idx'], method['end_idx'] + 1):
            content.append(original_lines[i])
        content.append('\n')
    
    content.append('}\n')
    return content

parts = []

if large_widgets:
    content = make_part_content(large_widgets, 'Large widget builders', 'RetailPOSLargeWidgets')
    filename = 'lib/screens/retail_pos_screen_modern_large_widgets.dart'
    with open(filename, 'w', encoding='utf-8') as f:
        f.writelines(content)
    total_lines = sum(m['size'] for m in large_widgets)
    parts.append((filename.split('/')[-1], len(large_widgets), total_lines))
    print(f'✓ Created large widgets part: {len(large_widgets)} methods, {total_lines} lines')

if medium_widgets:
    content = make_part_content(medium_widgets, 'Medium widget builders', 'RetailPOSMediumWidgets')
    filename = 'lib/screens/retail_pos_screen_modern_medium_widgets.dart'
    with open(filename, 'w', encoding='utf-8') as f:
        f.writelines(content)
    total_lines = sum(m['size'] for m in medium_widgets)
    parts.append((filename.split('/')[-1], len(medium_widgets), total_lines))
    print(f'✓ Created medium widgets part: {len(medium_widgets)} methods, {total_lines} lines')

if void_ops:
    content = make_part_content(void_ops, 'Void operations', 'RetailPOSOperations')
    filename = 'lib/screens/retail_pos_screen_modern_operations.dart'
    with open(filename, 'w', encoding='utf-8') as f:
        f.writelines(content)
    total_lines = sum(m['size'] for m in void_ops)
    parts.append((filename.split('/')[-1], len(void_ops), total_lines))
    print(f'✓ Created operations part: {len(void_ops)} methods, {total_lines} lines')

if future_ops:
    content = make_part_content(future_ops, 'Future operations', 'RetailPOSFutureOps')
    filename = 'lib/screens/retail_pos_screen_modern_futures.dart'
    with open(filename, 'w', encoding='utf-8') as f:
        f.writelines(content)
    total_lines = sum(m['size'] for m in future_ops)
    parts.append((filename.split('/')[-1], len(future_ops), total_lines))
    print(f'✓ Created futures part: {len(future_ops)} methods, {total_lines} lines')

# Build new main file
all_extracted = set()
for method_list in [large_widgets, medium_widgets, void_ops, future_ops]:
    for m in method_list:
        all_extracted.add((m['start_idx'], m['end_idx']))

new_main = header[:]

# Add part directives
last_import = 0
for i in range(len(new_main)):
    if new_main[i].startswith('import '):
        last_import = i

if parts:
    new_main.insert(last_import + 1, '\n')
    for part_file, _, _ in parts:
        new_main.insert(last_import + 2, f"part '{part_file}';\n")

# Add class and keep only non-extracted methods
for i in range(header_end, len(original_lines)):
    skip = False
    for start, end in all_extracted:
        if start <= i <= end:
            skip = True
            break
    
    if not skip:
        new_main.append(original_lines[i])

with open('lib/screens/retail_pos_screen_modern.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_main)

total_extracted = sum(m['size'] for m in methods_to_extract)
print(f'\n✓ Updated main file: {len(original_lines)} → {len(new_main)} lines')
print(f'  Total extracted: {total_extracted} lines')
print(f'  Includes _buildNumberPad: 974 lines (needs manual fix)')

print('\n' + '=' * 80)
print(f'RESULT: Main file = {len(new_main)} lines')
if len(new_main) < 1000:
    print('✓ COMPLIANT (<1000)')
else:
    print(f'Note: Still {len(new_main) - 1000} lines over (mainly _buildNumberPad)')
print('=' * 80)
