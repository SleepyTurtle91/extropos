#!/usr/bin/env python3
import re

# Read file
with open('lib/screens/reports_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find boundaries
print_report_start = None
build_advanced_pdf_end = None

for i, line in enumerate(lines):
    if '  Future<void> _printReport()' in line:
        print_report_start = i
    elif '  pw.Widget _buildAdvancedPDFContent()' in line:
        # Find closing brace
        brace_level = 0
        for j in range(i, len(lines)):
            brace_level += lines[j].count('{') - lines[j].count('}')
            if brace_level == 0 and j > i:
                build_advanced_pdf_end = j + 1
                break

print(f'_printReport start: line {print_report_start + 1 if print_report_start else "NOT FOUND"}')
print(f'_buildAdvancedPDFContent end: line {build_advanced_pdf_end if build_advanced_pdf_end else "NOT FOUND"}')

# Create replacement
replacement = '''  Future<void> _printReport() async {
    if (_loading) return;
    try {
      if (_showAdvancedReports) {
        await ReportsExportService().printAdvancedReport(
          context,
          _selectedFormat,
          _selectedReportType,
          _salesSummaryReport,
          _productSalesReport,
          _dayClosingReport,
          _selectedPeriod,
          mounted: mounted,
        );
      } else {
        await ReportsExportService().printBasicReport(
          context,
          _currentReport,
          _selectedPeriod,
          mounted: mounted,
        );
      }
    } catch (e) {
      debugPrint('Reports: Print failed: $e');
      if (mounted) {
        ToastHelper.showToast(context, 'Print failed: $e');
      }
    }
  }

  Future<printer_model.Printer?> _getDefaultPrinter() async {
    final printers = await DatabaseService.instance.getPrinters();
    return printers.isNotEmpty ? printers.first : null;
  }

'''

# Replace section
if print_report_start is not None and build_advanced_pdf_end is not None:
    new_lines = (
        lines[:print_report_start] +
        [replacement] +
        lines[build_advanced_pdf_end:]
    )
    
    # Write back
    with open('lib/screens/reports_screen.dart', 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    
    removed_lines = build_advanced_pdf_end - print_report_start
    replacement_lines = len(replacement.splitlines())
    net_reduction = removed_lines - replacement_lines
    
    print(f'\n✓ Successfully replaced {removed_lines} lines')
    print(f'  Original lines (lines {print_report_start + 1} to {build_advanced_pdf_end}): {removed_lines}')
    print(f'  Replacement size: {replacement_lines} lines')
    print(f'  Net reduction: {net_reduction} lines')
    print(f'  New file size: {len(new_lines)} lines')
else:
    print('ERROR: Could not find method boundaries')
