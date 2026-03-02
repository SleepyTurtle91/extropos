#!/usr/bin/env python3
import re

with open('lib/screens/printers_management_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()
    lines = content.split('\n')

# Methods to extract (in order of appearance)
methods_to_extract = [
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

# Find exact line ranges for each method
method_ranges = {}
for method_name in methods_to_extract:
    for i, line in enumerate(lines):
        if f'Widget {method_name}(' in line:
            # Find closing brace
            brace_count = 0
            for j in range(i, len(lines)):
                brace_count += lines[j].count('{') - lines[j].count('}')
                if brace_count == 0 and j > i:
                    method_ranges[method_name] = (i, j)
                    print(f'{method_name}: lines {i+1} to {j+1} ({j - i} lines)')
                    break
            break

print(f'\nFound {len(method_ranges)} methods')
print(f'Total lines to extract: {sum(end - start for start, end in method_ranges.values())}')
