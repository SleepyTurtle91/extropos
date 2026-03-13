part of 'advanced_reporting_service.dart';

extension AdvancedReportingServiceAnalysis on AdvancedReportingService {
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
}
