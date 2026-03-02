part of 'reports_screen.dart';

extension ReportsScreenViewWidgetsPart1 on _ReportsScreenState {
  Widget _buildBasicReportsView() {
    if (_currentReport == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format selector for printing
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Print Format',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Thermal 58mm'),
                        selected: _selectedFormat == ReportFormat.thermal58mm,
                        onSelected: (selected) {
                          if (selected)
                            setState(
                              () => _selectedFormat = ReportFormat.thermal58mm,
                            );
                        },
                      ),
                      FilterChip(
                        label: const Text('Thermal 80mm'),
                        selected: _selectedFormat == ReportFormat.thermal80mm,
                        onSelected: (selected) {
                          if (selected)
                            setState(
                              () => _selectedFormat = ReportFormat.thermal80mm,
                            );
                        },
                      ),
                      FilterChip(
                        label: const Text('PDF A4'),
                        selected: _selectedFormat == ReportFormat.pdfA4,
                        onSelected: (selected) {
                          if (selected)
                            setState(
                              () => _selectedFormat = ReportFormat.pdfA4,
                            );
                        },
                      ),
                      FilterChip(
                        label: const Text('PDF Thermal'),
                        selected: _selectedFormat == ReportFormat.pdfThermal,
                        onSelected: (selected) {
                          if (selected)
                            setState(
                              () => _selectedFormat = ReportFormat.pdfThermal,
                            );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Period Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Period',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Today'),
                        selected:
                            _selectedPeriod.startDate.day == DateTime.now().day,
                        onSelected: (selected) {
                          if (selected) {
                            setState(
                              () => _selectedPeriod = ReportPeriod.today(),
                            );
                            _loadReport();
                          }
                        },
                      ),
                      FilterChip(
                        label: const Text('This Week'),
                        selected:
                            _selectedPeriod.startDate.weekday == 1 &&
                            _selectedPeriod.endDate
                                    .difference(_selectedPeriod.startDate)
                                    .inDays ==
                                6,
                        onSelected: (selected) {
                          if (selected) {
                            setState(
                              () => _selectedPeriod = ReportPeriod.thisWeek(),
                            );
                            _loadReport();
                          }
                        },
                      ),
                      FilterChip(
                        label: const Text('This Month'),
                        selected:
                            _selectedPeriod.startDate.day == 1 &&
                            _selectedPeriod.endDate.month ==
                                DateTime.now().month,
                        onSelected: (selected) {
                          if (selected) {
                            setState(
                              () => _selectedPeriod = ReportPeriod.thisMonth(),
                            );
                            _loadReport();
                          }
                        },
                      ),
                      FilterChip(
                        label: const Text('Last Month'),
                        selected:
                            _selectedPeriod.startDate.month ==
                            (DateTime.now().month == 1
                                ? 12
                                : DateTime.now().month - 1),
                        onSelected: (selected) {
                          if (selected) {
                            setState(
                              () => _selectedPeriod = ReportPeriod.lastMonth(),
                            );
                            _loadReport();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Total Sales',
                  value: FormattingService.currency(_currentReport!.grossSales),
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Total Orders',
                  value: _currentReport!.transactionCount.toString(),
                  icon: Icons.receipt,
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Avg Order Value',
                  value: FormattingService.currency(
                    _currentReport!.averageTicket,
                  ),
                  icon: Icons.trending_up,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Period',
                  value:
                      '${_selectedPeriod.startDate.toString().split(' ')[0]} to ${_selectedPeriod.endDate.toString().split(' ')[0]}',
                  icon: Icons.calendar_today,
                  color: Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Payment Methods Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Methods',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._currentReport!.paymentMethods.entries.map((entry) {
                    final percentage = _currentReport!.grossSales > 0
                        ? (entry.value / _currentReport!.grossSales * 100)
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(entry.key)),
                          Text(
                            FormattingService.currency(entry.value),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 60,
                            child: Text(
                              '${percentage.toStringAsFixed(1)}%',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Top Selling Items
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._currentReport!.topCategories.entries
                      .take(10)
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(child: Text(entry.key)),
                              Text(
                                FormattingService.currency(entry.value),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Hourly Sales Chart (Simple)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hourly Sales',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Hourly sales chart requires enhanced reporting model
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Hourly sales data not available.\nEnable enhanced reporting in settings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
