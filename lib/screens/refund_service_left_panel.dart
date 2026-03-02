part of 'refund_service_screen.dart';

/// Extension containing left panel UI (search and transaction list)
extension RefundServiceLeftPanel on _RefundServiceScreenState {
  /// Build left panel with search and recent transactions
  Widget buildLeftPanel() {
    return Container(
      width: 400,
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TRANSACTION LOOKUP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slate400)),
          const SizedBox(height: 16),
          TextField(
            onChanged: (val) => _searchQuery = val,
            decoration: InputDecoration(
              hintText: 'Scan receipt or enter ID (FP-...)',
              prefixIcon: const Icon(Icons.search, color: AppColors.slate400),
              filled: true,
              fillColor: AppColors.slate50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.rose500)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: handleSearch,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.slate900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Search', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RECENT TRANSACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slate400)),
              Text('View All', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.indigo600)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingTransactions
                ? const Center(child: CircularProgressIndicator())
                : _recentTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, color: AppColors.slate200, size: 40),
                            const SizedBox(height: 12),
                            const Text('No transactions loaded', style: TextStyle(fontSize: 14, color: AppColors.slate400, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            const Text('Search by receipt ID to begin', style: TextStyle(fontSize: 12, color: AppColors.slate400)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _recentTransactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final tx = _recentTransactions[index];
                          return InkWell(
                            onTap: () => handleTransactionSelect(tx),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(tx['order_number']?.toString() ?? tx['id']?.toString() ?? 'N/A', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.slate900)),
                                      Text("${DateFormat('HH:mm').format(DateTime.parse(tx['created_at'] as String? ?? DateTime.now().toIso8601String()))} • ${tx['created_by'] as String? ?? 'POS'}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate400)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text("RM ${((tx['total'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.slate900)),
                                      Text(tx['payment_method'] as String? ?? 'Unknown', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate400)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.amber50, border: Border.all(color: AppColors.amber100), borderRadius: BorderRadius.circular(16)),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.amber600, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text('Refund Policy: Items returned after 24 hours require regional manager approval.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.amber800))),
              ],
            ),
          )
        ],
      ),
    );
  }
}
