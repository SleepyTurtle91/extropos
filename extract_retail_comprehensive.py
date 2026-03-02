import re

def count_braces(text):
    """Count unmatched opening braces"""
    return text.count('{') - text.count('}')

def find_method_end(lines, start_line):
    """Find the end line of a method by counting braces"""
    brace_count = 0
    started = False
    
    for i in range(start_line - 1, len(lines)):
        line = lines[i]
        
        # Count braces
        opens = line.count('{')
        closes = line.count('}')
        brace_count += opens - closes
        
        if opens > 0:
            started = True
        
        # Method ends when braces balance and we've started
        if started and brace_count == 0:
            return i + 1  # 1-based line number
    
    return len(lines)

# Read original file
with open('lib/screens/retail_pos_screen_modern.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print('=' * 80)
print('RETAIL POS SCREEN - COMPREHENSIVE EXTRACTION')
print('='  * 80)
print(f'Original file: {len(lines)} lines')
print()

# Find all methods
all_methods = []
for i, line in enumerate(lines, 1):
    stripped = line.strip()
    # Match method signatures
    match = re.match(r'^(Widget|Future<void>|void|Future<bool>|Future<Customer\?>)\s+(_\w+)', stripped)
    if match:
        all_methods.append({
            'line': i,
            'return_type': match.group(1),
            'name': match.group(2)
        })

# Calculate exact boundaries using brace counting
for method in all_methods:
    method['end_line'] = find_method_end(lines, method['line'])
    method['size'] = method['end_line'] - method['line'] + 1

print(f'Found {len(all_methods)} methods')
print()

# Categorize methods
widget_methods = [m for m in all_methods if m['return_type'] == 'Widget']
show_methods = [m for m in all_methods if m['name'].startswith('_show')]
operation_methods = [m for m in all_methods if m not in widget_methods and m not in show_methods]

print(f'Widget builders (_build*): {len(widget_methods)} methods ({sum(m["size"] for m in widget_methods)} lines)')
print(f'Dialogs (_show*): {len(show_methods)} methods ({sum(m["size"] for m in show_methods)} lines)')
print(f'Operations (other): {len(operation_methods)} methods ({sum(m["size"] for m in operation_methods)} lines)')
print()

# EXTRACTION PLAN
print('EXTRACTION PLAN:')
print('  Phase 1: Extract all Widget _build* methods')
print('  Phase 2: Extract remaining large operations')
print()

# === PHASE 1: Extract Widget Builders ===
print('PHASE 1: Extracting Widget Builders')
print('-' * 80)

widget_methods.sort(key=lambda m: m['line'])

# Create part file content
part_widgets = []
part_widgets.append("// Part of retail_pos_screen_modern.dart\n")
part_widgets.append("// Widget Builders Extension\n")
part_widgets.append("\n")
part_widgets.append("part of 'retail_pos_screen_modern.dart';\n")
part_widgets.append("\n")
part_widgets.append("extension RetailPOSWidgets on _RetailPOSScreenModernState {\n")

for method in widget_methods:
    start_idx = method['line'] - 1
    end_idx = method['end_line']
    method_lines = lines[start_idx:end_idx]
    part_widgets.extend(method_lines)
    part_widgets.append('\n')
    print(f'  {method["name"]}: {method["size"]} lines')

part_widgets.append("}\n")

# Save widgets part file
with open('lib/screens/retail_pos_screen_modern_widgets.dart', 'w', encoding='utf-8') as f:
    f.writelines(part_widgets)

print(f'\n✓ Created retail_pos_screen_modern_widgets.dart ({len(part_widgets)} lines)')
print()

# === Remove extracted methods from main file ===
new_lines = lines.copy()

# Remove in reverse order to maintain line numbers
for method in reversed(widget_methods):
    start_idx = method['line'] - 1
    end_idx = method['end_line']
    del new_lines[start_idx:end_idx]

# Add part directive after imports
last_import = 0
for i, line in enumerate(new_lines):
    if line.strip().startswith('import '):
        last_import = i

new_lines.insert(last_import + 1, "\npart 'retail_pos_screen_modern_widgets.dart';\n")

# Save updated main file
with open('lib/screens/retail_pos_screen_modern.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print(f'✓ Updated main file: {len(lines)} → {len(new_lines)} lines')
print(f'  Reduction: {len(lines) - len(new_lines)} lines')
print()

# Final status
print('=' * 80)
print('EXTRACTION COMPLETE')
print(f'  Main file: {len(new_lines)} lines - {"✓ COMPLIANT" if len(new_lines) < 1000 else "⚠️ Needs more work"}')
print(f'  Widgets part: {len(part_widgets)} lines')
print('=' * 80)
