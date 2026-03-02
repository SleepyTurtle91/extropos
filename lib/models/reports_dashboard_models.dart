import 'package:flutter/material.dart';

// --- Data Models (For DB Mapping) ---

enum ReportsBusinessType { retail, cafe, dining }

enum ReportsTimeRange { daily, weekly, monthly, yearly, custom }

class ReportsStatData {
  final String label;
  final String value;
  final String trend;
  final bool isUp;
  final IconData icon;
  final Color color;

  ReportsStatData({
    required this.label,
    required this.value,
    required this.trend,
    required this.isUp,
    required this.icon,
    required this.color,
  });
}

class ReportsInventoryItem {
  final String id;
  final String name;
  final String category;
  final double stock;
  final int min;
  final String? unit;
  final double cost;
  final String status;

  ReportsInventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.min,
    this.unit,
    required this.cost,
    required this.status,
  });
}

class ReportsBreakdownItem {
  final String label;
  final double percentage;
  final String amount;
  final Color color;

  ReportsBreakdownItem({
    required this.label,
    required this.percentage,
    required this.amount,
    required this.color,
  });
}

class TrendResult {
  final String label;
  final bool isUp;

  const TrendResult(this.label, this.isUp);
}
