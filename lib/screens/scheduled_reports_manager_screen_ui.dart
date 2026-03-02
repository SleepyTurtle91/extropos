part of 'scheduled_reports_manager_screen.dart';

extension _ScheduledReportsUIBuilders on _ScheduledReportsManagerScreenState {
  Widget buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_scheduledReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Scheduled Reports',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first automated report schedule',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          // Mobile: List view
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _scheduledReports.length,
            itemBuilder: (context, index) {
              return buildReportCard(_scheduledReports[index]);
            },
          );
        } else {
          // Desktop: Grid view
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.m),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 420,
              crossAxisSpacing: AppSpacing.m,
              mainAxisSpacing: AppSpacing.m,
              childAspectRatio: 1.5,
            ),
            itemCount: _scheduledReports.length,
            itemBuilder: (context, index) {
              return buildReportCard(_scheduledReports[index]);
            },
          );
        }
      },
    );
  }

  Widget buildReportCard(ScheduledReport report) {
    final nextRun = report.nextRun;
    final lastRun = report.lastRun;
    final isActive = report.isActive;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showReportDetails(report),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Switch(
                    value: isActive,
                    onChanged: (value) => _toggleReportStatus(report, value),
                    activeColor: const Color(0xFF2563EB),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              buildInfoRow(
                Icons.analytics_outlined,
                getReportTypeName(report.reportType),
              ),
              const SizedBox(height: 4),
              buildInfoRow(
                Icons.schedule_outlined,
                getFrequencyName(report.frequency),
              ),
              const SizedBox(height: 4),
              buildInfoRow(
                Icons.email_outlined,
                '${report.recipientEmails.length} recipient(s)',
              ),
              const SizedBox(height: 4),
              buildInfoRow(
                Icons.download_outlined,
                report.exportFormats
                    .map((f) => f.name.toUpperCase())
                    .join(', '),
              ),
              const Spacer(),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Run',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        nextRun != null
                            ? DateFormat('MMM d, HH:mm').format(nextRun)
                            : 'Not scheduled',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (lastRun != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Last Run',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, HH:mm').format(lastRun),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _testRunReport(report),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Test Run'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editReport(report),
                    tooltip: 'Edit',
                    color: const Color(0xFF2563EB),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteReport(report),
                    tooltip: 'Delete',
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  String getReportTypeName(ReportType type) {
    switch (type) {
      case ReportType.salesSummary:
        return 'Sales Summary';
      case ReportType.productSales:
        return 'Product Sales';
      case ReportType.categorySales:
        return 'Category Sales';
      case ReportType.paymentMethod:
        return 'Payment Methods';
      case ReportType.employeePerformance:
        return 'Employee Performance';
      case ReportType.inventory:
        return 'Inventory Report';
      case ReportType.shrinkage:
        return 'Shrinkage Report';
      case ReportType.laborCost:
        return 'Labor Cost';
      case ReportType.customerAnalysis:
        return 'Customer Analysis';
      case ReportType.basketAnalysis:
        return 'Basket Analysis';
      case ReportType.loyaltyProgram:
        return 'Loyalty Program';
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
    }
  }

  String getFrequencyName(ScheduleFrequency frequency) {
    switch (frequency) {
      case ScheduleFrequency.hourly:
        return 'Hourly';
      case ScheduleFrequency.daily:
        return 'Daily';
      case ScheduleFrequency.weekly:
        return 'Weekly';
      case ScheduleFrequency.monthly:
        return 'Monthly';
      case ScheduleFrequency.quarterly:
        return 'Quarterly';
      case ScheduleFrequency.yearly:
        return 'Yearly';
    }
  }
}
