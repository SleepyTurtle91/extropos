part of 'reports_dashboard_screen.dart';

extension ReportsDashboardUIBuilders on _ReportsDashboardScreenState {
  Widget _buildReportsDashboardScreen(BuildContext context) {
    final Color accentColor = _getAccentColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModeAndDateHeader(),
                const SizedBox(height: 24),
                _buildMainTitleHeader(accentColor),
                const SizedBox(height: 40),
                if (activeTimeRange == ReportsTimeRange.daily)
                  _buildShiftOperations(),
                const SizedBox(height: 40),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  _buildStatsGrid(),
                  const SizedBox(height: 40),
                  _buildInventoryValuation(accentColor),
                  const SizedBox(height: 40),
                  _buildPerformanceSection(accentColor),
                ],
              ],
            ),
          ),
          if (activeModalReport != null) _buildReportModalOverlay(),
          if (exportingType != null) _buildExportOverlay(),
        ],
      ),
    );
  }

  Color _getAccentColor() {
    switch (activeMode) {
      case ReportsBusinessType.retail:
        return const Color(0xFF4F46E5);
      case ReportsBusinessType.cafe:
        return Colors.amber.shade800;
      case ReportsBusinessType.dining:
        return Colors.red.shade700;
    }
  }

  Widget _buildModeAndDateHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: ReportsBusinessType.values.map((mode) {
              final isActive = activeMode == mode;
              return GestureDetector(
                onTap: () {
                  setState(() => activeMode = mode);
                  _fetchReportData();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    mode.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Reporting Period: ${activeTimeRange == ReportsTimeRange.custom ? '${startDate.day}/${startDate.month} to ${endDate.day}/${endDate.month}' : '21 Feb 2026'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainTitleHeader(Color accent) {
    return MainTitleHeaderWidget(
      activeTimeRange: activeTimeRange,
      onTimeRangeChanged: (range) {
        setState(() => activeTimeRange = range);
        _fetchReportData();
      },
      modeName: activeMode.name,
      customDatePicker: activeTimeRange == ReportsTimeRange.custom
          ? _buildCustomDatePicker()
          : null,
      exportDropdown: _buildExportDropdown(),
    );
  }

  Widget _buildCustomDatePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event, size: 14, color: Colors.grey),
          SizedBox(width: 8),
          Text(
            '2026-02-01 to 2026-02-21',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildExportDropdown() {
    return PopupMenuButton<String>(
      onSelected: _handleExport,
      offset: const Offset(0, 50),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text('Export PDF'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'csv',
          child: Row(
            children: [
              Icon(Icons.table_chart, color: Colors.green, size: 18),
              SizedBox(width: 8),
              Text('Export CSV'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF4F46E5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Export Report',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftOperations() {
    return Row(
      children: [
        Expanded(
          child: _buildShiftCard(
            'X-Report',
            'Snapshot (Read Only)',
            Icons.description,
            const Color(0xFF4F46E5),
            Colors.indigo.shade50,
            'X',
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildShiftCard(
            'Z-Report',
            'Daily Close (Reset)',
            Icons.lock,
            Colors.red.shade600,
            Colors.red.shade50,
            'Z',
          ),
        ),
      ],
    );
  }

  Widget _buildShiftCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Color bg,
    String key,
  ) {
    return ReportsShiftCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      bgColor: bg,
      reportKey: key,
      onViewDetails: () => setState(() => activeModalReport = key),
    );
  }

  Widget _buildStatsGrid() {
    if (currentStats.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;
        if (constraints.maxWidth < 600) {
          columns = 1;
        } else if (constraints.maxWidth < 900) {
          columns = 2;
        } else if (constraints.maxWidth < 1200) {
          columns = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 24,
            mainAxisExtent: 160,
          ),
          itemCount: currentStats.length,
          itemBuilder: (context, index) {
            final stat = currentStats[index];
            return ReportsStatCard(
              label: stat.label,
              value: stat.value,
              trend: stat.trend,
              isUp: stat.isUp,
              icon: stat.icon,
              color: stat.color,
            );
          },
        );
      },
    );
  }

  Widget _buildInventoryValuation(Color accent) {
    return InventoryValuationWidget(
      inventory: currentInventory,
      accentColor: accent,
      onExport: _handleExport,
      onAddStock: () {},
    );
  }

  Widget _buildPerformanceSection(Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildPlaceholderChart(accent)),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: _buildCategoryBreakdown()),
      ],
    );
  }

  Widget _buildPlaceholderChart(Color accent) {
    return Container(
      padding: const EdgeInsets.all(32),
      height: 420,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Performance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          const Center(
            child: Text(
              'Chart visualization ready for database stream',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Container(
      padding: const EdgeInsets.all(32),
      height: 420,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            breakdownTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 32),
          if (currentBreakdown.isEmpty)
            const Expanded(
              child: Center(child: Text('No category data available.')),
            )
          else
            ...currentBreakdown.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('${item.percentage.toInt()}%'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: item.percentage / 100,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation(item.color),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExportOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.1),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Generating ${exportingType?.toUpperCase()}...',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: exportProgress),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportModalOverlay() {
    return ReportModalOverlayWidget(
      reportType: activeModalReport!,
      onClose: () => setState(() => activeModalReport = null),
    );
  }
}
