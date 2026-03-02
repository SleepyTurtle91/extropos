part of 'lock_screen.dart';

extension LockScreenOperations on _LockScreenState {
  Future<void> _submit() async {
    if (_loading) return;
    final pin = _pin.trim();
    if (pin.isEmpty) return;

    final handled = await TechnicianService.handlePinIfTechnician(context, pin);
    if (handled) return;

    if (pin == '888888') {
      try {
        final users = await DatabaseService.instance.getUsers();
        if (users.isEmpty) {
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
}
