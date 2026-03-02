part of 'unified_pos_screen.dart';

extension UnifiedPOSTables on _UnifiedPOSScreenState {
  void _showTableSelectionDialog() {
    final mockTables = [
      {'id': 'table-1', 'name': 'Table 1', 'capacity': 4, 'occupied': false},
      {'id': 'table-2', 'name': 'Table 2', 'capacity': 4, 'occupied': true},
      {'id': 'table-3', 'name': 'Table 3', 'capacity': 6, 'occupied': false},
      {'id': 'table-4', 'name': 'Table 4', 'capacity': 2, 'occupied': false},
      {'id': 'table-5', 'name': 'VIP Table', 'capacity': 8, 'occupied': false},
      {'id': 'table-6', 'name': 'Corner Booth', 'capacity': 6, 'occupied': true},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Table'),
        content: SizedBox(
          width: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: mockTables.length,
            itemBuilder: (context, index) {
              final table = mockTables[index];
              final occupied = table['occupied'] as bool? ?? false;
              final tableName = table['name'] as String? ?? 'Table';
              final tableId = table['id'] as String? ?? '';
              final capacity = table['capacity'] as int? ?? 0;
              return InkWell(
                onTap: occupied
                    ? null
                    : () {
                        Navigator.pop(context);
                        _updateState(() => selectedTableId = tableId);
                        _updateState(() => cart.clear());
                      },
                child: Container(
                  decoration: BoxDecoration(
                    color: occupied ? Colors.grey.shade300 : Colors.green.shade50,
                    border: Border.all(
                      color: occupied ? Colors.grey : Colors.green,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.table_restaurant,
                        color: occupied ? Colors.grey : Colors.green,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tableName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: occupied ? Colors.grey : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '$capacity seats',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      if (occupied)
                        const Text(
                          'OCCUPIED',
                          style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSelectionView() {
    final mockTables = [
      {'id': 'table-1', 'name': 'Table 1', 'capacity': 4, 'occupied': false},
      {'id': 'table-2', 'name': 'Table 2', 'capacity': 4, 'occupied': true},
      {'id': 'table-3', 'name': 'Table 3', 'capacity': 6, 'occupied': false},
      {'id': 'table-4', 'name': 'Table 4', 'capacity': 2, 'occupied': false},
      {'id': 'table-5', 'name': 'VIP Table', 'capacity': 8, 'occupied': false},
      {'id': 'table-6', 'name': 'Corner Booth', 'capacity': 6, 'occupied': true},
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select a Table', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: mockTables.length,
              itemBuilder: (context, index) {
                final table = mockTables[index];
                final occupied = table['occupied'] as bool? ?? false;
                final tableName = table['name'] as String? ?? 'Table';
                final tableId = table['id'] as String? ?? '';
                final capacity = table['capacity'] as int? ?? 0;
                return InkWell(
                  onTap: occupied
                      ? null
                      : () {
                          _updateState(() => selectedTableId = tableId);
                          _updateState(() => cart.clear());
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: occupied ? Colors.grey.shade300 : Colors.green.shade50,
                      border: Border.all(
                        color: occupied ? Colors.grey : Colors.green,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.table_restaurant,
                          color: occupied ? Colors.grey : Colors.green,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tableName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: occupied ? Colors.grey : Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Capacity: $capacity seats',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (occupied)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              'OCCUPIED',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
