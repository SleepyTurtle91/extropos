import 'dart:async';

import 'package:extropos/config/app_flavor.dart';
import 'package:extropos/models/user_model.dart';
import 'package:extropos/screens/debug_tools_screen.dart';
import 'package:extropos/screens/first_admin_setup_screen.dart';
import 'package:extropos/services/config_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/lock_manager.dart';
import 'package:extropos/services/technician_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  static const _panelBg = Color(0xFF131B2C);
  static const _cardBg = Color(0xFF1C2538);
  static const _indigo = Color(0xFF4F46E5);
  static const _indigoBright = Color(0xFF6366F1);
  static const _emerald = Color(0xFF10B981);
  static const _rose = Color(0xFFF43F5E);
  static const _slate400 = Color(0xFF94A3B8);
  static const _slate500 = Color(0xFF64748B);
  static const _slate600 = Color(0xFF475569);
  static const _slate700 = Color(0xFF334155);

  static const _minPinLength = 4;
  static const _maxPinLength = 6;
  static const _pinIndicators = 6;

  final List<Color> _userColors = const [
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF0EA5E9),
    Color(0xFFEC4899),
    Color(0xFF22C55E),
  ];

  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  String _pin = '';
  bool _isError = false;
  bool _isSuccess = false;
  bool _showUsers = false;
  bool _loading = false;
  String? _infoMessage;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<User> _users = [];
  User? _selectedUser;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _currentTime = DateTime.now());
    });

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _loadUsers();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final pin = _pin.trim();
    if (pin.isEmpty) return;

    // Technician override handled first
    final handled = await TechnicianService.handlePinIfTechnician(context, pin);
    if (handled) return;

    // Check for first-time setup with PIN 888888
    if (pin == '888888') {
      try {
        final users = await DatabaseService.instance.getUsers();
        if (users.isEmpty) {
          // No users exist, allow first admin creation
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FirstAdminSetupScreen(),
            ),
          );
          return;
        }
      } catch (e) {
        // If database error, still allow first admin creation
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FirstAdminSetupScreen(),
          ),
        );
        return;
      }
    }

    final selected = _selectedUser;
    if (selected == null) {
      setState(() {
        _infoMessage = 'Select a user first';
        _isError = false;
      });
      return;
    }

    if (pin != selected.pin) {
      _showPinError();
      return;
    }

    setState(() {
      _loading = true;
      _isError = false;
      _infoMessage = null;
    });

    try {
      final ok = await LockManager.instance.attemptUnlock(pin);
      if (!ok) {
        _showPinError();
        return;
      }

      setState(() => _isSuccess = true);

      if (!mounted) return;
      // Navigate to the correct home screen based on app flavor
      Navigator.pushReplacementNamed(context, AppFlavor.homeRoute);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleNumPress(String num) {
    if (_pin.length < _maxPinLength && !_isSuccess && !_loading) {
      final nextPin = _pin + num;
      setState(() {
        _pin = nextPin;
        _isError = false;
        _infoMessage = null;
      });

      if (nextPin.length == _maxPinLength) {
        _submit();
        return;
      }

      if (nextPin.length == _minPinLength && _shouldAutoSubmit(nextPin)) {
        _submit();
      }
    }
  }

  void _handleBackspace() {
    if (_pin.isNotEmpty && !_isSuccess && !_loading) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _isError = false;
        _infoMessage = null;
      });
    }
  }

  void _showPinError() {
    setState(() {
      _isError = true;
      _infoMessage = null;
    });
    _shakeController.forward(from: 0.0);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _pin = '';
          _isError = false;
          _isSuccess = false;
          _infoMessage = null;
        });
      }
    });
  }

  bool _shouldAutoSubmit(String pin) {
    if (_selectedUser == null) return false;
    if (TechnicianService.technicianPin.startsWith(pin)) return false;
    return true;
  }

  Future<void> _loadUsers() async {
    try {
      final users = await DatabaseService.instance.getUsers();
      if (!mounted) return;
      setState(() {
        _users = users.where((u) => u.status == UserStatus.active).toList();
        if (_users.isNotEmpty) {
          _selectedUser = _users.first;
          _showUsers = false;
            _pulseController.stop();
          } else {
            _selectedUser = null;
            _showUsers = true;
            if (!_pulseController.isAnimating) {
              _pulseController.repeat(reverse: true);
            }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _users = [];
        _selectedUser = null;
        _showUsers = true;
        });
        if (!_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
    }
  }

  String _formatTime(DateTime time) {
    final h = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final m = time.minute.toString().padLeft(2, '0');
    final p = time.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  String _formatDate(DateTime time) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[time.weekday - 1]}, ${months[time.month - 1]} ${time.day}';
  }

  String _initialsForUser(User user) {
    final parts = user.fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    return '$first$last';
  }

  Color _colorForUser(User user) {
    final index = user.id.hashCode.abs() % _userColors.length;
    return _userColors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth >= 1024;
          final isMediumScreen = constraints.maxWidth >= 600;
          final screenScale = isMediumScreen 
              ? constraints.maxWidth / 1200 
              : constraints.maxWidth / 480;
          
          return SafeArea(
            child: Row(
              children: [
                if (isLargeScreen) Expanded(child: _buildLeftPanel()),
                SizedBox(
                  width: isLargeScreen 
                      ? 500 
                      : (isMediumScreen ? constraints.maxWidth * 0.9 : constraints.maxWidth),
                  child: _buildRightPanel(screenScale: screenScale),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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

  Widget _buildRightPanel({double screenScale = 1.0}) {
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
                  onPressed: () {
                    // Offer help: technician PIN hint is not shown. Keep minimal.
                  },
                  child: const Text('Need help? Contact technician'),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DebugToolsScreen(),
                        ),
                      );
                    },
                    child: const Text('Open debug tools'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

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
                                    color: _colorForUser(u).withOpacity(0.8),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    Icon(Icons.check_circle, color: _emerald, size: 18 * screenScale),
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

  Widget _buildIconBtn(IconData icon, VoidCallback? onTap, {Color? color, double screenScale = 1.0}) {
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
