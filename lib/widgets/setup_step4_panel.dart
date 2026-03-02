import 'package:flutter/material.dart';

class SetupStep4Panel extends StatelessWidget {
  final String syncMode;
  final ValueChanged<String> onSyncModeChanged;

  static const _sky = Color(0xFF0EA5E9);
  static const _slate800 = Color(0xFF1E293B);

  const SetupStep4Panel({
    required this.syncMode,
    required this.onSyncModeChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey(4),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            Icons.cloud,
            _sky,
            Colors.lightBlue.shade50,
            'Database & Sync',
            'Choose how ExtroPOS stores your data.',
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: Colors.grey.shade200, width: 2),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Opacity(
              opacity: 0.6,
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud,
                      color: Colors.grey.shade400,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Cloud Sync',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'COMING SOON',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF4F46E5),
                                  letterSpacing: 1,
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Automatically backup data, sync across multiple terminals, and access real-time online reports.',
                          style: TextStyle(
                            color: Colors.grey,
                            height: 1.5,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => onSyncModeChanged('local'),
            borderRadius: BorderRadius.circular(32),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: syncMode == 'local'
                    ? const Color(0xFFF8FAFC)
                    : Colors.white,
                border: Border.all(
                  color: syncMode == 'local' ? _slate800 : Colors.grey.shade200,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: syncMode == 'local'
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: syncMode == 'local' ? _slate800 : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.dns,
                      color:
                          syncMode == 'local' ? Colors.white : Colors.grey.shade400,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Local Only',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: syncMode == 'local'
                                ? _slate800
                                : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Data is stored securely on this device only. Works fully offline, but no automatic backups.',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            height: 1.5,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStepHeader(
    IconData icon,
    Color color,
    Color bgColor,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
