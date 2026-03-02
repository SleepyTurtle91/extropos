#!/usr/bin/env python3
"""Extract the largest Widget builder methods"""

import re

with open('lib/screens/advanced_reports_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f'Processing {len(lines)} lines\n')

# Find Widget builder methods
widget_methods = {}
for i, line in enumerate(lines, 1):
    if '  Widget _build' in line:
        match = re.search(r'Widget\s+(_build\w+)', line)
        if match:
            method = match.group(1)
            widget_methods[method] = i
            print(f'Found {method} at line {i}')

print(f'\nTotal Widget builders found: {len(widget_methods)}')

if not widget_methods:
    print('ERROR: No widget methods found')
    exit(1)

# Find method ends
def find_method_end(start_line_idx):
    brace_count = 0
    in_method = False
    for i in range(start_line_idx, len(lines)):
        line = lines[i]
        for char in line:
            if char == '{':
                brace_count += 1
                in_method = True
            elif char == '}':
                brace_count -= 1
                if in_method and brace_count == 0:
                    return i + 1
    return len(lines)

# Calculate sizes
method_ranges = {}
for method, start_line in widget_methods.items():
    end_line = find_method_end(start_line - 1)
    size = end_line - start_line + 1
    method_ranges[method] = (start_line, end_line, size)

# Sort by size and show top 15
sorted_methods = sorted(method_ranges.items(), key=lambda x: x[1][2], reverse=True)
print('\nTop 15 largest Widget methods:')
for method, (start, end, size) in sorted_methods[:15]:
    print(f'  {method}: {size} lines')

# Extract only the large ones (>100 lines)
large_methods = {m: r for m, r in method_ranges.items() if r[2] > 100}
print(f'\nLarge methods (>100 lines): {len(large_methods)}')
for method in sorted(large_methods.keys()):
    start, end, size = large_methods[method]
    print(f'  {method}: {size} lines')

# Create widgets part file
if large_methods:
    widgets_part = []
    widgets_part.append('// Part of advanced_reports_screen.dart\n')
    widgets_part.append('// Large Widget builders extracted from main file\n')
    widgets_part.append('\n')
    widgets_part.append("part of 'advanced_reports_screen.dart';\n")
    widgets_part.append('\n')
    widgets_part.append('extension AdvancedReportsLargeWidgets on _AdvancedReportsScreenState {\n')
    
    total_extracted = 0
    for method in sorted(large_methods.keys(), key=lambda m: large_methods[m][0]):
        start, end, size = large_methods[method]
        for i in range(start - 1, end):
            widgets_part.append(lines[i])
        widgets_part.append('\n')
        total_extracted += size
    
    widgets_part.append('}\n')
    
    with open('lib/screens/advanced_reports_screen_large_widgets.dart', 'w', encoding='utf-8') as f:
        f.writelines(widgets_part)
    
    print(f'\n✓ Created advanced_reports_screen_large_widgets.dart ({total_extracted} lines)')
    
    # Update main file
    with open('lib/screens/advanced_reports_screen.dart', 'r', encoding='utf-8') as f:
        main_lines = f.readlines()
    
    # Add part directive
    for i, line in enumerate(main_lines):
        if "part 'advanced_reports_screen_export.dart'" in line:
            main_lines.insert(i + 1, "part 'advanced_reports_screen_large_widgets.dart';\n")
            break
    
    # Remove extracted methods (reverse order)
    for method in sorted(large_methods.keys(), key=lambda m: large_methods[m][0], reverse=True):
        start, end, _ = large_methods[method]
        del main_lines[start - 1:end]
    
    with open('lib/screens/advanced_reports_screen.dart', 'w', encoding='utf-8') as f:
        f.writelines(main_lines)
    
    print(f'✓ Updated main file: {len(lines)} → {len(main_lines)} lines')
    print(f'  Reduction: {len(lines) - len(main_lines)} lines')
    print(f'\n✓ FINAL EXTRACTION COMPLETE')
else:
    print('\n✗ No large widget methods to extract (all <100 lines)')
