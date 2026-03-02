#!/usr/bin/env python3
"""Extract printer operation methods into a service file."""

# Read the file
with open('lib/screens/printers_management_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Methods to extract to printer operations service
operation_methods = [
    ('_discoverPrintersAsync', 219),
    ('_searchBluetoothPrinters', 340),
    ('_searchUsbPrinters', 411),
    ('_sampleReceiptPrint', 626),
    ('_debugForcePrint', 921),
]

# Find exact boundaries
extracted = []
for method_name, start_line in operation_methods:
    start = start_line - 1
    brace_count = 0
    for j in range(start, len(lines)):
        brace_count += lines[j].count('{') - lines[j].count('}')
        if brace_count == 0 and j > start:
            end = j + 1
            size = end - start
            extracted.append((method_name, start, end, size))
            print(f'{method_name:30s}: lines {start_line}-{end} ({size} lines)')
            break

total_lines = sum(size for _, _, _, size in extracted)
print(f'\nTotal operation methods: {len(extracted)}')
print(f'Total lines to extract: {total_lines}')
print(f'Estimated reduction: 2693 → {2693 - total_lines} lines')
