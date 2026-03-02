part of 'refund_service_screen.dart';

/// Extension containing success panel UI
extension RefundServiceSuccessPanel on _RefundServiceScreenState {
  /// Build success confirmation panel
  Widget buildSuccessPanel() {
    return Center(
      key: const ValueKey('success'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 128, height: 128,
            decoration: BoxDecoration(color: AppColors.emerald100, borderRadius: BorderRadius.circular(40)),
            child: const Icon(Icons.check_circle, color: AppColors.emerald600, size: 64),
          ),
          const SizedBox(height: 32),
          Text(isWholeBill ? 'Receipt Voided' : 'Refund Successful', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.slate900)),
          const SizedBox(height: 16),
          Text('Balance of RM ${refundTotal.toStringAsFixed(2)} has been issued via $_refundMethod.', style: const TextStyle(fontSize: 20, color: AppColors.slate400, fontWeight: FontWeight.w500)),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200, height: 64,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.print, color: Colors.white),
                  label: const Text('Print Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.slate900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 200, height: 64,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentView = RefundView.lookup;
                      _selectedTransaction = null;
                      _refundItems.clear();
                      _restockMap.clear();
                      _refundReason = '';
                      _refundMethod = '';
                      _internalNotes = '';
                      _managerPin = '';
                    });
                  },
                  icon: const Icon(Icons.arrow_forward, color: AppColors.emerald600),
                  label: const Text('Next Transaction', style: TextStyle(color: AppColors.emerald600, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald100, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
