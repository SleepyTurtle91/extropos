part of 'lock_screen.dart';

extension _LockScreenRightPanel on _LockScreenState {
  Widget _buildRightPanel({required BoxConstraints constraints}) {
    final screenScale = constraints.maxWidth > 600
        ? constraints.maxWidth / 1200
        : constraints.maxWidth / 480;

    return Container(
      decoration: BoxDecoration(
        color: _panelBg,
        border: Border(left: BorderSide(color: Colors.white.withOpacity(0.05))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 40,
          )
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: 360 * (screenScale > 1 ? 1 : screenScale),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildUserSelector(screenScale: screenScale),
                SizedBox(height: 40 * screenScale),
                _buildPinIndicators(screenScale: screenScale),
                SizedBox(height: 16 * screenScale),
                _buildStatusMessage(screenScale: screenScale),
                SizedBox(height: 16 * screenScale),
                _buildNumpad(screenScale: screenScale),
                SizedBox(height: 16 * screenScale),
                Text(
                  'Enter your PIN to unlock',
                  style: TextStyle(
                    color: _slate600,
                    fontWeight: FontWeight.w500,
                    fontSize: 14 * screenScale,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {},
                  child: const Text('Need help? Contact technician'),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 8),
                  // Debug tools removed
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinIndicators({double screenScale = 1.0}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinIndicators, (index) {
        final isFilled = index < _pin.length;
        var color = const Color(0xFF2A3449);
        var shadows = <BoxShadow>[];
        var scale = 1.0;

        if (_isSuccess) {
          color = _emerald;
          shadows = [BoxShadow(color: color.withOpacity(0.5), blurRadius: 15)];
          scale = 1.1;
        } else if (_isError) {
          color = _rose;
          shadows = [BoxShadow(color: color.withOpacity(0.5), blurRadius: 15)];
        } else if (isFilled) {
          color = _indigoBright;
          shadows = [BoxShadow(color: color.withOpacity(0.5), blurRadius: 15)];
          scale = 1.1;
        }

        final baseSize = 18.0 * screenScale;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 10 * screenScale),
          width: baseSize * scale,
          height: baseSize * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: shadows,
          ),
        );
      }),
    );
  }

  Widget _buildStatusMessage({double screenScale = 1.0}) {
    final fontSize = 16.0 * screenScale;
    return SizedBox(
      height: 32 * screenScale,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _infoMessage != null
              ? Text(
                  _infoMessage!,
                  style: TextStyle(
                    color: _slate500,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                  ),
                )
              : _isSuccess
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            color: _emerald, size: 18 * screenScale),
                        SizedBox(width: 8 * screenScale),
                        Text(
                          'Access Granted',
                          style: TextStyle(
                            color: _emerald,
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                      ],
                    )
                  : _isError
                      ? Text(
                          'Incorrect PIN',
                          style: TextStyle(
                            color: _rose,
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        )
                      : Text(
                          'Enter your PIN',
                          style: TextStyle(
                            color: _slate500,
                            fontWeight: FontWeight.w500,
                            fontSize: fontSize,
                          ),
                        ),
        ),
      ),
    );
  }
}
