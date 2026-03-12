part of 'lock_screen.dart';

extension _LockScreenNumpad on _LockScreenState {
  Widget _buildNumpad({double screenScale = 1.0}) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 16 * screenScale,
        crossAxisSpacing: 16 * screenScale,
        childAspectRatio: 1.2,
        children: [
          ...[1, 2, 3, 4, 5, 6, 7, 8, 9]
              .map((n) => _buildNumpadBtn(n.toString(), screenScale: screenScale)),
          _buildIconBtn(
            Icons.lock,
            _pin.length >= _minPinLength && !_loading ? _submit : null,
            color: _indigo,
            screenScale: screenScale,
          ),
          _buildNumpadBtn('0', screenScale: screenScale),
          _buildIconBtn(
            Icons.backspace_outlined,
            _pin.isNotEmpty ? _handleBackspace : null,
            color: _rose,
            screenScale: screenScale,
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadBtn(String text, {double screenScale = 1.0}) {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => _handleNumPress(text),
        borderRadius: BorderRadius.circular(24),
        highlightColor: _indigo,
        splashColor: _indigo.withOpacity(0.5),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 32 * screenScale,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback? onTap,
      {Color? color, double screenScale = 1.0}) {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        highlightColor: color?.withOpacity(0.2) ?? Colors.transparent,
        splashColor: color?.withOpacity(0.3) ?? Colors.transparent,
        child: Center(
          child: Icon(icon, size: 28 * screenScale, color: color ?? _slate600),
        ),
      ),
    );
  }
}
