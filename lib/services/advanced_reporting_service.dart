import 'dart:convert';

import 'package:extropos/models/advanced_reporting_features.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/sales_report.dart' show ReportPeriod;
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/email_template_service.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:uuid/uuid.dart';

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

  // ==================== COMPARATIVE ANALYSIS ====================

  /// Compare two periods for any metric
  Future<ComparativeAnalysis> generateComparativeAnalysis({
    required ReportPeriod currentPeriod,
    required ReportPeriod comparisonPeriod,
    required List<String> metricsToCompare,
  }) async {
    final metrics = <String, PeriodComparison>{};

    // Get data for both periods
    final currentReport = await DatabaseService.instance
        .generateSalesSummaryReport(currentPeriod);
    final comparisonReport = await DatabaseService.instance
        .generateSalesSummaryReport(comparisonPeriod);

    // Build comparisons
    for (final metricName in metricsToCompare) {
      final currentValue = _getMetricValue(metricName, currentReport);
      final previousValue = _getMetricValue(metricName, comparisonReport);

      metrics[metricName] = PeriodComparison(
        metricName: metricName,
        currentValue: currentValue,
        previousValue: previousValue,
      );
    }

    return ComparativeAnalysis(
      id: _uuid.v4(),
      generatedAt: DateTime.now(),
      currentPeriod: currentPeriod,
      comparisonPeriod: comparisonPeriod,
      metrics: metrics,
    );
  }

  double _getMetricValue(String metricName, dynamic report) {
    // Extract metric value from report based on metric name
    // This is a simplified version - expand based on actual report structure
    switch (metricName.toLowerCase()) {
      case 'gross_sales':
      case 'gross sales':
        return report.grossSales ?? 0.0;
      case 'net_sales':
      case 'net sales':
        return report.netSales ?? 0.0;
      case 'transactions':
      case 'total transactions':
        return (report.totalTransactions ?? 0).toDouble();
      case 'average_transaction':
      case 'average transaction value':
        return report.averageTransactionValue ?? 0.0;
      default:
        return 0.0;
    }
  }

  // ==================== SALES FORECASTING ====================

  /// Generate sales forecast using simple moving average
  Future<SalesForecast> generateSalesForecast({
    required DateTime startDate,
    required DateTime endDate,
    required int forecastDays,
    String method = 'linear', // 'linear', 'exponential', 'seasonal'
  }) async {
    // Get historical data (last 30 days or more for better accuracy)
    final historicalPeriod = ReportPeriod(
      startDate: startDate.subtract(Duration(days: 30)),
      endDate: endDate,
      label: 'Historical Data',
    );

    final historicalReport = await DatabaseService.instance
        .generateSalesSummaryReport(historicalPeriod);

    // Extract daily sales data
    final dailySales = historicalReport.dailySales;

    // Calculate forecast using selected method
    final forecasts = <ForecastDataPoint>[];
    final forecastStartDate = endDate.add(const Duration(days: 1));

    switch (method) {
      case 'linear':
        forecasts.addAll(
          _linearForecast(dailySales, forecastStartDate, forecastDays),
        );
        break;
      case 'exponential':
        forecasts.addAll(
          _exponentialForecast(dailySales, forecastStartDate, forecastDays),
        );
        break;
      case 'seasonal':
        forecasts.addAll(
          _seasonalForecast(dailySales, forecastStartDate, forecastDays),
        );
        break;
      default:
        forecasts.addAll(
          _linearForecast(dailySales, forecastStartDate, forecastDays),
        );
    }

    final totalForecasted = forecasts.fold(
      0.0,
      (sum, f) => sum + f.forecastedValue,
    );

    return SalesForecast(
      id: _uuid.v4(),
      generatedAt: DateTime.now(),
      forecastStartDate: forecastStartDate,
      forecastEndDate: forecastStartDate.add(Duration(days: forecastDays - 1)),
      dailyForecasts: forecasts,
      totalForecastedSales: totalForecasted,
      confidenceInterval: 15.0, // ±15% confidence
      forecastMethod: method,
      modelParameters: {
        'historical_days': dailySales.length,
        'forecast_days': forecastDays,
      },
    );
  }

  List<ForecastDataPoint> _linearForecast(
    Map<String, double> historical,
    DateTime startDate,
    int days,
  ) {
    // Calculate average and trend
    final values = historical.values.toList();
    final average = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length;

    // Simple linear trend
    double trend = 0.0;
    if (values.length > 1) {
      trend = (values.last - values.first) / values.length;
    }

    final forecasts = <ForecastDataPoint>[];
    for (var i = 0; i < days; i++) {
      final forecastValue = average + (trend * i);
      final date = startDate.add(Duration(days: i));

      forecasts.add(
        ForecastDataPoint(
          date: date,
          forecastedValue: forecastValue.clamp(0, double.infinity),
          lowerBound: (forecastValue * 0.85).clamp(0, double.infinity),
          upperBound: forecastValue * 1.15,
        ),
      );
    }

    return forecasts;
  }

  List<ForecastDataPoint> _exponentialForecast(
    Map<String, double> historical,
    DateTime startDate,
    int days,
  ) {
    // Exponential smoothing
    final values = historical.values.toList();
    if (values.isEmpty) return [];

    const alpha = 0.3; // Smoothing factor
    double smoothed = values.first;

    for (var i = 1; i < values.length; i++) {
      smoothed = alpha * values[i] + (1 - alpha) * smoothed;
    }

    final forecasts = <ForecastDataPoint>[];
    for (var i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      forecasts.add(
        ForecastDataPoint(
          date: date,
          forecastedValue: smoothed,
          lowerBound: smoothed * 0.85,
          upperBound: smoothed * 1.15,
        ),
      );
    }

    return forecasts;
  }

  List<ForecastDataPoint> _seasonalForecast(
    Map<String, double> historical,
    DateTime startDate,
    int days,
  ) {
    // Simple seasonal pattern (day of week)
    final values = historical.values.toList();
    if (values.isEmpty) return [];

    // Calculate day-of-week averages
    final dayAverages = <int, double>{};
    final dayCounts = <int, int>{};

    historical.forEach((dateStr, value) {
      try {
        final date = DateTime.parse(dateStr);
        final dayOfWeek = date.weekday;
        dayAverages[dayOfWeek] = (dayAverages[dayOfWeek] ?? 0) + value;
        dayCounts[dayOfWeek] = (dayCounts[dayOfWeek] ?? 0) + 1;
      } catch (e) {
        // Skip invalid dates
      }
    });

    // Calculate averages
    dayAverages.forEach((day, total) {
      dayAverages[day] = total / (dayCounts[day] ?? 1);
    });

    final forecasts = <ForecastDataPoint>[];
    for (var i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dayOfWeek = date.weekday;
      final forecastValue = dayAverages[dayOfWeek] ?? values.last;

      forecasts.add(
        ForecastDataPoint(
          date: date,
          forecastedValue: forecastValue,
          lowerBound: forecastValue * 0.85,
          upperBound: forecastValue * 1.15,
        ),
      );
    }

    return forecasts;
  }

  // ==================== ABC ANALYSIS ====================

  /// Generate ABC analysis for inventory optimization
  Future<ABCAnalysisReport> generateABCAnalysis({
    required ReportPeriod period,
  }) async {
    final productReport = await DatabaseService.instance
        .generateProductSalesReport(period);

    // Sort products by revenue (descending)
    final sortedProducts = List<ProductSalesData>.from(
      productReport.productSales,
    )..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

    final totalRevenue = productReport.totalRevenue;
    final totalItems = sortedProducts.length;

    // Categorize items (80-15-5 rule)
    final categoryA = <ABCItem>[];
    final categoryB = <ABCItem>[];
    final categoryC = <ABCItem>[];

    double cumulativeRevenue = 0;
    int rank = 1;

    for (final product in sortedProducts) {
      cumulativeRevenue += product.totalRevenue;
      final revenuePercentage = (product.totalRevenue / totalRevenue) * 100;
      final cumulativePercentage = (cumulativeRevenue / totalRevenue) * 100;

      String category;
      String recommendation;

      if (cumulativePercentage <= 80) {
        category = 'A';
        recommendation =
            'High priority - maintain optimal stock levels, frequent monitoring';
      } else if (cumulativePercentage <= 95) {
        category = 'B';
        recommendation =
            'Medium priority - regular stock reviews, moderate inventory';
      } else {
        category = 'C';
        recommendation =
            'Low priority - minimize stock, consider discontinuation';
      }

      final abcItem = ABCItem(
        itemId: product.productId,
        itemName: product.productName,
        revenue: product.totalRevenue,
        quantity: product.unitsSold,
        revenuePercentage: revenuePercentage,
        cumulativeRank: rank,
        category: category,
        recommendedAction: recommendation,
      );

      if (category == 'A') {
        categoryA.add(abcItem);
      } else if (category == 'B') {
        categoryB.add(abcItem);
      } else {
        categoryC.add(abcItem);
      }

      rank++;
    }

    return ABCAnalysisReport(
      id: _uuid.v4(),
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      categoryA: categoryA,
      categoryB: categoryB,
      categoryC: categoryC,
      totalRevenue: totalRevenue,
      totalItems: totalItems,
    );
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

  // ==================== ADVANCED VISUALIZATIONS ====================

  /// Get data formatted for specific chart types
  Map<String, dynamic> getChartData(
    dynamic report,
    String chartType, {
    String? metricName,
  }) {
    switch (chartType) {
      case 'line':
        return _getLineChartData(report, metricName);
      case 'bar':
        return _getBarChartData(report, metricName);
      case 'pie':
        return _getPieChartData(report);
      case 'scatter':
        return _getScatterChartData(report);
      case 'heatmap':
        return _getHeatmapData(report);
      default:
        return {};
    }
  }

  Map<String, dynamic> _getLineChartData(dynamic report, String? metricName) {
    // Extract time-series data for line charts
    return {'labels': [], 'datasets': []};
  }

  Map<String, dynamic> _getBarChartData(dynamic report, String? metricName) {
    // Extract categorical data for bar charts
    return {'labels': [], 'values': []};
  }

  Map<String, dynamic> _getPieChartData(dynamic report) {
    // Extract percentage data for pie charts
    return {'labels': [], 'values': []};
  }

  Map<String, dynamic> _getScatterChartData(dynamic report) {
    // Extract correlation data for scatter plots
    return {'points': []};
  }

  Map<String, dynamic> _getHeatmapData(dynamic report) {
    // Extract grid data for heatmaps (e.g., hourly sales by day)
    return {'xLabels': [], 'yLabels': [], 'values': []};
  }

  // ==================== REPORT INSIGHTS & RECOMMENDATIONS ====================

  /// Analyze report and generate insights
  Future<List<ReportInsight>> generateInsights(dynamic report) async {
    final insights = <ReportInsight>[];

    // Analyze trends
    // Detect anomalies
    // Generate recommendations

    return insights;
  }

  // ==================== EMAIL DELIVERY ====================

  /// Execute scheduled report and send via email
  Future<bool> executeScheduledReport(ScheduledReport report) async {
    try {
      final emailService = EmailTemplateService.instance;
      final businessInfo = BusinessInfo.instance;

      // Check if business email is configured
      if (businessInfo.email.isEmpty) {
        print('Cannot send report: Business email not configured');
        return false;
      }

      // Generate report data based on type
      final reportData = await _generateReportData(
        report.reportType,
        report.period,
      );

      // Generate export files if formats specified
      List<String> attachmentFilenames = [];
      if (report.exportFormats.isNotEmpty) {
        // Note: Export functionality can be added when needed
        // For now, reports are sent as HTML email only
        attachmentFilenames = report.exportFormats.map((format) {
          return '${report.name}_${_formatDate(DateTime.now())}.${format.toString().split('.').last.toLowerCase()}';
        }).toList();
      }

      // Generate HTML email
      final htmlBody = emailService.generateScheduledReportEmail(
        reportType: report.reportType.toString().split('.').last,
        reportName: report.name,
        period: report.period,
        reportData: reportData,
        attachmentFilenames: attachmentFilenames,
      );

      // Send email to all recipients using SMTP
      bool allSucceeded = true;
      for (final recipient in report.recipientEmails) {
        final success = await _sendEmailViaSMTP(
          from: businessInfo.email,
          to: recipient,
          subject: '${report.name} - ${report.period.label}',
          htmlBody: htmlBody,
        );

        if (!success) {
          allSucceeded = false;
          print('Failed to send email to $recipient');
        }
      }

      // Update next run time and last run time
      final updatedReport = report.copyWith(
        lastRun: DateTime.now(),
        nextRun: _calculateNextRun(DateTime.now(), report.frequency),
      );
      await updateScheduledReport(updatedReport);

      return allSucceeded;
    } catch (e) {
      print('Error executing scheduled report: $e');
      return false;
    }
  }

  /// Send email via SMTP (using generic SMTP server)
  Future<bool> _sendEmailViaSMTP({
    required String from,
    required String to,
    required String subject,
    required String htmlBody,
  }) async {
    try {
      // Get business info for SMTP configuration
      final businessInfo = BusinessInfo.instance;

      // SMTP configuration from BusinessInfo
      final smtpServer = SmtpServer(
        businessInfo.smtpHost ?? 'smtp.gmail.com',
        port: businessInfo.smtpPort ?? 587,
        username: businessInfo.smtpUsername ?? from,
        password: businessInfo.smtpPassword ?? '',
        ignoreBadCertificate: false,
        ssl: businessInfo.smtpUseSsl ?? false,
        allowInsecure: true,
      );

      // Create message
      final message = Message()
        ..from = Address(from, BusinessInfo.instance.businessName)
        ..recipients.add(to)
        ..subject = subject
        ..html = htmlBody;

      // Send message
      final sendReport = await send(message, smtpServer);
      print('Email sent: ${sendReport.toString()}');
      return true;
    } catch (e) {
      print('Error sending email via SMTP: $e');
      return false;
    }
  }

  /// Format date for filename
  String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  /// Generate report data based on report type
  Future<Map<String, dynamic>> _generateReportData(
    ReportType reportType,
    ReportPeriod period,
  ) async {
    // This is a placeholder - in production, this would query actual sales data
    // from the database based on the period
    switch (reportType) {
      case ReportType.salesSummary:
        return {
          'totalSales': 1234.56,
          'transactionCount': 45,
          'taxAmount': 123.45,
        };
      case ReportType.productSales:
        return {
          'topProducts': [
            {'name': 'Product A', 'quantity': 10, 'revenue': 100.0},
            {'name': 'Product B', 'quantity': 8, 'revenue': 80.0},
          ],
        };
      case ReportType.employeePerformance:
        return {
          'employees': [
            {'name': 'John', 'totalSales': 500.0, 'transactionCount': 20},
            {'name': 'Jane', 'totalSales': 450.0, 'transactionCount': 18},
          ],
        };
      case ReportType.profitLoss:
        return {'revenue': 1000.0, 'costs': 600.0};
      default:
        return {};
    }
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
