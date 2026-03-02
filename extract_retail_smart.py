import re

def find_method_end_simple(lines, start_line, method_name):
    """Find method end by looking for the next method at same indentation"""
    for i in range(start_line, len(lines)):
        line = lines[i]
        # Look for next method signature at column 2 (same indentation)
        if i > start_line and re.match(r'^  (Widget|void|Future<void>|Future<bool>)\s+_\w+', line):
            return i  # Return 1-based line number (next method line -1)
    return len(lines)

# Read file
with open('lib/screens/retail_pos_screen_modern.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print('SMART EXTRACTION - Skip problematic methods')
print('=' * 80)
print(f'Original: {len(lines)} lines\n')

# Find all methods
methods = []
for i, line in enumerate(lines, 1):
    # Don't strip - match with leading spaces
    match = re.match(r'^  (Widget|void|Future<void>)\s+(_\w+)', line)
    if match:
        methods.append({
            'line': i,
            'return_type': match.group(1),
            'name': match.group(2)
        })

# Calculate sizes using simple boundary detection
for idx, method in enumerate(methods):
    if idx + 1 < len(methods):
        method['end_line'] = methods[idx + 1]['line'] - 1
    else:
        method['end_line'] = len(lines) - 1  # Exclude final closing brace
    method['size'] = method['end_line'] - method['line'] + 1

# Categorize
widget_methods = [m for m in methods if m['return_type'] == 'Widget' and '_buildNumber' not in m['name']]
show_methods = [m for m in methods if '_show' in m['name']]
other_methods = [m for m in methods if m not in widget_methods and m not in show_methods]

print(f'Widget builders (exc. _buildNumber*): {len(widget_methods)} methods')
print(f'Dialog methods (_show*): {len(show_methods)} methods')
print(f'Other methods: {len(other_methods)} methods\n')

# Extract widgets (excluding number pad related)
print('PHASE 1: Extract Widget Builders')
print('-' * 80)

part_widgets = []
part_widgets.append("// Part of retail_pos_screen_modern.dart\n")
part_widgets.append("// Widget Builders Extension\n")
part_widgets.append("\n")
part_widgets.append("part of 'retail_pos_screen_modern.dart';\n")
part_widgets.append("\n")
part_widgets.append("extension RetailPOSWidgets on _RetailPOSScreenModernState {\n")

for m in widget_methods:
    start_idx = m['line'] - 1
    end_idx = m['end_line']
    part_widgets.extend(lines[start_idx:end_idx])
    part_widgets.append('\n')
    print(f'  {m["name"]}: {m["size"]} lines')

part_widgets.append("}\n")

with open('lib/screens/retail_pos_screen_modern_widgets.dart', 'w', encoding='utf-8') as f:
    f.writelines(part_widgets)

print(f'\n✓ Created widgets part: {len(part_widgets)} lines\n')

# Extract dialogs
print('PHASE 2: Extract Dialog Methods')
print('-' * 80)

part_dialogs = []
part_dialogs.append("// Part of retail_pos_screen_modern.dart\n")
part_dialogs.append("// Dialog Methods Extension\n")
part_dialogs.append("\n")
part_dialogs.append("part of 'retail_pos_screen_modern.dart';\n")
part_dialogs.append("\n")
part_dialogs.append("extension RetailPOSDialogs on _RetailPOSScreenModernState {\n")

for m in show_methods:
    start_idx = m['line'] - 1
    end_idx = m['end_line']
    part_dialogs.extend(lines[start_idx:end_idx])
    part_dialogs.append('\n')
    print(f'  {m["name"]}: {m["size"]} lines')

part_dialogs.append("}\n")

with open('lib/screens/retail_pos_screen_modern_dialogs.dart', 'w', encoding='utf-8') as f:
    f.writelines(part_dialogs)

print(f'\n✓ Created dialogs part: {len(part_dialogs)} lines\n')

#Remove extracted methods
new_lines = lines.copy()
all_extracted = widget_methods + show_methods
all_extracted.sort(key=lambda m: m['line'], reverse=True)

for m in all_extracted:
    start_idx = m['line'] - 1
    end_idx = m['end_line']
    del new_lines[start_idx:end_idx]

# Add part directives
last_import = 0
for i, line in enumerate(new_lines):
    if line.strip().startswith('import '):
        last_import = i

new_lines.insert(last_import + 1, "\npart 'retail_pos_screen_modern_widgets.dart';\n")
new_lines.insert(last_import + 2, "part 'retail_pos_screen_modern_dialogs.dart';\n")

with open('lib/screens/retail_pos_screen_modern.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print(f'✓ Updated main file: {len(lines)} → {len(new_lines)} lines')
print(f'  Reduction: {len(lines) - len(new_lines)} lines\n')

print('=' * 80)
print(f'RESULT: Main file = {len(new_lines)} lines - {"✓ COMPLIANT" if len(new_lines) < 1000 else "⚠️ Still over"}')
print('=' * 80)
