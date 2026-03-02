part of 'refund_service_screen.dart';

/// Extension containing lookup empty state UI
extension RefundServiceLookupState on _RefundServiceScreenState {
  /// Build empty state when no transaction is selected
  Widget buildLookupEmptyState() {
    return Center(
      key: const ValueKey('lookup'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40), border: Border.all(color: AppColors.slate100)),
            child: const Icon(Icons.refresh, color: AppColors.slate200, size: 48),
          ),
          const SizedBox(height: 24),
          const Text('Ready for Refund', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.slate400)),
          const SizedBox(height: 8),
          const Text('Search or select a transaction to start.', style: TextStyle(color: AppColors.slate400, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
