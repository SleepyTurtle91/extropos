import 'package:extropos/models/shift_model.dart';
import 'package:extropos/models/user_model.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/shift_service.dart';
import 'package:extropos/services/user_service.dart';
import 'package:flutter/material.dart';

class ActiveShiftsScreen extends StatefulWidget {
  const ActiveShiftsScreen({super.key});

  @override
  State<ActiveShiftsScreen> createState() => _ActiveShiftsScreenState();
}

class _ActiveShiftsScreenState extends State<ActiveShiftsScreen> {
  late List<Shift> _activeShifts;
  late Map<String, User?> _userCache;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _activeShifts = [];
    _userCache = {};
    _loadActiveShifts();
  }

  Future<void> _loadActiveShifts() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'shifts',
        where: 'status = ?',
        whereArgs: ['active'],
        orderBy: 'start_time DESC',
      );

      final shifts = maps.map((map) => Shift.fromMap(map)).toList();

      // Load user data for each shift
      for (final shift in shifts) {
        if (!_userCache.containsKey(shift.userId)) {
          final user = await UserService.instance.getById(shift.userId);
          _userCache[shift.userId] = user;
        }
      }

      setState(() {
        _activeShifts = shifts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading active shifts: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Shifts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActiveShifts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeShifts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text(
                        'No active shifts',
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
                  itemCount: _activeShifts.length,
                  itemBuilder: (context, index) {
                    final shift = _activeShifts[index];
                    final user = _userCache[shift.userId];
                    return _buildShiftCard(shift, user);
                  },
                ),
    );
  }

  Widget _buildShiftCard(Shift shift, User? user) {
    final duration = DateTime.now().difference(shift.startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Unknown User',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDateTime(shift.startTime),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricColumn('Opening Cash', 'RM ${shift.openingCash.toStringAsFixed(2)}'),
              _buildMetricColumn('Duration', '${hours}h ${minutes}m'),
              _buildMetricColumn('Status', shift.status),
            ],
          ),
          if (shift.notes != null && shift.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Note: ${shift.notes}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showEndShiftDialog(context, shift),
              icon: const Icon(Icons.logout),
              label: const Text('End Shift'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showEndShiftDialog(BuildContext context, Shift shift) {
    final closingCashController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Shift'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: closingCashController,
                decoration: const InputDecoration(
                  labelText: 'Closing Cash Amount',
                  hintText: 'RM',
                  border: OutlineInputBorder(),
                  prefixText: 'RM ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _endShift(context, shift, closingCashController, notesController),
            child: const Text('End Shift'),
          ),
        ],
      ),
    );
  }

  Future<void> _endShift(
    BuildContext context,
    Shift shift,
    TextEditingController closingCashController,
    TextEditingController notesController,
  ) async {
    try {
      final closingCash = double.tryParse(closingCashController.text);
      if (closingCash == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid closing cash amount')),
        );
        return;
      }

      await ShiftService.instance.endShift(
        shift.id,
        closingCash,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift ended successfully')),
        );
        _loadActiveShifts();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
