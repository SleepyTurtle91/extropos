class DateRangeValue {
  final DateTime start;
  final DateTime end;

  const DateRangeValue({required this.start, required this.end});
}

enum DashboardPeriodPreset {
  today,
  last7Days,
  thisMonth,
  lastMonth,
  lastYear,
  custom,
}

class DashboardPeriodService {
  const DashboardPeriodService._();

  static String label(DashboardPeriodPreset preset) {
    switch (preset) {
      case DashboardPeriodPreset.today:
        return 'Today';
      case DashboardPeriodPreset.last7Days:
        return 'Last 7 days';
      case DashboardPeriodPreset.thisMonth:
        return 'This month';
      case DashboardPeriodPreset.lastMonth:
        return 'Last month';
      case DashboardPeriodPreset.lastYear:
        return 'Last year';
      case DashboardPeriodPreset.custom:
        return 'Custom';
    }
  }

  static DateRangeValue resolveRange(
    DashboardPeriodPreset preset, {
    DateTime? now,
    DateRangeValue? customRange,
  }) {
    final DateTime current = now ?? DateTime.now();

    switch (preset) {
      case DashboardPeriodPreset.today:
        final start = DateTime(current.year, current.month, current.day);
        return DateRangeValue(start: start, end: current);
      case DashboardPeriodPreset.last7Days:
        return DateRangeValue(
          start: current.subtract(const Duration(days: 6)),
          end: current,
        );
      case DashboardPeriodPreset.thisMonth:
        final start = DateTime(current.year, current.month, 1);
        return DateRangeValue(start: start, end: current);
      case DashboardPeriodPreset.lastMonth:
        final firstDayThisMonth = DateTime(current.year, current.month, 1);
        final lastDayLastMonth = firstDayThisMonth.subtract(
          const Duration(days: 1),
        );
        final firstDayLastMonth = DateTime(
          lastDayLastMonth.year,
          lastDayLastMonth.month,
          1,
        );
        return DateRangeValue(start: firstDayLastMonth, end: lastDayLastMonth);
      case DashboardPeriodPreset.lastYear:
        final start = DateTime(current.year - 1, 1, 1);
        final end = DateTime(current.year - 1, 12, 31, 23, 59, 59);
        return DateRangeValue(start: start, end: end);
      case DashboardPeriodPreset.custom:
        if (customRange != null) return customRange;
        return DateRangeValue(
          start: current.subtract(const Duration(days: 6)),
          end: current,
        );
    }
  }
}
