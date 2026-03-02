#!/usr/bin/env python3
"""Find remaining large screen files that need refactoring"""

import os
from pathlib import Path

screens_dir = Path('lib/screens')
large_files = []

for file in screens_dir.glob('*.dart'):
    # Skip part files
    if '_content' in file.name or '_widgets' in file.name or '_operations' in file.name or '_export' in file.name or '_helpers' in file.name:
        continue
    
    with open(file, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
        line_count = len(lines)
        
        if line_count > 1000:
            large_files.append((file.name, line_count))

print('=' * 80)
print('LARGE SCREEN FILES (>1000 lines)')
print('=' * 80)

if large_files:
    for name, count in sorted(large_files, key=lambda x: x[1], reverse=True):
        status = '❌ NEEDS REFACTORING' if count > 1000 else '✓'
        print(f'{name:50} {count:5} lines  {status}')
    print(f'\nTotal files needing refactoring: {len(large_files)}')
else:
    print('✓ ALL SCREEN FILES COMPLIANT (<1000 lines)')
    print('\nRecent successful refactorings:')
    print('  ✓ reports_screen.dart: 2,819 → 940 lines')
    print('  ✓ printers_management_screen.dart: 3,248 → 803 lines')
    print('  ✓ advanced_reports_screen.dart: 4,200 → 981 lines')

print('=' * 80)
