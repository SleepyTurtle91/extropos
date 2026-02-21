import 'package:extropos/models/shift_model.dart';
import 'package:extropos/models/user_model.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/user_service.dart';
import 'package:flutter/material.dart';

class ShiftReconciliationScreen extends StatefulWidget {
  const ShiftReconciliationScreen({super.key});

  @override
  State<ShiftReconciliationScreen> createState() =>
      _ShiftReconciliationScreenState();
}

class _ShiftReconciliationScreenState extends State<ShiftReconciliationScreen> {
  late List<Shift> _unconciliedShifts;
  late Map<String, User?> _userCache;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _unconciliedShifts = [];
    _userCache = {};
    _loadUnconciliedShifts();
  }

  Future<void> _loadUnconciliedShifts() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Get all completed shifts with variances that need acknowledgment
      final maps = await db.query(
        'shifts',
        where: 'status = ? AND variance_acknowledged = ?',
        whereArgs: ['completed', 0],
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
        _unconciliedShifts = shifts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading unconciled shifts: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Reconciliation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUnconciliedShifts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _unconciliedShifts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
                      const SizedBox(height: 16),
                      const Text(
                        'All shifts reconciled!',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to Dashboard'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _unconciliedShifts.length,
                  itemBuilder: (context, index) {
                    final shift = _unconciliedShifts[index];
                    return _buildReconciliationCard(shift);
                  },
                ),
    );
  }

  Widget _buildReconciliationCard(Shift shift) {
    final user = _userCache[shift.userId];
    final variance = shift.variance ?? 0;
    final isShortage = variance < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isShortage ? Colors.red.withOpacity(0.05) : Colors.green.withOpacity(0.05),
        border: Border.all(
          color: isShortage ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? 'Unknown User',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(shift.startTime),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isShortage ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isShortage ? 'SHORTAGE' : 'SURPLUS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isShortage ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildReconciliationDetails(shift, variance),
          const SizedBox(height: 16),
          _buildReconciliationActions(shift),
        ],
      ),
    );
  }

  Widget _buildReconciliationDetails(Shift shift, double variance) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildDetailRow('Opening Cash', 'RM ${shift.openingCash.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildDetailRow('Expected Cash', 'RM ${(shift.expectedCash ?? 0).toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildDetailRow('Closing Cash', 'RM ${(shift.closingCash ?? 0).toStringAsFixed(2)}'),
          const Divider(height: 16),
          _buildDetailRow(
            'Variance',
            'RM ${variance.abs().toStringAsFixed(2)} ${variance > 0 ? 'SURPLUS' : 'SHORTAGE'}',
            valueColor: variance > 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }

  Widget _buildReconciliationActions(Shift shift) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info, size: 20, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Variance must be acknowledged by a manager before finalizing',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showVarianceExplanation(context, shift),
                child: const Text('View Details'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _acknowledgeVariance(shift),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Acknowledge'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showVarianceExplanation(BuildContext context, Shift shift) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Variance Explanation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Common causes of cash variances:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildCauseItem('Customer refunds or cancellations'),
              _buildCauseItem('Change-making errors'),
              _buildCauseItem('Incorrect transaction amounts'),
              _buildCauseItem('Lost or damaged currency'),
              _buildCauseItem('Promotional discounts'),
              const SizedBox(height: 16),
              const Text('Actions:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildActionItem('Review transaction records'),
              _buildActionItem('Recount cash drawer'),
              _buildActionItem('Check void/refund log'),
              _buildActionItem('Document in system'),
              if (shift.notes != null && shift.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(shift.notes!),
                    ],
                  ),
                ),
              ],
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

  Widget _buildCauseItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildActionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.arrow_right, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _acknowledgeVariance(Shift shift) async {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acknowledge Variance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Variance: RM ${(shift.variance ?? 0).abs().toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for variance',
                border: OutlineInputBorder(),
                hintText: 'Explain the variance...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _confirmAcknowledgment(context, shift, reasonController),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAcknowledgment(
    BuildContext context,
    Shift shift,
    TextEditingController reasonController,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Update shift to mark variance as acknowledged
      final updatedShift = shift.copyWith(
        varianceAcknowledged: true,
        notes: reasonController.text.isNotEmpty
            ? '${shift.notes ?? ''}\n[Manager Acknowledgment]: ${reasonController.text}'
            : shift.notes,
      );

      await db.update(
        'shifts',
        updatedShift.toMap(),
        where: 'id = ?',
        whereArgs: [shift.id],
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Variance acknowledged successfully')),
        );
        _loadUnconciliedShifts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
