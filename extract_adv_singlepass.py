#!/usr/bin/env python3
"""
Single-pass extraction for advanced_reports_screen.dart
Reads file once, identifies all methods, creates part files, rebuilds main file
"""

import re

# Read original file ONCE
with open('lib/screens/advanced_reports_screen.dart', 'r', encoding='utf-8') as f:
    original_lines = f.readlines()

print('=' * 80)
print('SINGLE-PASS EXTRACTION: advanced_reports_screen.dart')
print('=' * 80)
print(f'Input: {len(original_lines)} lines\n')

# Extract everything before class definition
header_end = 0
for i, line in enumerate(original_lines):
    if line.strip().startswith('class AdvancedReportsScreen'):
        header_end = i
        break

header = original_lines[:header_end]
print(f'Header: {len(header)} lines (imports/annotations)\n')

# Find all methods in State class
def find_method_range(lines, start_idx):
    """Find start and end of a method"""
    brace_count = 0
    in_method = False
    
    for i in range(start_idx, len(lines)):
        line = lines[i]
        
        for char in line:
            if char == '{':
                brace_count += 1
                in_method = True
            elif char == '}':
                brace_count -= 1
                if in_method and brace_count == 0:
                    return (start_idx, i)
    
    return (start_idx, len(lines) - 1)

# Scan for all methods
methods = []
for i in range(header_end, len(original_lines)):
    line = original_lines[i]
    
    # Match method definitions
    if re.match(r'^  (void|Widget|Future|@override|String|pw\.Widget|bool|int)\s+_?\w+', line):
        if not line.strip().startswith('@'):  # Skip decorators
            method_match = re.search(r'(?:void|Widget|Future[<\w>]*|String|pw\.Widget|bool|int)\s+(_?\w+)\s*\(', line)
            if method_match:
                method_name = method_match.group(1)
                start_line = i
                end_line_idx = find_method_range(original_lines, i)
                end_line = end_line_idx[1]
                size = end_line - start_line + 1
                
                methods.append({
                    'name': method_name,
                    'start_idx': start_line,
                    'end_idx': end_line,
                    'size': size,
                    'is_widget': 'Widget' in line or 'pw.Widget' in line,
                    'is_future': 'Future' in line,
                    'is_private': method_name.startswith('_')
                })

print(f'Found {len(methods)} methods total\n')

# Categorize methods
pdf_methods = [m for m in methods if '_PDF' in m['name']]
export_methods = [m for m in methods if m['name'] in ['_exportReport', '_exportPDF', '_generateCSVData']]
large_widgets = [m for m in methods if m['is_widget'] and m['size'] > 100]
medium_widgets = [m for m in methods if m['is_widget'] and 50 <= m['size'] <= 100]
small_widgets = [m for m in methods if m['is_widget'] and m['size'] < 50]
operations = [m for m in methods if not m['is_widget'] and m['name'] != 'build']

print(f'PDF methods: {len(pdf_methods)}')
print(f'Export methods: {len(export_methods)}')
print(f'Large widgets (>100): {len(large_widgets)}')
print(f'Medium widgets (50-100): {len(medium_widgets)}')
print(f'Small widgets (<50): {len(small_widgets)}')
print(f'Operations (void/Future): {len(operations)}\n')

# Extract to part files
def make_part_content(header, methods, part_name, extension_name):
    """Generate content for a part file"""
    content = []
    content.append('// Part of advanced_reports_screen.dart\n')
    content.append(f'// Auto-extracted {part_name}\n')
    content.append('\n')
    content.append("part of 'advanced_reports_screen.dart';\n")
    content.append('\n')
    content.append(f'extension {extension_name} on _AdvancedReportsScreenState {{\n')
    
    for method in sorted(methods, key=lambda m: m['start_idx']):
        for i in range(method['start_idx'], method['end_idx'] + 1):
            content.append(original_lines[i])
        content.append('\n')
    
    content.append('}\n')
    return content

# Create all part files
parts = []

if pdf_methods:
    content = make_part_content(header, pdf_methods, 'PDF helpers', 'AdvancedReportsPDF')
    with open('lib/screens/advanced_reports_screen_pdf.dart', 'w') as f:
        f.writelines(content)
    parts.append(('advanced_reports_screen_pdf.dart', len(pdf_methods), sum(m['size'] for m in pdf_methods)))
    print(f'✓ Created PDF part: {len(pdf_methods)} methods, {sum(m["size"] for m in pdf_methods)} lines')

