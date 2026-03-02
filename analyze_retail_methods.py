import re

# Read file
with open('lib/screens/retail_pos_screen_modern.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print('RETAIL POS METHOD SIZE ANALYSIS')
print('=' * 80)
print(f'Total file lines: {len(lines)}')
print()

# Find all methods with line ranges
methods = []
for i, line in enumerate(lines, 1):
    stripped = line.strip()
    if re.match(r'^(Widget|Future<void>|void|Future<bool>|Future<Customer\?>) _\w+', stripped):
        # Extract method name
        match = re.match(r'^(Widget|Future<void>|void|Future<bool>|Future<Customer\?>)\s+(_\w+)', stripped)
        if match:
            methods.append({
                'line': i,
                'return_type': match.group(1),
                'name': match.group(2),
                'full': stripped[:100]
            })

# Calculate sizes by finding the next method or end of class
for idx, method in enumerate(methods):
    start_line = method['line']
    if idx + 1 < len(methods):
        end_line = methods[idx + 1]['line'] - 1
    else:
        # Find end of class (closing brace at column 0)
        end_line = len(lines)
        for i in range(start_line, len(lines)):
            if re.match(r'^\}', lines[i]):
                end_line = i
                break
    
    method['end_line'] = end_line
    method['size'] = end_line - start_line + 1

# Sort by size
methods_by_size = sorted(methods, key=lambda m: m['size'], reverse=True)

print(f'Found {len(methods)} methods\n')

# Group by type and size
widgets = [m for m in methods if m['return_type'] == 'Widget']
futures = [m for m in methods if 'Future' in m['return_type']]
voids = [m for m in methods if m['return_type'] == 'void']

print('TOP 20 LARGEST METHODS:')
print('-' * 80)
for i, method in enumerate(methods_by_size[:20], 1):
    print(f"{i:2d}. {method['name']:40s} {method['size']:4d} lines  [Line {method['line']:4d}-{method['end_line']:4d}] ({method['return_type']})")

print()
print('METHOD CATEGORIES:')
print(f'  Widget builders: {len(widgets)} methods ({sum(m["size"] for m in widgets)} lines)')
print(f'  Future operations: {len(futures)} methods ({sum(m["size"] for m in futures)} lines)')
print(f'  Void operations: {len(voids)} methods ({sum(m["size"] for m in voids)} lines)')
print()

# Find state vars (before first method)
first_method_line = methods[0]['line'] if methods else len(lines)
state_vars_size = first_method_line - 42  # Approximate, subtract class header
print(f'State variables section: ~{state_vars_size} lines')
print()

# Recommendations
print('EXTRACTION STRATEGY:')
print('=' * 80)
print('Based on proven part/part of pattern from previous refactorings:\n')

# Group methods logically
dialogs = [m for m in methods if 'show' in m['name'].lower() and 'Dialog' in m['name']]
builders = [m for m in methods if 'build' in m['name'].lower()]
payment = [m for m in methods if 'payment' in m['name'].lower() or 'card' in m['name'].lower() or 'cash' in m['name'].lower()]
product = [m for m in methods if 'product' in m['name'].lower() or 'category' in m['name'].lower()]

print(f'1. Dialog methods ({len(dialogs)}): {sum(m["size"] for m in dialogs)} lines')
for m in dialogs[:5]:
    print(f'   - {m["name"]} ({m["size"]} lines)')

print(f'\n2. Widget builders ({len(builders)}): {sum(m["size"] for m in builders)} lines')
for m in sorted(builders, key=lambda x: x['size'], reverse=True)[:8]:
    print(f'   - {m["name"]} ({m["size"]} lines)')

print(f'\n3. Payment operations ({len(payment)}): {sum(m["size"] for m in payment)} lines')
for m in payment[:5]:
    print(f'   - {m["name"]} ({m["size"]} lines)')

print(f'\n4. Product/category methods ({len(product)}): {sum(m["size"] for m in product)} lines')
for m in product[:5]:
    print(f'   - {m["name"]} ({m["size"]} lines)')

print('\n' + '=' * 80)
print('RECOMMENDED PART FILES:')
print('  1. retail_pos_screen_modern_widgets.dart - All _build* methods')
print('  2. retail_pos_screen_modern_dialogs.dart - All _show* dialog methods')
print('  3. retail_pos_screen_modern_operations.dart - Payment, cart, data operations')
print()
total_extractable = sum(m['size'] for m in dialogs + builders + payment)
print(f'Estimated extractable: ~{total_extractable} lines')
print(f'Estimated main file after: ~{len(lines) - total_extractable} lines')
