import 'package:extropos/models/shift_model.dart';
import 'package:extropos/models/user_model.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/user_service.dart';
import 'package:flutter/material.dart';

class ShiftHistoryScreen extends StatefulWidget {
  const ShiftHistoryScreen({super.key});

  @override
  State<ShiftHistoryScreen> createState() => _ShiftHistoryScreenState();
}

class _ShiftHistoryScreenState extends State<ShiftHistoryScreen> {
  late DateTimeRange _selectedDateRange;
  late List<Shift> _shifts;
  late Map<String, User?> _userCache;
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'date'; // date, staff, sales, variance

  @override
  void initState() {
    super.initState();
    _shifts = [];
    _userCache = {};
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
    );
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'shifts',
        where: 'start_time >= ? AND start_time <= ? AND status = ?',
        whereArgs: [
          _selectedDateRange.start.toIso8601String(),
          _selectedDateRange.end.toIso8601String(),
          'completed',
        ],
        orderBy: 'start_time DESC',
      );

      var shifts = maps.map((map) => Shift.fromMap(map)).toList();

      // Load user data
      for (final shift in shifts) {
        if (!_userCache.containsKey(shift.userId)) {
          final user = await UserService.instance.getById(shift.userId);
          _userCache[shift.userId] = user;
        }
      }

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        shifts = shifts.where((shift) {
          final userName = _userCache[shift.userId]?.fullName ?? '';
          return userName.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }

      // Apply sorting
      switch (_sortBy) {
        case 'staff':
          shifts.sort((a, b) {
            final nameA = _userCache[a.userId]?.fullName ?? '';
            final nameB = _userCache[b.userId]?.fullName ?? '';
            return nameA.compareTo(nameB);
          });
          break;
        case 'sales':
          shifts.sort((a, b) {
            final salesA = a.closingCash ?? 0;
            final salesB = b.closingCash ?? 0;
            return salesB.compareTo(salesA);
          });
          break;
        case 'variance':
          shifts.sort((a, b) {
            final varA = (a.variance ?? 0).abs();
            final varB = (b.variance ?? 0).abs();
            return varB.compareTo(varA);
          });
          break;
        default:
          // Already sorted by date DESC
          break;
      }

      setState(() {
        _shifts = shifts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters
            _buildFiltersSection(),
            const SizedBox(height: 24),

            // Results Count
            Text(
              '${_shifts.length} shift${_shifts.length != 1 ? 's' : ''} found',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),

            // Shifts List
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_shifts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No shifts found',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _shifts.length,
                itemBuilder: (context, index) {
                  final shift = _shifts[index];
                  return _buildShiftCard(shift);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Range Picker
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${_formatDate(_selectedDateRange.start)} - ${_formatDate(_selectedDateRange.end)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _selectedDateRange,
                  );
                  if (picked != null) {
                    setState(() => _selectedDateRange = picked);
                    setState(() => _isLoading = true);
                    _loadHistory();
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('Date'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Search Box
        TextField(
          onChanged: (value) {
            setState(() => _searchQuery = value);
            _loadHistory();
          },
          decoration: InputDecoration(
            hintText: 'Search by staff name...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),

        // Sort Options
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSortChip('Date', 'date'),
              const SizedBox(width: 8),
              _buildSortChip('Staff', 'staff'),
              const SizedBox(width: 8),
              _buildSortChip('Sales', 'sales'),
              const SizedBox(width: 8),
              _buildSortChip('Variance', 'variance'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _sortBy = value);
        _loadHistory();
      },
      backgroundColor: Colors.grey[100],
      selectedColor: Colors.blue.withOpacity(0.2),
      side: BorderSide(
        color: isSelected ? Colors.blue : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildShiftCard(Shift shift) {
    final user = _userCache[shift.userId];
    final variance = shift.variance ?? 0;
    final isShortage = variance < 0;
    final duration = (shift.endTime ?? DateTime.now()).difference(shift.startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'COMPLETED',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  'Duration',
                  '${hours}h ${minutes}m',
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Opening',
                  'RM ${shift.openingCash.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Closing',
                  'RM ${(shift.closingCash ?? 0).toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Expected',
                  'RM ${(shift.expectedCash ?? 0).toStringAsFixed(2)}',
                ),
                const Divider(height: 16),
                _buildDetailRow(
                  'Variance',
                  'RM ${variance.abs().toStringAsFixed(2)}',
                  valueColor: isShortage ? Colors.red : Colors.green,
                ),
              ],
            ),
          ),
          if (shift.varianceAcknowledged != true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Awaiting Manager Acknowledgment',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ),
          ],
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

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
