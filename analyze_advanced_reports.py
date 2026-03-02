import re

with open('lib/screens/advanced_reports_screen.dart', 'r') as f:
    lines = f.readlines()

print('=' * 80)
print('ADVANCED_REPORTS_SCREEN.DART ANALYSIS')
print('=' * 80)
print(f'Total lines: {len(lines)}')
print()

# Find all methods
methods = []
for i, line in enumerate(lines, 1):
    match = re.match(r'^  (Widget|void|Future<void>)\s+(_\w+)', line)
    if match:
        methods.append({'line': i, 'return_type': match.group(1), 'name': match.group(2)})

# Calculate sizes
for idx, method in enumerate(methods):
    if idx + 1 < len(methods):
        method['end_line'] = methods[idx + 1]['line'] - 1
    else:
        method['end_line'] = len(lines)
    method['size'] = method['end_line'] - method['line'] + 1

# Categorize
widgets = [m for m in methods if m['return_type'] == 'Widget']
futures = [m for m in methods if 'Future' in m['return_type']]
voids = [m for m in methods if m['return_type'] == 'void']

print(f'Found {len(methods)} methods')
print(f'  Widget: {len(widgets)} total, {sum(m["size"] for m in widgets)} lines')
print(f'  Future: {len(futures)} total, {sum(m["size"] for m in futures)} lines')
print(f'  Void: {len(voids)} total, {sum(m["size"] for m in voids)} lines')
print()

methods_by_size = sorted(methods, key=lambda m: m['size'], reverse=True)

print('TOP 20 LARGEST METHODS:')
print('-' * 80)
for i, m in enumerate(methods_by_size[:20], 1):
    print(f'{i:2d}. {m["name"]:45s} {m["size"]:4d} lines')

# Extractables
large = [m for m in methods if m['size'] > 50]
extractable = sum(m['size'] for m in large)
remaining = len(lines) - extractable

print()
print(f'Methods > 50 lines: {len(large)} methods, {extractable} lines total')
print(f'Estimated main file after extraction: {remaining} lines')
print(f'Status: {"✓ ACHIEVABLE (<1000)" if remaining < 1000 else "Need more extraction"}')

# Breakdown by type
widget_large = [m for m in widgets if m['size'] > 50]
void_large = [m for m in voids if m['size'] > 50]
future_large = [m for m in futures if m['size'] > 50]

print()
print('EXTRACTION OPPORTUNITIES:')
print(f'  Widget builders: {len(widget_large)} methods, {sum(m["size"] for m in widget_large)} lines')
print(f'  Void operations: {len(void_large)} methods, {sum(m["size"] for m in void_large)} lines')
print(f'  Future operations: {len(future_large)} methods, {sum(m["size"] for m in future_large)} lines')
