import 'package:extropos/services/error_handler.dart';
import 'package:flutter/material.dart';

/// In-app error console for debugging and troubleshooting
class ErrorConsoleScreen extends StatefulWidget {
  const ErrorConsoleScreen({super.key});

  @override
  State<ErrorConsoleScreen> createState() => _ErrorConsoleScreenState();
}

class _ErrorConsoleScreenState extends State<ErrorConsoleScreen> {
  final ScrollController _scrollController = ScrollController();
  List<ErrorRecord> _errorHistory = [];
  Map<String, int> _errorStats = {};

  @override
  void initState() {
    super.initState();
    _loadErrorData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadErrorData() {
    setState(() {
      _errorHistory = ErrorHandler.getErrorHistory();
      _errorStats = ErrorHandler.getErrorStats();
    });
  }

  void _clearErrors() {
    ErrorHandler.clearErrorHistory();
    _loadErrorData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadErrorData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearErrors,
            tooltip: 'Clear All Errors',
          ),
        ],
      ),
      body: Column(
        children: [
          // Error Statistics
          _buildErrorStats(),

          // Error List
          Expanded(
            child: _errorHistory.isEmpty
                ? _buildEmptyState()
                : _buildErrorList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Errors',
              _errorHistory.length.toString(),
              Icons.error,
              Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Database',
              (_errorStats['ErrorCategory.database'] ?? 0).toString(),
              Icons.storage,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Hardware',
              (_errorStats['ErrorCategory.hardware'] ?? 0).toString(),
              Icons.print,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Network',
              (_errorStats['ErrorCategory.network'] ?? 0).toString(),
              Icons.wifi,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No errors recorded',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Errors will appear here when they occur',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _errorHistory.length,
      itemBuilder: (context, index) {
        final error = _errorHistory[index];
        return _buildErrorTile(error);
      },
    );
  }

  Widget _buildErrorTile(ErrorRecord error) {
    final color = _getSeverityColor(error.severity);
    final icon = _getSeverityIcon(error.severity);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          error.userMessage ?? error.error.toString(),
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_formatCategory(error.category)} • ${_formatTimestamp(error.timestamp)}',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Severity', error.severity.toString().toUpperCase()),
                _buildDetailRow('Category', error.category.toString().split('.').last),
                _buildDetailRow('Time', _formatTimestamp(error.timestamp)),
                const SizedBox(height: 8),
                const Text(
                  'Error Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    error.error.toString(),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                if (error.stackTrace.toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Stack Trace:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        error.stackTrace.toString(),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.blue;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.purple;
    }
  }

  IconData _getSeverityIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Icons.info;
      case ErrorSeverity.medium:
        return Icons.warning;
      case ErrorSeverity.high:
        return Icons.error;
      case ErrorSeverity.critical:
        return Icons.dangerous;
    }
  }

  String _formatCategory(ErrorCategory category) {
    return category.toString().split('.').last;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}