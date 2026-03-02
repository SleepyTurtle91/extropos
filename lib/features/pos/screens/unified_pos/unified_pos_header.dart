part of 'unified_pos_screen.dart';

extension UnifiedPOSHeader on _UnifiedPOSScreenState {
  Widget _buildHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _updateState(() => isSidebarCollapsed = !isSidebarCollapsed),
            icon: const Icon(Icons.menu),
          ),
          const SizedBox(width: 16),
          if (activeMode == POSMode.restaurant && selectedTableId != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.shade50, border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.table_restaurant, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(selectedTableId ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _updateState(() => selectedTableId = null),
                      child: Icon(Icons.close, color: Colors.green.shade400, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: TextField(
                  onChanged: (v) => _updateState(() => searchQuery = v),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey, size: 20),
                    hintText: 'Search products...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          CircleAvatar(backgroundColor: Colors.grey.shade200, child: const Icon(Icons.person, color: Colors.grey)),
        ],
      ),
    );
  }
}
