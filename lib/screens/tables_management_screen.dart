import 'package:extropos/models/table_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/theme/design_system.dart';
import 'package:extropos/theme/spacing.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/responsive_row.dart';
import 'package:flutter/material.dart';

class TablesManagementScreen extends StatefulWidget {
  const TablesManagementScreen({super.key});

  @override
  State<TablesManagementScreen> createState() => _TablesManagementScreenState();
}

class _TablesManagementScreenState extends State<TablesManagementScreen> {
  List<RestaurantTable> tables = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    final currentContext = context; // capture for toast/UI calls
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
    final widgetContext = context; // Capture widget context
    showDialog(
      context: context,
      builder: (context) => _TableFormDialog(
        onSave: (table) async {
          try {
            await DatabaseService.instance.insertTable(table);
            if (!mounted) return;
            await _loadTables(); // Reload tables from database
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

  void _performBulkAdd(int count, int capacity, String baseName) async {
    final currentContext = context; // capture for async operations
    Navigator.pop(currentContext); // Close the dialog

    try {
      // Show loading indicator
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

      // Generate and insert tables
      final tablesToAdd = <RestaurantTable>[];
      for (int i = 1; i <= count; i++) {
        final tableId = 'table_${DateTime.now().millisecondsSinceEpoch}_$i';
        final tableName = '$baseName $i';
        tablesToAdd.add(
          RestaurantTable(id: tableId, name: tableName, capacity: capacity),
        );
      }

      // Insert all tables
      for (final table in tablesToAdd) {
        await DatabaseService.instance.insertTable(table);
      }

      // Close loading dialog
      if (mounted) {
        Navigator.pop(currentContext);
      }

      // Reload tables and show success
      if (!mounted) return;
      await _loadTables();
      if (!mounted) return;

      ToastHelper.showToast(currentContext, 'Successfully added $count tables');
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(currentContext)) {
        Navigator.pop(currentContext);
      }

      if (!mounted) return;
      ToastHelper.showToast(currentContext, 'Error adding tables: $e');
    }
  }

  void _editTable(RestaurantTable table) {
    final widgetContext = context; // Capture widget context
    showDialog(
      context: context,
      builder: (context) => _TableFormDialog(
        table: table,
        onSave: (updatedTable) async {
          try {
            await DatabaseService.instance.updateTable(updatedTable);
            if (!mounted) return;
            await _loadTables(); // Reload tables from database
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
    final widgetContext = context; // Capture widget context
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
                await _loadTables(); // Reload tables from database
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

  void _duplicateTable(RestaurantTable table) async {
    final currentContext = context; // capture context for async UI
    try {
      // Generate a unique ID for the new table
      final newId = 'table_${DateTime.now().millisecondsSinceEpoch}';
      final newTable = RestaurantTable(
        id: newId,
        name: '${table.name} (Copy)',
        capacity: table.capacity,
      );

      await DatabaseService.instance.insertTable(newTable);
      if (!mounted) return;
      await _loadTables(); // Reload tables from database
      if (!mounted) return;

      ToastHelper.showToast(currentContext, 'Table duplicated successfully');
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(currentContext, 'Error duplicating table: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tables Management'),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tables Management'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Use wrapping layout for smaller screens
                if (constraints.maxWidth < 800) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _StatCard(
                          icon: Icons.table_restaurant,
                          label: 'Total Tables',
                          value: tables.length.toString(),
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _StatCard(
                          icon: Icons.check_circle,
                          label: 'Available',
                          value: tables
                              .where((t) => t.isAvailable)
                              .length
                              .toString(),
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _StatCard(
                          icon: Icons.people,
                          label: 'Occupied',
                          value: tables
                              .where((t) => t.isOccupied)
                              .length
                              .toString(),
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _StatCard(
                          icon: Icons.warning,
                          label: 'Capacity Warnings',
                          value: tables
                              .where((t) => t.needsCapacityWarning)
                              .length
                              .toString(),
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _StatCard(
                          icon: Icons.error,
                          label: 'Over Capacity',
                          value: tables
                              .where((t) => t.isOverCapacity)
                              .length
                              .toString(),
                          color: Colors.red,
                        ),
                      ),
                    ],
                  );
                }
                // Use row layout for wider screens
                return Row(
                  children: [
                    _StatCard(
                      icon: Icons.table_restaurant,
                      label: 'Total Tables',
                      value: tables.length.toString(),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    _StatCard(
                      icon: Icons.check_circle,
                      label: 'Available',
                      value: tables
                          .where((t) => t.isAvailable)
                          .length
                          .toString(),
                      color: Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _StatCard(
                      icon: Icons.people,
                      label: 'Occupied',
                      value: tables
                          .where((t) => t.isOccupied)
                          .length
                          .toString(),
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    _StatCard(
                      icon: Icons.warning,
                      label: 'Capacity Warnings',
                      value: tables
                          .where((t) => t.needsCapacityWarning)
                          .length
                          .toString(),
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    _StatCard(
                      icon: Icons.error,
                      label: 'Over Capacity',
                      value: tables
                          .where((t) => t.isOverCapacity)
                          .length
                          .toString(),
                      color: Colors.red,
                    ),
                    const SizedBox(width: 16),
                    _StatCard(
                      icon: Icons.event_seat,
                      label: 'Total Capacity',
                      value: tables
                          .fold(0, (sum, t) => sum + t.capacity)
                          .toString(),
                      color: Colors.purple,
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Grid column sizing handled by maxCrossAxisExtent; keep childAspectRatio responsive

                return GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: AppTokens.tableCardMinWidth + 40,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: AppSpacing.m,
                    mainAxisSpacing: AppSpacing.m,
                  ),
                  itemCount: tables.length,
                  itemBuilder: (context, index) {
                    final table = tables[index];
                    return Card(
                      elevation: 2,
                      child: InkWell(
                        onTap: () => _editTable(table),
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.table_restaurant,
                                    size: 48,
                                    color: table.isAvailable
                                        ? Colors.green
                                        : table.isOccupied
                                        ? Colors.orange
                                        : Colors.grey,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    table.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.person, size: 16),
                                      const SizedBox(width: 4),
                                      Text('${table.capacity} seats'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: table.isAvailable
                                          ? Color.fromRGBO(76, 175, 80, 0.1)
                                          : table.isOccupied
                                          ? Color.fromRGBO(255, 152, 0, 0.1)
                                          : Color.fromRGBO(158, 158, 158, 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      table.status.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: table.isAvailable
                                            ? Colors.green
                                            : table.isOccupied
                                            ? Colors.orange
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 20),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _editTable(table);
                                      break;
                                    case 'duplicate':
                                      _duplicateTable(table);
                                      break;
                                    case 'delete':
                                      _deleteTable(table);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'duplicate',
                                    child: Row(
                                      children: [
                                        Icon(Icons.copy, size: 18),
                                        SizedBox(width: 8),
                                        Text('Duplicate'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Add Tables',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _addTable();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Single Table'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showBulkAddDialog();
                          },
                          icon: const Icon(Icons.library_add),
                          label: const Text('Bulk Add'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add),
        label: const Text('Add Tables'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Return a plain Card — callers should decide when to use Expanded.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
