#!/usr/bin/env python3
"""Remove methods from main file that are already in part file"""

import re

# Methods that are in the part file
methods_to_remove = [
    '_generateReportCsv',
    '_generateAdvancedCSVData',
    '_getReportTypeLabel',
    '_buildAdvancedReportContent',
    '_buildSalesSummaryContent',
    '_buildProductSalesContent',
    '_buildCategorySalesContent',
    '_buildPaymentMethodContent',
    '_buildEmployeePerformanceContent',
    '_buildInventoryContent',
    '_buildShrinkageContent',
    '_buildLaborCostContent',
    '_buildCustomerAnalysisContent',
    '_buildBasketAnalysisContent',
    '_buildLoyaltyProgramContent',
    '_buildDayClosingContent',
    '_buildDailyStaffPerformanceContent',
]

with open('lib/screens/reports_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f'Input: {len(lines)} lines\n')

# Find all methods in main file
def find_method_end(lines, start_idx):
    brace_count = 0
    in_method = False
    for i in range(start_idx, len(lines)):
        line = lines[i]
        for char in line:
            if char == '{':
                brace_count += 1
                in_method = True
            elif char == '}':
                brace_count -= 1
                if in_method and brace_count == 0:
                    return i
    return len(lines) - 1

# Find duplicate methods
duplicates = {}
for i, line in enumerate(lines):
    for method in methods_to_remove:
        if f' {method}(' in line and ('Widget' in line or 'String' in line or 'Future' in line or 'void' in line):
            end_idx = find_method_end(lines, i)
            size = end_idx - i + 1
            duplicates[method] = (i, end_idx, size)
            print(f'Found {method}: lines {i+1}-{end_idx+1} ({size} lines)')
            break

print(f'\nFound {len(duplicates)} duplicate methods')
total_to_remove = sum(size for _, _, size in duplicates.values())
print(f'Total lines to remove: {total_to_remove}')

# Remove methods in reverse order
for method in sorted(duplicates.keys(), key=lambda m: duplicates[m][0], reverse=True):
    start, end, size = duplicates[method]
    del lines[start:end+1]
    print(f'Removed {method}')

with open('lib/screens/reports_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print(f'\n✓ Updated main file: {len(lines) + total_to_remove} → {len(lines)} lines')
print(f'  Reduction: {total_to_remove} lines')

if len(lines) < 1000:
    print(f'\n✓✓✓ SUCCESS: {len(lines)} lines (<1000) ✓ COMPLIANT')
else:
    print(f'\nNote: {len(lines)} lines (need {len(lines) - 1000} more)')
