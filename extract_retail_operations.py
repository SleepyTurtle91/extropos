import re

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

# Read current file
with open('lib/screens/retail_pos_screen_modern.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print('=' * 80)
print('EXTRACTING DIALOG & OPERATION METHODS')
print('=' * 80)
print(f'Current file: {len(lines)} lines')
print()

# Find all _show* methods
show_methods = []
for i, line in enumerate(lines, 1):
    stripped = line.strip()
    match = re.match(r'^(void|Future<void>)\s+(_show\w+)', stripped)
    if match:
        show_methods.append({
            'line': i,
            'return_type': match.group(1),
            'name': match.group(2)
        })

# Calculate boundaries
for method in show_methods:
    method['end_line'] = find_method_end(lines, method['line'])
    method['size'] = method['end_line'] - method['line'] + 1

show_methods.sort(key=lambda m: m['line'])

print(f'Found {len(show_methods)} dialog methods: {sum(m["size"] for m in show_methods)} lines')
for m in show_methods:
    print(f'  {m["name"]}: {m["size"]} lines')
print()

# Find large operation methods to extract
operation_methods = []
for i, line in enumerate(lines, 1):
    stripped = line.strip()
    # Match Future operations (likely large)
    match = re.match(r'^Future<void>\s+(_\w+)', stripped)
    if match and not match.group(1).startswith('_show'):
        operation_methods.append({
            'line': i,
            'return_type': 'Future<void>',
            'name': match.group(1)
        })

# Calculate boundaries for operations
for method in operation_methods:
    method['end_line'] = find_method_end(lines, method['line'])
    method['size'] = method['end_line'] - method['line'] + 1

operation_methods.sort(key=lambda m: m['line'])

# Only extract operations > 50 lines
large_operations = [m for m in operation_methods if m['size'] > 50]

print(f'Found {len(large_operations)} large operations: {sum(m["size"] for m in large_operations)} lines')
for m in large_operations:
    print(f'  {m["name"]}: {m["size"]} lines')
print()

# Combine methods to extract
methods_to_extract = show_methods + large_operations
methods_to_extract.sort(key=lambda m: m['line'])

total_to_extract = sum(m['size'] for m in methods_to_extract)
print(f'Total to extract: {len(methods_to_extract)} methods, {total_to_extract} lines')
print()

# Create part file
part_ops = []
part_ops.append("// Part of retail_pos_screen_modern.dart\n")
part_ops.append("// Dialog and Operation Methods Extension\n")
part_ops.append("\n")
part_ops.append("part of 'retail_pos_screen_modern.dart';\n")
part_ops.append("\n")
part_ops.append("extension RetailPOSOperations on _RetailPOSScreenModernState {\n")

for method in methods_to_extract:
    start_idx = method['line'] - 1
    end_idx = method['end_line']
    method_lines = lines[start_idx:end_idx]
    part_ops.extend(method_lines)
    part_ops.append('\n')

part_ops.append("}\n")

# Save operations part file
with open('lib/screens/retail_pos_screen_modern_operations.dart', 'w', encoding='utf-8') as f:
    f.writelines(part_ops)

print(f'✓ Created retail_pos_screen_modern_operations.dart ({len(part_ops)} lines)')
print()

# Remove extracted methods from main file
new_lines = lines.copy()

for method in reversed(methods_to_extract):
    start_idx = method['line'] - 1
    end_idx = method['end_line']
    del new_lines[start_idx:end_idx]

# Add part directive
for i, line in enumerate(new_lines):
    if "part 'retail_pos_screen_modern_widgets.dart';" in line:
        new_lines.insert(i + 1, "part 'retail_pos_screen_modern_operations.dart';\n")
        break

# Save
with open('lib/screens/retail_pos_screen_modern.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print(f'✓ Updated main file: {len(lines)} → {len(new_lines)} lines')
print(f'  Reduction: {len(lines) - len(new_lines)} lines')
print()

# Status
print('=' * 80)
print('FINAL STATUS')
print(f'  Main file: {len(new_lines)} lines - {"✓ COMPLIANT" if len(new_lines) < 1000 else "⚠️ Still over"}')
print(f'  Widgets part: 2436 lines')
print(f'  Operations part: {len(part_ops)} lines')
print('=' * 80)
