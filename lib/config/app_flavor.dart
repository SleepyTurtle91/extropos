// App Flavor Configuration
// Used to determine which flavor (POS, Backend, KDS, Dealer, Frontend) is currently running

class AppFlavor {
  static AppFlavorType _currentFlavor = AppFlavorType.pos;

  static void setFlavor(AppFlavorType flavor) {
    _currentFlavor = flavor;
  }

  static AppFlavorType get current => _currentFlavor;

  static bool get isPOS => _currentFlavor == AppFlavorType.pos;
  static bool get isBackend => _currentFlavor == AppFlavorType.backend;
  static bool get isKDS => _currentFlavor == AppFlavorType.kds;
  static bool get isDealer => _currentFlavor == AppFlavorType.dealer;
  static bool get isFrontend => _currentFlavor == AppFlavorType.frontend;

  static String get homeRoute {
    switch (_currentFlavor) {
      case AppFlavorType.pos:
        return '/pos';
      case AppFlavorType.backend:
        return '/backend';
      case AppFlavorType.kds:
        return '/kds';
      case AppFlavorType.dealer:
        return '/dealer';
      case AppFlavorType.frontend:
        return '/frontend';
    }
  }
}

enum AppFlavorType { pos, backend, kds, dealer, frontend }
