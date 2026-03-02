#!/usr/bin/env python3
"""Extract content builders and helpers from reports_screen.dart using part/part of pattern."""

with open('lib/screens/reports_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find all content builder methods
content_builders = []
for i, line in enumerate(lines):
    if line.strip().startswith('Widget _build') and 'Content()' in line:
        method_name = line.strip().split('(')[0].replace('Widget ', '')
        brace_count = 0
        for j in range(i, len(lines)):
            brace_count += lines[j].count('{') - lines[j].count('}')
            if brace_count == 0 and j > i:
                content_builders.append((method_name, i, j + 1))
                break

# Find helper methods to extract
helper_methods = [
    '_generateReportCsv',
    '_generateAdvancedCSVData',
    '_getReportTypeLabel',
]

for method_name in helper_methods:
    for i, line in enumerate(lines):
        if f'String {method_name}(' in line or f'String {method_name}()' in line:
            brace_count = 0
            for j in range(i, len(lines)):
                brace_count += lines[j].count('{') - lines[j].count('}')
                if brace_count == 0 and j > i:
                    content_builders.append((method_name, i, j + 1))
                    break
            break

# Sort by line number (reversed for removal)
content_builders.sort(key=lambda x: x[1], reverse=True)

print(f'Found {len(content_builders)} methods to extract\n')

# Create the content builders part file
part_content = ["part of 'reports_screen.dart';\n\n"]
part_content.append("// Content builder methods and helpers extracted from _ReportsScreenState\n")
part_content.append("extension ReportsScreenContentBuilders on _ReportsScreenState {\n")

for method_name, start, end in reversed(content_builders):
    part_content.append('\n')
    part_content.extend(lines[start:end])
    print(f'{method_name}: lines {start+1}-{end}')

part_content.append('}\n')

# Write part file
with open('lib/screens/reports_screen_content.dart', 'w', encoding='utf-8') as f:
    f.writelines(part_content)

# Remove methods from main file
main_lines = lines[:]
for method_name, start, end in content_builders:
    del main_lines[start:end]

# Add part directive after imports
for i, line in enumerate(main_lines):
    if line.startswith('import ') or line.startswith('part '):
        continue
    elif i > 0 and (main_lines[i-1].startswith('import ') or main_lines[i-1].startswith('part ')):
        main_lines.insert(i, "part 'reports_screen_content.dart';\n")
        break

# Write updated main file
with open('lib/screens/reports_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(main_lines)

total_extracted = sum(end - start for _, start, end in content_builders)
print(f'\n✓ Extracted {len(content_builders)} methods ({total_extracted} lines)')
print(f'✓ Created lib/screens/reports_screen_content.dart ({len(part_content)} lines)')
print(f'✓ Updated reports_screen.dart: {len(lines)} → {len(main_lines)} lines')
print(f'  Reduction: {len(lines) - len(main_lines)} lines')
print(f'  Status: {"✓ COMPLIANT" if len(main_lines) < 1000 else f"Needs -{len(main_lines) - 1000} more"}')
