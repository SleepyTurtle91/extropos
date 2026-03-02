part of 'reports_screen.dart';

extension ReportsScreenOperations on _ReportsScreenState {
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    try {
      if (_showAdvancedReports) {
        await _loadAdvancedReport();
      } else {
        final report = await DatabaseService.instance.generateSalesReport(
          _selectedPeriod,
        );
        if (mounted) {
          setState(() {
            _currentReport = report;
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ToastHelper.showToast(context, 'Error loading report: $e');
      }
    }
  }

  Future<void> _loadAdvancedReport() async {
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
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ToastHelper.showToast(context, 'Error loading advanced report: $e');
      }
    }
  }

  Future<void> _exportReport() async {
    if (_loading) return;

    debugPrint('Reports: Export button pressed');

    try {
      if (_showAdvancedReports) {
        debugPrint('Reports: Exporting advanced report');
        await _exportAdvancedReport();
      } else {
        debugPrint('Reports: Exporting basic report');
        await _exportBasicReport();
      }
    } catch (e) {
      debugPrint('Reports: Export failed with error: $e');
      if (mounted) {
        ToastHelper.showToast(context, 'Export failed: $e');
      }
    }
  }

  Future<void> _exportBasicReport() async {
    if (_loading) return;
    final csvContent = _generateReportCsv();
    await ReportsExportService().exportBasicReport(
      context,
      csvContent,
      mounted: mounted,
    );
  }

  Future<void> _exportAdvancedReport() async {
    if (_loading) return;
    final csvData = _generateAdvancedCSVData();
    await ReportsExportService().exportAdvancedReport(
      context,
      csvData,
      _selectedReportType.name,
      mounted: mounted,
    );
  }

  Future<void> _printReport() async {
    if (_loading) return;
    try {
      if (_showAdvancedReports) {
        await ReportsExportService().printAdvancedReport(
          context,
          _selectedFormat,
          _selectedReportType,
          _salesSummaryReport,
          _productSalesReport,
          _dayClosingReport,
          _selectedPeriod,
          mounted: mounted,
        );
      } else {
        await ReportsExportService().printBasicReport(
          context,
          _currentReport,
          _selectedPeriod,
          mounted: mounted,
        );
      }
    } catch (e) {
      debugPrint('Reports: Print failed: $e');
      if (mounted) {
        ToastHelper.showToast(context, 'Print failed: $e');
      }
    }
  }

  Future<printer_model.Printer?> _getDefaultPrinter() async {
    final printers = await DatabaseService.instance.getPrinters();
    return printers.isNotEmpty ? printers.first : null;
  }

}
