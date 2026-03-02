#!/usr/bin/env python3
"""Properly remove widget methods from main file (they're already in the part file)."""

with open('lib/screens/printers_management_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f'Starting with {len(lines)} lines')

# Widget methods to remove (they're already in the part file)
widget_methods = [
    '_buildPrinterCard',
    '_buildHeader',
    '_buildLeftPanel',
    '_buildRoleDot',
    '_buildRightPanel',
    '_buildToggleBtn',
    '_buildTypeSelectBtn',
    '_buildJobToggle',
    '_buildKitchenCategories',
]

# Find actual method boundaries
methods_to_remove = []
for method_name in widget_methods:
    for i, line in enumerate(lines):
        if f'Widget {method_name}(' in line:
            start = i
            brace_count = 0
            for j in range(i, len(lines)):
                brace_count += lines[j].count('{') - lines[j].count('}')
                if brace_count == 0 and j > i:
                    end = j + 1
                    methods_to_remove.append((method_name, start, end))
                    print(f'Will remove {method_name}: lines {start+1}-{end} ({end-start} lines)')
                    break
            break

# Sort by line number (reversed for removal from bottom up)
methods_to_remove.sort(key=lambda x: x[1], reverse=True)

# Remove widget methods from main file
main_lines = lines[:]
for method_name, start, end in methods_to_remove:
    del main_lines[start:end]

# Write updated main file
with open('lib/screens/printers_management_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(main_lines)

total_removed = sum(end - start for _, start, end in methods_to_remove)
print(f'\n✓ Removed {len(methods_to_remove)} widget methods ({total_removed} lines)')
print(f'✓ Updated printers_management_screen.dart')
print(f'  Before: {len(lines)} lines')
print(f'  After: {len(main_lines)} lines')
print(f'  Reduction: {len(lines) - len(main_lines)} lines')
