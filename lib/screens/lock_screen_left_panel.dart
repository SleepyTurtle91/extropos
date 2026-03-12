part of 'lock_screen.dart';

extension _LockScreenLeftPanel on _LockScreenState {
  Widget _buildLeftPanel() {
    return Stack(
      children: [
        Positioned(
          top: -200,
          left: -100,
          child: Container(
            width: 800,
            height: 800,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _indigo.withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                  color: _indigo.withOpacity(0.1),
                  blurRadius: 120,
                  spreadRadius: 120,
                )
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(64.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _indigo,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _indigo.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'E',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'ExtroPOS',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Terminal ${ConfigService.instance.terminalId}',
                    style: TextStyle(
                      fontSize: 16,
                      color: _slate400,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTime(_currentTime),
                    style: const TextStyle(
                      fontSize: 96,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: -2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatDate(_currentTime),
                    style: TextStyle(
                      fontSize: 24,
                      color: _slate400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.verified_user, color: _emerald, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'System Secured • Database Synced',
                    style: TextStyle(
                      color: _slate500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}
