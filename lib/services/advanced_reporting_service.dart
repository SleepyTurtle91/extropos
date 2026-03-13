import 'dart:convert';

import 'package:extropos/models/advanced_reporting_features.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/sales_report.dart' show ReportPeriod;
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/email_template_service.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:uuid/uuid.dart';

part 'advanced_reporting_service_analysis.dart';
part 'advanced_reporting_service_export.dart';

/// Advanced reporting service with scheduling, forecasting, and analytics
class AdvancedReportingService {
  static final AdvancedReportingService instance =
      AdvancedReportingService._init();
  AdvancedReportingService._init();

  final _uuid = const Uuid();

  // ==================== SCHEDULED REPORTS ====================

  /// Create a scheduled report configuration
  Future<ScheduledReport> createScheduledReport({
    required String name,
    required ReportType reportType,
    required ReportPeriod period,
    required ScheduleFrequency frequency,
    required List<String> recipientEmails,
    required List<ExportFormat> exportFormats,
    Map<String, dynamic>? customFilters,
  }) async {
    final report = ScheduledReport(
      id: _uuid.v4(),
      name: name,
      reportType: reportType,
      period: period,
      frequency: frequency,
      recipientEmails: recipientEmails,
      exportFormats: exportFormats,
      customFilters: customFilters,
      nextRun: _calculateNextRun(DateTime.now(), frequency),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to database
    await DatabaseService.instance.saveScheduledReport(report);

    return report;
  }

  DateTime _calculateNextRun(DateTime from, ScheduleFrequency frequency) {
    switch (frequency) {
      case ScheduleFrequency.hourly:
        return from.add(const Duration(hours: 1));
      case ScheduleFrequency.daily:
        return DateTime(
          from.year,
          from.month,
          from.day + 1,
          8,
          0,
        ); // 8 AM next day
      case ScheduleFrequency.weekly:
        return DateTime(
          from.year,
          from.month,
          from.day + 7,
          8,
          0,
        ); // Same day next week
      case ScheduleFrequency.monthly:
        return DateTime(
          from.year,
          from.month + 1,
          1,
          8,
          0,
        ); // 1st of next month
      case ScheduleFrequency.quarterly:
        return DateTime(from.year, from.month + 3, 1, 8, 0); // 1st of quarter
      case ScheduleFrequency.yearly:
        return DateTime(from.year + 1, 1, 1, 8, 0); // Jan 1st next year
    }
  }

  /// Get all scheduled reports
  Future<List<ScheduledReport>> getScheduledReports() async {
    final maps = await DatabaseService.instance.getScheduledReports();
    return maps.map((map) => _scheduleFromMap(map)).toList();
  }

  ScheduledReport _scheduleFromMap(Map<String, dynamic> map) {
    return ScheduledReport(
      id: map['id'] as String,
      name: map['name'] as String,
      reportType: ReportType.values.firstWhere(
        (e) => e.name == map['report_type'],
        orElse: () => ReportType.salesSummary,
      ),
      period: ReportPeriod(
        label: map['period_label'] as String,
        startDate: DateTime.parse(map['period_start'] as String),
        endDate: DateTime.parse(map['period_end'] as String),
      ),
      frequency: ScheduleFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => ScheduleFrequency.daily,
      ),
      recipientEmails: List<String>.from(
        json.decode(map['recipient_emails'] as String),
      ),
      exportFormats: (json.decode(map['export_formats'] as String) as List)
          .map(
            (e) => ExportFormat.values.firstWhere(
              (f) => f.name == e,
              orElse: () => ExportFormat.pdf,
            ),
          )
          .toList(),
      isActive: (map['is_active'] as int) == 1,
      nextRun: map['next_run'] != null
          ? DateTime.parse(map['next_run'] as String)
          : null,
      lastRun: map['last_run'] != null
          ? DateTime.parse(map['last_run'] as String)
          : null,
      customFilters: map['custom_filters'] != null
          ? json.decode(map['custom_filters'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Update a scheduled report
  Future<void> updateScheduledReport(ScheduledReport report) async {
    await DatabaseService.instance.updateScheduledReport(report);
  }

  /// Delete a scheduled report
  Future<void> deleteScheduledReport(String id) async {
    await DatabaseService.instance.deleteScheduledReport(id);
  }

  // ==================== CUSTOM REPORT BUILDER ====================

  /// Create custom report template
  Future<CustomReportTemplate> createCustomTemplate({
    required String name,
    required String description,
    required List<ReportMetric> metrics,
    required List<ReportGroupBy> groupBy,
    required List<ReportFilter> filters,
    required List<ReportSort> sorting,
    required String createdBy,
    bool isShared = false,
  }) async {
    final template = CustomReportTemplate(
      id: _uuid.v4(),
      name: name,
      description: description,
      selectedMetrics: metrics,
      groupByFields: groupBy,
      filters: filters,
      sorting: sorting,
      createdBy: createdBy,
      isShared: isShared,
    );

    // Save to database
    await DatabaseService.instance.saveCustomReportTemplate({
      'id': template.id,
      'name': template.name,
      'description': template.description,
      'selected_metrics': jsonEncode(
        template.selectedMetrics.map((m) => m.toString()).toList(),
      ),
      'group_by_fields': jsonEncode(
        template.groupByFields.map((g) => g.toString()).toList(),
      ),
      'filters': jsonEncode(
        template.filters
            .map(
              (f) => {
                'fieldName': f.fieldName,
                'operator': f.operator.toString(),
                'value': f.value,
                'value2': f.value2,
              },
            )
            .toList(),
      ),
      'sorting': jsonEncode(
        template.sorting
            .map(
              (s) => {
                'fieldName': s.fieldName,
                'direction': s.direction.toString(),
              },
            )
            .toList(),
      ),
      'created_by': template.createdBy,
      'is_shared': template.isShared ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    return template;
  }

  /// Execute custom report template
  Future<Map<String, dynamic>> executeCustomReport(
    CustomReportTemplate template,
    ReportPeriod period,
  ) async {
    // Build SQL query from template
    // Execute query
    // Return structured results
    return {};
  }

  /// Get reports that are due for execution
  Future<List<ScheduledReport>> getReportsDueForExecution() async {
    final dueReports = await DatabaseService.instance
        .getReportsDueForExecution();
    return dueReports.map((map) => _scheduleFromMap(map)).toList();
  }

  /// Execute all reports that are due
  Future<void> executeAllDueReports() async {
    final dueReports = await getReportsDueForExecution();

    for (final report in dueReports) {
      if (!report.isActive) continue;

      final success = await executeScheduledReport(report);
      print(
        'Report "${report.name}" execution: ${success ? "SUCCESS" : "FAILED"}',
      );
    }
  }
}

class ReportInsight {
  final String title;
  final String description;
  final InsightType type; // 'positive', 'negative', 'neutral', 'warning'
  final String? actionRecommendation;
  final double? impactScore; // 0-100 importance score

  ReportInsight({
    required this.title,
    required this.description,
    required this.type,
    this.actionRecommendation,
    this.impactScore,
  });
}

enum InsightType { positive, negative, neutral, warning }

// Import types from models
class ProductSalesData {
  final String productId;
  final String productName;
  final String category;
  final int unitsSold;
  final double totalRevenue;
  final double averagePrice;

  ProductSalesData({
    required this.productId,
    required this.productName,
    required this.category,
    required this.unitsSold,
    required this.totalRevenue,
    required this.averagePrice,
  });
}
