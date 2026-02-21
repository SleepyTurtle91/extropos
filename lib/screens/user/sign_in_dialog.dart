import 'package:extropos/services/business_session_service.dart';
import 'package:extropos/services/user_session_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class SignInDialog extends StatefulWidget {
  const SignInDialog({super.key});

  @override
  State<SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends State<SignInDialog> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _enteredPin = '';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _onKeyPressed(String key) {
    if (key == 'clear') {
      setState(() {
        _enteredPin = '';
        _pinController.text = '';
      });
    } else if (key == 'backspace') {
      if (_enteredPin.isNotEmpty) {
        setState(() {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
          _pinController.text = _enteredPin;
        });
      }
    } else {
      if (_enteredPin.length < 6) {
        setState(() {
          _enteredPin += key;
          _pinController.text = _enteredPin;
        });
      }
    }
  }

  Future<void> _signIn() async {
    if (_enteredPin.isEmpty) {
      ToastHelper.showToast(context, 'Please enter your PIN');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await UserSessionService().signInUser(_enteredPin);

      if (success && mounted) {
        final user = UserSessionService().currentActiveUser;

        Navigator.of(context).pop(true);
        ToastHelper.showToast(context, 'Welcome, ${user?.fullName ?? 'User'}!');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Sign in failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = BusinessSessionService().currentSession;

    return AlertDialog(
      title: const Text('Cashier Sign In'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (session != null) ...[
              Text(
                'Business opened: ${session.openDate.toString().substring(0, 16)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
            ],
            const Text(
              'Enter your 4-6 digit PIN to sign in for this shift.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            // PIN Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  6,
                  (index) => Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _enteredPin.length
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Numeric Keypad
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 1; i <= 9; i++)
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _onKeyPressed(i.toString()),
                    child: Text(
                      i.toString(),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _onKeyPressed('clear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Clear', style: TextStyle(fontSize: 14)),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _onKeyPressed('0'),
                  child: const Text('0', style: TextStyle(fontSize: 20)),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _onKeyPressed('backspace'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Icon(Icons.backspace),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Hidden form field for validation
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _pinController,
                style: const TextStyle(color: Colors.transparent),
                decoration: const InputDecoration.collapsed(hintText: ''),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter PIN';
                  }
                  if (value.length < 4 || value.length > 6) {
                    return 'PIN must be 4-6 digits';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _signIn,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Sign In'),
        ),
      ],
    );
  }
}
