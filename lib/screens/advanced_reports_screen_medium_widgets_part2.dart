part of 'advanced_reports_screen.dart';

extension AdvancedReportsMediumWidgetsPart2 on _AdvancedReportsScreenState {
  Widget _buildEmployeePerformanceContent() {
    if (_employeePerformanceReport == null) return const SizedBox.shrink();

    final report = _employeePerformanceReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Employees',
              report.employeePerformance
                  .where(_matchesEmployeeFilter)
                  .length
                  .toString(),
              Icons.people,
            ),
            _buildMetricCard(
              'Top Performer',
              (report.employeePerformance.where(_matchesEmployeeFilter).isEmpty
                  ? report.topPerformer
                  : report.employeePerformance
                        .where(_matchesEmployeeFilter)
                        .reduce((a, b) => a.totalSales > b.totalSales ? a : b)
                        .employeeName),
              Icons.star,
            ),
          ],
        ),

        const SizedBox(height: 32),

        const Text(
          'Employee Performance',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: report.employeePerformance
                  .where((employee) {
                    final f = _currentFilter;
                    if (f == null) return true;
                    var ok = true;
                    if (f.searchText != null && f.searchText!.isNotEmpty) {
                      ok = employee.employeeName.toLowerCase().contains(
                        f.searchText!.toLowerCase(),
                      );
                    }
                    if (f.minAmount != null) {
                      ok = ok && employee.totalSales >= f.minAmount!;
                    }
                    if (f.maxAmount != null) {
                      ok = ok && employee.totalSales <= f.maxAmount!;
                    }
                    return ok;
                  })
                  .map((employee) {
                    return ListTile(
                      title: Text(employee.employeeName),
                      subtitle: Text(
                        '${employee.transactionCount} transactions � Avg: RM${employee.averageTransactionValue.toStringAsFixed(2)}',
                      ),
                      trailing: Text(
                        'RM${employee.totalSales.toStringAsFixed(2)}',
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryContent() {
    if (_inventoryReport == null) return const SizedBox.shrink();

    final report = _inventoryReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Items',
              report.inventoryItems.length.toString(),
              Icons.inventory,
            ),
            _buildMetricCard(
              'Low Stock Items',
              report.lowStockItems.length.toString(),
              Icons.warning,
            ),
            _buildMetricCard(
              'Out of Stock',
              report.outOfStockItems.length.toString(),
              Icons.error,
            ),
            _buildMetricCard(
              'Total Value',
              'RM${report.totalInventoryValue.toStringAsFixed(2)}',
              Icons.attach_money,
            ),
          ],
        ),

        const SizedBox(height: 32),

        const Text(
          'Inventory Status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: report.inventoryItems.take(20).map((item) {
                return ListTile(
                  title: Text(item.itemName),
                  subtitle: Text(
                    '${item.category} � Stock: ${item.currentStock}',
                  ),
                  trailing: Text(item.stockStatus),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShrinkageContent() {
    if (_shrinkageReport == null) return const SizedBox.shrink();

    final report = _shrinkageReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Shrinkage Items',
              report.shrinkageItems.length.toString(),
              Icons.warning,
            ),
            _buildMetricCard(
              'Total Shrinkage Value',
              'RM${report.totalShrinkageValue.toStringAsFixed(2)}',
              Icons.attach_money,
            ),
            _buildMetricCard(
              'Shrinkage %',
              '${report.totalShrinkagePercentage.toStringAsFixed(1)}%',
              Icons.percent,
            ),
          ],
        ),

        const SizedBox(height: 32),

        const Text(
          'Shrinkage Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: report.shrinkageItems.take(20).map((item) {
                return ListTile(
                  title: Text(item.itemName),
                  subtitle: Text(
                    'Variance: ${item.variance} � Reason: ${item.reason}',
                  ),
                  trailing: Text('RM${item.varianceValue.toStringAsFixed(2)}'),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLaborCostContent() {
    if (_laborCostReport == null) return const SizedBox.shrink();

    final report = _laborCostReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Labor Cost',
              'RM${report.totalLaborCost.toStringAsFixed(2)}',
              Icons.attach_money,
            ),
            _buildMetricCard(
              'Labor Cost %',
              '${report.laborCostPercentage.toStringAsFixed(1)}%',
              Icons.percent,
            ),
            _buildMetricCard(
              'Efficiency Data Points',
              report.efficiencyData.length.toString(),
              Icons.analytics,
            ),
          ],
        ),

        const SizedBox(height: 32),

        const Text(
          'Labor Cost by Department',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: report.laborCostByDepartment.entries.map((entry) {
                return ListTile(
                  title: Text(entry.key),
                  trailing: Text('RM${entry.value.toStringAsFixed(2)}'),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
