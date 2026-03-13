part of 'reports_screen.dart';

extension _ReportsScreenMethods on _ReportsScreenState {
  Future<void> loadFilters() async {
    try {
      final categories = await DatabaseService.instance.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories.map((c) => c.name).toList();
        });
      }
    } catch (e) {
      // Silently handle filter loading errors
    }
  }

  Future<void> loadReportsData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Load current period data
      final summary = await DatabaseService.instance.getSalesSummary(
        startDate: _selectedPeriod.startDate,
        endDate: _selectedPeriod.endDate,
        categoryId: _selectedCategory,
        staffId: _selectedStaff,
      );

      // Load comparison data if enabled
      SalesSummary? comparisonSummary;
      if (_showComparison) {
        final comparisonPeriod = _getComparisonPeriod();
        comparisonSummary = await DatabaseService.instance.getSalesSummary(
          startDate: comparisonPeriod.startDate,
          endDate: comparisonPeriod.endDate,
          categoryId: _selectedCategory,
          staffId: _selectedStaff,
        );
      }

      // Load top products
      final topProducts = await DatabaseService.instance.getTopProducts(
        startDate: _selectedPeriod.startDate,
        endDate: _selectedPeriod.endDate,
        categoryId: _selectedCategory,
        staffId: _selectedStaff,
        limit: 10,
      );

      // Load staff performance
      final staffPerformance = await DatabaseService.instance.getStaffPerformance(
        startDate: _selectedPeriod.startDate,
        endDate: _selectedPeriod.endDate,
      );

      // Load product analytics
      final productAnalytics = await DatabaseService.instance.getProductAnalytics(
        startDate: _selectedPeriod.startDate,
        endDate: _selectedPeriod.endDate,
        categoryId: _selectedCategory,
      );

      // Load daily sales data
      final dailySales = await DatabaseService.instance.getDailySales(
        startDate: _selectedPeriod.startDate,
        endDate: _selectedPeriod.endDate,
        categoryId: _selectedCategory,
        staffId: _selectedStaff,
      );

      // Load categories for filter
      final categories = await DatabaseService.instance.getCategories();
      final categoryNames = categories.map((c) => c.name).toList();

      if (mounted) {
        setState(() {
          _salesSummary = summary;
          _comparisonSummary = comparisonSummary;
          _topProducts = topProducts;
          _staffPerformance = staffPerformance;
          _productAnalytics = productAnalytics;
          _dailySales = dailySales;
          _categories = categoryNames;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Failed to load reports data: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  ReportPeriod _getComparisonPeriod() {
    final currentStart = _selectedPeriod.startDate;
    final currentEnd = _selectedPeriod.endDate;
    final duration = currentEnd.difference(currentStart);

    return ReportPeriod(
      label: 'Previous Period',
      startDate: currentStart.subtract(duration + const Duration(days: 1)),
      endDate: currentStart.subtract(const Duration(days: 1)),
    );
  }

  void onPeriodChanged(ReportPeriod newPeriod) {
    setState(() => _selectedPeriod = newPeriod);
    loadReportsData();
  }

  void onCategoryChanged(String? category) {
    setState(() => _selectedCategory = category);
    loadReportsData();
  }

  void onStaffChanged(String? staff) {
    setState(() => _selectedStaff = staff);
    loadReportsData();
  }

  void toggleComparison(bool value) {
    setState(() => _showComparison = value);
    loadReportsData();
  }
}
