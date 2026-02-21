import 'package:extropos/models/activity_log_model.dart';
import 'package:flutter/material.dart';

/// Reusable widget for displaying activity logs in expandable list format
///
/// Features:
/// - Shows action, resource, user, timestamp, status
/// - Expandable rows for before/after change details
/// - Color-coded by action type
class ActivityLogListWidget extends StatefulWidget {
  final List<ActivityLogModel> logs;

  const ActivityLogListWidget({
    super.key,
    required this.logs,
  });

  @override
  State<ActivityLogListWidget> createState() => _ActivityLogListWidgetState();
}

class _ActivityLogListWidgetState extends State<ActivityLogListWidget> {
  final Set<int> _expandedIndices = {};

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'lock':
        return Colors.orange;
      case 'unlock':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getActionIcon(String action) {
    switch (action) {
      case 'create':
        return '➕';
      case 'update':
        return '✏️';
      case 'delete':
        return '🗑️';
      case 'lock':
        return '🔒';
      case 'unlock':
        return '🔓';
      default:
        return '•';
    }
  }

  Widget _buildChangeDetails(ActivityLogModel log) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (log.changesBefore.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '❌ Before:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...log.changesBefore.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${entry.key}: ${entry.value}',
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (log.changesAfter.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✅ After:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                ...log.changesAfter.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        if (log.errorMessage != null && log.errorMessage!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ Error:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.errorMessage!,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.logs.length,
      itemBuilder: (context, index) {
        final log = widget.logs[index];
        final isExpanded = _expandedIndices.contains(index);
        final actionColor = _getActionColor(log.action);
        final actionIcon = _getActionIcon(log.action);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              ListTile(
                selected: isExpanded,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(actionIcon, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(log.action.toUpperCase()),
                    ),
                    Chip(
                      label: Text(
                        log.success ? '✅ Success' : '❌ Failed',
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: log.success
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      labelStyle: TextStyle(
                        color: log.success ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '${log.resourceType} • ${log.resourceId}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          log.userId,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(log.timestamp),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedIndices.remove(index);
                      } else {
                        _expandedIndices.add(index);
                      }
                    });
                  },
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildChangeDetails(log),
                ),
            ],
          ),
        );
      },
    );
  }
}
