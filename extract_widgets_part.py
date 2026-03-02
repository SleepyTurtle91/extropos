#!/usr/bin/env python3
"""Split printers_management_screen.dart using part/part of pattern."""

with open('lib/screens/printers_management_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Widget methods to extract (line numbers from previous analysis)
widget_methods = [
    ('_buildPrinterCard', 1140, 1356),
    ('_buildHeader', 1530, 1646),
    ('_buildLeftPanel', 1648, 1890),
    ('_buildRoleDot', 1892, 1899),
    ('_buildRightPanel', 1901, 2370),
    ('_buildToggleBtn', 2392, 2393),
    ('_buildTypeSelectBtn', 2431, 2432),
    ('_buildJobToggle', 2477, 2592),
    ('_buildKitchenCategories', 2594, 2690),
]

# Find actual method boundaries with brace counting
actual_methods = []
for method_name, approx_start, approx_end in widget_methods:
    for i, line in enumerate(lines):
        if f'Widget {method_name}(' in line and i >= approx_start - 5 and i <= approx_start + 5:
            start = i
            brace_count = 0
            for j in range(i, len(lines)):
                brace_count += lines[j].count('{') - lines[j].count('}')
                if brace_count == 0 and j > i:
                    end = j + 1
                    actual_methods.append((method_name, start, end))
                    print(f'{method_name}: lines {start+1}-{end} ({end-start} lines)')
                    break
            break

# Sort by line number (reversed for extraction from bottom up)
actual_methods.sort(key=lambda x: x[1], reverse=True)

# Extract widget methods
widgets_part_content = ["part of 'printers_management_screen.dart';\n\n"]
widgets_part_content.append("// Widget builder methods extracted from _PrintersManagementScreenState\n")
widgets_part_content.append("extension PrintersManagementWidgets on _PrintersManagementScreenState {\n")

# Collect all widget method code
for method_name, start, end in reversed(actual_methods):
    widgets_part_content.append('\n')
    widgets_part_content.extend(lines[start:end])

widgets_part_content.append('}\n')

# Write widgets part file
with open('lib/screens/printers_management_screen_widgets.dart', 'w', encoding='utf-8') as f:
    f.writelines(widgets_part_content)

# Remove widget methods from main file (from bottom to top to maintain indices)
main_lines = lines[:]
for method_name, start, end in actual_methods:
    del main_lines[start:end]

# Add part directive after imports
import_end = 0
for i, line in enumerate(main_lines):
    if line.startswith('import '):
        import_end = i + 1
    elif import_end > 0 and not line.startswith('import ') and not line.strip() == '':
        break

main_lines.insert(import_end, "\npart 'printers_management_screen_widgets.dart';\n")

# Write updated main file
with open('lib/screens/printers_management_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(main_lines)

print(f'\n✓ Extracted {len(actual_methods)} widget methods')
print(f'✓ Created lib/screens/printers_management_screen_widgets.dart ({len(widgets_part_content)} lines)')
print(f'✓ Updated printers_management_screen.dart')
print(f'  Original: {len(lines)} lines')
print(f'  New: {len(main_lines)} lines')
print(f'  Reduction: {len(lines) - len(main_lines)} lines')
