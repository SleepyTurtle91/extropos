// Part of advanced_reports_screen.dart
// Auto-split Operations

part of 'advanced_reports_screen.dart';

extension AdvancedReportsOperationsPart3 on _AdvancedReportsScreenState {
  String _filterSummary() {
    final f = _currentFilter;
    if (f == null) return '';
    final parts = <String>[];
    if (f.searchText != null && f.searchText!.isNotEmpty) parts.add('Q: ${f.searchText}');
    if (f.minAmount != null) parts.add('Min: ${f.minAmount!.toStringAsFixed(2)}');
    if (f.maxAmount != null) parts.add('Max: ${f.maxAmount!.toStringAsFixed(2)}');
    if (f.dateRange != null)
      parts.add(
        '${f.dateRange!.start.toIso8601String().substring(0, 10)} - ${f.dateRange!.end.toIso8601String().substring(0, 10)}',
      );
    return parts.join(' | ');
  }

  String _getReportTypeLabel(ReportType type) {
    switch (type) {
      case ReportType.salesSummary:
        return 'Sales Summary';
      case ReportType.productSales:
        return 'Product Sales';
      case ReportType.categorySales:
        return 'Category Sales';
      case ReportType.paymentMethod:
        return 'Payment Methods';
      case ReportType.inventory:
        return 'Inventory';
      case ReportType.shrinkage:
        return 'Shrinkage';
      case ReportType.employeePerformance:
        return 'Employee Performance';
      case ReportType.laborCost:
        return 'Labor Cost';
      case ReportType.customerAnalysis:
        return 'Customer Analysis';
      case ReportType.basketAnalysis:
        return 'Basket Analysis';
      case ReportType.loyaltyProgram:
        return 'Loyalty Program';
      case ReportType.dayClosing:
        return 'Day Closing';
      case ReportType.profitLoss:
        return 'Profit & Loss';
      case ReportType.cashFlow:
        return 'Cash Flow';
      case ReportType.taxSummary:
        return 'Tax Summary';
      case ReportType.inventoryValuation:
        return 'Inventory Valuation';
      case ReportType.abcAnalysis:
        return 'ABC Analysis';
      case ReportType.demandForecasting:
        return 'Demand Forecasting';
      case ReportType.menuEngineering:
        return 'Menu Engineering';
      case ReportType.tablePerformance:
        return 'Table Performance';
      case ReportType.dailyStaffPerformance:
        return 'Daily Staff Performance';
    }
  }

