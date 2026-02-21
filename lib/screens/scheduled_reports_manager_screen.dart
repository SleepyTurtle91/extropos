import 'package:extropos/models/advanced_reporting_features.dart';
import 'package:extropos/models/sales_report.dart' show ReportPeriod;
import 'package:extropos/services/advanced_reporting_service.dart';
import 'package:extropos/theme/spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduledReportsManagerScreen extends StatefulWidget {
  const ScheduledReportsManagerScreen({super.key});

  @override
  State<ScheduledReportsManagerScreen> createState() =>
      _ScheduledReportsManagerScreenState();
}

class _ScheduledReportsManagerScreenState
    extends State<ScheduledReportsManagerScreen> {
  List<ScheduledReport> _scheduledReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScheduledReports();
  }

  Future<void> _loadScheduledReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await AdvancedReportingService.instance
          .getScheduledReports();
      setState(() {
        _scheduledReports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading reports: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduled Reports'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScheduledReports,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateReportDialog,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Schedule'),
      ),
    );
  }

  Widget _buildBody() {
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
              return _buildReportCard(_scheduledReports[index]);
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
              return _buildReportCard(_scheduledReports[index]);
            },
          );
        }
      },
    );
  }

  Widget _buildReportCard(ScheduledReport report) {
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
              _buildInfoRow(
                Icons.analytics_outlined,
                _getReportTypeName(report.reportType),
              ),
              const SizedBox(height: 4),
              _buildInfoRow(
                Icons.schedule_outlined,
                _getFrequencyName(report.frequency),
              ),
              const SizedBox(height: 4),
              _buildInfoRow(
                Icons.email_outlined,
                '${report.recipientEmails.length} recipient(s)',
              ),
              const SizedBox(height: 4),
              _buildInfoRow(
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

  Widget _buildInfoRow(IconData icon, String text) {
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

  String _getReportTypeName(ReportType type) {
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

  String _getFrequencyName(ScheduleFrequency frequency) {
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

  void _showCreateReportDialog() {
    _showReportDialog();
  }

  void _editReport(ScheduledReport report) {
    _showReportDialog(existing: report);
  }

  void _showReportDialog({ScheduledReport? existing}) {
    showDialog(
      context: context,
      builder: (context) => _ReportScheduleDialog(existing: existing),
    ).then((report) {
      if (report != null) {
        _loadScheduledReports();
      }
    });
  }

  void _showReportDetails(ScheduledReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'Report Type',
                _getReportTypeName(report.reportType),
              ),
              _buildDetailRow('Frequency', _getFrequencyName(report.frequency)),
              _buildDetailRow('Period', report.period.label),
              _buildDetailRow('Recipients', report.recipientEmails.join(', ')),
              _buildDetailRow(
                'Export Formats',
                report.exportFormats
                    .map((f) => f.name.toUpperCase())
                    .join(', '),
              ),
              if (report.nextRun != null)
                _buildDetailRow(
                  'Next Run',
                  DateFormat('MMM d, y HH:mm').format(report.nextRun!),
                ),
              if (report.lastRun != null)
                _buildDetailRow(
                  'Last Run',
                  DateFormat('MMM d, y HH:mm').format(report.lastRun!),
                ),
              _buildDetailRow(
                'Status',
                report.isActive ? 'Active' : 'Inactive',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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

  Future<void> _toggleReportStatus(
    ScheduledReport report,
    bool isActive,
  ) async {
    final updated = report.copyWith(isActive: isActive);
    await AdvancedReportingService.instance.updateScheduledReport(updated);

    setState(() {
      final index = _scheduledReports.indexOf(report);
      if (index >= 0) {
        _scheduledReports[index] = updated;
      }
    });
  }

  Future<void> _testRunReport(ScheduledReport report) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Execute the report and send via email
      final success = await AdvancedReportingService.instance
          .executeScheduledReport(report);

      if (mounted) {
        Navigator.pop(context);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Report sent to ${report.recipientEmails.length} recipient(s)',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to send report. Check SMTP and email settings.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteReport(ScheduledReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scheduled Report'),
        content: Text('Are you sure you want to delete "${report.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AdvancedReportingService.instance.deleteScheduledReport(report.id);
      setState(() {
        _scheduledReports.remove(report);
      });
    }
  }
}

class _ReportScheduleDialog extends StatefulWidget {
  final ScheduledReport? existing;

  const _ReportScheduleDialog({this.existing});

  @override
  State<_ReportScheduleDialog> createState() => _ReportScheduleDialogState();
}

class _ReportScheduleDialogState extends State<_ReportScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailsController = TextEditingController();

  ReportType _selectedReportType = ReportType.salesSummary;
  ScheduleFrequency _selectedFrequency = ScheduleFrequency.daily;
  ReportPeriod _selectedPeriod = ReportPeriod.today();
  final Set<ExportFormat> _selectedFormats = {ExportFormat.pdf};

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _emailsController.text = widget.existing!.recipientEmails.join(', ');
      _selectedReportType = widget.existing!.reportType;
      _selectedFrequency = widget.existing!.frequency;
      _selectedPeriod = widget.existing!.period;
      _selectedFormats.addAll(widget.existing!.exportFormats);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Schedule' : 'New Schedule'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Schedule Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ReportType>(
                  value: _selectedReportType,
                  decoration: const InputDecoration(
                    labelText: 'Report Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ReportType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getReportTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedReportType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ScheduleFrequency>(
                  value: _selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                  ),
                  items: ScheduleFrequency.values.map((freq) {
                    return DropdownMenuItem(
                      value: freq,
                      child: Text(_getFrequencyName(freq)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedFrequency = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ReportPeriod>(
                  value: _selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Report Period',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      [
                        ReportPeriod.today(),
                        ReportPeriod.yesterday(),
                        ReportPeriod.thisWeek(),
                        ReportPeriod.lastWeek(),
                        ReportPeriod.thisMonth(),
                        ReportPeriod.lastMonth(),
                        ReportPeriod.thisYear(),
                        ReportPeriod.lastYear(),
                      ].map((period) {
                        return DropdownMenuItem(
                          value: period,
                          child: Text(period.label),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPeriod = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailsController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Emails (comma-separated)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter at least one email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Export Formats',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ExportFormat.values.map((format) {
                    return FilterChip(
                      label: Text(format.name.toUpperCase()),
                      selected: _selectedFormats.contains(format),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedFormats.add(format);
                          } else {
                            _selectedFormats.remove(format);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveSchedule,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _getReportTypeName(ReportType type) {
    // Use same logic as parent screen
    return type.name;
  }

  String _getFrequencyName(ScheduleFrequency frequency) {
    return frequency.name[0].toUpperCase() + frequency.name.substring(1);
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFormats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one export format'),
        ),
      );
      return;
    }

    final emails = _emailsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final report = await AdvancedReportingService.instance
        .createScheduledReport(
          name: _nameController.text,
          reportType: _selectedReportType,
          period: _selectedPeriod,
          frequency: _selectedFrequency,
          recipientEmails: emails,
          exportFormats: _selectedFormats.toList(),
        );

    if (mounted) {
      Navigator.pop(context, report);
    }
  }
}
