part of '../database_service.dart';

extension DatabaseServiceReportsAdvanced on DatabaseService {
  Future<SalesSummaryReport> generateSalesSummaryReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> orderMaps = await db.query(
      'orders',
      where: 'created_at >= ? AND created_at <= ? AND status = ?',
      whereArgs: [
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
        'completed',
      ],
    );

    double grossSales = 0.0;
    double totalDiscounts = 0.0;
    double totalRefunds = 0.0;
    double taxCollected = 0.0;
    int totalTransactions = orderMaps.length;
    Map<String, double> taxBreakdown = {};
    Map<String, double> hourlySales = {};
    Map<String, double> dailySales = {};

    for (final orderMap in orderMaps) {
      final createdAt = DateTime.parse(orderMap['created_at'] as String);
      final subtotal = orderMap['subtotal'] as double;
      final tax = orderMap['tax'] as double;
      final discount = orderMap['discount'] as double? ?? 0.0;

      grossSales += subtotal + tax;
      totalDiscounts += discount;
      taxCollected += tax;

      final hour = createdAt.hour;
      hourlySales[hour.toString()] =
          (hourlySales[hour.toString()] ?? 0.0) + (subtotal + tax);

      final dayKey = createdAt.toIso8601String().substring(0, 10);
      dailySales[dayKey] = (dailySales[dayKey] ?? 0.0) + (subtotal + tax);

      if (tax > 0) {
        final taxRate = (tax / subtotal * 100).round();
        final taxKey = '${taxRate.toStringAsFixed(1)}%';
        taxBreakdown[taxKey] = (taxBreakdown[taxKey] ?? 0.0) + tax;
      }
    }

    final netSales = grossSales - totalDiscounts - totalRefunds;
    final averageTransactionValue =
        totalTransactions > 0 ? grossSales / totalTransactions : 0.0;

