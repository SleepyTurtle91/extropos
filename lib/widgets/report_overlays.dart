import 'package:flutter/material.dart';

class ExportProgressOverlay extends StatelessWidget {
  final String? exportingType;
  final double exportProgress;

  const ExportProgressOverlay({
    required this.exportingType,
    required this.exportProgress,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (exportingType == null) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.1),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Generating ${exportingType?.toUpperCase()}...',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: exportProgress),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportModalOverlay extends StatelessWidget {
  final String? activeModalReport;
  final VoidCallback onClose;

  const ReportModalOverlay({
    required this.activeModalReport,
    required this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (activeModalReport == null) return const SizedBox.shrink();

    final isX = activeModalReport == 'X';
    final themeColor = isX ? const Color(0xFF4F46E5) : Colors.red.shade600;

    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          width: 480,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$activeModalReport-Report Detail',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text(
                      'Connect to Shift Table for Real-time Totals',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
