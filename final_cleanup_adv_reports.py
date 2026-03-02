#!/usr/bin/env python3
"""Final cleanup - extract remaining ~65 lines"""

import re

with open('lib/screens/advanced_reports_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f'Current size: {len(lines)} lines')
print('Target: <1000 lines\n')

# Find remaining helper methods
# Look for _formatTime, _formatDuration, _filterSummary, _getReportTypeLabel, etc.
helper_methods = {}
for i, line in enumerate(lines, 1):
    if '  String _' in line or '  bool _matches' in line:
        match = re.search(r'(?:String|bool)\s+(_\w+)\s*\(', line)
        if match:
            method = match.group(1)
            helper_methods[method] = i

print(f'Found {len(helper_methods)} helper methods:')
for m, line_num in sorted(helper_methods.items(), key=lambda x: x[1]):
    print(f'  {m}: line {line_num}')

def find_method_end(lines, start_idx):
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
                    return i
    return len(lines) - 1

method_ranges = {}
total_to_extract = 0
for method, start_line in helper_methods.items():
    end_line_idx = find_method_end(lines, start_line - 1)
    size = end_line_idx - (start_line - 1) + 1
    method_ranges[method] = (start_line, end_line_idx + 1, size)
    total_to_extract += size

print(f'\nTotal helper lines: {total_to_extract}')

if total_to_extract < 50:
    print('Need to find more to extract...')
    # Find void methods (filter/format helpers)
    for i, line in enumerate(lines, 1):
        if '  void _' in line:
            match = re.search(r'void\s+(_\w+)', line)
            if match:
                method = match.group(1)
                if method not in helper_methods:
                    end_line_idx = find_method_end(lines, i - 1)
                    size = end_line_idx - (i - 1) + 1
                    if size < 30:
                        method_ranges[method] = (i, end_line_idx + 1, size)
                        total_to_extract += size
                        print(f'  Added {method}: {size} lines')

print(f'\nTotal to extract: {total_to_extract} lines')

if total_to_extract < 65:
    print('Creating minimal helpers part file only')

# Create part file
helpers_part = []
helpers_part.append('// Part of advanced_reports_screen.dart\n')
helpers_part.append('// Helper methods\n')
helpers_part.append('\n')
helpers_part.append("part of 'advanced_reports_screen.dart';\n")
helpers_part.append('\n')
helpers_part.append('extension AdvancedReportsHelpers on _AdvancedReportsScreenState {\n')

for method in sorted(method_ranges.keys(), key=lambda m: method_ranges[m][0]):
    start, end, size = method_ranges[method]
    for i in range(start - 1, end - 1):
        if i < len(lines):
            helpers_part.append(lines[i])
    helpers_part.append('\n')

helpers_part.append('}\n')

with open('lib/screens/advanced_reports_screen_helpers.dart', 'w') as f:
    f.writelines(helpers_part)

print(f'✓ Created helpers part')

# Update main file
with open('lib/screens/advanced_reports_screen.dart', 'r') as f:
    main_lines = f.readlines()

# Add part directive
for i, line in enumerate(main_lines):
    if "part 'advanced_reports_screen_export.dart'" in line:
        main_lines.insert(i + 1, "part 'advanced_reports_screen_helpers.dart';\n")
        break

# Remove extracted methods (reverse order)
for method in sorted(method_ranges.keys(), key=lambda m: method_ranges[m][0], reverse=True):
    start, end, _ = method_ranges[method]
    del main_lines[start - 1:end - 1]

with open('lib/screens/advanced_reports_screen.dart', 'w') as f:
    f.writelines(main_lines)

print(f'✓ Updated main file: {len(lines)} → {len(main_lines)} lines')
print(f'  Reduction: {len(lines) - len(main_lines)} lines')

if len(main_lines) < 1000:
    print(f'\n✓ SUCCESS: {len(main_lines)} lines (<1000) ✓ COMPLIANT')
else:
    print(f'\nNote: {len(main_lines)} lines (need {len(main_lines) - 1000} more lines removed)')
