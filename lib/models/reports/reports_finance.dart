/// Auto-generated from advanced_reports.dart - Do not edit manually
///
/// Reports Finance
library;

import 'package:extropos/models/reports/reports_base.dart';
import 'package:extropos/models/reports/reports_sales.dart' show CashFlowTransaction;

class CashReconciliation {
  final double openingFloat;
  final double cashSales;
  final double cashRefunds;
  final double paidOuts;
  final double paidIns;
  final double expectedCash;
  final double actualCash;
  final String notes;

  CashReconciliation({
    required this.openingFloat,
    required this.cashSales,
    required this.cashRefunds,
    required this.paidOuts,
    required this.paidIns,
    required this.expectedCash,
    required this.actualCash,
    required this.notes,
  });

  double get variance => actualCash - expectedCash;
  bool get isBalanced => variance.abs() < 0.01; // Within 1 cent tolerance
}

class CashFlowReport extends BaseReport {
  final double openingCash;
  final double closingCash;
  final double cashInflows;
  final double cashOutflows;
  final double netCashFlow;
  final Map<String, double> inflowBreakdown;
  final Map<String, double> outflowBreakdown;
  final List<CashFlowTransaction> transactions;

  CashFlowReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.openingCash,
    required this.closingCash,
    required this.cashInflows,
    required this.cashOutflows,
    required this.netCashFlow,
    required this.inflowBreakdown,
    required this.outflowBreakdown,
    required this.transactions,
  });
}

class TaxSummaryReport extends BaseReport {
  final double totalTaxCollected;
  final double totalTaxPaid;
  final Map<String, double> taxBreakdown;
  final List<TaxItem> taxItems;
  final double taxLiability;

  TaxSummaryReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.totalTaxCollected,
    required this.totalTaxPaid,
    required this.taxBreakdown,
    required this.taxItems,
    required this.taxLiability,
  });
}

class TaxItem {
  final String taxType;
  final double rate;
  final double amount;
  final DateTime date;

  TaxItem({
    required this.taxType,
    required this.rate,
    required this.amount,
    required this.date,
  });
}

