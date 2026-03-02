#!/usr/bin/env python3

with open('lib/screens/printers_management_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Extract lines 2692 to end (both _PrinterFormDialog classes)
dialog_start = 2691  # 0-indexed
dialog_content = lines[dialog_start:]

# Extract the imports needed for the dialog
imports = """import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/printer_service_clean.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';

"""

# Create new file with dialog classes
new_file_content = imports + ''.join(dialog_content)

# Write to new file
with open('lib/dialogs/printer_form_dialog.dart', 'w', encoding='utf-8') as f:
    f.write(new_file_content)

# Update original file - remove dialog classes and add import
main_content = lines[:dialog_start]

# Add import for the new dialog file
import_line_to_add = "import 'package:extropos/dialogs/printer_form_dialog.dart';\n"

# Find where to insert import (after other imports)
insert_idx = 0
for i,line in enumerate(main_content):
    if line.startswith('import '):
        insert_idx = i + 1

main_content.insert(insert_idx, import_line_to_add)

# Write updated main file
with open('lib/screens/printers_management_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(main_content)

print(f'✓ Extracted _PrinterFormDialog classes ({len(dialog_content)} lines)')
print(f'✓ Created lib/dialogs/printer_form_dialog.dart ({len(dialog_content) + len(imports.splitlines())} lines)')
print(f'✓ Updated printers_management_screen.dart ({len(main_content)} lines)')
print(f'  Reduction: {len(lines)} → {len(main_content)} lines ({len(lines) - len(main_content)} lines removed)')