    return SalesSummaryReport(
      id: 'sales_summary_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      grossSales: grossSales,
      netSales: netSales,
      totalDiscounts: totalDiscounts,
      totalRefunds: totalRefunds,
      taxCollected: taxCollected,
      averageTransactionValue: averageTransactionValue,
      totalTransactions: totalTransactions,
      taxBreakdown: taxBreakdown,
      hourlySales: hourlySales,
      dailySales: dailySales,
    );
  }

  Future<ProductSalesReport> generateProductSalesReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final query = '''
      SELECT
        oi.item_id,
        i.name as item_name,
        c.name as category_name,
        SUM(oi.quantity) as units_sold,
        SUM(oi.subtotal) as total_revenue,
        AVG(oi.item_price) as average_price
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      JOIN items i ON oi.item_id = i.id
      LEFT JOIN categories c ON i.category_id = c.id
      WHERE o.created_at >= ? AND o.created_at <= ? AND o.status = 'completed'
      GROUP BY oi.item_id, i.name, c.name
      ORDER BY total_revenue DESC
    ''';

    final results = await db.rawQuery(query, [
      period.startDate.toIso8601String(),
      period.endDate.toIso8601String(),
    ]);

    final productSales = results
        .map(
          (row) => ProductSalesData(
            productId: row['item_id'] as String,
            productName: row['item_name'] as String,
            category: row['category_name'] as String? ?? 'Uncategorized',
            unitsSold: row['units_sold'] as int,
            totalRevenue: row['total_revenue'] as double,
            averagePrice: row['average_price'] as double,
          ),
        )
        .toList();

    final topSellingProducts = <String, int>{};
    final worstSellingProducts = <String, double>{};

    for (final product in productSales) {
      if (topSellingProducts.length < 10) {
        topSellingProducts[product.productName] = product.unitsSold;
      }
      worstSellingProducts[product.productName] = product.totalRevenue;
    }

    final sortedWorst = worstSellingProducts.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final worstSellingMap = Map.fromEntries(sortedWorst.take(10));

    final totalUnitsSold = productSales.fold<int>(
      0,
      (sum, p) => sum + p.unitsSold,
    );
    final totalRevenue = productSales.fold<double>(
      0.0,
      (sum, p) => sum + p.totalRevenue,
    );

    return ProductSalesReport(
      id: 'product_sales_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      productSales: productSales,
      topSellingProducts: topSellingProducts,
      worstSellingProducts: worstSellingMap,
      totalUnitsSold: totalUnitsSold.toDouble(),
      totalRevenue: totalRevenue,
    );
  }

  Future<CategorySalesReport> generateCategorySalesReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final query = '''
      SELECT
        c.id as category_id,
        c.name as category_name,
        SUM(oi.subtotal) as revenue,
        COUNT(DISTINCT o.id) as transaction_count,
        AVG(o.total) as average_transaction
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      JOIN items i ON oi.item_id = i.id
      JOIN categories c ON i.category_id = c.id
      WHERE o.created_at >= ? AND o.created_at <= ? AND o.status = 'completed'
      GROUP BY c.id, c.name
      ORDER BY revenue DESC
    ''';

    final results = await db.rawQuery(query, [
      period.startDate.toIso8601String(),
      period.endDate.toIso8601String(),
    ]);

    final categorySales = <String, CategorySalesData>{};
    String topPerformingCategory = '';
    String lowestPerformingCategory = '';
    double maxRevenue = 0.0;
    double minRevenue = double.infinity;

    for (final row in results) {
      final categoryId = row['category_id'] as String;
      final categoryName = row['category_name'] as String;
      final revenue = row['revenue'] as double;
      final transactionCount = row['transaction_count'] as int;
      final averageTransaction = row['average_transaction'] as double;

      final topProductsQuery = '''
        SELECT i.name, SUM(oi.quantity) as qty
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.id
        JOIN items i ON oi.item_id = i.id
        WHERE o.created_at >= ? AND o.created_at <= ? AND o.status = 'completed'
        AND i.category_id = ?
        GROUP BY i.name
        ORDER BY qty DESC
        LIMIT 5
      ''';

      final topProductsResults = await db.rawQuery(topProductsQuery, [
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
        categoryId,
      ]);

      final topProducts = <String, int>{};
      for (final productRow in topProductsResults) {
        topProducts[productRow['name'] as String] = productRow['qty'] as int;
      }

      final categoryData = CategorySalesData(
        categoryId: categoryId,
        categoryName: categoryName,
        revenue: revenue,
        grossProfit: revenue * 0.3,
        transactionCount: transactionCount,
        averageTransactionValue: averageTransaction,
        topProducts: topProducts,
      );

      categorySales[categoryName] = categoryData;

      if (revenue > maxRevenue) {
        maxRevenue = revenue;
        topPerformingCategory = categoryName;
      }
      if (revenue < minRevenue) {
        minRevenue = revenue;
        lowestPerformingCategory = categoryName;
      }
    }

    return CategorySalesReport(
      id: 'category_sales_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      categorySales: categorySales,
      topPerformingCategory: topPerformingCategory,
      lowestPerformingCategory: lowestPerformingCategory,
    );
  }

  Future<PaymentMethodReport> generatePaymentMethodReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final query = '''
      SELECT
        pm.name as method_name,
        SUM(o.total) as total_amount,
        COUNT(o.id) as transaction_count
      FROM orders o
      LEFT JOIN payment_methods pm ON o.payment_method_id = pm.id
      WHERE o.created_at >= ? AND o.created_at <= ? AND o.status = 'completed'
      GROUP BY pm.id, pm.name
      ORDER BY total_amount DESC
    ''';

    final results = await db.rawQuery(query, [
      period.startDate.toIso8601String(),
      period.endDate.toIso8601String(),
    ]);

    final paymentBreakdown = <String, PaymentMethodData>{};
    double totalProcessed = 0.0;
    String mostUsedMethod = '';
    String highestRevenueMethod = '';
    int maxTransactions = 0;
    double maxRevenue = 0.0;

    for (final row in results) {
      final methodName = row['method_name'] as String? ?? 'Cash';
      final totalAmount = row['total_amount'] as double;
      final transactionCount = row['transaction_count'] as int;

      totalProcessed += totalAmount;

      final paymentData = PaymentMethodData(
        methodId: methodName.toLowerCase().replaceAll(' ', '_'),
        methodName: methodName,
        totalAmount: totalAmount,
        transactionCount: transactionCount,
        averageTransaction: transactionCount > 0
            ? totalAmount / transactionCount
            : 0.0,
        percentageOfTotal: 0.0,
      );

      paymentBreakdown[methodName] = paymentData;

      if (transactionCount > maxTransactions) {
        maxTransactions = transactionCount;
        mostUsedMethod = methodName;
      }
      if (totalAmount > maxRevenue) {
        maxRevenue = totalAmount;
        highestRevenueMethod = methodName;
      }
    }

    paymentBreakdown.forEach((key, data) {
      paymentBreakdown[key] = PaymentMethodData(
        methodId: data.methodId,
        methodName: data.methodName,
        totalAmount: data.totalAmount,
        transactionCount: data.transactionCount,
        averageTransaction: data.averageTransaction,
        percentageOfTotal: totalProcessed > 0
            ? (data.totalAmount / totalProcessed) * 100
            : 0.0,
      );
    });

    return PaymentMethodReport(
      id: 'payment_method_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      paymentBreakdown: paymentBreakdown,
      mostUsedMethod: mostUsedMethod,
      highestRevenueMethod: highestRevenueMethod,
      totalProcessed: totalProcessed,
    );
  }

  Future<EmployeePerformanceReport> generateEmployeePerformanceReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final query = '''
      SELECT
        u.id as employee_id,
        u.name as employee_name,
        COUNT(o.id) as transaction_count,
        SUM(o.total) as total_sales,
        AVG(o.total) as average_transaction,
        SUM(o.discount) as total_discounts
      FROM orders o
      JOIN users u ON o.user_id = u.id
      WHERE o.created_at >= ? AND o.created_at <= ? AND o.status = 'completed'
      GROUP BY u.id, u.name
      ORDER BY total_sales DESC
    ''';

    final results = await db.rawQuery(query, [
      period.startDate.toIso8601String(),
      period.endDate.toIso8601String(),
    ]);

    final employeePerformance = <EmployeeData>[];
    String topPerformer = '';
    String needsImprovement = '';
    double maxSales = 0.0;
    double minSales = double.infinity;

    for (final row in results) {
      final employeeId = row['employee_id'] as String;
      final employeeName = row['employee_name'] as String;
      final transactionCount = row['transaction_count'] as int;
      final totalSales = row['total_sales'] as double;
      final averageTransaction = row['average_transaction'] as double;
      final totalDiscounts = row['total_discounts'] as double;

      final employeeData = EmployeeData(
        employeeId: employeeId,
        employeeName: employeeName,
        totalSales: totalSales,
        transactionCount: transactionCount,
        averageTransactionValue: averageTransaction,
        totalDiscountsGiven: totalDiscounts,
        tipsAccrued: 0.0,
        laborCostPercentage: 0.0,
        hoursWorked: 0,
        voidedTransactions: {},
        refundsProcessed: {},
      );

      employeePerformance.add(employeeData);

      if (totalSales > maxSales) {
        maxSales = totalSales;
        topPerformer = employeeName;
      }
      if (totalSales < minSales) {
        minSales = totalSales;
        needsImprovement = employeeName;
      }
    }

    return EmployeePerformanceReport(
      id: 'employee_performance_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      employeePerformance: employeePerformance,
      departmentPerformance: {},
      topPerformer: topPerformer,
      needsImprovement: needsImprovement,
    );
  }

  Future<InventoryReport> generateInventoryReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;

    final query = '''
      SELECT
        i.id,
        i.name,
        i.price,
        i.cost_price,
        COALESCE(i.stock_quantity, 0) as stock_quantity,
        COALESCE(i.min_stock_level, 0) as min_stock_level,
        COALESCE(i.max_stock_level, 0) as max_stock_level,
        c.name as category_name,
        COALESCE(SUM(oi.quantity), 0) as units_sold,
        COALESCE(SUM(oi.quantity * oi.price), 0) as revenue,
        COALESCE(AVG(oi.price), 0) as avg_selling_price,
        COUNT(DISTINCT o.id) as order_count,
        MAX(o.created_at) as last_sale_date
      FROM items i
      LEFT JOIN categories c ON i.category_id = c.id
      LEFT JOIN order_items oi ON i.id = oi.item_id
      LEFT JOIN orders o ON oi.order_id = o.id AND o.created_at BETWEEN ? AND ?
      WHERE i.is_active = 1
      GROUP BY i.id, i.name, i.price, i.cost_price, i.stock_quantity, i.min_stock_level, i.max_stock_level, c.name
      ORDER BY units_sold DESC
    ''';

    final results = await db.rawQuery(query, [
      period.startDate.toIso8601String(),
      period.endDate.toIso8601String(),
    ]);

    final inventoryItems = <InventoryItemData>[];
    double totalValue = 0;
    final stockValueByCategory = <String, double>{};
    final lowStockItems = <String>[];
    final outOfStockItems = <String>[];

    for (final row in results) {
      final stockQuantity = (row['stock_quantity'] as int?) ?? 0;
      final minStock = (row['min_stock_level'] as int?) ?? 0;
      final maxStock = (row['max_stock_level'] as int?) ?? 0;
      final costPrice = (row['cost_price'] as double?) ?? 0.0;
      final unitsSold = (row['units_sold'] as int?) ?? 0;
      final revenue = (row['revenue'] as double?) ?? 0.0;
      final lastSaleDate = row['last_sale_date'] != null
          ? DateTime.parse(row['last_sale_date'] as String)
          : null;
      final daysSinceLastSale = lastSaleDate != null
          ? DateTime.now().difference(lastSaleDate).inDays
          : 999;
      final category = (row['category_name'] as String?) ?? 'Uncategorized';

      final stockStatus = _calculateStockStatus(
        stockQuantity,
        minStock,
        maxStock,
      );

      final inventoryItem = InventoryItemData(
        itemId: row['id'].toString(),
        itemName: row['name'] as String,
        category: category,
        currentStock: stockQuantity,
        reorderPoint: minStock,
        costOfGoodsSold: costPrice * unitsSold,
        grossMarginReturnOnInvestment: revenue > 0
            ? ((revenue - (costPrice * unitsSold)) / revenue) * 100
            : 0.0,
        daysSinceLastSale: daysSinceLastSale,
        stockStatus: stockStatus,
      );

      inventoryItems.add(inventoryItem);
      final itemValue = stockQuantity * ((row['price'] as double?) ?? 0.0);
      totalValue += itemValue;
      stockValueByCategory[category] =
          (stockValueByCategory[category] ?? 0.0) + itemValue;

      if (stockStatus == 'out_of_stock') {
        outOfStockItems.add(row['name'] as String);
      } else if (stockStatus == 'low_stock') {
        lowStockItems.add(row['name'] as String);
      }
    }

    return InventoryReport(
      id: 'inventory_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      inventoryItems: inventoryItems,
      stockValueByCategory: stockValueByCategory,
      lowStockItems: lowStockItems,
      outOfStockItems: outOfStockItems,
      totalInventoryValue: totalValue,
      inventoryTurnoverRate: 0.0,
    );
  }

  Future<ShrinkageReport> generateShrinkageReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;

    final shrinkageData = <ShrinkageData>[];

    final adjustmentQuery = '''
      SELECT
        i.name as item_name,
        i.id as item_id,
        COALESCE(SUM(ia.quantity_change), 0) as total_adjustments,
        COUNT(ia.id) as adjustment_count,
        ia.reason,
        ia.created_at
      FROM items i
      LEFT JOIN inventory_adjustments ia ON i.id = ia.item_id
        AND ia.created_at BETWEEN ? AND ?
      WHERE i.is_active = 1
      GROUP BY i.id, i.name, ia.reason
      HAVING total_adjustments < 0
      ORDER BY ABS(total_adjustments) DESC
    ''';

    final adjustmentResults = await db.rawQuery(adjustmentQuery, [
      period.startDate.toIso8601String(),
      period.endDate.toIso8601String(),
    ]);

    double totalShrinkageValue = 0;

    for (final row in adjustmentResults) {
      final adjustments = (row['total_adjustments'] as int?) ?? 0;
      if (adjustments >= 0) continue;

      final shrinkageItem = ShrinkageData(
        itemId: row['item_id'].toString(),
        itemName: row['item_name'] as String,
        expectedQuantity: 0,
        actualQuantity: adjustments.abs(),
        variance: adjustments,
        varianceValue: 0.0,
        reason: (row['reason'] as String?) ?? 'unknown',
        lastCountDate: DateTime.parse(row['created_at'] as String),
      );

      shrinkageData.add(shrinkageItem);
      totalShrinkageValue += shrinkageItem.varianceValue;
    }

    return ShrinkageReport(
      id: 'shrinkage_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      shrinkageItems: shrinkageData,
      totalShrinkageValue: totalShrinkageValue,
      totalShrinkagePercentage: 0.0,
      shrinkageByCategory: {},
      shrinkageByReason: {},
    );
  }

  Future<LaborCostReport> generateLaborCostReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;

    final laborQuery = '''
      SELECT
        u.id,
        u.name,
        u.role,
        COALESCE(u.hourly_wage, 0) as hourly_wage,
        COALESCE(SUM(ets.hours_worked), 0) as total_hours,
        COUNT(DISTINCT ets.id) as shift_count,
        COALESCE(AVG(ets.hours_worked), 0) as avg_hours_per_shift
      FROM users u
      LEFT JOIN employee_time_sheets ets ON u.id = ets.user_id
        AND ets.date BETWEEN ? AND ?
      WHERE u.is_active = 1 AND u.role IN ('manager', 'cashier', 'server')
      GROUP BY u.id, u.name, u.role, u.hourly_wage
      ORDER BY total_hours DESC
    ''';

    final laborResults = await db.rawQuery(laborQuery, [
      period.startDate.toIso8601String().substring(0, 10),
      period.endDate.toIso8601String().substring(0, 10),
    ]);

    final efficiencyData = <LaborEfficiencyData>[];
    double totalLaborCost = 0;
    final laborCostByDepartment = <String, double>{};
    final laborCostByShift = <String, double>{};

    for (final row in laborResults) {
      final hourlyWage = (row['hourly_wage'] as double?) ?? 0.0;
      final hoursWorked = (row['total_hours'] as double?) ?? 0.0;
      final laborCost = hourlyWage * hoursWorked;
      final role = (row['role'] as String?) ?? 'Unknown';

      final efficiencyItem = LaborEfficiencyData(
        shift: 'All Shifts',
        department: role,
        scheduledHours: hoursWorked.round(),
        actualHours: hoursWorked.round(),
        salesDuringShift: 0.0,
        laborCostEfficiency: 0.0,
      );

      efficiencyData.add(efficiencyItem);
      totalLaborCost += laborCost;

      laborCostByDepartment[role] =
          (laborCostByDepartment[role] ?? 0.0) + laborCost;

      laborCostByShift['All Shifts'] =
          (laborCostByShift['All Shifts'] ?? 0.0) + laborCost;
    }

    final salesQuery = '''
      SELECT COALESCE(SUM(total_amount), 0) as total_sales
      FROM orders
      WHERE created_at BETWEEN ? AND ? AND status = 'completed'
    ''';

    final salesResult = await db.rawQuery(salesQuery, [
      period.startDate.toIso8601String(),
      period.endDate.toIso8601String(),
    ]);
    final totalSales = (salesResult.first['total_sales'] as double?) ?? 0.0;

    return LaborCostReport(
      id: 'labor_cost_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      totalLaborCost: totalLaborCost,
      laborCostPercentage: totalSales > 0
          ? (totalLaborCost / totalSales) * 100
          : 0.0,
      laborCostByDepartment: laborCostByDepartment,
      laborCostByShift: laborCostByShift,
      efficiencyData: efficiencyData,
    );
  }

  Future<CustomerReport> generateCustomerReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;

    final customerQuery = '''
      SELECT
        o.customer_name,
        o.customer_phone,
        COUNT(DISTINCT o.id) as order_count,
        COALESCE(SUM(o.total_amount), 0) as total_spent,
        COALESCE(AVG(o.total_amount), 0) as avg_order_value,
        MAX(o.created_at) as last_order_date,
        MIN(o.created_at) as first_order_date,
        GROUP_CONCAT(DISTINCT oi.item_id) as purchased_items
      FROM orders o
      LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE o.created_at BETWEEN ? AND ?
        AND o.customer_name IS NOT NULL
        AND o.customer_name != ''
        AND o.status = 'completed'
      GROUP BY o.customer_name, o.customer_phone
      ORDER BY total_spent DESC
    ''';

    final customerResults = await db.rawQuery(customerQuery, [
      period.startDate.toIso8601String(),
      period.endDate.toIso8601String(),
    ]);

    final topCustomers = <TopCustomerData>[];
    final customerSegments = <String, int>{};
    final inactiveCustomers = <InactiveCustomerData>[];
    int totalActiveCustomers = 0;
    double totalRevenue = 0.0;

    for (final row in customerResults) {
      final totalSpent = (row['total_spent'] as double?) ?? 0.0;
      final orderCount = (row['order_count'] as int?) ?? 0;
      final lastOrderDate = row['last_order_date'] != null
          ? DateTime.parse(row['last_order_date'] as String)
          : null;

      final customer = TopCustomerData(
        customerId: 'customer_${customerResults.indexOf(row)}',
        customerName: (row['customer_name'] as String?) ?? 'Unknown',
        totalSpent: totalSpent,
        visitCount: orderCount,
        averageOrderValue: orderCount > 0 ? totalSpent / orderCount : 0.0,
        lastVisit: lastOrderDate ?? DateTime.now(),
        favoriteProducts: [],
      );

      topCustomers.add(customer);
      totalRevenue += totalSpent;
      totalActiveCustomers++;

      if (totalSpent >= 500) {
        customerSegments['VIP'] = (customerSegments['VIP'] ?? 0) + 1;
      } else if (totalSpent >= 200) {
        customerSegments['Gold'] = (customerSegments['Gold'] ?? 0) + 1;
      } else if (totalSpent >= 50) {
        customerSegments['Silver'] = (customerSegments['Silver'] ?? 0) + 1;
      } else {
        customerSegments['Bronze'] = (customerSegments['Bronze'] ?? 0) + 1;
      }
    }

    return CustomerReport(
      id: 'customer_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      topCustomers: topCustomers.take(20).toList(),
      customerSegments: customerSegments,
      inactiveCustomers: inactiveCustomers,
      totalActiveCustomers: totalActiveCustomers,
      averageCustomerLifetimeValue: totalActiveCustomers > 0
          ? totalRevenue / totalActiveCustomers
          : 0.0,
    );
  }

  Future<BasketAnalysisReport> generateBasketAnalysisReport(
    ReportPeriod period,
  ) async {
    return BasketAnalysisReport(
      id: 'basket_analysis_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      frequentlyBoughtTogether: {},
      productAffinityScores: {},
      recommendedBundles: [],
      purchasePatterns: {},
    );
  }

  Future<LoyaltyProgramReport> generateLoyaltyProgramReport(
    ReportPeriod period,
  ) async {
    return LoyaltyProgramReport(
      id: 'loyalty_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      totalMembers: 0,
      activeMembers: 0,
      totalPointsIssued: 0.0,
      totalPointsRedeemed: 0.0,
      redemptionRate: 0.0,
      revenueFromLoyaltyMembers: 0.0,
      pointsByTier: {},
    );
  }
}

String _calculateStockStatus(int currentStock, int minStock, int maxStock) {
  if (currentStock <= 0) return 'Out of Stock';
  if (currentStock <= minStock) return 'Low Stock';
  if (currentStock > maxStock) return 'Overstock';
  return 'In Stock';
}
