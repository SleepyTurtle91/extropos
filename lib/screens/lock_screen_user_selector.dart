part of 'lock_screen.dart';

extension LockScreenUserSelector on _LockScreenState {
  Widget _buildUserSelector({double screenScale = 1.0}) {
    final selected = _selectedUser;
    final showUsers = _showUsers && _users.isNotEmpty;
    final pulseValue = _users.isEmpty ? _pulseAnimation.value : 0.0;
    final basePadding = 16.0 * screenScale;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = 1.0 + (0.02 * pulseValue);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: _users.isEmpty
                ? null
                : () => setState(() => _showUsers = !_showUsers),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: EdgeInsets.all(basePadding),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _users.isEmpty
                      ? _indigo.withOpacity(0.5 + (0.3 * pulseValue))
                      : Colors.white.withOpacity(0.1),
                  width: _users.isEmpty ? 1.5 : 1.0,
                ),
                boxShadow: _users.isEmpty
                    ? [
                        BoxShadow(
                          color: _indigo.withOpacity(0.3 + (0.3 * pulseValue)),
                          blurRadius: 16 + (8 * pulseValue),
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48 * screenScale,
                    height: 48 * screenScale,
                    decoration: BoxDecoration(
                      color: selected == null
                          ? _slate700
                          : _colorForUser(selected),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        selected == null ? 'U' : _initialsForUser(selected),
                        style: TextStyle(
                          fontSize: 18 * screenScale,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16 * screenScale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected?.fullName ?? 'Select user',
                          style: TextStyle(
                            fontSize: 18 * screenScale,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          selected?.roleDisplayName ?? 'No active users',
                          style: TextStyle(
                            fontSize: 14 * screenScale,
                            color: _slate400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: showUsers ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: _users.isEmpty ? _slate600 : _slate400,
                      size: 20 * screenScale,
                    ),
                  )
                ],
              ),
            ),
          ),
          if (showUsers)
            Positioned(
              top: 88 * screenScale,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(8 * screenScale),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: _users
                      .map(
                        (u) => InkWell(
                          onTap: () {
                            setState(() {
                              _selectedUser = u;
                              _showUsers = false;
                              _pin = '';
                              _isError = false;
                              _infoMessage = null;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: EdgeInsets.all(12 * screenScale),
                            decoration: BoxDecoration(
                              color: selected?.id == u.id
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40 * screenScale,
                                  height: 40 * screenScale,
                                  decoration: BoxDecoration(
                                    color:
                                        _colorForUser(u).withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _initialsForUser(u),
                                      style: TextStyle(
                                        fontSize: 14 * screenScale,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16 * screenScale),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      u.fullName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 14 * screenScale,
                                      ),
                                    ),
                                    Text(
                                      u.roleDisplayName,
                                      style: TextStyle(
                                        fontSize: 12 * screenScale,
                                        color: _slate400,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
