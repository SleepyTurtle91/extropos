// Part of advanced_reports_screen.dart
// Auto-extracted Export operations

part of 'advanced_reports_screen.dart';

extension AdvancedReportsExport on _AdvancedReportsScreenState {
  String _generateCSVData() {
    final csvData = <List<String>>[];

    switch (_selectedReportType) {
      case ReportType.salesSummary:
        if (_salesSummaryReport != null) {
          csvData.add(['Metric', 'Value']);
          csvData.add(['Gross Sales', _salesSummaryReport!.grossSales.toStringAsFixed(2)]);
          csvData.add(['Net Sales', _salesSummaryReport!.netSales.toStringAsFixed(2)]);
          csvData.add(['Total Discounts', _salesSummaryReport!.totalDiscounts.toStringAsFixed(2)]);
          csvData.add(['Total Refunds', _salesSummaryReport!.totalRefunds.toStringAsFixed(2)]);
          csvData.add(['Tax Collected', _salesSummaryReport!.taxCollected.toStringAsFixed(2)]);
          csvData.add([
            'Average Transaction Value',
            _salesSummaryReport!.averageTransactionValue.toStringAsFixed(2),
          ]);
          csvData.add(['Total Transactions', _salesSummaryReport!.totalTransactions.toString()]);
        }
        break;

      case ReportType.productSales:
        if (_productSalesReport != null) {
          csvData.add(['Product Name', 'Category', 'Units Sold', 'Total Revenue', 'Average Price']);
          for (final product in _productSalesReport!.productSales.where((product) {
            final f = _currentFilter;
            if (f == null) return true;
            var ok = true;
            if (f.searchText != null && f.searchText!.isNotEmpty) {
              ok =
                  product.productName.toLowerCase().contains(f.searchText!.toLowerCase()) ||
                  product.category.toLowerCase().contains(f.searchText!.toLowerCase());
            }
            if (f.minAmount != null) ok = ok && product.totalRevenue >= f.minAmount!;
            if (f.maxAmount != null) ok = ok && product.totalRevenue <= f.maxAmount!;
            return ok;
          })) {
            csvData.add([
              product.productName,
              product.category,
              product.unitsSold.toString(),
              product.totalRevenue.toStringAsFixed(2),
              product.averagePrice.toStringAsFixed(2),
            ]);
          }
        }
        break;

      case ReportType.categorySales:
        if (_categorySalesReport != null) {
          csvData.add(['Category', 'Revenue', 'Transactions', 'Average Transaction']);
          for (final entry in _categorySalesReport!.categorySales.entries) {
            final name = entry.key;
            final data = entry.value;
            final f = _currentFilter;
            if (f != null) {
              if (f.searchText != null &&
                  f.searchText!.isNotEmpty &&
                  !name.toLowerCase().contains(f.searchText!.toLowerCase()))
                continue;
              if (f.minAmount != null && data.revenue < f.minAmount!) continue;
              if (f.maxAmount != null && data.revenue > f.maxAmount!) continue;
            }
            csvData.add([
              name,
              data.revenue.toStringAsFixed(2),
              data.transactionCount.toString(),
              data.averageTransactionValue.toStringAsFixed(2),
            ]);
          }
        }
        break;

      case ReportType.paymentMethod:
        if (_paymentMethodReport != null) {
          csvData.add([
            'Payment Method',
            'Total Amount',
            'Transactions',
            'Average Transaction',
            'Percentage',
          ]);
          for (final entry in _paymentMethodReport!.paymentBreakdown.entries) {
            final name = entry.key;
            final data = entry.value;
            final f = _currentFilter;
            if (f != null) {
              if (f.searchText != null &&
                  f.searchText!.isNotEmpty &&
                  !name.toLowerCase().contains(f.searchText!.toLowerCase()))
                continue;
              if (f.minAmount != null && data.totalAmount < f.minAmount!) continue;
              if (f.maxAmount != null && data.totalAmount > f.maxAmount!) continue;
            }
            csvData.add([
              name,
              data.totalAmount.toStringAsFixed(2),
              data.transactionCount.toString(),
              data.averageTransaction.toStringAsFixed(2),
              '${data.percentageOfTotal.toStringAsFixed(1)}%',
            ]);
          }
        }
        break;

      case ReportType.employeePerformance:
        if (_employeePerformanceReport != null) {
          csvData.add([
            'Employee',
            'Total Sales',
            'Transactions',
            'Average Transaction',
            'Discounts Given',
          ]);
          for (final employee in _employeePerformanceReport!.employeePerformance.where((employee) {
            final f = _currentFilter;
            if (f == null) return true;
            var ok = true;
            if (f.searchText != null && f.searchText!.isNotEmpty)
              ok = employee.employeeName.toLowerCase().contains(f.searchText!.toLowerCase());
            if (f.minAmount != null) ok = ok && employee.totalSales >= f.minAmount!;
            if (f.maxAmount != null) ok = ok && employee.totalSales <= f.maxAmount!;
            return ok;
          })) {
            csvData.add([
              employee.employeeName,
              employee.totalSales.toStringAsFixed(2),
              employee.transactionCount.toString(),
              employee.averageTransactionValue.toStringAsFixed(2),
              employee.totalDiscountsGiven.toStringAsFixed(2),
            ]);
          }
        }
        break;

      case ReportType.inventory:
        if (_inventoryReport != null) {
          csvData.add([
            'Item Name',
            'Category',
            'Stock Level',
            'Reorder Point',
            'Status',
            'Days Since Last Sale',
          ]);
          for (final item in _inventoryReport!.inventoryItems) {
            csvData.add([
              item.itemName,
              item.category,
              item.currentStock.toString(),
              item.reorderPoint.toString(),
              item.stockStatus,
              item.daysSinceLastSale.toString(),
            ]);
          }
        }
        break;

      case ReportType.shrinkage:
        if (_shrinkageReport != null) {
          csvData.add([
            'Item Name',
            'Expected Quantity',
            'Actual Quantity',
            'Variance',
            'Reason',
            'Last Count Date',
          ]);
          for (final item in _shrinkageReport!.shrinkageItems) {
            csvData.add([
              item.itemName,
              item.expectedQuantity.toString(),
              item.actualQuantity.toString(),
              item.variance.toString(),
              item.reason,
              item.lastCountDate.toString(),
            ]);
          }
        }
        break;

      case ReportType.laborCost:
        if (_laborCostReport != null) {
          csvData.add(['Department', 'Labor Cost', 'Percentage of Sales']);
          for (final entry in _laborCostReport!.laborCostByDepartment.entries) {
            final dept = entry.key;
            final cost = entry.value;
            csvData.add([
              dept,
              cost.toStringAsFixed(2),
              '${_laborCostReport!.laborCostPercentage.toStringAsFixed(1)}%',
            ]);
          }
        }
        break;

      case ReportType.customerAnalysis:
        if (_customerReport != null) {
          csvData.add([
            'Customer Name',
            'Total Spent',
            'Visit Count',
            'Average Order Value',
            'Last Visit',
          ]);
          for (final customer in _customerReport!.topCustomers.where((customer) {
            final f = _currentFilter;
            if (f == null) return true;
            var ok = true;
            if (f.searchText != null && f.searchText!.isNotEmpty)
              ok = customer.customerName.toLowerCase().contains(f.searchText!.toLowerCase());
            if (f.minAmount != null) ok = ok && customer.totalSpent >= f.minAmount!;
            if (f.maxAmount != null) ok = ok && customer.totalSpent <= f.maxAmount!;
            return ok;
          })) {
            csvData.add([
              customer.customerName,
              customer.totalSpent.toStringAsFixed(2),
              customer.visitCount.toString(),
              customer.averageOrderValue.toStringAsFixed(2),
              customer.lastVisit.toString(),
            ]);
          }
        }
        break;

      case ReportType.basketAnalysis:
        if (_basketAnalysisReport != null) {
          csvData.add(['Analysis Type', 'Details']);
          csvData.add([
            'Frequently Bought Together',
            _basketAnalysisReport!.frequentlyBoughtTogether.length.toString(),
          ]);
          csvData.add([
            'Product Affinities',
            _basketAnalysisReport!.productAffinityScores.length.toString(),
          ]);
          csvData.add([
            'Recommended Bundles',
            _basketAnalysisReport!.recommendedBundles.length.toString(),
          ]);
        }
        break;

      case ReportType.loyaltyProgram:
        if (_loyaltyProgramReport != null) {
          csvData.add(['Metric', 'Value']);
          csvData.add(['Total Members', _loyaltyProgramReport!.totalMembers.toString()]);
          csvData.add(['Active Members', _loyaltyProgramReport!.activeMembers.toString()]);
          csvData.add(['Points Issued', _loyaltyProgramReport!.totalPointsIssued.toString()]);
          csvData.add(['Points Redeemed', _loyaltyProgramReport!.totalPointsRedeemed.toString()]);
          csvData.add([
            'Redemption Rate',
            '${_loyaltyProgramReport!.redemptionRate.toStringAsFixed(1)}%',
          ]);
        }
        break;

      case ReportType.dayClosing:
        _appendDayClosingCsv(csvData);
        break;
      case ReportType.profitLoss:
        _appendProfitLossCsv(csvData);
        break;
      case ReportType.cashFlow:
        _appendCashFlowCsv(csvData);
        break;
      case ReportType.taxSummary:
        _appendTaxSummaryCsv(csvData);
        break;
      case ReportType.inventoryValuation:
        _appendInventoryValuationCsv(csvData);
        break;
      case ReportType.abcAnalysis:
        _appendAbcAnalysisCsv(csvData);
        break;
      case ReportType.demandForecasting:
        _appendDemandForecastingCsv(csvData);
        break;
      case ReportType.menuEngineering:
        _appendMenuEngineeringCsv(csvData);
        break;
      case ReportType.tablePerformance:
        _appendTablePerformanceCsv(csvData);
        break;
      case ReportType.dailyStaffPerformance:
        _appendDailyStaffPerformanceCsv(csvData);
        break;
    }

    return const ListToCsvConverter().convert(csvData);
  }

