part of 'tables_management_screen.dart';

extension TablesManagementContent on _TablesManagementScreenState {
  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: LayoutBuilder(
        builder: (context, constraints) {
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
                    value: tables.where((t) => t.isAvailable).length.toString(),
                    color: Colors.green,
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - 12) / 2,
                  child: _StatCard(
                    icon: Icons.people,
                    label: 'Occupied',
                    value: tables.where((t) => t.isOccupied).length.toString(),
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
                    value: tables.where((t) => t.isOverCapacity).length.toString(),
                    color: Colors.red,
                  ),
                ),
              ],
            );
          }

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
                value: tables.where((t) => t.isAvailable).length.toString(),
                color: Colors.green,
              ),
              const SizedBox(width: 16),
              _StatCard(
                icon: Icons.people,
                label: 'Occupied',
                value: tables.where((t) => t.isOccupied).length.toString(),
                color: Colors.orange,
              ),
              const SizedBox(width: 16),
              _StatCard(
                icon: Icons.warning,
                label: 'Capacity Warnings',
                value:
                    tables.where((t) => t.needsCapacityWarning).length.toString(),
                color: Colors.orange,
              ),
              const SizedBox(width: 16),
              _StatCard(
                icon: Icons.error,
                label: 'Over Capacity',
                value: tables.where((t) => t.isOverCapacity).length.toString(),
                color: Colors.red,
              ),
              const SizedBox(width: 16),
              _StatCard(
                icon: Icons.event_seat,
                label: 'Total Capacity',
                value: tables.fold(0, (sum, t) => sum + t.capacity).toString(),
                color: Colors.purple,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTablesGrid() {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Adaptive columns based on screen width
          int columns;
          if (constraints.maxWidth < 600) {
            columns = 1;
          } else if (constraints.maxWidth < 900) {
            columns = 2;
          } else if (constraints.maxWidth < 1200) {
            columns = 3;
          } else {
            columns = 4;
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.m),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
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
    );
  }
}
