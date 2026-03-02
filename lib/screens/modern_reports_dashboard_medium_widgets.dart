part of 'modern_reports_dashboard.dart';

extension ModernReportsDashboardMediumWidgets on _ModernReportsDashboardState {
  Widget _buildModeAndDateHeader() {
    final periodLabel = _activeTimeRange == TimeRange.custom
        ? '${DateFormat('dd MMM yyyy').format(_startDate)} to ${DateFormat('dd MMM yyyy').format(_endDate)}'
        : DateFormat('dd MMM yyyy').format(DateTime.now());

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
            children: BusinessMode.values.map((mode) {
              final isActive = _activeMode == mode;
              return GestureDetector(
                onTap: () {
                  setState(() => _activeMode = mode);
                  _loadData();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _displayModeName(mode).toUpperCase(),
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
              'Reporting Period: $periodLabel',
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_displayModeName(_activeMode)} Analytics',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'Detailed intelligence for ExtroPOS ${_displayModeName(_activeMode).toLowerCase()} owners',
                style: const TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: TimeRange.values.map((range) {
                  final isActive = _activeTimeRange == range;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _activeTimeRange = range;
                        final period = _periodForRange(range);
                        _startDate = period.startDate;
                        _endDate = period.endDate;
                      });
                      _loadData();
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.black : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _displayRangeName(range),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (_activeTimeRange == TimeRange.custom) ...[
              const SizedBox(height: 12),
              _buildCustomDatePicker(),
            ],
            const SizedBox(height: 12),
            _buildExportDropdown(),
          ],
        ),
      ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              _buildShiftCard(
                'X-Report',
                'Snapshot (Read Only)',
                Icons.description,
                const Color(0xFF4F46E5),
                Colors.indigo.shade50,
                'X',
              ),
              const SizedBox(height: 24),
              _buildShiftCard(
                'Z-Report',
                'Daily Close (Reset)',
                Icons.lock,
                Colors.red.shade600,
                Colors.red.shade50,
                'Z',
              ),
            ],
          );
        }

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
      },
    );
  }

}