  Future<void> _exportReport() async {
    if (_isLoading) return;

    try {
      final csvData = _generateCSVData();
      final fileName =
          '${_selectedReportType.name}_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop: Use file selector to save
        final file = await getSaveLocation(suggestedName: fileName);
        if (file != null) {
          await File(file.path).writeAsString(csvData);
          if (mounted)
            ToastHelper.showToast(context, 'Report exported successfully');
        }
      } else {
        // Mobile: Share file
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(csvData);
        await SharePlus.instance.share(
          ShareParams(text: 'Exported Report', sharePositionOrigin: Rect.zero),
        );
      }
    } catch (e) {
      if (mounted) ToastHelper.showToast(context, 'Export failed: $e');
    }
  }

  Future<void> _exportPDF() async {
    if (_isLoading) return;

    try {
      final pdf = pw.Document();
      final reportTitle = _getReportTypeLabel(_selectedReportType);
      final generatedDate = DateTime.now();

      // Add title page
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  reportTitle,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Period: ${_selectedPeriod.label}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  'Generated: ${generatedDate.toString()}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
                _buildPDFContent(),
              ],
            );
          },
        ),
      );

      // Save or share the PDF
      final fileName =
          '${_selectedReportType.name}_${generatedDate.toIso8601String().substring(0, 10)}.pdf';

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop: Use file selector to save
        final file = await getSaveLocation(suggestedName: fileName);
        if (file != null) {
          final bytes = await pdf.save();
          await File(file.path).writeAsBytes(bytes);
          if (mounted)
            ToastHelper.showToast(context, 'PDF exported successfully');
        }
      } else {
        // Mobile: Use printing package to share/print
        await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
      }
    } catch (e) {
      if (mounted) ToastHelper.showToast(context, 'PDF export failed: $e');
    }
  }

  pw.Widget _buildPDFContent() {
    switch (_selectedReportType) {
      case ReportType.salesSummary:
        return _buildSalesSummaryPDF();
      case ReportType.productSales:
        return _buildProductSalesPDF();
      case ReportType.categorySales:
        return _buildCategorySalesPDF();
      case ReportType.paymentMethod:
        return _buildPaymentMethodPDF();
      case ReportType.employeePerformance:
        return _buildEmployeePerformancePDF();
      case ReportType.inventory:
        return _buildInventoryPDF();
      case ReportType.shrinkage:
        return _buildShrinkagePDF();
      case ReportType.laborCost:
        return _buildLaborCostPDF();
      case ReportType.customerAnalysis:
        return _buildCustomerAnalysisPDF();
      case ReportType.basketAnalysis:
        return _buildBasketAnalysisPDF();
      case ReportType.loyaltyProgram:
        return _buildLoyaltyProgramPDF();
      case ReportType.dayClosing:
        return _buildDayClosingPDF();
      case ReportType.profitLoss:
        return _buildProfitLossPDF();
      case ReportType.cashFlow:
        return _buildCashFlowPDF();
      case ReportType.taxSummary:
        return _buildTaxSummaryPDF();
      case ReportType.inventoryValuation:
        return _buildInventoryValuationPDF();
      case ReportType.abcAnalysis:
        return _buildABCAnalysisPDF();
      case ReportType.demandForecasting:
        return _buildDemandForecastingPDF();
      case ReportType.menuEngineering:
        return _buildMenuEngineeringPDF();
      case ReportType.tablePerformance:
        return _buildTablePerformancePDF();
      case ReportType.dailyStaffPerformance:
        return _buildDailyStaffPerformancePDF();
    }
  }
}
