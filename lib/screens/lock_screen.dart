import 'dart:async';

import 'package:extropos/config/app_flavor.dart';
import 'package:extropos/models/user_model.dart';
import 'package:extropos/screens/first_admin_setup_screen.dart';
import 'package:extropos/services/config_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/lock_manager.dart';
import 'package:extropos/services/technician_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

part 'lock_screen_operations.dart';
part 'lock_screen_left_panel.dart';
part 'lock_screen_right_panel.dart';
part 'lock_screen_user_selector.dart';
part 'lock_screen_numpad.dart';

const _panelBg = Color(0xFF131B2C);
const _cardBg = Color(0xFF1C2538);
const _indigo = Color(0xFF4F46E5);
const _indigoBright = Color(0xFF6366F1);
const _emerald = Color(0xFF10B981);
const _rose = Color(0xFFF43F5E);
const _slate400 = Color(0xFF94A3B8);
const _slate500 = Color(0xFF64748B);
const _slate600 = Color(0xFF475569);
const _slate700 = Color(0xFF334155);
const _minPinLength = 4;
const _maxPinLength = 6;
const _pinIndicators = 6;

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth >= 1024;
          final isMediumScreen = constraints.maxWidth >= 600;

          return SafeArea(
            child: Row(
              children: [
                if (isLargeScreen) Expanded(child: _buildLeftPanel()),
                SizedBox(
                  width: isLargeScreen
                      ? 500
                      : (isMediumScreen
                          ? constraints.maxWidth * 0.9
                          : constraints.maxWidth),
                  child: _buildRightPanel(constraints: constraints),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
