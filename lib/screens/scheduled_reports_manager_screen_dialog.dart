import 'package:extropos/models/advanced_reporting_features.dart';
import 'package:extropos/models/sales_report.dart' show ReportPeriod;
import 'package:extropos/services/advanced_reporting_service.dart';
import 'package:flutter/material.dart';

class ReportScheduleDialog extends StatefulWidget {
  final ScheduledReport? existing;

  const ReportScheduleDialog({super.key, this.existing});

  @override
  State<ReportScheduleDialog> createState() => _ReportScheduleDialogState();
}

class _ReportScheduleDialogState extends State<ReportScheduleDialog> {
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
