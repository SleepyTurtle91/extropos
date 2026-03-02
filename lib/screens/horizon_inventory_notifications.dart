part of 'horizon_inventory_grid_screen.dart';

/// Extension containing notification toasts
extension HorizonInventoryNotifications on _HorizonInventoryGridScreenState {
  /// Show success toast notification
  void showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: HorizonColors.emerald,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error toast notification
  void showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: HorizonColors.rose,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
