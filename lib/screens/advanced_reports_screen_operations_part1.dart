// Part of advanced_reports_screen.dart
// Auto-split Operations

part of 'advanced_reports_screen.dart';

extension AdvancedReportsOperationsPart1 on _AdvancedReportsScreenState {
  void _startAutoRefreshIfEnabled() {
    if (_autoRefreshEnabled && _autoRefreshTimer == null) {
      _autoRefreshTimer = Timer.periodic(
        Duration(minutes: _autoRefreshIntervalMinutes),
        (timer) => _autoRefreshReport(),
      );
    }
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  void _toggleAutoRefresh() {
    if (!_autoRefreshEnabled) {
      // Show dialog to configure auto-refresh interval
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Auto-refresh Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose refresh interval:'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [1, 5, 10, 15, 30].map((minutes) {
                  return ChoiceChip(
                    label: Text('$minutes min'),
                    selected: _autoRefreshIntervalMinutes == minutes,
                    onSelected: (selected) {
                      if (selected) {
                        _updateState(() => _autoRefreshIntervalMinutes = minutes);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateState(() => _autoRefreshEnabled = true);
                _startAutoRefreshIfEnabled();
                if (mounted)
                  ToastHelper.showToast(
                    context,
                    'Auto-refresh enabled ($_autoRefreshIntervalMinutes min)',
                  );
              },
              child: const Text('Enable'),
            ),
          ],
        ),
      );
    } else {
      _updateState(() => _autoRefreshEnabled = false);
      _stopAutoRefresh();
      if (mounted) ToastHelper.showToast(context, 'Auto-refresh disabled');
    }
  }

}
