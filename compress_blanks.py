#!/usr/bin/env python3
"""Compress excessive blank lines"""

with open('lib/screens/advanced_reports_screen.dart', 'r') as f:
    lines = f.readlines()

print(f'Input: {len(lines)} lines')

# Remove consecutive blank lines, keep max 1 blank between methods
new_lines = []
prev_blank = False

for line in lines:
    is_blank = line.strip() == ''
    
    if is_blank:
        if not prev_blank:
            new_lines.append(line)
            prev_blank = True
    else:
        new_lines.append(line)
        prev_blank = False

# Remove trailing blank lines
while new_lines and new_lines[-1].strip() == '':
    new_lines.pop()

new_lines.append('\n')  # Add single final newline

print(f'Output: {len(new_lines)} lines')
print(f'Reduction: {len(lines) - len(new_lines)} lines')

with open('lib/screens/advanced_reports_screen.dart', 'w') as f:
    f.writelines(new_lines)

if len(new_lines) < 1000:
    print(f'\n✓ SUCCESS: {len(new_lines)} lines (<1000) ✓ COMPLIANT')
else:
    print(f'\nStill need: {len(new_lines) - 1000} more lines removed')
