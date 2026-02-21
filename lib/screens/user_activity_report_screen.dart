import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/services/formatting_service.dart';
import 'package:extropos/services/user_activity_service.dart';
import 'package:flutter/material.dart';

class UserActivityReportScreen extends StatefulWidget {
  const UserActivityReportScreen({super.key});

  @override
  State<UserActivityReportScreen> createState() =>
      _UserActivityReportScreenState();
}

class _UserActivityReportScreenState extends State<UserActivityReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  Map<String, dynamic>? _activitySummary;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadActivitySummary();
  }

  Future<void> _loadActivitySummary() async {
    setState(() => _isLoading = true);
    try {
      final summary = await UserActivityService.instance.getUserActivitySummary(
        _startDate,
        _endDate,
      );
      setState(() => _activitySummary = summary);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading activity summary: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadActivitySummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Activity Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activitySummary == null
          ? const Center(child: Text('No activity data available'))
          : _buildActivityReport(),
    );
  }

  Widget _buildActivityReport() {
    final summary = _activitySummary!['summary'] as List<dynamic>;
    final dateRange = _activitySummary!['date_range'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'From ${FormattingService.formatDate(dateRange['start'])} to ${FormattingService.formatDate(dateRange['end'])}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Summary statistics
          if (summary.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Statistics',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Users',
                            summary.length.toString(),
                            Icons.people,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            'Total Transactions',
                            summary
                                .fold<int>(
                                  0,
                                  (sum, user) =>
                                      sum + (user['transaction_count'] as int),
                                )
                                .toString(),
                            Icons.receipt,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Sales',
                            '${BusinessInfo.instance.currencySymbol}${summary.fold<double>(0.0, (sum, user) => sum + (user['total_sales'] as double)).toStringAsFixed(2)}',
                            Icons.attach_money,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            'Cash Drawer Opens',
                            summary
                                .fold<int>(
                                  0,
                                  (sum, user) =>
                                      sum + (user['drawer_opens'] as int),
                                )
                                .toString(),
                            Icons.lock_open,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // User activity table
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Performance',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('User')),
                          DataColumn(label: Text('Transactions')),
                          DataColumn(label: Text('Total Sales')),
                          DataColumn(label: Text('Drawer Opens')),
                          DataColumn(label: Text('First Sign-in')),
                          DataColumn(label: Text('Last Sign-out')),
                        ],
                        rows: summary.map((user) {
                          return DataRow(
                            cells: [
                              DataCell(Text(user['full_name'] ?? 'Unknown')),
                              DataCell(
                                Text(user['transaction_count'].toString()),
                              ),
                              DataCell(
                                Text(
                                  '${BusinessInfo.instance.currencySymbol}${(user['total_sales'] as double).toStringAsFixed(2)}',
                                ),
                              ),
                              DataCell(Text(user['drawer_opens'].toString())),
                              DataCell(
                                Text(
                                  user['first_sign_in'] != null
                                      ? FormattingService.formatDateTime(
                                          user['first_sign_in'],
                                        )
                                      : 'N/A',
                                ),
                              ),
                              DataCell(
                                Text(
                                  user['last_sign_out'] != null
                                      ? FormattingService.formatDateTime(
                                          user['last_sign_out'],
                                        )
                                      : 'N/A',
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No user activity found for the selected date range',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
