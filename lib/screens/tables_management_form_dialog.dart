part of 'tables_management_screen.dart';

class _TableFormDialog extends StatefulWidget {
  final RestaurantTable? table;
  final Function(RestaurantTable) onSave;

  const _TableFormDialog({this.table, required this.onSave});

  @override
  State<_TableFormDialog> createState() => _TableFormDialogState();
}

class _TableFormDialogState extends State<_TableFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _capacityController;
  late TableStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.table?.name ?? '');
    _capacityController = TextEditingController(
      text: widget.table?.capacity.toString() ?? '4',
    );
    _selectedStatus = widget.table?.status ?? TableStatus.available;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.isEmpty) {
      ToastHelper.showToast(context, 'Please enter table name');
      return;
    }

    final capacity = int.tryParse(_capacityController.text);
    if (capacity == null || capacity < 1) {
      ToastHelper.showToast(context, 'Please enter valid capacity');
      return;
    }

    final table = RestaurantTable(
      id: widget.table?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      capacity: capacity,
      status: _selectedStatus,
      orders: widget.table?.orders,
      occupiedSince: widget.table?.occupiedSince,
      customerName: widget.table?.customerName,
    );

    widget.onSave(table);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.table == null ? 'Add Table' : 'Edit Table'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Table Name *',
                  border: OutlineInputBorder(),
                  hintText: 'Table 1',
                ),
              ),
              const SizedBox(height: 16),
              ResponsiveRow(
                breakpoint: 480,
                rowChildren: [
                  Expanded(
                    child: TextField(
                      controller: _capacityController,
                      decoration: const InputDecoration(
                        labelText: 'Capacity *',
                        border: OutlineInputBorder(),
                        hintText: '4',
                        suffixText: 'seats',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<TableStatus>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status *',
                        border: OutlineInputBorder(),
                      ),
                      items: TableStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedStatus = value);
                        }
                      },
                    ),
                  ),
                ],
                columnChildren: [
                  TextField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                      labelText: 'Capacity *',
                      border: OutlineInputBorder(),
                      hintText: '4',
                      suffixText: 'seats',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TableStatus>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status *',
                      border: OutlineInputBorder(),
                    ),
                    items: TableStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedStatus = value);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
