part of 'table_management_screen.dart';

/// UI extension for TableManagementScreen
extension TableManagementScreenUI on _TableManagementScreenState {
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
}
