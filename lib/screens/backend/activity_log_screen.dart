import 'package:extropos/models/activity_log_model.dart';
import 'package:extropos/models/role_model.dart';
import 'package:extropos/screens/backend/widgets/activity_log_list_widget.dart';
import 'package:extropos/services/access_control_service.dart';
import 'package:extropos/services/audit_service.dart';
import 'package:flutter/material.dart';

/// Activity Log Screen for Backend Flavor
///
/// Displays comprehensive audit trail with filtering and export capabilities.
/// Shows user actions, resource changes, before/after snapshots.
///
/// Permission Requirements:
/// - VIEW_ACTIVITY_LOG (to see logs)
/// - EXPORT_ACTIVITY_LOG (to export)
class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  late AuditService _auditService;
  late AccessControlService _accessControl;

  List<ActivityLogModel> _allLogs = [];
  List<ActivityLogModel> _filteredLogs = [];

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  String _selectedUser = 'all';
  String _selectedAction = 'all';
  String _selectedResourceType = 'all';
  String _selectedStatus = 'all'; // 'all', 'success', 'failed'

  bool _isLoading = false;
  String? _errorMessage;

  // Pagination
  static const int _pageSize = 20;
  int _currentPage = 0;

  // Unique values for dropdowns
  late final Set<String> _userIds = {};
  late final Set<String> _actions = {};
  late final Set<String> _resourceTypes = {};

  @override
  void initState() {
    super.initState();
    _auditService = AuditService.instance;
    _accessControl = AccessControlService.instance;

    // Listen for activity changes
    _auditService.addListener(_onActivityChanged);

    // Load initial data
    _loadActivityLogs();
  }

  @override
  void dispose() {
    _auditService.removeListener(_onActivityChanged);
    super.dispose();
  }

  void _onActivityChanged() {
    if (mounted) {
      _loadActivityLogs();
    }
  }

  Future<void> _loadActivityLogs() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final logs = await _auditService.getRecentActivityLogs(limit: 500);
      
      // Collect unique values for filters
      _userIds.clear();
      _actions.clear();
      _resourceTypes.clear();
      
      for (final log in logs) {
        _userIds.add(log.userId);
        _actions.add(log.action);
        _resourceTypes.add(log.resourceType);
      }

      setState(() {
        _allLogs = logs;
        _applyFilters();
      });
    } catch (e) {
      print('❌ Error loading activity logs: $e');
      setState(() {
        _errorMessage = 'Failed to load activity logs: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<ActivityLogModel> filtered = _allLogs;

    // Date range filter
    filtered = filtered.where((log) {
      final logDate = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
      return logDate.isAfter(_startDate) && logDate.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    // User filter
    if (_selectedUser != 'all') {
      filtered = filtered.where((log) => log.userId == _selectedUser).toList();
    }

    // Action filter
    if (_selectedAction != 'all') {
      filtered = filtered.where((log) => log.action == _selectedAction).toList();
    }

    // Resource type filter
    if (_selectedResourceType != 'all') {
      filtered = filtered.where((log) => log.resourceType == _selectedResourceType).toList();
    }

    // Status filter
    if (_selectedStatus == 'success') {
      filtered = filtered.where((log) => log.success).toList();
    } else if (_selectedStatus == 'failed') {
      filtered = filtered.where((log) => !log.success).toList();
    }

    // Sort by timestamp descending (newest first)
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    setState(() {
      _filteredLogs = filtered;
      _currentPage = 0;
    });
  }

  void _onDateRangeChanged(DateTime start, DateTime end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
    _applyFilters();
  }

  void _onUserFilterChanged(String? value) {
    setState(() {
      _selectedUser = value ?? 'all';
    });
    _applyFilters();
  }

  void _onActionFilterChanged(String? value) {
    setState(() {
      _selectedAction = value ?? 'all';
    });
    _applyFilters();
  }

  void _onResourceTypeFilterChanged(String? value) {
    setState(() {
      _selectedResourceType = value ?? 'all';
    });
    _applyFilters();
  }

  void _onStatusFilterChanged(String? value) {
    setState(() {
      _selectedStatus = value ?? 'all';
    });
    _applyFilters();
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      _onDateRangeChanged(picked.start, picked.end);
    }
  }

  Future<void> _exportLogs() async {
    try {
      final json = await _auditService.exportLogsAsJson();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Exported ${json.length} logs to clipboard'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error exporting logs: $e')),
        );
      }
    }
  }

  // Get paginated logs
  List<ActivityLogModel> get _paginatedLogs {
    final start = _currentPage * _pageSize;
    final end = start + _pageSize;
    if (start >= _filteredLogs.length) return [];
    return _filteredLogs.sublist(start, min(end, _filteredLogs.length));
  }

  int get _totalPages => (_filteredLogs.length / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        elevation: 0,
        actions: [
          FutureBuilder<bool>(
            future: _accessControl.hasPermission(Permission.EXPORT_ACTIVITY_LOG),
            builder: (context, snapshot) {
              final canExport = snapshot.data ?? false;
              if (!canExport) return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Export logs',
                onPressed: _isLoading ? null : _exportLogs,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatCard(
                  title: 'Total Logs',
                  value: _allLogs.length.toString(),
                  icon: Icons.receipt_long,
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  title: 'Successful',
                  value: _allLogs.where((l) => l.success).length.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  title: 'Failed',
                  value: _allLogs.where((l) => !l.success).length.toString(),
                  icon: Icons.error,
                  color: Colors.red,
                ),
              ],
            ),
          ),
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date range picker
                GestureDetector(
                  onTap: _showDateRangePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_startDate.toString().split(' ')[0]} to ${_endDate.toString().split(' ')[0]}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter dropdowns
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 3,
                  children: [
                    DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      onChanged: _onStatusFilterChanged,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Status')),
                        DropdownMenuItem(value: 'success', child: Text('✅ Success')),
                        DropdownMenuItem(value: 'failed', child: Text('❌ Failed')),
                      ],
                    ),
                    DropdownButton<String>(
                      value: _selectedUser,
                      isExpanded: true,
                      onChanged: _onUserFilterChanged,
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('All Users')),
                        ..._userIds.map((userId) {
                          return DropdownMenuItem(value: userId, child: Text(userId));
                        }).toList(),
                      ],
                    ),
                    DropdownButton<String>(
                      value: _selectedAction,
                      isExpanded: true,
                      onChanged: _onActionFilterChanged,
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('All Actions')),
                        ..._actions.map((action) {
                          return DropdownMenuItem(value: action, child: Text(action));
                        }).toList(),
                      ],
                    ),
                    DropdownButton<String>(
                      value: _selectedResourceType,
                      isExpanded: true,
                      onChanged: _onResourceTypeFilterChanged,
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('All Resources')),
                        ..._resourceTypes.map((resourceType) {
                          return DropdownMenuItem(value: resourceType, child: Text(resourceType));
                        }).toList(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Activity Log List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadActivityLogs,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredLogs.isEmpty
                        ? const Center(child: Text('No activity logs found'))
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                ActivityLogListWidget(logs: _paginatedLogs),
                                // Pagination
                                if (_totalPages > 1)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          onPressed: _currentPage > 0
                                              ? () {
                                                  setState(() => _currentPage--);
                                                }
                                              : null,
                                          icon: const Icon(Icons.chevron_left),
                                        ),
                                        Text(
                                          'Page ${_currentPage + 1} of $_totalPages',
                                        ),
                                        IconButton(
                                          onPressed:
                                              _currentPage < _totalPages - 1
                                                  ? () {
                                                      setState(() => _currentPage++);
                                                    }
                                                  : null,
                                          icon: const Icon(Icons.chevron_right),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function for min
int min(int a, int b) => a < b ? a : b;
