#!/usr/bin/env python3
"""Extract void and Future operation methods"""

import re

with open('lib/screens/advanced_reports_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f'Processing {len(lines)} lines\n')

# Find void and Future methods (but exclude lifecycle like initState, dispose, build)
operation_methods = {}
for i, line in enumerate(lines, 1):
    if ('  void _' in line or '  Future' in line) and 'initState' not in line and 'dispose' not in line and 'build' not in line:
        match = re.search(r'(?:void|Future[<\w>]*)\s+(_\w+)', line)
        if match:
            method = match.group(1)
            operation_methods[method] = i

print(f'Operation methods found: {len(operation_methods)}')
for m in sorted(operation_methods.items(), key=lambda x: x[1]):
    print(f'  {m[0]}: line {m[1]}')

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
for method, start_line in operation_methods.items():
    end_line = find_method_end(start_line - 1)
    size = end_line - start_line + 1
    method_ranges[method] = (start_line, end_line, size)
    total_to_extract += size

print(f'\nTop operation methods by size:')
for m, (start, end, size) in sorted(method_ranges.items(), key=lambda x: x[1][2], reverse=True)[:10]:
    print(f'  {m}: {size} lines')

print(f'\nTotal to extract: {total_to_extract} lines')

# Create part file
ops_part = []
ops_part.append('// Part of advanced_reports_screen.dart\n')
ops_part.append('// Operation methods (void, Future) extracted from main file\n')
ops_part.append('\n')
ops_part.append("part of 'advanced_reports_screen.dart';\n")
ops_part.append('\n')
ops_part.append('extension AdvancedReportsOperations on _AdvancedReportsScreenState {\n')

for method in sorted(method_ranges.keys(), key=lambda m: method_ranges[m][0]):
    start, end, size = method_ranges[method]
    for i in range(start - 1, end):
        ops_part.append(lines[i])
    ops_part.append('\n')

ops_part.append('}\n')

with open('lib/screens/advanced_reports_screen_operations.dart', 'w', encoding='utf-8') as f:
    f.writelines(ops_part)

print(f'\n✓ Created advanced_reports_screen_operations.dart ({total_to_extract} lines)')

# Update main file
with open('lib/screens/advanced_reports_screen.dart', 'r', encoding='utf-8') as f:
    main_lines = f.readlines()

# Add part directive
for i, line in enumerate(main_lines):
    if "part 'advanced_reports_screen_medium_widgets.dart'" in line:
        main_lines.insert(i + 1, "part 'advanced_reports_screen_operations.dart';\n")
        break

# Remove extracted methods (reverse order)
for method in sorted(method_ranges.keys(), key=lambda m: method_ranges[m][0], reverse=True):
    start, end, _ = method_ranges[method]
    del main_lines[start - 1:end]

with open('lib/screens/advanced_reports_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(main_lines)

print(f'✓ Updated main file: {len(lines)} → {len(main_lines)} lines')
print(f'  Reduction: {len(lines) - len(main_lines)} lines')
print(f'\n✓ OPERATIONS EXTRACTION COMPLETE')
