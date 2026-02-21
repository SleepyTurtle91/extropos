import 'package:extropos/services/user_session_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class SignOutDialogSimple extends StatefulWidget {
  const SignOutDialogSimple({super.key});

  @override
  State<SignOutDialogSimple> createState() => _SignOutDialogSimpleState();
}

class _SignOutDialogSimpleState extends State<SignOutDialogSimple> {
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);

    try {
      await UserSessionService().signOutUser();
      if (mounted) {
        Navigator.of(context).pop(true);
        ToastHelper.showToast(context, 'Signed out successfully');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Sign out failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = UserSessionService().currentActiveUser;

    if (currentUser == null) {
      return AlertDialog(
        title: const Text('Error'),
        content: const Text('No user currently signed in'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Cashier Sign Out'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current user: ${currentUser.fullName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            if (UserSessionService().signInTime != null)
              Text(
                'Signed in: ${UserSessionService().signInTime!.toString().substring(0, 16)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            const Text(
              'Sign out to allow another cashier to use the POS.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Reason for signing out...',
              ),
              maxLines: 2,
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
          onPressed: _isLoading ? null : _signOut,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Sign Out'),
        ),
      ],
    );
  }
}
