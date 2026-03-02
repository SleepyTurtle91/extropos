part of 'tables_management_screen.dart';

extension TablesManagementOperations on _TablesManagementScreenState {
  Future<void> _loadTables() async {
    final currentContext = context;
    try {
      final loadedTables = await DatabaseService.instance.getTables();
      setState(() {
        tables = loadedTables;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ToastHelper.showToast(currentContext, 'Error loading tables: $e');
      }
    }
  }

  void _addTable() {
    final widgetContext = context;
    showDialog(
      context: context,
      builder: (context) => _TableFormDialog(
        onSave: (table) async {
          try {
            await DatabaseService.instance.insertTable(table);
            if (!mounted) return;
            await _loadTables();
            if (!mounted) return;
            if (mounted) {
              ToastHelper.showToast(widgetContext, 'Table added successfully');
            }
          } catch (e) {
            if (!mounted) return;
            if (mounted) {
              ToastHelper.showToast(widgetContext, 'Error adding table: $e');
            }
          }
        },
      ),
    );
  }

  void _showBulkAddDialog() {
    int tableCount = 10;
    int capacity = 4;
    String baseName = 'Table';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Bulk Add Tables'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add multiple tables at once with the same capacity.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: tableCount.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Number of Tables',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.format_list_numbered),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final count = int.tryParse(value);
                    if (count != null && count > 0 && count <= 100) {
                      tableCount = count;
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: capacity.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Capacity per Table',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final cap = int.tryParse(value);
                    if (cap != null && cap > 0 && cap <= 20) {
                      capacity = cap;
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: baseName,
                  decoration: const InputDecoration(
                    labelText: 'Base Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.table_restaurant),
                    hintText: 'e.g., Table, Booth, VIP',
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      baseName = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Will create: $baseName 1, $baseName 2, ..., $baseName $tableCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _performBulkAdd(tableCount, capacity, baseName),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Tables'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performBulkAdd(int count, int capacity, String baseName) async {
    final currentContext = context;
    Navigator.pop(currentContext);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Adding tables...'),
            ],
          ),
        ),
      );

      final tablesToAdd = <RestaurantTable>[];
      for (int i = 1; i <= count; i++) {
        final tableId = 'table_${DateTime.now().millisecondsSinceEpoch}_$i';
        final tableName = '$baseName $i';
        tablesToAdd.add(
          RestaurantTable(id: tableId, name: tableName, capacity: capacity),
        );
      }

      for (final table in tablesToAdd) {
        await DatabaseService.instance.insertTable(table);
      }

      if (mounted) {
        Navigator.pop(currentContext);
      }

      if (!mounted) return;
      await _loadTables();
      if (!mounted) return;

      ToastHelper.showToast(currentContext, 'Successfully added $count tables');
    } catch (e) {
      if (mounted && Navigator.canPop(currentContext)) {
        Navigator.pop(currentContext);
      }

      if (!mounted) return;
      ToastHelper.showToast(currentContext, 'Error adding tables: $e');
    }
  }

  void _editTable(RestaurantTable table) {
    final widgetContext = context;
    showDialog(
      context: context,
      builder: (context) => _TableFormDialog(
        table: table,
        onSave: (updatedTable) async {
          try {
            await DatabaseService.instance.updateTable(updatedTable);
            if (!mounted) return;
            await _loadTables();
            if (!mounted) return;
            if (mounted) {
              ToastHelper.showToast(
                widgetContext,
                'Table updated successfully',
              );
            }
          } catch (e) {
            if (!mounted) return;
            if (mounted) {
              ToastHelper.showToast(widgetContext, 'Error updating table: $e');
            }
          }
        },
      ),
    );
  }

  void _deleteTable(RestaurantTable table) {
    final widgetContext = context;
    if (table.isOccupied) {
      ToastHelper.showToast(widgetContext, 'Cannot delete an occupied table');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Table'),
        content: Text('Are you sure you want to delete "${table.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await DatabaseService.instance.deleteTable(table.id);
                if (!mounted) return;
                await _loadTables();
                if (!mounted) return;
                if (mounted) {
                  Navigator.pop(context);
                  ToastHelper.showToast(
                    widgetContext,
                    'Table deleted successfully',
                  );
                }
              } catch (e) {
                if (!mounted) return;
                if (mounted) {
                  Navigator.pop(context);
                  ToastHelper.showToast(
                    widgetContext,
                    'Error deleting table: $e',
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _duplicateTable(RestaurantTable table) async {
    final currentContext = context;
    try {
      final newId = 'table_${DateTime.now().millisecondsSinceEpoch}';
      final newTable = RestaurantTable(
        id: newId,
        name: '${table.name} (Copy)',
        capacity: table.capacity,
      );

      await DatabaseService.instance.insertTable(newTable);
      if (!mounted) return;
      await _loadTables();
      if (!mounted) return;

      ToastHelper.showToast(currentContext, 'Table duplicated successfully');
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(currentContext, 'Error duplicating table: $e');
    }
  }
}
