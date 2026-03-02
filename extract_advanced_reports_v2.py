#!/usr/bin/env python3
"""Extract large methods from advanced_reports_screen.dart"""

import re

with open('lib/screens/advanced_reports_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()
    lines = content.split('\n')

print('=' * 80)
print('PARSING advanced_reports_screen.dart')
print('=' * 80)

# Find all method signatures at class level (2-space indent)
method_pattern = r'^  (Widget|void|Future<\w+>)\s+(_\w+)\s*\('
methods = []

for i, line in enumerate(lines):
    m = re.match(method_pattern, line)
    if m:
        return_type = m.group(1)
        method_name = m.group(2)
        methods.append({
            'line': i,
            'name': method_name,
            'type': return_type,
            'start_text': line.strip()[:50]
        })

print(f'Found {len(methods)} methods')

# Group by type
widgets = [m for m in methods if m['type'] == 'Widget']
voids = [m for m in methods if m['type'] == 'void']
futures = [m for m in methods if 'Future' in m['type']]

print(f'  Widget: {len(widgets)}')
print(f'  Void: {len(voids)}')
print(f'  Future: {len(futures)}')
print()

# Find method ends
def find_method_end(line_num):
    """Find end of method by tracking brace balance"""
    brace_count = 0
    in_method = False
    
    for i in range(line_num, len(lines)):
        line = lines[i]
        
        # Skip strings
        if "'" in line or '"' in line:
            # Simple skip for string content
            pass
        
        for char in line:
            if char == '{':
                brace_count += 1
                in_method = True
            elif char == '}':
                brace_count -= 1
                if in_method and brace_count == 0:
                    return i
    
    return len(lines) - 1

print('Finding method boundaries...')
for method in methods:
    method['end'] = find_method_end(method['line'])
    method['size'] = method['end'] - method['line'] + 1

# Show sizes
print('\nMethod sizes:')
for m in sorted(methods, key=lambda x: x['size'], reverse=True)[:10]:
    print(f'  {m["name"]}: {m["size"]} lines')

# Extract widgets
print('\nExtracting widgets...')
widget_content = []
widget_lines_count = 0

widget_content.append('// Part of advanced_reports_screen.dart')
widget_content.append('// Widget builders extracted from main file')
widget_content.append('')
widget_content.append("part of 'advanced_reports_screen.dart';")
widget_content.append('')
widget_content.append('extension AdvancedReportsWidgets on _AdvancedReportsScreenState {')

for m in widgets:
    start = m['line']
    end = m['end'] + 1
    widget_content.extend(lines[start:end])
    widget_content.append('')
    widget_lines_count += m['size']

widget_content.append('}')
widget_content.append('')

with open('lib/screens/advanced_reports_screen_widgets.dart', 'w', encoding='utf-8') as f:
    f.write('\n'.join(widget_content))

print(f'✓ Created advanced_reports_screen_widgets.dart: {widget_lines_count} lines')

# Extract operations
print('Extracting void operations...')
void_content = []
void_lines_count = 0

void_content.append('// Part of advanced_reports_screen.dart')
void_content.append('// Void operation methods extracted from main file')
void_content.append('')
void_content.append("part of 'advanced_reports_screen.dart';")
void_content.append('')
void_content.append('extension AdvancedReportsOperations on _AdvancedReportsScreenState {')

for m in voids:
    start = m['line']
    end = m['end'] + 1
    void_content.extend(lines[start:end])
    void_content.append('')
    void_lines_count += m['size']

void_content.append('}')
void_content.append('')

with open('lib/screens/advanced_reports_screen_operations.dart', 'w', encoding='utf-8') as f:
    f.write('\n'.join(void_content))

print(f'✓ Created advanced_reports_screen_operations.dart: {void_lines_count} lines')

# Extract futures
print('Extracting Future methods...')
future_content = []
future_lines_count = 0

future_content.append('// Part of advanced_reports_screen.dart')
future_content.append('// Export and async operation methods extracted from main file')
future_content.append('')
future_content.append("part of 'advanced_reports_screen.dart';")
future_content.append('')
future_content.append('extension AdvancedReportsExport on _AdvancedReportsScreenState {')

for m in futures:
    start = m['line']
    end = m['end'] + 1
    future_content.extend(lines[start:end])
    future_content.append('')
    future_lines_count += m['size']

future_content.append('}')
future_content.append('')

with open('lib/screens/advanced_reports_screen_export.dart', 'w', encoding='utf-8') as f:
    f.write('\n'.join(future_content))

print(f'✓ Created advanced_reports_screen_export.dart: {future_lines_count} lines')

# Create new main file - remove extracted methods, add part directives
print('\nUpdating main file...')
new_main = []

# Copy up to imports
import_end = 0
for i, line in enumerate(lines):
    if line.strip().startswith('import ') or line.strip().startswith('export '):
        import_end = i

# Copy everything up to and including imports
new_main.extend(lines[:import_end + 1])

# Add part directives
new_main.append('')
new_main.append("part 'advanced_reports_screen_widgets.dart';")
new_main.append("part 'advanced_reports_screen_operations.dart';")
new_main.append("part 'advanced_reports_screen_export.dart';")

# Find class definition start
class_start = 0
for i in range(import_end + 1, len(lines)):
    if lines[i].strip().startswith('class '):
        class_start = i
        break

# Copy from class def until first method
new_main.extend(lines[class_start:methods[0]['line']])

# Remove all extracted methods from main (in reverse order to preserve indices)
all_methods_sorted = sorted(methods, key=lambda m: m['line'], reverse=True)
remaining_lines = lines[:]

for m in all_methods_sorted:
    del remaining_lines[m['line']:m['end'] + 1]

# Find where methods started
methods_start = methods[0]['line']
remaining_from_methods = remaining_lines[methods_start:]

new_main.extend(remaining_from_methods)

# Remove trailing empty lines
while new_main and not new_main[-1].strip():
    new_main.pop()

new_main.append('')

with open('lib/screens/advanced_reports_screen.dart', 'w', encoding='utf-8') as f:
    f.write('\n'.join(new_main))

print(f'✓ Updated main file: {len(lines)} → {len(new_main)} lines')
print(f'  Reduction: {len(lines) - len(new_main)} lines')

print()
print('=' * 80)
print('EXTRACTION COMPLETE')
print('=' * 80)
print(f'Main file: {len(new_main)} lines ✓')
print(f'  - Widgets part: {widget_lines_count} lines')
print(f'  - Operations part: {void_lines_count} lines')
print(f'  - Export part: {future_lines_count} lines')
print(f'  - Total extracted: {widget_lines_count + void_lines_count + future_lines_count} lines')
print()
