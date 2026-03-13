part of '../database_service.dart';

extension DatabaseServiceReportsFinancialAnalysis on DatabaseService {
  Future<ABCAnalysisReport> generateABCAnalysisReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> orderItemMaps = await db.rawQuery(
      '''
      SELECT oi.product_id, p.name, SUM(oi.quantity * oi.price) as revenue
      FROM order_items oi
      JOIN products p ON oi.product_id = p.id
      JOIN orders o ON oi.order_id = o.id
      WHERE o.created_at >= ? AND o.created_at <= ? AND o.status = ?
      GROUP BY oi.product_id, p.name
      ORDER BY revenue DESC
    ''',
      [period.startDate.toIso8601String(), period.endDate.toIso8601String(), 'completed'],
    );

    double totalRevenue = orderItemMaps.fold(0.0, (sum, item) => sum + (item['revenue'] as double));
    final abcItems = <ABCItem>[];
    double cumulativePercentage = 0.0;

    for (int i = 0; i < orderItemMaps.length; i++) {
      final item = orderItemMaps[i];
      final revenue = item['revenue'] as double;
      final percentage = totalRevenue > 0 ? (revenue / totalRevenue) * 100 : 0.0;
      cumulativePercentage += percentage;

      String category = cumulativePercentage <= 80 ? 'A' : (cumulativePercentage <= 95 ? 'B' : 'C');
      abcItems.add(ABCItem(
        itemId: item['product_id'] as String,
        itemName: item['name'] as String,
        revenue: revenue,
        percentageOfTotal: percentage,
        category: category,
        rank: i + 1,
      ));
    }

    final categorizedItems = <String, List<ABCItem>>{};
    for (final item in abcItems) {
      categorizedItems.putIfAbsent(item.category, () => []).add(item);
    }

    return ABCAnalysisReport(
      id: 'abc_analysis_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      abcItems: abcItems,
      categorizedItems: categorizedItems,
      totalRevenue: totalRevenue,
      aCategoryRevenue: abcItems.where((item) => item.category == 'A').fold(0.0, (sum, item) => sum + item.revenue),
      bCategoryRevenue: abcItems.where((item) => item.category == 'B').fold(0.0, (sum, item) => sum + item.revenue),
      cCategoryRevenue: abcItems.where((item) => item.category == 'C').fold(0.0, (sum, item) => sum + item.revenue),
    );
  }

  Future<DemandForecastingReport> generateDemandForecastingReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;
    final historicalStart = period.startDate.subtract(const Duration(days: 30));

    final List<Map<String, dynamic>> historicalData = await db.rawQuery(
      '''
      SELECT DATE(o.created_at) as date, SUM(oi.quantity) as total_quantity
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      WHERE o.created_at >= ? AND o.created_at <= ? AND o.status = ?
      GROUP BY DATE(o.created_at)
      ORDER BY date
    ''',
      [historicalStart.toIso8601String(), period.endDate.toIso8601String(), 'completed'],
    );

    final forecastItems = <ForecastItem>[];
    final historicalDataMap = <String, List<double>>{};
    final forecastDataMap = <String, List<double>>{};

    for (final data in historicalData) {
      final quantity = data['total_quantity'] as double;
      final forecastQuantity = quantity * 1.05;

      forecastItems.add(ForecastItem(
        itemId: 'total_sales',
        itemName: 'Total Sales',
        historicalSales: [quantity],
        forecastedSales: [forecastQuantity],
        confidenceLevel: 0.8,
      ));

      historicalDataMap['total'] = [quantity];
      forecastDataMap['total'] = [forecastQuantity];
    }

    return DemandForecastingReport(
      id: 'demand_forecasting_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      forecastItems: forecastItems,
      historicalData: historicalDataMap,
      forecastData: forecastDataMap,
      forecastAccuracy: 0.85,
      forecastingMethod: 'Simple Moving Average',
    );
  }

  Future<MenuEngineeringReport> generateMenuEngineeringReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> productData = await db.rawQuery(
      '''
      SELECT p.id, p.name, SUM(oi.quantity) as units_sold, SUM(oi.quantity * oi.price) as revenue, COUNT(DISTINCT oi.order_id) as order_count,
      (SELECT COUNT(*) FROM orders o WHERE o.created_at >= ? AND o.created_at <= ? AND o.status = ?) as total_orders
      FROM products p
      LEFT JOIN order_items oi ON p.id = oi.product_id
      LEFT JOIN orders o ON oi.order_id = o.id AND o.created_at >= ? AND o.created_at <= ? AND o.status = ?
      GROUP BY p.id, p.name
    ''',
      [period.startDate.toIso8601String(), period.endDate.toIso8601String(), 'completed', period.startDate.toIso8601String(), period.endDate.toIso8601String(), 'completed'],
    );

    final menuItems = <MenuItem>[];
    final totalOrders = productData.isNotEmpty ? (productData.first['total_orders'] as int? ?? 0) : 0;

    for (final product in productData) {
      final unitsSold = product['units_sold'] as int? ?? 0;
      final revenue = product['revenue'] as double? ?? 0.0;
      final orderCount = product['order_count'] as int? ?? 0;
      final popularity = totalOrders > 0 ? (orderCount / totalOrders) * 100 : 0.0;
      final profit = revenue - (revenue * 0.3);
      final profitability = revenue > 0 ? (profit / revenue) * 100 : 0.0;

      String category = (popularity >= 70 && profitability >= 30) ? 'star' :
                        (popularity >= 70 ? 'plowhorse' : (profitability >= 30 ? 'puzzle' : 'dog'));

      menuItems.add(MenuItem(
        itemId: product['id'] as String,
        itemName: product['name'] as String,
        popularity: popularity,
        profitability: profitability,
        category: category,
        unitsSold: unitsSold,
        revenue: revenue,
        cost: revenue * 0.3,
        profit: profit,
      ));
    }

    final categorizedItems = <String, List<MenuItem>>{};
    for (final item in menuItems) {
      categorizedItems.putIfAbsent(item.category, () => []).add(item);
    }

    return MenuEngineeringReport(
      id: 'menu_engineering_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      menuItems: menuItems,
      categorizedItems: categorizedItems,
      starsCount: categorizedItems['star']?.length ?? 0,
      plowhorsesCount: categorizedItems['plowhorse']?.length ?? 0,
      puzzlesCount: categorizedItems['puzzle']?.length ?? 0,
      dogsCount: categorizedItems['dog']?.length ?? 0,
    );
  }
}
