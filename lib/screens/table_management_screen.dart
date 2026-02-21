import 'package:extropos/models/table_model.dart';
import 'package:extropos/services/table_management_service.dart';
import 'package:flutter/material.dart';

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  late TableManagementService _tableService;
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tableService = TableManagementService();
    _tableService.addListener(_onServiceChanged);
    _initializeTables();
  }

  Future<void> _initializeTables() async {
    await _tableService.loadTablesFromDatabase();
    setState(() {});
  }

  void _onServiceChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _tableService.removeListener(_onServiceChanged);
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _showAddTableDialog() {
    _nameController.clear();
    _capacityController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Table'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Table Name (e.g., Table 1)',
                  hintText: 'Enter table name',
                  prefixIcon: Icon(Icons.table_restaurant),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Seating Capacity',
                  hintText: 'e.g., 4',
                  prefixIcon: Icon(Icons.people),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              final capacityStr = _capacityController.text.trim();

              if (name.isEmpty || capacityStr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final capacity = int.tryParse(capacityStr) ?? 0;
              if (capacity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Capacity must be greater than 0')),
                );
                return;
              }

              // Generate ID based on existing tables
              final id = 'T${_tableService.tables.length + 1}';

              final success =
                  await _tableService.createTable(id: id, name: name, capacity: capacity);

              if (!mounted) return;

              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ Table "$name" added successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Failed to add table')),
                );
              }
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  void _showEditTableDialog(RestaurantTable table) {
    _nameController.text = table.name;
    _capacityController.text = table.capacity.toString();

    final customerNameController = TextEditingController(text: table.customerName);
    final customerPhoneController =
        TextEditingController(text: table.customerPhone);
    final notesController = TextEditingController(text: table.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Table'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Table Name',
                  prefixIcon: Icon(Icons.table_restaurant),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  prefixIcon: Icon(Icons.people),
                ),
              ),
              const SizedBox(height: 12),
              if (table.isOccupied) ...[
                TextField(
                  controller: customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: customerPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Customer Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Allergies, Preferences, etc.)',
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Customer details can only be edited when the table is occupied.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              final capacityStr = _capacityController.text.trim();
              final capacity = int.tryParse(capacityStr) ?? 0;

              if (name.isEmpty || capacity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid table details')),
                );
                return;
              }

              final success = await _tableService.updateTable(
                id: table.id,
                customerName: customerNameController.text.trim(),
                customerPhone: customerPhoneController.text.trim(),
                notes: notesController.text.trim(),
              );

              if (!mounted) return;

              Navigator.pop(context);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Table updated')),
                );
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(RestaurantTable table) {
    if (table.isOccupied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Cannot delete occupied table')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Table'),
        content: Text('Delete "${table.name}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await _tableService.deleteTable(table.id);

              if (!mounted) return;
              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ "${table.name}" deleted')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Failed to delete table')),
                );
              }
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _tableService.getTableStatistics();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Table Management'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Stats Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStatCard(
                    'Total Tables',
                    '${stats['total'] ?? 0}',
                    Colors.blue,
                    Icons.table_restaurant,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Available',
                    '${stats['available'] ?? 0}',
                    Colors.green,
                    Icons.check_circle,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Occupied',
                    '${stats['occupied'] ?? 0}',
                    Colors.orange,
                    Icons.people,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Cleaning',
                    '${stats['cleaning'] ?? 0}',
                    Colors.purple,
                    Icons.cleaning_services,
                  ),
                ],
              ),
            ),
            // Tables Grid
            Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 4;
                  if (constraints.maxWidth < 600) {
                    crossAxisCount = 1;
                  } else if (constraints.maxWidth < 900) {
                    crossAxisCount = 2;
                  } else if (constraints.maxWidth < 1200) {
                    crossAxisCount = 3;
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _tableService.tables.length,
                    itemBuilder: (context, index) {
                      final table = _tableService.tables[index];
                      return _buildTableCard(table);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTableDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Table'),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCard(RestaurantTable table) {
    final color = _getStatusColor(table.status);
    final statusText = table.status.toString().split('.').last.toUpperCase();

    return GestureDetector(
      onTap: () => _showEditTableDialog(table),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          table.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '👥 Capacity: ${table.capacity}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (table.isOccupied) ...[
                if (table.customerName != null)
                  Text(
                    '👤 ${table.customerName}',
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                if (table.occupiedDurationMinutes > 0)
                  Text(
                    '⏱️ ${table.occupiedDurationMinutes} min',
                    style: TextStyle(fontSize: 11, color: Colors.orange),
                  ),
              ] else if (table.isReserved && table.customerName != null)
                Text(
                  '🔖 Reserved: ${table.customerName}',
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                )
              else
                const Text(
                  '✓ Available',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: 'Edit',
                    child: IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      onPressed: () => _showEditTableDialog(table),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Delete',
                    child: IconButton(
                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(table),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return Colors.green;
      case TableStatus.occupied:
        return Colors.orange;
      case TableStatus.reserved:
        return Colors.blue;
      case TableStatus.merged:
        return Colors.purple;
      case TableStatus.cleaning:
        return Colors.brown;
    }
  }
}
