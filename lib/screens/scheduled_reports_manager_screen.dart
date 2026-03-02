import 'package:extropos/models/advanced_reporting_features.dart';
import 'package:extropos/screens/scheduled_reports_manager_screen_dialog.dart';
import 'package:extropos/services/advanced_reporting_service.dart';
import 'package:extropos/theme/spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

part 'scheduled_reports_manager_screen_ui.dart';

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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading reports: $e')));
      }
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
      builder: (context) => ReportScheduleDialog(existing: existing),
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
              buildDetailRow(
                'Report Type',
                getReportTypeName(report.reportType),
              ),
              buildDetailRow('Frequency', getFrequencyName(report.frequency)),
              buildDetailRow('Period', report.period.label),
              buildDetailRow('Recipients', report.recipientEmails.join(', ')),
              buildDetailRow(
                'Export Formats',
                report.exportFormats
                    .map((f) => f.name.toUpperCase())
                    .join(', '),
              ),
              if (report.nextRun != null)
                buildDetailRow(
                  'Next Run',
                  DateFormat('MMM d, y HH:mm').format(report.nextRun!),
                ),
              if (report.lastRun != null)
                buildDetailRow(
                  'Last Run',
                  DateFormat('MMM d, y HH:mm').format(report.lastRun!),
                ),
              buildDetailRow(
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
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
      body: buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateReportDialog,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Schedule'),
      ),
    );
  }
}
