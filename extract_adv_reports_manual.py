#!/usr/bin/env python3
"""Manually extract advanced_reports_screen methods with proper brace matching"""

import re

# Read original file
with open('lib/screens/advanced_reports_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f'Processing {len(lines)} lines from advanced_reports_screen.dart\n')

# Key methods to extract - these are the large PDF builders
# They are relatively self-contained and safe to move
pdf_methods = {
    '_buildSalesSummaryPDF': (418, 437),      # Start line, End line (approx)
    '_buildProductSalesPDF': (438, 466),
    '_buildCategorySalesPDF': (467, 490),
    '_buildPaymentMethodPDF': (491, 525),
    '_buildEmployeePerformancePDF': (526, 553),
    '_buildInventoryPDF': (554, 583),
    '_buildShrinkagePDF': (584, 611),
    '_buildLaborCostPDF': (612, 638),
    '_buildCustomerAnalysisPDF': (639, 673),
    '_buildBasketAnalysisPDF': (674, 692),
    '_buildLoyaltyProgramPDF': (693, 723),
    '_buildDayClosingPDF': (724, 779),
    '_buildProfitLossPDF': (780, 800),
    '_buildCashFlowPDF': (801, 815),
    '_buildTaxSummaryPDF': (816, 833),
    '_buildInventoryValuationPDF': (834, 852),
    '_buildABCAnalysisPDF': (853, 873),
    '_buildDemandForecastingPDF': (874, 895),
    '_buildMenuEngineeringPDF': (896, 918),
    '_buildTablePerformancePDF': (919, 946),
}

# Find exact line numbers for these methods
method_lines = {}
for i, line in enumerate(lines, 1):
    for method_name in pdf_methods:
        if f'  pw.Widget {method_name}' in line:
            method_lines[method_name] = i
            print(f'Found {method_name} at line {i}')

if not method_lines:
    print('ERROR: Could not find PDF methods. Checking actual file content...')
    for i, line in enumerate(lines[400:450], 400):
        if '_build' in line and 'PDF' in line:
            print(f'Line {i}: {line.rstrip()[:80]}')
    exit(1)

# Find end of each method using brace counting
def find_method_end(start_line_idx):
    """Find end of method by tracking braces"""
    brace_count = 0
    in_method = False
    
    for i in range(start_line_idx, len(lines)):
        line = lines[i]
        
        for char in line:
            if char == '{':
                brace_count += 1
                in_method = True
            elif char == '}':
                brace_count -= 1
                if in_method and brace_count == 0:
                    return i + 1  # Return 1-based line number
    
    return len(lines)

# Calculate method ranges
method_ranges = {}
for method, start_line_1based in method_lines.items():
    start_idx = start_line_1based - 1  # Convert to 0-based
    end_line_1based = find_method_end(start_idx)
    method_ranges[method] = (start_line_1based, end_line_1based)
    print(f'{method}: lines {start_line_1based}-{end_line_1based}')

print(f'\nTotal PDF helper methods found: {len(method_ranges)}')

# Create PDF helpers part file
pdf_part = []
pdf_part.append('// Part of advanced_reports_screen.dart\n')
pdf_part.append('// PDF helper methods extracted from main file\n')
pdf_part.append('\n')
pdf_part.append("part of 'advanced_reports_screen.dart';\n")
pdf_part.append('\n')
pdf_part.append('extension AdvancedReportsPDF on _AdvancedReportsScreenState {\n')

extracted_lines = 0
for method, (start, end) in sorted(method_ranges.items(), key=lambda x: x[1][0]):
    # Extract lines (convert to 0-based indexing)
    for i in range(start - 1, end):
        pdf_part.append(lines[i])
    pdf_part.append('\n')
    extracted_lines += (end - start + 1)

pdf_part.append('}\n')

# Write part file
with open('lib/screens/advanced_reports_screen_pdf_helpers.dart', 'w', encoding='utf-8') as f:
    f.writelines(pdf_part)

print(f'\n✓ Created advanced_reports_screen_pdf_helpers.dart ({extracted_lines} lines)')

# Now update main file to add part directive
with open('lib/screens/advanced_reports_screen.dart', 'r', encoding='utf-8') as f:
    main_content = f.read()

# Find last import/export line
import_lines = []
for i, line in enumerate(main_content.split('\n')):
    if line.startswith('import ') or line.startswith('export '):
        import_lines.append(i)

if import_lines:
    insert_line = max(import_lines) + 1
    lines_list = main_content.split('\n')
    lines_list.insert(insert_line, '')
    lines_list.insert(insert_line + 1, "part 'advanced_reports_screen_pdf_helpers.dart';")
    main_content = '\n'.join(lines_list)

# Remove extracted methods from main (in reverse order)
for method, (start, end) in sorted(method_ranges.items(), key=lambda x: x[1][0], reverse=True):
    lines_list = main_content.split('\n')
    # Delete lines (accounting for 0-based indexing)
    del lines_list[start - 1:end]
    main_content = '\n'.join(lines_list)

# Write updated main file
with open('lib/screens/advanced_reports_screen.dart', 'w', encoding='utf-8') as f:
    f.write(main_content)

orig_lines = len(lines)
new_lines = len(main_content.split('\n'))
print(f'\n✓ Updated main file: {orig_lines} → {new_lines} lines (reduction: {orig_lines - new_lines})')
print(f'\n✓ EXTRACTION COMPLETE')
