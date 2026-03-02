#!/usr/bin/env python3
"""Extract ALL Widget builder methods (second pass)"""

import re

with open('lib/screens/advanced_reports_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f'Processing {len(lines)} lines\n')

# Find ALL Widget builder methods (but exclude _buildReportContent as it's a dispatcher)
widget_methods = {}
for i, line in enumerate(lines, 1):
    if '  Widget _build' in line:
        match = re.search(r'Widget\s+(_build\w+)', line)
        if match:
            method = match.group(1)
            # We'll skip the small dispatcher and metrics card for now
            if method not in ['_buildReportContent', '_buildMetricCard']:
                widget_methods[method] = i

print(f'Widget builders to extract: {len(widget_methods)}')

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

# Calculate ranges
method_ranges = {}
total_to_extract = 0
for method, start_line in widget_methods.items():
    end_line = find_method_end(start_line - 1)
    size = end_line - start_line + 1
    method_ranges[method] = (start_line, end_line, size)
    total_to_extract += size
    print(f'  {method}: {size} lines')

print(f'\nTotal to extract: {total_to_extract} lines')

# Create widgets part file
widgets_part = []
widgets_part.append('// Part of advanced_reports_screen.dart\n')
widgets_part.append('// Medium Widget builders extracted from main file\n')
widgets_part.append('\n')
widgets_part.append("part of 'advanced_reports_screen.dart';\n")
widgets_part.append('\n')
widgets_part.append('extension AdvancedReportsMediumWidgets on _AdvancedReportsScreenState {\n')

for method in sorted(method_ranges.keys(), key=lambda m: method_ranges[m][0]):
    start, end, size = method_ranges[method]
    for i in range(start - 1, end):
        widgets_part.append(lines[i])
    widgets_part.append('\n')

widgets_part.append('}\n')

with open('lib/screens/advanced_reports_screen_medium_widgets.dart', 'w', encoding='utf-8') as f:
    f.writelines(widgets_part)

print(f'\n✓ Created advanced_reports_screen_medium_widgets.dart ({total_to_extract} lines)')

# Update main file
with open('lib/screens/advanced_reports_screen.dart', 'r', encoding='utf-8') as f:
    main_lines = f.readlines()

# Add part directive
for i, line in enumerate(main_lines):
    if "part 'advanced_reports_screen_large_widgets.dart'" in line:
        main_lines.insert(i + 1, "part 'advanced_reports_screen_medium_widgets.dart';\n")
        break

# Remove extracted methods (reverse order)
for method in sorted(method_ranges.keys(), key=lambda m: method_ranges[m][0], reverse=True):
    start, end, _ = method_ranges[method]
    del main_lines[start - 1:end]

with open('lib/screens/advanced_reports_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(main_lines)

print(f'✓ Updated main file: {len(lines)} → {len(main_lines)} lines')
print(f'  Reduction: {len(lines) - len(main_lines)} lines')
print(f'\n✓ SECOND WIDGET EXTRACTION COMPLETE')
