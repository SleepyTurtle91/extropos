#!/usr/bin/env python3
"""Integrate reports_screen_content.dart part file into reports_screen.dart"""

import re

# Read main file
with open('lib/screens/reports_screen.dart', 'r', encoding='utf-8') as f:
    main_lines = f.readlines()

# Read part file to see what methods are there
with open('lib/screens/reports_screen_content.dart', 'r', encoding='utf-8') as f:
    part_content = f.read()

print(f'Current main file: {len(main_lines)} lines')

# Check if part directive already exists
has_part = any('part \'reports_screen_content.dart\'' in line for line in main_lines)
print(f'Has part directive: {has_part}')

if not has_part:
    # Find last import line
    last_import_idx = 0
    for i, line in enumerate(main_lines):
        if line.startswith('import '):
            last_import_idx = i
    
    # Add part directive after imports
    print(f'Adding part directive after line {last_import_idx + 1}')
    main_lines.insert(last_import_idx + 1, '\n')
    main_lines.insert(last_import_idx + 2, "part 'reports_screen_content.dart';\n")
    
    with open('lib/screens/reports_screen.dart', 'w', encoding='utf-8') as f:
        f.writelines(main_lines)
    
    print(f'✓ Added part directive')
    print(f'New line count: {len(main_lines)}')
else:
    print('Part directive already exists')

# Now check how many methods are in the part file
methods_in_part = re.findall(r'(Widget|String|Future<void>|void)\s+(_\w+)\s*\(', part_content)
print(f'\nMethods in part file: {len(methods_in_part)}')
for method_type, method_name in methods_in_part[:10]:
    print(f'  {method_type} {method_name}()')

print('\nNext step: Remove these methods from main file if they exist there')
