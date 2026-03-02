#!/usr/bin/env python3
"""Extract remaining small widgets from retail_pos"""

import re

with open('lib/screens/retail_pos_screen_modern.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f'Current size: {len(lines)} lines')

# Find remaining Widget methods
def find_method_end(lines, start_idx):
    brace_count = 0
    in_method = False
    for i in range(start_idx, len(lines)):
        for char in lines[i]:
            if char == '{':
                brace_count += 1
                in_method = True
            elif char == '}':
                brace_count -= 1
                if in_method and brace_count == 0:
                    return i
    return len(lines) - 1

widget_methods = []
for i, line in enumerate(lines):
    if '  Widget _' in line and '(' in line:
        match = re.search(r'Widget\s+(_\w+)\s*\(', line)
        if match:
            method_name = match.group(1)
            if method_name != '_buildNumberPad':  # Skip the giant one
                end_idx = find_method_end(lines, i)
                size = end_idx - i + 1
                widget_methods.append({
                    'name': method_name,
                    'start': i,
                    'end': end_idx,
                    'size': size
                })

print(f'\nFound {len(widget_methods)} small Widget methods:')
total = sum(m['size'] for m in widget_methods)
for m in sorted(widget_methods, key=lambda x: x['size'], reverse=True)[:10]:
    print(f'  {m["name"]:40} {m["size"]:3} lines')

print(f'\nTotal extractable: {total} lines')

if total > 180:
    # Create small widgets part
    content = []
    content.append('// Part of retail_pos_screen_modern.dart\n')
    content.append('// Small widget builders\n')
    content.append('\n')
    content.append("part of 'retail_pos_screen_modern.dart';\n")
    content.append('\n')
    content.append('extension RetailPOSSmallWidgets on _RetailPOSScreenModernState {\n')
    
    for method in sorted(widget_methods, key=lambda m: m['start']):
        for i in range(method['start'], method['end'] + 1):
            content.append(lines[i])
        content.append('\n')
    
    content.append('}\n')
    
    with open('lib/screens/retail_pos_screen_modern_small_widgets.dart', 'w', encoding='utf-8') as f:
        f.writelines(content)
    
    print(f'✓ Created small widgets part: {len(widget_methods)} methods, {total} lines')
    
    # Update main file
    with open('lib/screens/retail_pos_screen_modern.dart', 'r', encoding='utf-8') as f:
        main_lines = f.readlines()
    
    # Add part directive
    for i, line in enumerate(main_lines):
        if "part 'retail_pos_screen_modern_medium_widgets.dart'" in line:
            main_lines.insert(i + 1, "part 'retail_pos_screen_modern_small_widgets.dart';\n")
            break
    
    # Remove extracted methods (reverse order)
    for method in sorted(widget_methods, key=lambda m: m['start'], reverse=True):
        del main_lines[method['start']:method['end'] + 1]
    
    with open('lib/screens/retail_pos_screen_modern.dart', 'w', encoding='utf-8') as f:
        f.writelines(main_lines)
    
    print(f'✓ Updated main file: {len(lines)} → {len(main_lines)} lines')
    print(f'  Reduction: {len(lines) - len(main_lines)} lines')
    
    if len(main_lines) < 1000:
        print(f'\n✓✓✓ SUCCESS: {len(main_lines)} lines (<1000) ✓ COMPLIANT')
    else:
        print(f'\nNote: {len(main_lines)} lines (need {len(main_lines) - 1000} more)')
else:
    print('Not enough small widgets to extract')
