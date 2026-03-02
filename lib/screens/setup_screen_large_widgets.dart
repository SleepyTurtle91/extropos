part of 'setup_screen.dart';

extension SetupScreenLargeWidgets on _SetupScreenState {
  Widget _buildProgressBar() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      margin: const EdgeInsets.only(bottom: 48),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps * 2 - 1, (index) {
              if (index.isEven) {
                final stepNum = (index ~/ 2) + 1;
                final isPast = _step > stepNum;
                final isActive = _step >= stepNum;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive ? _indigo : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? _indigo : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: _indigo.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Center(
                    child: isPast
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            '$stepNum',
                            style: TextStyle(
                              color:
                                  isActive ? Colors.white : Colors.grey.shade400,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              }

              final stepNum = (index ~/ 2) + 1;
              final isActive = _step > stepNum;
              return Expanded(
                child: Container(
                  height: 4,
                  color: isActive ? _indigo : Colors.grey.shade200,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BUSINESS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'TERMINAL',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'OWNER',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'DATABASE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'READY',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

}
