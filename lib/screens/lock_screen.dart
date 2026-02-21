import 'package:extropos/config/app_flavor.dart';
import 'package:extropos/screens/debug_tools_screen.dart';
import 'package:extropos/screens/first_admin_setup_screen.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/lock_manager.dart';
import 'package:extropos/services/technician_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinCtrl.text.trim();
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

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ok = await LockManager.instance.attemptUnlock(pin);
      if (!ok) {
        setState(() => _error = 'Invalid PIN');
        return;
      }

      if (!mounted) return;
      // Navigate to the correct home screen based on app flavor
      Navigator.pushReplacementNamed(context, AppFlavor.homeRoute);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onNumericKeyTap(String key) {
    final current = _pinCtrl.text;
    if (key == 'back') {
      if (current.isNotEmpty) {
        setState(
          () => _pinCtrl.text = current.substring(0, current.length - 1),
        );
      }
      return;
    }
    if (key == 'enter') {
      _submit();
      return;
    }
    // digits
    if (RegExp(r'^[0-9]$').hasMatch(key)) {
      if (_pinCtrl.text.length < 8) {
        setState(() => _pinCtrl.text = _pinCtrl.text + key);
      }
    }
  }

  Widget _buildNumericKeypad() {
    final btnStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    Widget k(String label) => ElevatedButton(
      onPressed: () => _onNumericKeyTap(label),
      style: btnStyle,
      child: Text(label, style: const TextStyle(fontSize: 18)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.0,
        children: [
          k('1'),
          k('2'),
          k('3'),
          k('4'),
          k('5'),
          k('6'),
          k('7'),
          k('8'),
          k('9'),
          ElevatedButton(
            onPressed: () => _onNumericKeyTap('back'),
            style: btnStyle,
            child: const Icon(Icons.backspace),
          ),
          k('0'),
          ElevatedButton(
            onPressed: () => _onNumericKeyTap('enter'),
            style: btnStyle,
            child: const Icon(Icons.check),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unlock — ExtroPOS')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  kToolbarHeight -
                  32, // padding
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Enter your PIN to unlock',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildNumericKeypad(),
                    TextField(
                      controller: _pinCtrl,
                      keyboardType: TextInputType.number,
                      readOnly: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'PIN',
                        errorText: _error,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Unlock'),
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
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
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
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
