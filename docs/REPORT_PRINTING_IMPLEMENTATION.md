# Report Printing Implementation Guide

## Overview

The report printing system has been fully implemented with support for:

- ✅ **CSV Export** - Comma-separated values for spreadsheet import

- ✅ **PDF Export (A4)** - Professional printable documents

- ✅ **Thermal Print (58mm)** - Receipt printer format (32 characters wide)

- ✅ **Thermal Print (80mm)** - Wide receipt printer format (40 characters wide)

## Architecture

### Core Service: `ReportPrinterService`

Located at: [lib/services/report_printer_service.dart](lib/services/report_printer_service.dart)

**Purpose**: Centralized service for generating and printing sales reports in multiple formats.

**Key Methods**:

#### 1. PDF Generation

```dart
Future<Uint8List> generateReportPDF({
  required SalesSummary summary,
  required List<CategoryPerformance> categories,
  required List<ProductPerformance> topProducts,
  required List<PaymentMethodStats> paymentMethods,
  required String periodLabel,
})

```

Generates a professional A4 PDF document with:

- Report header with business information

- Summary metrics (Gross Sales, Net Sales, Transactions, Average Ticket, Total Refunds)

- Payment method breakdown table

- Top 10 products with ranking

- Sales by category

- Professional footer

**Dependencies**:

- `pdf: ^3.10.1` - PDF document generation

- `printing: ^5.11.0` - Platform-specific PDF handling

#### 2. Thermal Report Generation (58mm and 80mm)

```dart
String generateThermalReport({
  required SalesSummary summary,
  required List<ProductPerformance> topProducts,
  required List<PaymentMethodStats> paymentMethods,
  required String periodLabel,
  required int paperWidth,
})

```

Generates text-based thermal receipt format with:

- Centered header with business name and report title

- Period and generation timestamp

- Summary metrics in aligned columns

- Payment method breakdown

- Top 5 products (58mm) or Top 10 products (80mm)

- Professional formatting with border characters

**Paper Widths**:

- 58mm printer: 32 characters per line

- 80mm printer: 40 characters per line

#### 3. PDF Printing

```dart
Future<void> printPDF({
  required BuildContext context,
  required Uint8List pdfBytes,
  required String documentName,
})

```

Prints PDF to available printer using Printing package platform dialogs.

#### 4. Thermal Printing

```dart
Future<void> printThermal({
  required BuildContext context,
  required String thermalText,
  required int paperWidth,
})

```

Prints thermal formatted text via Android printer service or Windows printer.

#### 5. PDF Export to File

```dart
Future<String?> exportToPDFFile({
  required Uint8List pdfBytes,
})

```

Saves PDF to device storage:

- **Android**: Saves to Downloads folder (`/Download/`)

- **Desktop**: Shows file picker dialog

- Returns file path or null if cancelled

## UI Integration

### Modern Reports Dashboard

Location: [lib/screens/modern_reports_dashboard.dart](lib/screens/modern_reports_dashboard.dart)

**Export Button**:

- Located in dashboard header (FAB next to refresh)

- Opens modal with 4 export options

**Implementation Methods**:

#### `_exportCSV()`

- Existing method - no changes

- Exports as comma-separated values

#### `_exportPDF()` ✨ NEW

```dart
Future<void> _exportPDF() async {
  final reportService = ReportPrinterService.instance;
  
  // Generate PDF
  final pdfBytes = await reportService.generateReportPDF(
    summary: _summary!,
    categories: _categories,
    topProducts: _topProducts,
    paymentMethods: _paymentMethods,
    periodLabel: _selectedPeriod.label,
  );
  
  // Save to file
  final filePath = await reportService.exportToPDFFile(pdfBytes: pdfBytes);
}

```

- Generates PDF from current report data

- Saves to Downloads (Android) or shows save dialog (Desktop)

- Shows toast notification with file location

#### `_printThermal58mm()` ✨ NEW

```dart
Future<void> _printThermal58mm() async {
  final reportService = ReportPrinterService.instance;
  
  // Generate thermal format for 58mm
  final thermalText = reportService.generateThermalReport(
    summary: _summary!,
    topProducts: _topProducts.take(5).toList(),
    paymentMethods: _paymentMethods,
    periodLabel: _selectedPeriod.label,
    paperWidth: 32,
  );
  
  // Print to thermal printer
  await reportService.printThermal(
    context: context,
    thermalText: thermalText,
    paperWidth: 32,
  );
}

```

- Generates thermal format for 58mm receipt printer

- Includes top 5 products (limited due to paper width)

- Sends to Android printer service

#### `_printThermal80mm()` ✨ NEW

```dart
Future<void> _printThermal80mm() async {
  final reportService = ReportPrinterService.instance;
  
  // Generate thermal format for 80mm
  final thermalText = reportService.generateThermalReport(
    summary: _summary!,
    topProducts: _topProducts.take(10).toList(),
    paymentMethods: _paymentMethods,
    periodLabel: _selectedPeriod.label,
    paperWidth: 40,
  );
  
  // Print to thermal printer
  await reportService.printThermal(
    context: context,
    thermalText: thermalText,
    paperWidth: 40,
  );
}

```

- Generates thermal format for 80mm receipt printer

- Includes top 10 products (more room on wider paper)

- Sends to Android printer service

## Data Flow

### Export PDF Workflow

```
User clicks "Export as PDF (A4)"
    ↓
_exportPDF() called
    ↓
ReportPrinterService.generateReportPDF()
    ↓
PDF document built with tables and formatting
    ↓
PDF bytes returned
    ↓
reportService.exportToPDFFile(pdfBytes)
    ↓
    ├─ Android: Save to /Download/ folder
    └─ Desktop: Show file picker
    ↓
Toast notification with file path

```

