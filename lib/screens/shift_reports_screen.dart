import 'package:extropos/models/shift_model.dart';
import 'package:extropos/models/user_model.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/user_service.dart';
import 'package:flutter/material.dart';

class ShiftReportsScreen extends StatefulWidget {
  const ShiftReportsScreen({super.key});

  @override
  State<ShiftReportsScreen> createState() => _ShiftReportsScreenState();
}

class _ShiftReportsScreenState extends State<ShiftReportsScreen> {
  late DateTimeRange _selectedDateRange;
  late List<Shift> _shifts;
  late Map<String, User?> _userCache;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _shifts = [];
    _userCache = {};
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7)),
      end: DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
    );
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'shifts',
        where: 'start_time >= ? AND start_time <= ?',
        whereArgs: [
          _selectedDateRange.start.toIso8601String(),
          _selectedDateRange.end.toIso8601String(),
        ],
        orderBy: 'start_time DESC',
      );

      final shifts = maps.map((map) => Shift.fromMap(map)).toList();

      // Load user data
      for (final shift in shifts) {
        if (!_userCache.containsKey(shift.userId)) {
          final user = await UserService.instance.getById(shift.userId);
          _userCache[shift.userId] = user;
        }
      }

      setState(() {
        _shifts = shifts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reports: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Reports'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Picker
            _buildDateRangePicker(context),
            const SizedBox(height: 24),

            // Summary Cards
            if (!_isLoading) ...[
              _buildSummaryCards(),
              const SizedBox(height: 24),
            ],

            // Top Performers
            const Text('Top Performers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _buildTopPerformersTable(),

            const SizedBox(height: 24),

            // Shifts Table
            const Text('All Shifts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _shifts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No shifts in selected period',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      )
                    : _buildShiftsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangePicker(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_formatDate(_selectedDateRange.start)} - ${_formatDate(_selectedDateRange.end)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _selectedDateRange,
              );
              if (picked != null && mounted) {
                setState(() => _selectedDateRange = picked);
                setState(() => _isLoading = true);
                _loadReports();
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final completedShifts = _shifts.where((s) => s.status == 'completed').toList();
    final totalSales = completedShifts.fold<double>(0, (sum, shift) => sum + (shift.closingCash ?? 0));
    final avgSales = completedShifts.isNotEmpty ? totalSales / completedShifts.length : 0.0;
    final totalVariance = completedShifts.fold<double>(0, (sum, shift) => sum + (shift.variance?.abs() ?? 0));

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 2;
        if (constraints.maxWidth < 600) columns = 1;

        return GridView.count(
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildSummaryCard('Total Sales', 'RM ${totalSales.toStringAsFixed(2)}', Colors.green),
            _buildSummaryCard('Avg Sale/Shift', 'RM ${avgSales.toStringAsFixed(2)}', Colors.blue),
            _buildSummaryCard('Completed Shifts', completedShifts.length.toString(), Colors.orange),
            _buildSummaryCard('Total Variance', 'RM ${totalVariance.toStringAsFixed(2)}', Colors.red),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTopPerformersTable() {
    // Group by user and calculate totals
    final userStats = <String, Map<String, dynamic>>{};

    for (final shift in _shifts.where((s) => s.status == 'completed')) {
      if (!userStats.containsKey(shift.userId)) {
        userStats[shift.userId] = {
          'count': 0,
          'total_sales': 0.0,
          'user': _userCache[shift.userId],
        };
      }

      userStats[shift.userId]!['count']++;
      userStats[shift.userId]!['total_sales'] += shift.closingCash ?? 0;
    }

    final sorted = userStats.entries.toList()
      ..sort((a, b) => (b.value['total_sales'] as double).compareTo(a.value['total_sales'] as double));

    if (sorted.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No completed shifts', style: TextStyle(color: Colors.grey[500])),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Rank')),
          DataColumn(label: Text('Staff')),
          DataColumn(label: Text('Shifts')),
          DataColumn(label: Text('Total Sales')),
        ],
        rows: List.generate(
          sorted.length,
          (index) {
            final entry = sorted[index];
            final totalSales = entry.value['total_sales'] as double;
            final count = entry.value['count'] as int;

            return DataRow(cells: [
              DataCell(Text('${index + 1}')),
              DataCell(Text(entry.value['user']?.fullName ?? 'Unknown')),
              DataCell(Text(count.toString())),
              DataCell(Text('RM ${totalSales.toStringAsFixed(2)}')),
            ]);
          },
        ),
      ),
    );
  }

  Widget _buildShiftsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Staff')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Duration')),
          DataColumn(label: Text('Opening')),
          DataColumn(label: Text('Closing')),
          DataColumn(label: Text('Variance')),
        ],
        rows: _shifts
            .map(
              (shift) => DataRow(cells: [
                DataCell(Text(_userCache[shift.userId]?.fullName ?? 'Unknown')),
                DataCell(Text(_formatDate(shift.startTime))),
                DataCell(Text(_formatDuration(shift.startTime, shift.endTime))),
                DataCell(Text('RM ${shift.openingCash.toStringAsFixed(2)}')),
                DataCell(Text(shift.closingCash != null ? 'RM ${shift.closingCash!.toStringAsFixed(2)}' : 'N/A')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (shift.variance ?? 0) > 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      shift.variance != null ? 'RM ${shift.variance!.toStringAsFixed(2)}' : 'N/A',
                      style: TextStyle(
                        color: (shift.variance ?? 0) > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ]),
            )
            .toList(),
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  String _formatDuration(DateTime start, DateTime? end) {
    if (end == null) return 'Active';
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}
