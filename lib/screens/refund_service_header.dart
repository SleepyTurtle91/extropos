part of 'refund_service_screen.dart';

/// Extension containing header UI for refund service screen
extension RefundServiceHeader on _RefundServiceScreenState {
  /// Build header section
  Widget buildHeader() {
    return Container(
      height: 80,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.rose50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.refresh, color: AppColors.rose600),
              ),
              const SizedBox(width: 16),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Refund & Void Service', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.slate900)),
                  Text('ORDER CORRECTION PROTOCOL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate400)),
                ],
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.slate400, size: 18),
            label: const Text('Exit to POS', style: TextStyle(color: AppColors.slate400, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
