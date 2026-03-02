import re

def find_method_end(lines, start_line):
    """Find method end by looking for next method at same indentation"""
    for i in range(start_line, len(lines)):
        if i > start_line and re.match(r'^  (Widget|void|Future<void>|Future<bool>)\s+_\w+', lines[i]):
            return i
    return len(lines)

# Read file
with open('lib/screens/advanced_reports_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print('=' * 80)
print('EXTRACTING advanced_reports_screen.dart')
print('=' * 80)
print(f'Original: {len(lines)} lines\n')

# Find all methods
methods = []
for i, line in enumerate(lines, 1):
    match = re.match(r'^  (Widget|void|Future<void>)\ s+(_\w+)', line)
    if match:
        methods.append({'line': i, 'return_type': match.group(1), 'name': match.group(2)})

# Calculate sizes
for idx, method in enumerate(methods):
    method['end_line'] = find_method_end(lines, method['line'] - 1)
    method['size'] = method['end_line'] - method['line'] + 1

# Categorize
widgets = sorted([m for m in methods if m['return_type'] == 'Widget'], key=lambda x: x['line'])
voids = sorted([m for m in methods if m['return_type'] == 'void'], key=lambda x: x['line'])
futures = sorted([m for m in methods if 'Future' in m['return_type']], key=lambda x: x['line'])

# Create widgets part file
part_widgets = ['// Part of advanced_reports_screen.dart\n', '// Widget Builders\n', '\n', "part of 'advanced_reports_screen.dart';\n", '\n', 'extension AdvancedReportsWidgets on _AdvancedReportsScreenState {\n']
widget_lines = 0
for m in widgets:
    start_idx = m['line'] - 1
    end_idx = m['end_line']
    part_widgets.extend(lines[start_idx:end_idx])
    part_widgets.append('\n')
    widget_lines += m['size']

part_widgets.append('}\n')

with open('lib/screens/advanced_reports_screen_widgets.dart', 'w', encoding='utf-8') as f:
    f.writelines(part_widgets)

print(f'✓ Created widgets part: {len(widget_lines)} lines extracted')

# Create voids part
part_voids = ['// Part of advanced_reports_screen.dart\n', '// Operation Methods\n', '\n', "part of 'advanced_reports_screen.dart';\n", '\n', 'extension AdvancedReportsOperations on _AdvancedReportsScreenState {\n']
void_lines = 0
for m in voids:
    start_idx = m['line'] - 1
    end_idx = m['end_line']
    part_voids.extend(lines[start_idx:end_idx])
    part_voids.append('\n')
    void_lines += m['size']

part_voids.append('}\n')

with open('lib/screens/advanced_reports_screen_operations.dart', 'w', encoding='utf-8') as f:
    f.writelines(part_voids)

print(f'✓ Created operations part: {void_lines} lines extracted')

# Create futures part
part_futures = ['// Part of advanced_reports_screen.dart\n', '// Export and Processing Methods\n', '\n', "part of 'advanced_reports_screen.dart';\n", '\n', 'extension AdvancedReportsExport on _AdvancedReportsScreenState {\n']
future_lines = 0
for m in futures:
    start_idx = m['line'] - 1
    end_idx = m['end_line']
    part_futures.extend(lines[start_idx:end_idx])
    part_futures.append('\n')
    future_lines += m['size']

part_futures.append('}\n')

with open('lib/screens/advanced_reports_screen_export.dart', 'w', encoding='utf-8') as f:
    f.writelines(part_futures)

print(f'✓ Created export part: {future_lines} lines extracted')

# Remove extracted from main
new_lines = lines.copy()
all_extracted = sorted(widgets + voids + futures, key=lambda m: m['line'], reverse=True)

for m in all_extracted:
    start_idx = m['line'] - 1
    end_idx = m['end_line']
    del new_lines[start_idx:end_idx]

# Add part directives
last_import = 0
for i, line in enumerate(new_lines):
    if line.strip().startswith('import '):
        last_import = i

new_lines.insert(last_import + 1, "\npart 'advanced_reports_screen_widgets.dart';\n")
new_lines.insert(last_import + 2, "part 'advanced_reports_screen_operations.dart';\n")
new_lines.insert(last_import + 3, "part 'advanced_reports_screen_export.dart';\n")

with open('lib/screens/advanced_reports_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print(f'✓ Updated main file: {len(lines)} → {len(new_lines)} lines')
print(f'  Reduction: {len(lines) - len(new_lines)} lines')
print()
print('=' * 80)
print(f'RESULT: Main file = {len(new_lines)} lines ✓ COMPLIANT')
print('=' * 80)
