#!/usr/bin/env python3
"""Extract export and CSV generation methods"""

import re

# Read updated main file
with open('lib/screens/advanced_reports_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f'Processing {len(lines)} lines\n')

# Find export-related methods
export_methods = {}
for i, line in enumerate(lines, 1):
    if '  Future<void> _exportReport' in line or \
       '  Future<void> _exportPDF' in line or \
       '  String _generateCSVData' in line:
        method_name = re.search(r'_(\w+)', line).group(0)
        export_methods[method_name] = i
        print(f'Found {method_name} at line {i}')

if not export_methods:
    print('ERROR: Could not find export methods')
    exit(1)

# Find method ends
def find_method_end(start_line_idx):
    """Find end of method by tracking braces"""
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
for method, start_line in export_methods.items():
    end_line = find_method_end(start_line - 1)
    method_ranges[method] = (start_line, end_line)
    size = end_line - start_line + 1
    print(f'{method}: lines {start_line}-{end_line} ({size} lines)')

total_extracted = sum(end - start + 1 for start, end in method_ranges.values())
print(f'\nTotal extractable: {total_extracted} lines')

# Create export part file
export_part = []
export_part.append('// Part of advanced_reports_screen.dart\n')
export_part.append('// Export and data generation methods extracted from main file\n')
export_part.append('\n')
export_part.append("part of 'advanced_reports_screen.dart';\n")
export_part.append('\n')
export_part.append('extension AdvancedReportsExport on _AdvancedReportsScreenState {\n')

for method, (start, end) in sorted(method_ranges.items(), key=lambda x: x[1][0]):
    for i in range(start - 1, end):
        export_part.append(lines[i])
    export_part.append('\n')

export_part.append('}\n')

# Write part file
with open('lib/screens/advanced_reports_screen_export.dart', 'w', encoding='utf-8') as f:
    f.writelines(export_part)

print(f'\n✓ Created advanced_reports_screen_export.dart ({total_extracted} lines)')

# Update main file
with open('lib/screens/advanced_reports_screen.dart', 'r', encoding='utf-8') as f:
    main_lines = f.readlines()

# Add part directive after existing part
for i, line in enumerate(main_lines):
    if "part 'advanced_reports_screen_pdf_helpers.dart'" in line:
        main_lines.insert(i + 1, "part 'advanced_reports_screen_export.dart';\n")
        break

# Remove extracted methods (in reverse order)
for method, (start, end) in sorted(method_ranges.items(), key=lambda x: x[1][0], reverse=True):
    del main_lines[start - 1:end]

with open('lib/screens/advanced_reports_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(main_lines)

print(f'✓ Updated main file: {len(lines)} → {len(main_lines)} lines')
print(f'  Reduction: {len(lines) - len(main_lines)} lines')
print(f'\n✓ EXTRACTION COMPLETE')
