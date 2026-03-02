part of '../../printers_management_screen_widgets.dart';

extension PrintersManagementSmallWidgets on _PrintersManagementScreenState {
  Widget _buildRoleDot(Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildKitchenCategories(Printer printer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 1,
          color: const Color(0xFFE0E7FF).withOpacity(0.6),
          margin: const EdgeInsets.only(bottom: 16),
        ),
        const Text(
          'ASSIGNED CATEGORIES',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Color(0xFF818CF8),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        if (_availableCategories.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'No categories found. Create categories in Settings.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableCategories.map<Widget>((cat) {
              final isActive = printer.categories.contains(cat.id);
              return InkWell(
                onTap: () {
                  final nextCategories = List<String>.from(printer.categories);
                  if (isActive) {
                    nextCategories.remove(cat.id);
                  } else {
                    nextCategories.add(cat.id);
                  }
                  _updatePrinterField(categories: nextCategories);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF4F46E5) : Colors.white,
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF4F46E5)
                          : Colors.grey.shade200,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color:
                                  const Color(0xFF4F46E5).withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : Colors.grey.shade500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        if (_availableCategories.isNotEmpty && printer.categories.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Text(
              'Select at least one category to print.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF43F5E),
              ),
            ),
          )
      ],
    );
  }

}
