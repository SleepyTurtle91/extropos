part of 'modern_reports_dashboard.dart';

extension ModernReportsDashboardOperations on _ModernReportsDashboardState {
  void initState() {
    super.initState();
    _initializePeriod();
    _loadData();
  }

  void _initializePeriod() {
    _activeTimeRange = _timeRangeFromInitialPeriod();
    if (_activeTimeRange == TimeRange.custom) {
      final now = DateTime.now();
      _startDate = now.subtract(const Duration(days: 30));
      _endDate = now;
    } else {
      final period = _periodForRange(_activeTimeRange);
      _startDate = period.startDate;
      _endDate = period.endDate;
    }
  }

}