  String _formatLastRefreshTime() {
    if (_lastRefreshTime == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(_lastRefreshTime!);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showFilterDialog() {
    final searchController = TextEditingController(text: _currentFilter?.searchText);
    final minController = TextEditingController(text: _currentFilter?.minAmount?.toString());
    final maxController = TextEditingController(text: _currentFilter?.maxAmount?.toString());
    DateTimeRange? pickedRange = _currentFilter?.dateRange;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Advanced Filter'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      hintText: 'Product, category, customer, etc.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Min Amount'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: maxController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Max Amount'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final range = await showDateRangePicker(
                              context: ctx,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              initialDateRange: pickedRange,
                            );
                            setDialogState(() => pickedRange = range);
                          },
                          child: Text(
                            pickedRange == null
                                ? 'Choose Date Range'
                                : '${pickedRange!.start.toLocal().toIso8601String().substring(0, 10)} - ${pickedRange!.end.toLocal().toIso8601String().substring(0, 10)}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setDialogState(() {
                            pickedRange = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _updateState(() => _currentFilter = null);
                  Navigator.of(ctx).pop();
                  _loadReport();
                  if (mounted) ToastHelper.showToast(context, 'Filters cleared');
                },
                child: const Text('Clear'),
              ),
              ElevatedButton(
                onPressed: () {
                  final searchText = searchController.text.trim().isEmpty
                      ? null
                      : searchController.text.trim();
                  final min = double.tryParse(minController.text);
                  final max = double.tryParse(maxController.text);

                  _updateState(() {
                    _currentFilter = AdvancedReportFilter(
                      searchText: searchText,
                      minAmount: min,
                      maxAmount: max,
                      dateRange: pickedRange,
                    );
                  });

                  if (pickedRange != null) {
                    _updateState(
                      () => _selectedPeriod = ReportPeriod(
                        label: 'Custom',
                        startDate: pickedRange!.start,
                        endDate: pickedRange!.end,
                      ),
                    );
                  }

                  Navigator.of(ctx).pop();
                  _loadReport();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPeriodSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Report Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Today'),
              onTap: () {
                _updateState(() => _selectedPeriod = ReportPeriod.today());
                Navigator.of(context).pop();
                _loadReport();
              },
            ),
            ListTile(
              title: const Text('Yesterday'),
              onTap: () {
                final yesterday = DateTime.now().subtract(const Duration(days: 1));
                _updateState(
                  () => _selectedPeriod = ReportPeriod(
                    label: 'Yesterday',
                    startDate: DateTime(yesterday.year, yesterday.month, yesterday.day),
                    endDate: DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59),
                  ),
                );
                Navigator.of(context).pop();
                _loadReport();
              },
            ),
            ListTile(
              title: const Text('This Week'),
              onTap: () {
                final now = DateTime.now();
                final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                _updateState(
                  () => _selectedPeriod = ReportPeriod(
                    label: 'This Week',
                    startDate: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
                    endDate: now,
                  ),
                );
                Navigator.of(context).pop();
                _loadReport();
              },
            ),
            ListTile(
              title: const Text('This Month'),
              onTap: () {
                final now = DateTime.now();
                _updateState(
                  () => _selectedPeriod = ReportPeriod(
                    label: 'This Month',
                    startDate: DateTime(now.year, now.month, 1),
                    endDate: now,
                  ),
                );
                Navigator.of(context).pop();
                _loadReport();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadReport() async {
    _updateState(() => _isLoading = true);

    try {
      switch (_selectedReportType) {
        case ReportType.salesSummary:
          _salesSummaryReport = await DatabaseService.instance
              .generateSalesSummaryReport(_selectedPeriod);
          break;
        case ReportType.productSales:
          _productSalesReport = await DatabaseService.instance
              .generateProductSalesReport(_selectedPeriod);
          break;
        case ReportType.categorySales:
          _categorySalesReport = await DatabaseService.instance
              .generateCategorySalesReport(_selectedPeriod);
          break;
        case ReportType.paymentMethod:
          _paymentMethodReport = await DatabaseService.instance
              .generatePaymentMethodReport(_selectedPeriod);
          break;
        case ReportType.employeePerformance:
          _employeePerformanceReport = await DatabaseService.instance
              .generateEmployeePerformanceReport(_selectedPeriod);
          break;
        case ReportType.inventory:
          _inventoryReport = await DatabaseService.instance
              .generateInventoryReport(_selectedPeriod);
          break;
        case ReportType.shrinkage:
          _shrinkageReport = await DatabaseService.instance
              .generateShrinkageReport(_selectedPeriod);
          break;
        case ReportType.laborCost:
          _laborCostReport = await DatabaseService.instance
              .generateLaborCostReport(_selectedPeriod);
          break;
        case ReportType.customerAnalysis:
          _customerReport = await DatabaseService.instance
              .generateCustomerReport(_selectedPeriod);
          break;
        case ReportType.basketAnalysis:
          _basketAnalysisReport = await DatabaseService.instance
              .generateBasketAnalysisReport(_selectedPeriod);
          break;
        case ReportType.loyaltyProgram:
          _loyaltyProgramReport = await DatabaseService.instance
              .generateLoyaltyProgramReport(_selectedPeriod);
          break;
        case ReportType.dayClosing:
          _dayClosingReport = await DatabaseService.instance
              .generateDayClosingReport(_selectedPeriod);
          break;
        case ReportType.profitLoss:
          _profitLossReport = await DatabaseService.instance
              .generateProfitLossReport(_selectedPeriod);
          break;
        case ReportType.cashFlow:
          _cashFlowReport = await DatabaseService.instance
              .generateCashFlowReport(_selectedPeriod);
          break;
        case ReportType.taxSummary:
          _taxSummaryReport = await DatabaseService.instance
              .generateTaxSummaryReport(_selectedPeriod);
          break;
        case ReportType.inventoryValuation:
          _inventoryValuationReport = await DatabaseService.instance
              .generateInventoryValuationReport(_selectedPeriod);
          break;
        case ReportType.abcAnalysis:
          _abcAnalysisReport = await DatabaseService.instance
              .generateABCAnalysisReport(_selectedPeriod);
          break;
        case ReportType.demandForecasting:
          _demandForecastingReport = await DatabaseService.instance
              .generateDemandForecastingReport(_selectedPeriod);
          break;
        case ReportType.menuEngineering:
          _menuEngineeringReport = await DatabaseService.instance
              .generateMenuEngineeringReport(_selectedPeriod);
          break;
        case ReportType.tablePerformance:
          _tablePerformanceReport = await DatabaseService.instance
              .generateTablePerformanceReport(_selectedPeriod);
          break;
        case ReportType.dailyStaffPerformance:
          // Special case: daily staff performance report uses a specific date
          // For now, use the start date of the period
          _dailyStaffPerformanceReport = await DailyStaffPerformanceService
              .instance
              .generateDailyReport(_selectedPeriod.startDate);
          break;
      }
    } catch (e) {
      if (mounted) ToastHelper.showToast(context, 'Error loading report: $e');
    } finally {
      if (mounted) {
        _updateState(() {
          _isLoading = false;
          _lastRefreshTime = DateTime.now();
        });
      }
    }
  }

  Future<void> _autoRefreshReport() async {
    if (_isLoading) return; // Don't refresh if already loading

    try {
      // Only refresh if the screen is still mounted and visible
      if (!mounted) {
        _stopAutoRefresh();
        return;
      }

      await _loadReport();
      _lastRefreshTime = DateTime.now();

      if (mounted) ToastHelper.showToast(context, 'Report auto-refreshed');
    } catch (e) {
      // Silently handle auto-refresh errors to avoid spamming the user
      developer.log('Auto-refresh failed: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    final dateTime = DateTime.parse(isoString);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
  }

}