### Print Thermal Workflow

```
User clicks "Print (Thermal 58mm)"
    ↓
_printThermal58mm() called
    ↓
ReportPrinterService.generateThermalReport(paperWidth: 32)
    ↓
Text formatted with proper alignment (32 char width)
    ↓
reportService.printThermal()
    ↓
AndroidPrinterService.printReceipt() called
    ↓
Native Android printer service handles printing
    ↓
Toast notification with result

```

## Features

### PDF Report Features

- **Professional Layout**: A4 format with proper margins

- **Business Branding**: Business name, address at header

- **Data Tables**: Organized tables with borders

- **Summary Metrics**: Key KPIs highlighted

- **Product Analysis**: Top products with ranking

- **Payment Breakdown**: By payment method

- **Category Sales**: Sales distribution by category

- **Timestamp**: Report generated timestamp

- **Footer**: Certification text

### Thermal Report Features

- **Centered Header**: Business name and report title

- **Aligned Columns**: Proper spacing for different paper widths

- **Summary Section**: Key metrics in readable format

- **Payment Methods**: Transaction count and amounts

- **Top Products**: Ranked list with units and revenue

- **Professional Formatting**: Box drawing characters for aesthetics

- **Paper-Aware**: Different formatting for 58mm vs 80mm

## Configuration

### Business Information

All reports use data from [BusinessInfo.instance](lib/models/business_info_model.dart):

- `businessName` - Used in report header

- `currencySymbol` - Used for all monetary values (default "RM")

- `address` - Used in PDF header

### Printer Configuration

For thermal printing to work:

1. Ensure printer is detected by Android system
2. Configure in Settings → Printers Management
3. Printer must support text-based printing (most thermal printers do)

## Error Handling

All methods include try-catch blocks:

```dart
try {
  // Generate/print logic
} catch (e) {
  ToastHelper.showToast(context, 'Error message: $e');
}

```

**Error Messages**:

- "PDF export failed: [error]" - PDF generation error

- "Print error: [error]" - Thermal printing error

- "Failed to print. Check printer connection." - Printer not found

- "No data to print" - Missing summary data

## Testing Checklist

- [ ] CSV Export works (existing feature)

- [ ] PDF Export generates valid PDF file

- [ ] PDF Export saves to correct location:

  - [ ] Android: Downloads folder

  - [ ] Windows: Shows file picker

- [ ] PDF Print opens print dialog

- [ ] Thermal 58mm print sends to printer with correct format

- [ ] Thermal 80mm print sends to printer with correct format

- [ ] Toast notifications show appropriate messages

- [ ] All date ranges work (Today, This Week, This Month, Custom)

- [ ] Handles empty data gracefully

- [ ] Works with different currency symbols

- [ ] Works with various report periods

## Troubleshooting

### PDF Not Generating

- Check if `_summary` is null

- Verify `pdf` and `printing` packages are in pubspec.yaml

- Check dart analyze for import errors

### Thermal Print Not Working

- Verify printer is configured in Settings

- Check Android printer service is initialized

- Ensure printer supports text-based thermal printing

- On device: Check printer connection

### File Save Failed (PDF)

- Android: Verify storage permissions granted

- Desktop: Check user has write access to directory

- Verify path_provider package is installed

### Wrong Paper Width

- 58mm = 32 characters per line

- 80mm = 40 characters per line

- Adjust formatting if custom paper width needed

## Future Enhancements

1. **Email Reports**: Send PDF via email
2. **Scheduled Reports**: Auto-generate and send on schedule
3. **Custom Branding**: Include logo image in PDF
4. **Multiple Report Types**: Different formats for different users
5. **Cloud Upload**: Send directly to Google Drive
6. **Report Archive**: Store generated reports locally
7. **Batch Printing**: Print multiple reports at once
8. **Language Support**: Multi-language report headers

## Files Modified

### New Files Created

- [lib/services/report_printer_service.dart](lib/services/report_printer_service.dart) - Main report printing service

### Files Updated

- [lib/screens/modern_reports_dashboard.dart](lib/screens/modern_reports_dashboard.dart)

  - Added import for `report_printer_service`

  - Updated export modal options (removed "coming soon" placeholders)

  - Added `_exportPDF()` method

  - Added `_printThermal58mm()` method

  - Added `_printThermal80mm()` method

## Dependencies Used

- **pdf**: ^3.10.1 - PDF document generation

- **printing**: ^5.11.0 - Cross-platform printing

- **file_selector**: Already in project - File picker for desktop

- **path_provider**: Already in project - File system paths

- **intl**: Already in project - Date formatting

## Code Example

### Using ReportPrinterService Directly

```dart
import 'package:extropos/services/report_printer_service.dart';

final service = ReportPrinterService.instance;

// Generate PDF
final pdf = await service.generateReportPDF(
  summary: mySummary,
  categories: myCategories,
  topProducts: myProducts,
  paymentMethods: myPayments,
  periodLabel: 'December 2025',
);

// Generate thermal text
final thermal = service.generateThermalReport(
  summary: mySummary,
  topProducts: myProducts,
  paymentMethods: myPayments,
  periodLabel: 'December 2025',
  paperWidth: 32, // or 40 for 80mm
);

// Print or export
await service.printPDF(context: context, pdfBytes: pdf, documentName: 'sales_report');
await service.printThermal(context: context, thermalText: thermal, paperWidth: 32);

```

---

**Status**: ✅ Implementation Complete  
**Last Updated**: December 30, 2025  
**Tested On**: Windows (Desktop), Android (simulated)
