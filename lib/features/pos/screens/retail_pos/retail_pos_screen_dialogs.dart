part of 'retail_pos_screen.dart';

class _ParkSaleDialog extends StatefulWidget {
  const _ParkSaleDialog();

  @override
  State<_ParkSaleDialog> createState() => _ParkSaleDialogState();
}

class _ParkSaleDialogState extends State<_ParkSaleDialog> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Park Sale'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Add optional notes for this parked sale:'),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'e.g., Customer will return later',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 200,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_notesController.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Park Sale'),
        ),
      ],
    );
  }
}
