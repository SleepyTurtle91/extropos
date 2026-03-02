/// Auto-generated from advanced_reports.dart - Do not edit manually
///
/// Reports Customer
library;

import 'package:extropos/models/reports/reports_base.dart';

class CustomerReport extends BaseReport {
  final List<TopCustomerData> topCustomers;
  final Map<String, int> customerSegments;
  final List<InactiveCustomerData> inactiveCustomers;
  final int totalActiveCustomers;
  final double averageCustomerLifetimeValue;

  CustomerReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.topCustomers,
    required this.customerSegments,
    required this.inactiveCustomers,
    required this.totalActiveCustomers,
    required this.averageCustomerLifetimeValue,
  });
}

class TopCustomerData {
  final String customerId;
  final String customerName;
  final double totalSpent;
  final int visitCount;
  final double averageOrderValue;
  final DateTime lastVisit;
  final List<String> favoriteProducts;

  TopCustomerData({
    required this.customerId,
    required this.customerName,
    required this.totalSpent,
    required this.visitCount,
    required this.averageOrderValue,
    required this.lastVisit,
    required this.favoriteProducts,
  });
}

class InactiveCustomerData {
  final String customerId;
  final String customerName;
  final DateTime lastVisit;
  final double lastOrderValue;
  final int daysSinceLastVisit;
  final String segment;

  InactiveCustomerData({
    required this.customerId,
    required this.customerName,
    required this.lastVisit,
    required this.lastOrderValue,
    required this.daysSinceLastVisit,
    required this.segment,
  });
}

