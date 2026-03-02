/// Auto-generated from advanced_reports.dart - Do not edit manually
///
/// Reports Staff
library;

import 'package:extropos/models/reports/reports_base.dart';

class EmployeePerformanceReport extends BaseReport {
  final List<EmployeeData> employeePerformance;
  final Map<String, double> departmentPerformance;
  final String topPerformer;
  final String needsImprovement;

  EmployeePerformanceReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.employeePerformance,
    required this.departmentPerformance,
    required this.topPerformer,
    required this.needsImprovement,
  });
}

class EmployeeData {
  final String employeeId;
  final String employeeName;
  final double totalSales;
  final int transactionCount;
  final double averageTransactionValue;
  final double totalDiscountsGiven;
  final double tipsAccrued;
  final double laborCostPercentage;
  final int hoursWorked;
  final Map<String, int> voidedTransactions;
  final Map<String, double> refundsProcessed;

  EmployeeData({
    required this.employeeId,
    required this.employeeName,
    required this.totalSales,
    required this.transactionCount,
    required this.averageTransactionValue,
    required this.totalDiscountsGiven,
    required this.tipsAccrued,
    required this.laborCostPercentage,
    required this.hoursWorked,
    required this.voidedTransactions,
    required this.refundsProcessed,
  });
}

class ShiftSummary {
  final String employeeId;
  final String employeeName;
  final DateTime shiftStart;
  final DateTime? shiftEnd;
  final double salesDuringShift;
  final int transactionsDuringShift;
  final double cashHandled;
  final Duration shiftDuration;

  ShiftSummary({
    required this.employeeId,
    required this.employeeName,
    required this.shiftStart,
    this.shiftEnd,
    required this.salesDuringShift,
    required this.transactionsDuringShift,
    required this.cashHandled,
    required this.shiftDuration,
  });

  bool get isActive => shiftEnd == null;
}

