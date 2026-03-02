/// Auto-generated from advanced_reports.dart - Do not edit manually
///
/// Reports Base
library;

enum ExportFormat { csv, pdf, excel, json }

abstract class BaseReport {
  final String id;
  final DateTime generatedAt;
  final DateTime startDate;
  final DateTime endDate;
  final String periodLabel;

  BaseReport({
    required this.id,
    required this.generatedAt,
    required this.startDate,
    required this.endDate,
    required this.periodLabel,
  });
}

