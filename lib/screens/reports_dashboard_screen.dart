import 'dart:async';

import 'package:extropos/models/advanced_reports.dart';
import 'package:extropos/models/analytics_models.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/reports_dashboard_models.dart';
import 'package:extropos/models/sales_report.dart';
import 'package:extropos/services/analytics_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/widgets/reports_dashboard_widgets.dart';
import 'package:extropos/widgets/reports_shift_card.dart';
import 'package:extropos/widgets/reports_stat_card.dart';
import 'package:flutter/material.dart';

part 'reports_dashboard_screen_ui.dart';

class ReportsDashboardScreen extends StatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService.instance;

  @override
  Widget build(BuildContext context) {
    return _buildReportsDashboardScreen(context);
  }

  // --- UI State ---
  ReportsBusinessType activeMode = ReportsBusinessType.retail;
  ReportsTimeRange activeTimeRange = ReportsTimeRange.daily;
  String? activeModalReport; // 'X' or 'Z'
  String? exportingType;
  double exportProgress = 0.0;
  bool isLoading = false;

  DateTime startDate = DateTime(2026, 2, 1);
  DateTime endDate = DateTime(2026, 2, 21);

  // --- Dynamic Report Data (Populated by DB) ---
  List<ReportsStatData> currentStats = [];
  List<ReportsInventoryItem> currentInventory = [];
  List<ReportsBreakdownItem> currentBreakdown = [];
  String breakdownTitle = 'Performance Breakdown';

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  // Database Reporting Logic
  Future<void> _fetchReportData() async {
    setState(() => isLoading = true);
    final currency = BusinessInfo.instance.currencySymbol;
    final period = _buildReportPeriod();
    final previousPeriod = _buildPreviousPeriod(period);

    try {
      final results = await Future.wait([
        _analyticsService.getSalesSummary(
          startDate: period.startDate,
          endDate: period.endDate,
        ),
        _analyticsService.getSalesSummary(
          startDate: previousPeriod.startDate,
          endDate: previousPeriod.endDate,
        ),
        _analyticsService.getCategoryPerformance(
          startDate: period.startDate,
          endDate: period.endDate,
          limit: 6,
        ),
        DatabaseService.instance.generateInventoryValuationReport(period),
      ]);

      if (!mounted) return;

      final summary = results[0] as SalesSummary;
      final previousSummary = results[1] as SalesSummary;
      final categories = results[2] as List<CategoryPerformance>;
      final inventoryReport = results[3] as InventoryValuationReport;

      final stats = _buildStats(summary, previousSummary, currency);
      final breakdown = _buildBreakdown(summary, categories, currency);
      final inventory = _buildInventoryItems(inventoryReport);

      setState(() {
        currentStats = stats;
        currentBreakdown = breakdown;
        currentInventory = inventory;
        breakdownTitle = 'Category Breakdown';
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  ReportPeriod _buildReportPeriod() {
    final now = DateTime.now();
    switch (activeTimeRange) {
      case ReportsTimeRange.daily:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return ReportPeriod(label: 'Daily', startDate: start, endDate: end);
      case ReportsTimeRange.weekly:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        return ReportPeriod(label: 'Weekly', startDate: start, endDate: end);
      case ReportsTimeRange.monthly:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return ReportPeriod(label: 'Monthly', startDate: start, endDate: end);
      case ReportsTimeRange.yearly:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return ReportPeriod(label: 'Yearly', startDate: start, endDate: end);
      case ReportsTimeRange.custom:
        return ReportPeriod(
          label: 'Custom',
          startDate: startDate,
          endDate: endDate,
        );
    }
  }

  ReportPeriod _buildPreviousPeriod(ReportPeriod period) {
    final duration = period.endDate.difference(period.startDate);
    final prevEnd = period.startDate.subtract(const Duration(seconds: 1));
    final prevStart = prevEnd.subtract(duration);
    return ReportPeriod(
      label: 'Previous',
      startDate: prevStart,
      endDate: prevEnd,
    );
  }

  List<ReportsStatData> _buildStats(
    SalesSummary current,
    SalesSummary previous,
    String currency,
  ) {
    final revenueTrend = _buildTrend(
      current.totalRevenue,
      previous.totalRevenue,
    );
    final ordersTrend = _buildTrend(
      current.orderCount.toDouble(),
      previous.orderCount.toDouble(),
    );
    final averageTrend = _buildTrend(
      current.averageOrderValue,
      previous.averageOrderValue,
    );
    final itemsTrend = _buildTrend(
      current.itemsSold.toDouble(),
      previous.itemsSold.toDouble(),
    );

    return [
      ReportsStatData(
        label: 'Total Revenue',
        value: '$currency ${current.totalRevenue.toStringAsFixed(2)}',
        trend: revenueTrend.label,
        isUp: revenueTrend.isUp,
        icon: Icons.payments_rounded,
        color: const Color(0xFF4F46E5),
      ),
      ReportsStatData(
        label: 'Orders',
        value: current.orderCount.toString(),
        trend: ordersTrend.label,
        isUp: ordersTrend.isUp,
        icon: Icons.receipt_long,
        color: Colors.blueGrey.shade600,
      ),
      ReportsStatData(
        label: 'Avg Ticket',
        value: '$currency ${current.averageOrderValue.toStringAsFixed(2)}',
        trend: averageTrend.label,
        isUp: averageTrend.isUp,
        icon: Icons.trending_up,
        color: Colors.green.shade600,
      ),
      ReportsStatData(
        label: 'Items Sold',
        value: current.itemsSold.toString(),
        trend: itemsTrend.label,
        isUp: itemsTrend.isUp,
        icon: Icons.shopping_cart,
        color: Colors.orange.shade700,
      ),
    ];
  }

  List<ReportsBreakdownItem> _buildBreakdown(
    SalesSummary summary,
    List<CategoryPerformance> categories,
    String currency,
  ) {
    final total = summary.totalRevenue;
    if (total <= 0 || categories.isEmpty) return [];

    final colors = <Color>[
      const Color(0xFF4F46E5),
      Colors.blueGrey.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
    ];

    return categories.asMap().entries.map((entry) {
      final idx = entry.key;
      final category = entry.value;
      final percentage = (category.revenue / total) * 100;
      return ReportsBreakdownItem(
        label: category.categoryName,
        percentage: percentage.isNaN ? 0.0 : percentage,
        amount: '$currency ${category.revenue.toStringAsFixed(2)}',
        color: colors[idx % colors.length],
      );
    }).toList();
  }

  List<ReportsInventoryItem> _buildInventoryItems(
    InventoryValuationReport report,
  ) {
    return report.valuationItems.map((item) {
      final qty = item.quantity;
      final status = qty <= 0 ? 'Out' : (qty <= 5 ? 'Low' : 'In Stock');
      return ReportsInventoryItem(
        id: item.itemId,
        name: item.itemName,
        category: 'General',
        stock: qty.toDouble(),
        min: 0,
        unit: null,
        cost: item.costPrice,
        status: status,
      );
    }).toList();
  }

  _TrendResult _buildTrend(double current, double previous) {
    if (previous == 0) {
      if (current == 0) {
        return const _TrendResult('0%', true);
      }
      return const _TrendResult('New', true);
    }

    final diff = ((current - previous) / previous) * 100;
    final isUp = diff >= 0;
    final label = '${diff.abs().toStringAsFixed(1)}%';
    return _TrendResult(label, isUp);
  }

  void _handleExport(String type) {
    setState(() {
      exportingType = type;
      exportProgress = 0.0;
    });

    Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (exportProgress >= 1.0) {
        timer.cancel();
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) setState(() => exportingType = null);
        });
      } else {
        setState(() => exportProgress += 0.1);
      }
    });
  }
}

/// Trend result for dashboard statistics
class _TrendResult {
  final String label;
  final bool isUp;

  const _TrendResult(this.label, this.isUp);
}
