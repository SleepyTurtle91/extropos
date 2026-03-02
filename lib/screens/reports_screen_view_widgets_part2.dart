part of 'reports_screen.dart';

extension ReportsScreenViewWidgetsPart2 on _ReportsScreenState {
  Widget _buildAdvancedReportsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report type selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Type',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ReportType.values.map((type) {
                      return FilterChip(
                        label: Text(_getReportTypeLabel(type)),
                        selected: _selectedReportType == type,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedReportType = type);
                            _loadReport();
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Format selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Output Format',
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

          // Period selector (for time-based reports)
          if (_selectedReportType != ReportType.inventory)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Period',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Today'),
                          selected: _selectedPeriod == ReportPeriod.today(),
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
                          selected: _selectedPeriod == ReportPeriod.thisWeek(),
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
                          selected: _selectedPeriod == ReportPeriod.thisMonth(),
                          onSelected: (selected) {
                            if (selected) {
                              setState(
                                () =>
                                    _selectedPeriod = ReportPeriod.thisMonth(),
                              );
                              _loadReport();
                            }
                          },
                        ),
                        FilterChip(
                          label: const Text('Last Month'),
                          selected: _selectedPeriod == ReportPeriod.lastMonth(),
                          onSelected: (selected) {
                            if (selected) {
                              setState(
                                () =>
                                    _selectedPeriod = ReportPeriod.lastMonth(),
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

          // Report content
          _buildAdvancedReportContent(),
        ],
      ),
    );
  }

  Widget _buildCustomerContent() {
    if (_customerReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Total Active Customers: ${_customerReport!.totalActiveCustomers}',
            ),
            Text(
              'Average Customer Lifetime Value: ${FormattingService.currency(_customerReport!.averageCustomerLifetimeValue)}',
            ),
          ],
        ),
      ),
    );
  }

}
