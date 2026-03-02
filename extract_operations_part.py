#!/usr/bin/env python3
"""Extract operation methods into another part file."""

with open('lib/screens/printers_management_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Operation methods to extract
operation_methods = [
    '_discoverPrintersAsync',
    '_searchBluetoothPrinters',
    '_searchUsbPrinters',
    '_sampleReceiptPrint',
    '_debugForcePrint',
]

# Find actual method boundaries
actual_methods = []
for method_name in operation_methods:
    for i, line in enumerate(lines):
        if f'Future<void> {method_name}(' in line:
            start = i
            brace_count = 0
            for j in range(i, len(lines)):
                brace_count += lines[j].count('{') - lines[j].count('}')
                if brace_count == 0 and j > i:
                    end = j + 1
                    actual_methods.append((method_name, start, end))
                    print(f'{method_name}: lines {start+1}-{end} ({end-start} lines)')
                    break
            break

# Sort by line number (reversed for extraction from bottom up)
actual_methods.sort(key=lambda x: x[1], reverse=True)

# Extract operation methods
operations_part_content = ["part of 'printers_management_screen.dart';\n\n"]
operations_part_content.append("// Printer operation methods extracted from _PrintersManagementScreenState\n")
operations_part_content.append("extension PrintersManagementOperations on _PrintersManagementScreenState {\n")

# Collect all operation method code
for method_name, start, end in reversed(actual_methods):
    operations_part_content.append('\n')
    operations_part_content.extend(lines[start:end])

operations_part_content.append('}\n')

# Write operations part file
with open('lib/screens/printers_management_screen_operations.dart', 'w', encoding='utf-8') as f:
    f.writelines(operations_part_content)

# Remove operation methods from main file (from bottom to top)
main_lines = lines[:]
for method_name, start, end in actual_methods:
    del main_lines[start:end]

# Add part directive after the widgets part directive
for i, line in enumerate(main_lines):
    if "part 'printers_management_screen_widgets.dart';" in line:
        main_lines.insert(i + 1, "part 'printers_management_screen_operations.dart';\n")
        break

# Write updated main file
with open('lib/screens/printers_management_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(main_lines)

print(f'\n✓ Extracted {len(actual_methods)} operation methods')
print(f'✓ Created lib/screens/printers_management_screen_operations.dart ({len(operations_part_content)} lines)')
print(f'✓ Updated printers_management_screen.dart')
print(f'  Before: {len(lines)} lines')
print(f'  After: {len(main_lines)} lines')
print(f'  Reduction: {len(lines) - len(main_lines)} lines')
