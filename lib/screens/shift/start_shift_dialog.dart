import 'package:extropos/features/auth/services/shift_service.dart';
import 'package:flutter/material.dart';

class StartShiftDialog extends StatefulWidget {
  final String userId;

  const StartShiftDialog({
    super.key,
    required this.userId,
  });

  @override
  State<StartShiftDialog> createState() => _StartShiftDialogState();
}

class _StartShiftDialogState extends State<StartShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _openingCashController = TextEditingController(text: '0.00');
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _openingCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _startShift() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final openingCash = double.tryParse(_openingCashController.text.trim()) ??
        double.nan;
    if (openingCash.isNaN || openingCash < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid opening cash amount')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ShiftService.instance.startShift(
        widget.userId,
        openingCash,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start shift: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start Shift'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _openingCashController,
              decoration: const InputDecoration(
                labelText: 'Opening Cash',
                prefixText: 'RM ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Opening cash is required';
                }
                final parsed = double.tryParse(value.trim());
                if (parsed == null || parsed < 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _startShift,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Start'),
        ),
      ],
    );
  }
}
