import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/employee_performance_models.dart';
import 'package:extropos/models/user_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/employee_performance_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EmployeePerformanceScreen extends StatefulWidget {
  const EmployeePerformanceScreen({super.key});

  @override
  State<EmployeePerformanceScreen> createState() =>
      _EmployeePerformanceScreenState();
}

class _EmployeePerformanceScreenState extends State<EmployeePerformanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  List<EmployeePerformance> _performances = [];
  List<EmployeeRanking> _rankings = [];
  ShiftReport? _selectedShiftReport;
  String? _selectedUserId;
  bool _isLoading = false;

  final _performanceService = EmployeePerformanceService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final performances = await _performanceService.getEmployeePerformance(
        startDate: _dateRange.start,
        endDate: _dateRange.end,
      );

      final rankings = await _performanceService.getEmployeeLeaderboard(
        startDate: _dateRange.start,
        endDate: _dateRange.end,
        limit: 10,
      );

      setState(() {
        _performances = performances;
        _rankings = rankings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastHelper.showToast(context, 'Error loading performance data: $e');
      }
    }
  }

  Future<void> _loadShiftReport(String userId) async {
    try {
      final report = await _performanceService.getShiftReport(
        userId: userId,
        shiftStart: _dateRange.start,
        shiftEnd: _dateRange.end,
      );

      setState(() {
        _selectedShiftReport = report;
        _selectedUserId = userId;
      });
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Error loading shift report: $e');
      }
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
      await _loadData();
    }
  }

  Future<void> _exportCsv() async {
    try {
      final path = await _performanceService.saveEmployeePerformanceCsv(
        startDate: _dateRange.start,
        endDate: _dateRange.end,
      );

      if (mounted) {
        ToastHelper.showToast(context, 'Report exported to: $path');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Error exporting report: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Performance'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportCsv,
            tooltip: 'Export CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Overview'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Leaderboard'),
            Tab(icon: Icon(Icons.access_time), text: 'Shift Reports'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDateRangeDisplay(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildLeaderboardTab(),
                      _buildShiftReportsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeDisplay() {
    final formatter = DateFormat('MMM dd, yyyy');
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${formatter.format(_dateRange.start)} - ${formatter.format(_dateRange.end)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            '${_dateRange.duration.inDays + 1} days',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_performances.isEmpty) {
      return const Center(
        child: Text('No employee performance data available for this period'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildPerformanceTable(),
          const SizedBox(height: 24),
          _buildCommissionBreakdown(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalSales = _performances.fold(0.0, (sum, p) => sum + p.totalSales);
    final totalOrders = _performances.fold(0, (sum, p) => sum + p.orderCount);
    final totalCommission = _performances.fold(
      0.0,
      (sum, p) => sum + p.commission,
    );
    final avgPerformance = _performances.isNotEmpty
        ? totalSales / _performances.length
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;
        if (constraints.maxWidth < 600) {
          columns = 1;
        } else if (constraints.maxWidth < 900) {
          columns = 2;
        }

        final cards = [
          _buildSummaryCard(
            'Total Sales',
            '${BusinessInfo.instance.currencySymbol} ${totalSales.toStringAsFixed(2)}',
            Icons.attach_money,
            Colors.green,
          ),
          _buildSummaryCard(
            'Total Orders',
            totalOrders.toString(),
            Icons.shopping_cart,
            Colors.blue,
          ),
          _buildSummaryCard(
            'Total Commission',
            '${BusinessInfo.instance.currencySymbol} ${totalCommission.toStringAsFixed(2)}',
            Icons.payments,
            Colors.orange,
          ),
          _buildSummaryCard(
            'Avg per Employee',
            '${BusinessInfo.instance.currencySymbol} ${avgPerformance.toStringAsFixed(2)}',
            Icons.person,
            Colors.purple,
          ),
        ];

        if (columns == 1) {
          return Column(
            children: cards
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: c,
                  ),
                )
                .toList(),
          );
        } else {
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: cards
                .map(
                  (c) => SizedBox(
                    width:
                        (constraints.maxWidth - 16 * (columns - 1)) / columns,
                    child: c,
                  ),
                )
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Employee Performance Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Employee')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Sales'), numeric: true),
                  DataColumn(label: Text('Orders'), numeric: true),
                  DataColumn(label: Text('Items'), numeric: true),
                  DataColumn(label: Text('Avg Order'), numeric: true),
                  DataColumn(label: Text('Commission'), numeric: true),
                ],
                rows: _performances.map((perf) {
                  return DataRow(
                    cells: [
                      DataCell(Text(perf.userName)),
                      DataCell(Text(perf.userRole)),
                      DataCell(
                        Text(
                          '${BusinessInfo.instance.currencySymbol}${perf.totalSales.toStringAsFixed(2)}',
                        ),
                      ),
                      DataCell(Text(perf.orderCount.toString())),
                      DataCell(Text(perf.itemsSold.toString())),
                      DataCell(
                        Text(
                          '${BusinessInfo.instance.currencySymbol}${perf.averageOrderValue.toStringAsFixed(2)}',
                        ),
                      ),
                      DataCell(
                        Text(
                          '${BusinessInfo.instance.currencySymbol}${perf.commission.toStringAsFixed(2)}',
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
    );
  }

  Widget _buildCommissionBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Commission Tiers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...CommissionTier.defaultTiers.map((tier) {
              final employeesInTier = _performances.where((p) {
                final t = CommissionTier.getTierForSales(p.totalSales);
                return t?.tierName == tier.tierName;
              }).length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getTierColor(tier.tierName),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tier.tierName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '${BusinessInfo.instance.currencySymbol}${tier.minSales.toStringAsFixed(0)} - ${tier.maxSales == double.infinity ? '∞' : BusinessInfo.instance.currencySymbol + tier.maxSales.toStringAsFixed(0)} • ${(tier.rate * 100).toStringAsFixed(0)}% commission',
                      ),
                    ),
                    Text(
                      '$employeesInTier ${employeesInTier == 1 ? 'employee' : 'employees'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(String tierName) {
    switch (tierName) {
      case 'Bronze':
        return Colors.brown;
      case 'Silver':
        return Colors.grey;
      case 'Gold':
        return Colors.amber;
      case 'Platinum':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  Widget _buildLeaderboardTab() {
    if (_rankings.isEmpty) {
      return const Center(
        child: Text('No leaderboard data available for this period'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rankings.length,
      itemBuilder: (context, index) {
        final ranking = _rankings[index];
        return _buildLeaderboardCard(ranking);
      },
    );
  }

  Widget _buildLeaderboardCard(EmployeeRanking ranking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: ranking.rank <= 3 ? 4 : 2,
      child: ListTile(
        leading: _buildRankBadge(ranking.rank),
        title: Text(
          ranking.userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ranking.userRole),
            const SizedBox(height: 4),
            Text(
              '${ranking.orderCount} orders • ${BusinessInfo.instance.currencySymbol}${ranking.commission.toStringAsFixed(2)} commission',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${BusinessInfo.instance.currencySymbol}${ranking.totalSales.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Total Sales',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color;
    IconData icon;

    if (rank == 1) {
      color = Colors.amber;
      icon = Icons.emoji_events;
    } else if (rank == 2) {
      color = Colors.grey;
      icon = Icons.emoji_events;
    } else if (rank == 3) {
      color = Colors.brown;
      icon = Icons.emoji_events;
    } else {
      color = Colors.blue;
      icon = Icons.person;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: rank <= 3
            ? Icon(icon, color: Colors.white, size: 28)
            : Text(
                rank.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
      ),
    );
  }

  Widget _buildShiftReportsTab() {
    return FutureBuilder<List<User>>(
      future: DatabaseService.instance.getUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!;

        return Row(
          children: [
            // Employee list
            SizedBox(
              width: 250,
              child: Card(
                margin: EdgeInsets.zero,
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isSelected = _selectedUserId == user.id;

                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: const Color(
                        0xFF2563EB,
                      ).withOpacity(0.1),
                      title: Text(user.fullName),
                      subtitle: Text(user.roleDisplayName),
                      onTap: () => _loadShiftReport(user.id),
                    );
                  },
                ),
              ),
            ),
            // Shift report details
            Expanded(
              child: _selectedShiftReport == null
                  ? const Center(
                      child: Text('Select an employee to view shift report'),
                    )
                  : _buildShiftReportDetails(_selectedShiftReport!),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShiftReportDetails(ShiftReport report) {
    final formatter = DateFormat('MMM dd, yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            report.userName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'Shift: ${formatter.format(report.shiftStart)} - ${formatter.format(report.shiftEnd)}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            'Duration: ${report.shiftDuration.inHours}h ${report.shiftDuration.inMinutes % 60}m',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Summary cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildShiftCard(
                'Total Sales',
                '${BusinessInfo.instance.currencySymbol}${report.totalSales.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
              _buildShiftCard(
                'Orders',
                report.orderCount.toString(),
                Icons.shopping_cart,
                Colors.blue,
              ),
              _buildShiftCard(
                'Items Sold',
                report.itemsSold.toString(),
                Icons.inventory,
                Colors.orange,
              ),
              _buildShiftCard(
                'Avg Order',
                '${BusinessInfo.instance.currencySymbol}${report.averageOrderValue.toStringAsFixed(2)}',
                Icons.trending_up,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Payment breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Methods Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentRow('Cash', report.cashSales),
                  _buildPaymentRow('Card', report.cardSales),
                  _buildPaymentRow('Other', report.otherSales),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Refunds and voids
          if (report.refundCount > 0 || report.voidCount > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Refunds & Voids',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (report.refundCount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Refunds: ${report.refundCount}'),
                          Text(
                            '${BusinessInfo.instance.currencySymbol}${report.refundAmount.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (report.voidCount > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Voids: ${report.voidCount}'),
                          const Icon(Icons.cancel, color: Colors.red),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShiftCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String method, double amount) {
    final total =
        _selectedShiftReport!.cashSales +
        _selectedShiftReport!.cardSales +
        _selectedShiftReport!.otherSales;
    final percentage = total > 0 ? (amount / total) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(method),
              Text(
                '${BusinessInfo.instance.currencySymbol}${amount.toStringAsFixed(2)}',
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
