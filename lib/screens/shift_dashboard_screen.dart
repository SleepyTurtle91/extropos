import 'package:extropos/models/shift_model.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/shift_service.dart';
import 'package:extropos/services/user_session_service.dart';
import 'package:flutter/material.dart';

class ShiftDashboardScreen extends StatefulWidget {
  const ShiftDashboardScreen({super.key});

  @override
  State<ShiftDashboardScreen> createState() => _ShiftDashboardScreenState();
}

class _ShiftDashboardScreenState extends State<ShiftDashboardScreen> {
  late Shift? _currentShift;
  bool _isLoading = true;
  double _shiftSales = 0.0;
  int _transactionCount = 0;
  List<Shift> _recentShifts = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final shiftService = ShiftService.instance;
    final currentUser = UserSessionService().currentActiveUser;

    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      _currentShift = await shiftService.getCurrentShift(currentUser.id);

      if (_currentShift != null) {
        _shiftSales = await shiftService.calculateShiftSales(_currentShift!.id);
        _transactionCount = await _getTransactionCount(_currentShift!.id);
      }

      _recentShifts = await _getRecentShifts(currentUser.id, limit: 5);

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading shift dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<int> _getTransactionCount(String shiftId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM orders WHERE shift_id = ? AND status = "completed"',
      [shiftId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<List<Shift>> _getRecentShifts(String userId, {required int limit}) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'shifts',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'start_time DESC',
      limit: limit,
    );
    return maps.map((map) => Shift.fromMap(map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shift Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Dashboard'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Shift Status Card
            _buildCurrentShiftCard(),
            const SizedBox(height: 24),

            // KPI Cards
            LayoutBuilder(
              builder: (context, constraints) {
                int columns = 2;
                if (constraints.maxWidth < 600) columns = 1;

                return GridView.count(
                  crossAxisCount: columns,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildKPICard('Shift Sales', 'RM ${_shiftSales.toStringAsFixed(2)}', Colors.green),
                    _buildKPICard('Transactions', _transactionCount.toString(), Colors.blue),
                    _buildKPICard(
                      'Avg Transaction',
                      _transactionCount > 0
                          ? 'RM ${(_shiftSales / _transactionCount).toStringAsFixed(2)}'
                          : 'RM 0.00',
                      Colors.orange,
                    ),
                    _buildKPICard(
                      'Duration',
                      _currentShift != null ? _formatDuration(_currentShift!.startTime) : 'N/A',
                      Colors.purple,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/shift/active'),
                    icon: const Icon(Icons.people),
                    label: const Text('Active Shifts'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/shift/reports'),
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('Reports'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/shift/reconciliation'),
                    icon: const Icon(Icons.balance),
                    label: const Text('Reconciliation'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/shift/history'),
                    icon: const Icon(Icons.history),
                    label: const Text('History'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Shifts
            const Text('Recent Shifts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildRecentShiftsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentShiftCard() {
    if (_currentShift == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No active shift. Please start a shift to continue.',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
    }

    final duration = DateTime.now().difference(_currentShift!.startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Shift', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Opening: RM ${_currentShift!.openingCash.toStringAsFixed(2)}'),
              Text('Duration: ${hours}h ${minutes}m', style: const TextStyle(color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Status: ${_currentShift!.status.toUpperCase()}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildKPICard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
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

  Widget _buildRecentShiftsList() {
    if (_recentShifts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('No recent shifts', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentShifts.length,
      itemBuilder: (context, index) {
        final shift = _recentShifts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatDateTime(shift.startTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'RM ${shift.openingCash.toStringAsFixed(2)} → ${shift.closingCash?.toStringAsFixed(2) ?? 'Not closed'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: shift.status == 'completed' ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  shift.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: shift.status == 'completed' ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(DateTime startTime) {
    final now = DateTime.now();
    final duration = now.difference(startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}
