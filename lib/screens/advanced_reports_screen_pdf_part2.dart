// Part of advanced_reports_screen.dart

part of 'advanced_reports_screen.dart';

extension AdvancedReportsPdfPart2 on _AdvancedReportsScreenState {
  pw.Widget _buildCashFlowPDF() {
    if (_cashFlowReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Cash Flow Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Opening Cash: ${FormattingService.currency(_cashFlowReport!.openingCash)}',
        ),
        pw.Text(
          'Closing Cash: ${FormattingService.currency(_cashFlowReport!.closingCash)}',
        ),
        pw.Text(
          'Net Cash Flow: ${FormattingService.currency(_cashFlowReport!.netCashFlow)}',
        ),
      ],
    );
  }

  pw.Widget _buildTaxSummaryPDF() {
    if (_taxSummaryReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Tax Summary Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Total Tax Collected: ${FormattingService.currency(_taxSummaryReport!.totalTaxCollected)}',
        ),
        pw.Text(
          'Tax Liability: ${FormattingService.currency(_taxSummaryReport!.taxLiability)}',
        ),
        ..._taxSummaryReport!.taxBreakdown.entries.map(
          (entry) => pw.Text(
            '${entry.key} Tax Rate: ${FormattingService.currency(entry.value)}',
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInventoryValuationPDF() {
    if (_inventoryValuationReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Inventory Valuation Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Total Value: ${FormattingService.currency(_inventoryValuationReport!.totalInventoryValue)}',
        ),
        pw.Text(
          'Turnover Ratio: ${_inventoryValuationReport!.inventoryTurnoverRatio.toStringAsFixed(2)}',
        ),
        ..._inventoryValuationReport!.valuationItems
            .take(10)
            .map(
              (item) => pw.Text(
                '${item.itemName}: ${FormattingService.currency(item.totalRetailValue)}',
              ),
            ),
      ],
    );
  }

  pw.Widget _buildABCAnalysisPDF() {
    if (_abcAnalysisReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ABC Analysis Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'A Category Revenue: ${FormattingService.currency(_abcAnalysisReport!.aCategoryRevenue)}',
        ),
        pw.Text(
          'B Category Revenue: ${FormattingService.currency(_abcAnalysisReport!.bCategoryRevenue)}',
        ),
        pw.Text(
          'C Category Revenue: ${FormattingService.currency(_abcAnalysisReport!.cCategoryRevenue)}',
        ),
        ..._abcAnalysisReport!.abcItems
            .take(10)
            .map(
              (item) => pw.Text(
                '${item.itemName} (${item.category}): ${item.percentageOfTotal.toStringAsFixed(1)}%',
              ),
            ),
      ],
    );
  }

  pw.Widget _buildDemandForecastingPDF() {
    if (_demandForecastingReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Demand Forecasting Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Forecasting Method: ${_demandForecastingReport!.forecastingMethod}',
        ),
        pw.Text(
          'Forecast Accuracy: ${(_demandForecastingReport!.forecastAccuracy * 100).toStringAsFixed(1)}%',
        ),
        ..._demandForecastingReport!.forecastItems
            .take(5)
            .map(
              (item) => pw.Text(
                '${item.itemName}: Historical ${item.historicalSales.last.toStringAsFixed(0)}, Forecast ${item.forecastedSales.last.toStringAsFixed(0)}',
              ),
            ),
      ],
    );
  }

  pw.Widget _buildMenuEngineeringPDF() {
    if (_menuEngineeringReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Menu Engineering Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Stars: ${_menuEngineeringReport!.starsCount}'),
        pw.Text('Plowhorses: ${_menuEngineeringReport!.plowhorsesCount}'),
        pw.Text('Puzzles: ${_menuEngineeringReport!.puzzlesCount}'),
        pw.Text('Dogs: ${_menuEngineeringReport!.dogsCount}'),
        ..._menuEngineeringReport!.menuItems
            .take(10)
            .map(
              (item) => pw.Text(
                '${item.itemName} (${item.category}): ${item.popularity.toStringAsFixed(1)}% / ${item.profitability.toStringAsFixed(1)}%',
              ),
            ),
      ],
    );
  }

  pw.Widget _buildTablePerformancePDF() {
    if (_tablePerformanceReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Table Performance Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Total Tables: ${_tablePerformanceReport!.totalTables}'),
        pw.Text('Occupied Tables: ${_tablePerformanceReport!.occupiedTables}'),
        pw.Text(
          'Average Turnover: ${_tablePerformanceReport!.averageTableTurnover.toStringAsFixed(1)}',
        ),
        pw.Text(
          'Average Revenue/Table: ${FormattingService.currency(_tablePerformanceReport!.averageRevenuePerTable)}',
        ),
        ..._tablePerformanceReport!.tableData
            .take(10)
            .map(
              (table) => pw.Text(
                '${table.tableName}: ${FormattingService.currency(table.totalRevenue)}, ${table.totalOrders} orders',
              ),
            ),
      ],
    );
  }

}
