part of 'modern_reports_dashboard.dart';

extension ModernReportsDashboardFutures on _ModernReportsDashboardState {
  Future<void> _loadData() async {
    final period = _periodForRange(_activeTimeRange);

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _analyticsService.getSalesSummary(
          startDate: period.startDate,
          endDate: period.endDate,
        ),
        _analyticsService.getCategoryPerformance(
          startDate: period.startDate,
          endDate: period.endDate,
          limit: 10,
        ),
        _analyticsService.getTopProducts(
          startDate: period.startDate,
          endDate: period.endDate,
          limit: 10,
        ),
        _analyticsService.getPaymentMethodStats(
          startDate: period.startDate,
          endDate: period.endDate,
        ),
        _analyticsService.getDailySales(
          startDate: period.startDate,
          endDate: period.endDate,
        ),
        DatabaseService.instance.generateInventoryValuationReport(period),
      ]);

      if (!mounted) return;

      final inventoryReport = results[5] as InventoryValuationReport;
      final inventoryItems = inventoryReport.valuationItems.map((item) {
        final status = item.quantity <= 0 ? 'Out' : 'In Stock';
        return InventoryItem(
          id: item.itemId,
          name: item.itemName,
          category: 'General',
          stock: item.quantity.toDouble(),
          min: 0,
          unit: null,
          cost: item.costPrice,
          status: status,
        );
      }).toList();

      setState(() {
        _summary = results[0] as SalesSummary;
        _categories = results[1] as List<CategoryPerformance>;
        _topProducts = results[2] as List<ProductPerformance>;
        _paymentMethods = results[3] as List<PaymentMethodStats>;
        _dailySales = results[4] as List<DailySales>;
        _inventoryValuationReport = inventoryReport;
        _inventoryItems = inventoryItems;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleExport(String type) async {
    if (_isLoading) return;

    setState(() {
      _exportingType = type;
      _exportProgress = 0.2;
    });

    try {
      if (type == 'csv') {
        await _exportCSV();
      } else {
        await _exportPDF();
      }
      if (!mounted) return;
      setState(() => _exportProgress = 1.0);
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Export failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _exportingType = null);
      }
    }
  }

  Future<void> _exportCSV() async {
    try {
      final csv = await ReportExportService().generateCSV(
        grossSales: _summary?.grossSales ?? 0.0,
        netSales: _summary?.netSales ?? 0.0,
        transactionCount: _summary?.transactionCount ?? 0,
        avgTicket: _summary?.averageTransactionValue ?? 0.0,
        topProducts: _topProducts,
        periodLabel: _periodForRange(_activeTimeRange).label,
      );
      final success = await ReportExportService().exportCSVToFile(csv);
      if (mounted) ToastHelper.showToast(
        context,
        success ? 'Report exported successfully' : 'Export failed',
      );
    } catch (e) {
      if (mounted) ToastHelper.showToast(context, 'Export failed: $e');
    }
  }

  Future<void> _exportPDF() async {
    try {
      if (mounted) ToastHelper.showToast(context, 'Generating PDF...');
      final success = await ReportExportService().exportPDF(
        summary: _summary!,
        categories: _categories,
        topProducts: _topProducts,
        paymentMethods: _paymentMethods,
        periodLabel: _periodForRange(_activeTimeRange).label,
      );
      if (mounted) ToastHelper.showToast(
        context,
        success ? 'PDF exported successfully' : 'PDF export failed',
      );
    } catch (e) {
      if (mounted) ToastHelper.showToast(context, 'PDF export failed: $e');
    }
  }

  Future<void> _printThermal58mm() async {
    try {
      if (_summary == null) {
        ToastHelper.showToast(context, 'No data to print');
        return;
      }
      final printer = await _getDefaultPrinter();
      if (printer == null) {
        if (mounted) ToastHelper.showToast(context, 'No printer configured');
        return;
      }
      if (mounted) ToastHelper.showToast(context, 'Sending to thermal printer...');
      final reportService = ReportPrinterService.instance;
      final success = await reportService.printThermalSummary(
        printer: printer,
        summary: _summary!,
        periodLabel: _periodForRange(_activeTimeRange).label,
        categories: _categories,
        paymentMethods: _paymentMethods,
      );
      if (mounted) ToastHelper.showToast(
        context,
        success ? 'Report printed successfully' : 'Print failed - check printer',
      );
    } catch (e) {
      if (mounted) ToastHelper.showToast(context, 'Print error: $e');
    }
  }

  Future<void> _printThermal80mm() async {
    try {
      if (_summary == null) {
        ToastHelper.showToast(context, 'No data to print');
        return;
      }
      if (mounted) ToastHelper.showToast(context, 'Sending to thermal printer...');
      final success = await ReportExportService().printThermal80mm(
        summary: _summary!,
        categories: _categories,
        paymentMethods: _paymentMethods,
        periodLabel: _periodForRange(_activeTimeRange).label,
      );
      if (mounted) ToastHelper.showToast(
        context,
        success ? 'Report printed successfully' : 'Print failed - check printer',
      );
    } catch (e) {
      if (mounted) ToastHelper.showToast(context, 'Print error: $e');
    }
  }

}