if export_methods:
    content = make_part_content(header, export_methods, 'Export operations', 'AdvancedReportsExport')
    with open('lib/screens/advanced_reports_screen_export.dart', 'w') as f:
        f.writelines(content)
    parts.append(('advanced_reports_screen_export.dart', len(export_methods), sum(m['size'] for m in export_methods)))
    print(f'✓ Created Export part: {len(export_methods)} methods, {sum(m["size"] for m in export_methods)} lines')

if large_widgets:
    content = make_part_content(header, large_widgets, 'Large widgets (>100L)', 'AdvancedReportsLargeWidgets')
    with open('lib/screens/advanced_reports_screen_large_widgets.dart', 'w') as f:
        f.writelines(content)
    parts.append(('advanced_reports_screen_large_widgets.dart', len(large_widgets), sum(m['size'] for m in large_widgets)))
    print(f'✓ Created Large Widgets part: {len(large_widgets)} methods, {sum(m["size"] for m in large_widgets)} lines')

if medium_widgets:
    content = make_part_content(header, medium_widgets, 'Medium widgets (50-100L)', 'AdvancedReportsMediumWidgets')
    with open('lib/screens/advanced_reports_screen_medium_widgets.dart', 'w') as f:
        f.writelines(content)
    parts.append(('advanced_reports_screen_medium_widgets.dart', len(medium_widgets), sum(m['size'] for m in medium_widgets)))
    print(f'✓ Created Medium Widgets part: {len(medium_widgets)} methods, {sum(m["size"] for m in medium_widgets)} lines')

if operations:
    content = make_part_content(header, operations, 'Operations (void/Future)', 'AdvancedReportsOperations')
    with open('lib/screens/advanced_reports_screen_operations.dart', 'w') as f:
        f.writelines(content)
    parts.append(('advanced_reports_screen_operations.dart', len(operations), sum(m['size'] for m in operations)))
    print(f'✓ Created Operations part: {len(operations)} methods, {sum(m["size"] for m in operations)} lines')

# Build new main file - include only non-extracted methods and class definition
all_extracted = set()
for method_list in [pdf_methods, export_methods, large_widgets, medium_widgets, operations]:
    for m in method_list:
        all_extracted.add((m['start_idx'], m['end_idx']))

# Find class definition and build method
class_start = 0
build_start = 0
state_class_end = 0

for i in range(header_end, len(original_lines)):
    line = original_lines[i]
    if 'class _AdvancedReportsScreenState' in line:
        class_start = i
    if '  @override\n  Widget build(' in original_lines[i:i+2] if i+1 < len(original_lines) else False:
        build_start = i
        # Find end of build method
        for j in range(i, len(original_lines)):
            state_class_end = j
            if j > i and original_lines[j].strip() == '}' and original_lines[j-1].strip().endswith(');'):
                break

# Rebuild main file
new_main = header[:]

# Add imports for part files
last_import = 0
for i in range(len(new_main)):
    if new_main[i].startswith('import '):
        last_import = i

if parts:
    new_main.insert(last_import + 1, '\n')
    for part_file, _, _ in parts:
        new_main.insert(last_import + 2, f"part '{part_file}';\n")

# Add class and keep only non-extracted methods
for i in range(class_start, len(original_lines)):
    # Skip extracted methods
    skip = False
    for start, end in all_extracted:
        if start <= i <= end:
            skip = True
            break
    
    if not skip:
        new_main.append(original_lines[i])

# Ensure closing brace
if new_main[-1].strip() != '}':
    new_main.append('}\n')

# Write new main file
with open('lib/screens/advanced_reports_screen.dart', 'w') as f:
    f.writelines(new_main)

total_extracted = sum(m['size'] for m in pdf_methods + export_methods + large_widgets + medium_widgets + operations)
print(f'\n✓ Updated main file: {len(original_lines)} → {len(new_main)} lines')
print(f'  Total extracted: {total_extracted} lines')
print(f'  Reduction: {len(original_lines) - len(new_main)} lines')

print()
print('=' * 80)
print(f'RESULT: Main file = {len(new_main)} lines', end='')
if len(new_main) < 1000:
    print(' ✓ COMPLIANT (<1000)')
else:
    print(f' (still {len(new_main) - 1000} lines over target)')
print('=' * 80)
