#!/usr/bin/env python3
"""Extract printer operation methods into separate service file."""

with open('lib/screens/printers_management_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Methods to extract (in reverse order to maintain line numbers)
methods = [
    '_debugForcePrint',
    '_sampleReceiptPrint',
    '_searchUsbPrinters',
    '_searchBluetoothPrinters',
    '_discoverPrintersAsync',
]

# Find boundaries for all methods
method_data = []
for method_name in methods:
    for i, line in enumerate(lines):
        if f'Future<void> {method_name}(' in line:
            start = i
            brace_count = 0
            for j in range(i, len(lines)):
                brace_count += lines[j].count('{') - lines[j].count('}')
                if brace_count == 0 and j > i:
                    end = j + 1
                    method_data.append((method_name, start, end, ''.join(lines[start:end])))
                    break
            break

# Sort by start line (descending) to remove from bottom to top
method_data.sort(key=lambda x: x[1], reverse=True)

# Remove methods from main file  
main_lines = lines[:]
for name, start, end, _ in method_data:
    # Replace with a delegation
    delegation = f'''  Future<void> {name}(Printer printer) async {{
    await PrinterOperationsHelper.{name}(context, printer, _printerService);
  }}

'''
    main_lines[start:end] = [delegation]

# Create the imports for new file
imports = """import 'package:extropos/models/printer_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/printer_service_clean.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/dialog_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Helper class for printer discovery and testing operations
class PrinterOperationsHelper {
"""

# Build new file content
service_content = [imports]
for name, start, end, code in reversed(method_data):
    # Convert instance method to static method with context parameter
    static_code = code.replace(
        f'Future<void> {name}(Printer printer) async {{',
        f'static Future<void> {name}(BuildContext context, Printer printer, PrinterService printerService) async {{'
    )
    # Replace 'if (!mounted) return;' with 'if (!context.mounted) return;'
    static_code = static_code.replace('if (!mounted) return;', 'if (!context.mounted) return;')
    static_code = static_code.replace('if (mounted)', 'if (context.mounted)')
    static_code = static_code.replace('_printerService', 'printerService')
    
    service_content.append(static_code)
    service_content.append('\n')

service_content.append('}\n')

# Write the service file
with open('lib/helpers/printer_operations_helper.dart', 'w', encoding='utf-8') as f:
    f.write(''.join(service_content))

# Add import to main file
import_line = "import 'package:extropos/helpers/printer_operations_helper.dart';\n"
import_idx = 0
for i, line in enumerate(main_lines):
    if line.startswith('import '):
        import_idx = i + 1
main_lines.insert(import_idx, import_line)

# Write updated main file
with open('lib/screens/printers_management_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(main_lines)

print(f'✓ Extracted {len(method_data)} operation methods')
print(f'✓ Created lib/helpers/printer_operations_helper.dart')
print(f'✓ Updated printers_management_screen.dart')
print(f'  Original: {len(lines)} lines')
print(f'  New: {len(main_lines)} lines')
print(f'  Reduction: {len(lines) - len(main_lines)} lines')
