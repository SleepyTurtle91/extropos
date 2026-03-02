import re

with open('lib/screens/retail_pos_screen_modern.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print('EXTRACTING REMAINING LARGE OPERATIONS')
print('=' * 80)
print(f'Current: {len(lines)} lines\n')

# Find all remaining methods
methods = []
for i, line in enumerate(lines, 1):
    match = re.match(r'^  (void|Future<void>)\s+(_\w+)', line)
    if match:
        methods.append({
            'line': i,
            'return_type': match.group(1),
            'name': match.group(2)
        })

# Calculate sizes
for idx, method in enumerate(methods):
    if idx + 1 < len(methods):
        method['end_line'] = methods[idx + 1]['line'] - 1
    else:
        # Find closing brace of class
        for i in range(method['line'], len(lines)):
            if re.match(r'^\}$', lines[i]):
                method['end_line'] = i
                break
    method['size'] = method['end_line'] - method['line'] + 1

# Filter for methods > 40 lines (significant size)
large_ops = [m for m in methods if m['size'] > 40]
large_ops.sort(key=lambda m: m['size'], reverse=True)

print(f'Found {len(large_ops)} large operations (>40 lines):\n')
for m in large_ops:
    print(f'  {m["name"]}: {m["size"]} lines')

total_size = sum(m['size'] for m in large_ops)
print(f'\nTotal extractable: {total_size} lines')
print(f'Estimated result: {len(lines) - total_size} lines\n')

# Extract to operations part
part_ops = []
part_ops.append("// Part of retail_pos_screen_modern.dart\n")
part_ops.append("// Operation Methods Extension\n")
part_ops.append("\n")
part_ops.append("part of 'retail_pos_screen_modern.dart';\n")
part_ops.append("\n")
part_ops.append("extension RetailPOSOperations on _RetailPOSScreenModernState {\n")

for m in large_ops:
    start_idx = m['line'] - 1
    end_idx = m['end_line']
    part_ops.extend(lines[start_idx:end_idx])
    part_ops.append('\n')

part_ops.append("}\n")

with open('lib/screens/retail_pos_screen_modern_operations.dart', 'w', encoding='utf-8') as f:
    f.writelines(part_ops)

print(f'✓ Created operations part: {len(part_ops)} lines\n')

# Remove from main
new_lines = lines.copy()
for m in reversed(large_ops):
    start_idx = m['line'] - 1
    end_idx = m['end_line']
    del new_lines[start_idx:end_idx]

# Add part directive
for i, line in enumerate(new_lines):
    if "part 'retail_pos_screen_modern_dialogs.dart';" in line:
        new_lines.insert(i + 1, "part 'retail_pos_screen_modern_operations.dart';\n")
        break

with open('lib/screens/retail_pos_screen_modern.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print(f'✓ Updated main: {len(lines)} → {len(new_lines)} lines')
print(f'  Reduction: {len(lines) - len(new_lines)} lines\n')

print('=' * 80)
print(f'FINAL: {len(new_lines)} lines - {"✓ COMPLIANT" if len(new_lines)< 1000 else "⚠️ Still over by " + str(len(new_lines) - 1000)}')
print('=' * 80)
