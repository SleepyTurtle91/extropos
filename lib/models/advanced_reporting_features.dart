import 'package:extropos/models/sales_report.dart' show ReportPeriod;

/// Scheduled report configuration
class ScheduledReport {
  final String id;
  final String name;
  final ReportType reportType;
  final ReportPeriod period;
  final ScheduleFrequency frequency;
  final List<String> recipientEmails;
  final List<ExportFormat> exportFormats;
  final bool isActive;
  final DateTime? nextRun;
  final DateTime? lastRun;
  final Map<String, dynamic>? customFilters;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduledReport({
    required this.id,
    required this.name,
    required this.reportType,
    required this.period,
    required this.frequency,
    required this.recipientEmails,
    required this.exportFormats,
    this.isActive = true,
    this.nextRun,
    this.lastRun,
    this.customFilters,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  ScheduledReport copyWith({
    String? name,
    ReportType? reportType,
    ReportPeriod? period,
    ScheduleFrequency? frequency,
    List<String>? recipientEmails,
    List<ExportFormat>? exportFormats,
    bool? isActive,
    DateTime? nextRun,
    DateTime? lastRun,
    Map<String, dynamic>? customFilters,
  }) {
    return ScheduledReport(
      id: id,
      name: name ?? this.name,
      reportType: reportType ?? this.reportType,
      period: period ?? this.period,
      frequency: frequency ?? this.frequency,
      recipientEmails: recipientEmails ?? this.recipientEmails,
      exportFormats: exportFormats ?? this.exportFormats,
      isActive: isActive ?? this.isActive,
      nextRun: nextRun ?? this.nextRun,
      lastRun: lastRun ?? this.lastRun,
      customFilters: customFilters ?? this.customFilters,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'report_type': reportType.toString(),
      'period': period.toString(),
      'frequency': frequency.toString(),
      'recipient_emails': recipientEmails.join(','),
      'export_formats': exportFormats.map((e) => e.toString()).join(','),
      'is_active': isActive ? 1 : 0,
      'next_run': nextRun?.toIso8601String(),
      'last_run': lastRun?.toIso8601String(),
      'custom_filters': customFilters.toString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ScheduledReport.fromJson(Map<String, dynamic> json) {
    return ScheduledReport(
      id: json['id'] as String,
      name: json['name'] as String,
      reportType: ReportType.values.firstWhere(
        (e) => e.toString() == json['report_type'],
        orElse: () => ReportType.salesSummary,
      ),
      period: ReportPeriod.today(), // Parse from JSON
      frequency: ScheduleFrequency.values.firstWhere(
        (e) => e.toString() == json['frequency'],
        orElse: () => ScheduleFrequency.daily,
      ),
      recipientEmails: (json['recipient_emails'] as String).split(','),
      exportFormats: (json['export_formats'] as String)
          .split(',')
          .map(
            (e) => ExportFormat.values.firstWhere(
              (format) => format.toString() == e,
              orElse: () => ExportFormat.csv,
            ),
          )
          .toList(),
      isActive: json['is_active'] == 1,
      nextRun: json['next_run'] != null
          ? DateTime.parse(json['next_run'] as String)
          : null,
      lastRun: json['last_run'] != null
          ? DateTime.parse(json['last_run'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

enum ScheduleFrequency { hourly, daily, weekly, monthly, quarterly, yearly }

enum ExportFormat { csv, pdf, excel, json }

enum ReportType {
  salesSummary,
  productSales,
  categorySales,
  paymentMethod,
  employeePerformance,
  inventory,
  shrinkage,
  laborCost,
  customerAnalysis,
  basketAnalysis,
  loyaltyProgram,
  profitLoss, // NEW
  cashFlow, // NEW
  taxSummary, // NEW
  inventoryValuation, // NEW
  abcAnalysis, // NEW
  demandForecasting, // NEW
}

/// Comparative analysis data
class ComparativeAnalysis {
  final String id;
  final DateTime generatedAt;
  final ReportPeriod currentPeriod;
  final ReportPeriod comparisonPeriod;
  final Map<String, PeriodComparison> metrics;

  ComparativeAnalysis({
    required this.id,
    required this.generatedAt,
    required this.currentPeriod,
    required this.comparisonPeriod,
    required this.metrics,
  });

  double getChangePercentage(String metricName) {
    final comparison = metrics[metricName];
    if (comparison == null) return 0.0;
    return comparison.changePercentage;
  }

  bool isImprovement(String metricName) {
    return getChangePercentage(metricName) > 0;
  }
}

class PeriodComparison {
  final String metricName;
  final double currentValue;
  final double previousValue;
  final double difference;
  final double changePercentage;
  final String trend; // 'up', 'down', 'stable'

  PeriodComparison({
    required this.metricName,
    required this.currentValue,
    required this.previousValue,
  }) : difference = currentValue - previousValue,
       changePercentage = previousValue != 0
           ? ((currentValue - previousValue) / previousValue) * 100
           : 0,
       trend = currentValue > previousValue
           ? 'up'
           : currentValue < previousValue
           ? 'down'
           : 'stable';

  bool get isPositive => changePercentage > 0;
  bool get isNegative => changePercentage < 0;
  bool get isStable => changePercentage.abs() < 1.0;

  /// Returns true if the change is an improvement (increase is better for most metrics)
  bool get isImprovement => difference > 0;
}

/// Sales forecasting model
class SalesForecast {
  final String id;
  final DateTime generatedAt;
  final DateTime forecastStartDate;
  final DateTime forecastEndDate;
  final List<ForecastDataPoint> dailyForecasts;
  final double totalForecastedSales;
  final double confidenceInterval; // ±% confidence
  final String forecastMethod; // 'linear', 'exponential', 'seasonal'
  final Map<String, dynamic> modelParameters;

  SalesForecast({
    required this.id,
    required this.generatedAt,
    required this.forecastStartDate,
    required this.forecastEndDate,
    required this.dailyForecasts,
    required this.totalForecastedSales,
    required this.confidenceInterval,
    required this.forecastMethod,
    required this.modelParameters,
  });

  double getForecastForDate(DateTime date) {
    final forecast = dailyForecasts.firstWhere(
      (f) =>
          f.date.year == date.year &&
          f.date.month == date.month &&
          f.date.day == date.day,
      orElse: () => ForecastDataPoint(
        date: date,
        forecastedValue: 0,
        lowerBound: 0,
        upperBound: 0,
      ),
    );
    return forecast.forecastedValue;
  }
}

class ForecastDataPoint {
  final DateTime date;
  final double forecastedValue;
  final double lowerBound;
  final double upperBound;
  final double? actualValue; // For comparing forecasts to actuals

  ForecastDataPoint({
    required this.date,
    required this.forecastedValue,
    required this.lowerBound,
    required this.upperBound,
    this.actualValue,
  });

  double get accuracy {
    if (actualValue == null || forecastedValue == 0) return 0;
    return 100 -
        ((actualValue! - forecastedValue).abs() / forecastedValue * 100);
  }
}

/// ABC Analysis for inventory optimization
class ABCAnalysisReport {
  final String id;
  final DateTime generatedAt;
  final DateTime startDate;
  final DateTime endDate;
  final List<ABCItem> categoryA; // High value (80% revenue, 20% items)
  final List<ABCItem> categoryB; // Medium value
  final List<ABCItem> categoryC; // Low value (20% revenue, 80% items)
  final double totalRevenue;
  final int totalItems;

  ABCAnalysisReport({
    required this.id,
    required this.generatedAt,
    required this.startDate,
    required this.endDate,
    required this.categoryA,
    required this.categoryB,
    required this.categoryC,
    required this.totalRevenue,
    required this.totalItems,
  });

  double get categoryARevenue =>
      categoryA.fold(0.0, (sum, item) => sum + item.revenue);
  double get categoryBRevenue =>
      categoryB.fold(0.0, (sum, item) => sum + item.revenue);
  double get categoryCRevenue =>
      categoryC.fold(0.0, (sum, item) => sum + item.revenue);

  double get categoryAPercentage => (categoryARevenue / totalRevenue) * 100;
  double get categoryBPercentage => (categoryBRevenue / totalRevenue) * 100;
  double get categoryCPercentage => (categoryCRevenue / totalRevenue) * 100;
}

class ABCItem {
  final String itemId;
  final String itemName;
  final double revenue;
  final int quantity;
  final double revenuePercentage;
  final int cumulativeRank;
  final String category; // 'A', 'B', or 'C'
  final String recommendedAction; // Stocking recommendations

  ABCItem({
    required this.itemId,
    required this.itemName,
    required this.revenue,
    required this.quantity,
    required this.revenuePercentage,
    required this.cumulativeRank,
    required this.category,
    required this.recommendedAction,
  });
}

/// Custom report template
class CustomReportTemplate {
  final String id;
  final String name;
  final String description;
  final List<ReportMetric> selectedMetrics;
  final List<ReportGroupBy> groupByFields;
  final List<ReportFilter> filters;
  final List<ReportSort> sorting;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final bool isShared; // Share with other users

  CustomReportTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.selectedMetrics,
    required this.groupByFields,
    required this.filters,
    required this.sorting,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.createdBy,
    this.isShared = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
}

class ReportMetric {
  final String fieldName;
  final String displayName;
  final AggregationType aggregation; // sum, avg, count, min, max
  final String? format; // currency, percentage, number, date

  ReportMetric({
    required this.fieldName,
    required this.displayName,
    required this.aggregation,
    this.format,
  });
}

enum AggregationType { sum, average, count, min, max, median, distinct }

class ReportGroupBy {
  final String fieldName;
  final String displayName;
  final GroupByInterval? interval; // For date fields

  ReportGroupBy({
    required this.fieldName,
    required this.displayName,
    this.interval,
  });
}

enum GroupByInterval { hourly, daily, weekly, monthly, quarterly, yearly }

class ReportFilter {
  final String fieldName;
  final FilterOperator operator;
  final dynamic value;
  final dynamic value2; // For BETWEEN operator

  ReportFilter({
    required this.fieldName,
    required this.operator,
    required this.value,
    this.value2,
  });
}

enum FilterOperator {
  equals,
  notEquals,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
  between,
  contains,
  startsWith,
  endsWith,
  isNull,
  isNotNull,
  inList,
}

class ReportSort {
  final String fieldName;
  final SortDirection direction;

  ReportSort({required this.fieldName, required this.direction});
}

enum SortDirection { ascending, descending }
