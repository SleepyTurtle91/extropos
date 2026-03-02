part of 'printers_management_screen.dart';

/// Dialog handlers for printer CRUD operations
extension _PrintersManagementScreenDialogs on _PrintersManagementScreenState {
  Future<bool> _confirmAddPrinter(Printer printer) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Add Printer'),
            content: Text(
              'Found printer: ${printer.name} (${printer.connectionType.name}). Add it to your printers?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Add'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _addPrinter() {
    showDialog(
      context: context,
      builder: (context) => PrinterFormDialog(
        onSave: (printer) async {
          try {
            await PrinterBusinessLogicService.savePrinter(printer);
            if (!mounted) return;
            setState(() {
              printers.add(printer);
              _selectedPrinterId = printer.id;
            });
            if (mounted) {
              ToastHelper.showToast(
                context,
                'Printer saved successfully (ID: ${printer.id})',
              );
            }
          } catch (e) {
            if (mounted) {
              ToastHelper.showToast(context, 'Failed to save printer: $e');
            }
          }
        },
      ),
    );
  }

  void _editPrinter(Printer printer) {
    showDialog(
      context: context,
      builder: (context) => PrinterFormDialog(
        printer: printer,
        onSave: (updatedPrinter) async {
          try {
            await PrinterBusinessLogicService.savePrinter(updatedPrinter);
            if (!mounted) return;
            setState(() {
              final index = printers.indexWhere((p) => p.id == updatedPrinter.id);
              if (index != -1) printers[index] = updatedPrinter;
            });
            if (mounted) ToastHelper.showToast(context, 'Printer updated');
          } catch (e) {
            if (mounted) ToastHelper.showToast(context, 'Error: $e');
          }
        },
      ),
    );
  }

  void _deletePrinter(Printer printer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Printer'),
        content: Text('Are you sure you want to delete "${printer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await PrinterBusinessLogicService.deletePrinter(printer.id);
                if (!mounted) return;
                setState(() {
                  printers.removeWhere((p) => p.id == printer.id);
                  if (_selectedPrinterId == printer.id) {
                    _selectedPrinterId = printers.isNotEmpty
                        ? printers.first.id
                        : null;
                  }
                });
                if (!mounted) return;
                Navigator.pop(context);
                if (mounted) ToastHelper.showToast(context, 'Printer deleted');
              } catch (e) {
                if (mounted) {
                  ToastHelper.showToast(context, 'Error: $e');
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
