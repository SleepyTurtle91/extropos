/// Flavor configuration for FlutterPOS
///
/// Detects whether the app is running as POS or KDS flavor
/// and provides flavor-specific configurations.

// ignore_for_file: dangling_library_doc_comments

enum AppFlavor { pos, kds }

class FlavorConfig {
  /// Get the current app flavor from build-time environment variable
  static AppFlavor get currentFlavor {
    const flavorString = String.fromEnvironment('FLAVOR', defaultValue: 'pos');
    return flavorString.toLowerCase() == 'kds' ? AppFlavor.kds : AppFlavor.pos;
  }

  /// Check if running as POS app
  static bool get isPOS => currentFlavor == AppFlavor.pos;

  /// Check if running as KDS app
  static bool get isKDS => currentFlavor == AppFlavor.kds;

  /// Get the app name based on flavor
  static String get appName {
    switch (currentFlavor) {
      case AppFlavor.pos:
        return 'FlutterPOS';
      case AppFlavor.kds:
        return 'FlutterPOS Kitchen Display';
    }
  }

  /// Get the flavor name as string
  static String get flavorName {
    switch (currentFlavor) {
      case AppFlavor.pos:
        return 'POS';
      case AppFlavor.kds:
        return 'KDS';
    }
  }

  /// Get flavor-specific theme color
  static int get primaryColor {
    switch (currentFlavor) {
      case AppFlavor.pos:
        return 0xFF2563EB; // Blue for POS
      case AppFlavor.kds:
        return 0xFF059669; // Green for KDS
    }
  }

  /// Feature flags based on flavor
  static FlavorFeatures get features => FlavorFeatures._();
}

/// Feature flags for different flavors
class FlavorFeatures {
  FlavorFeatures._();

  // POS-specific features
  bool get enableModeSelection => FlavorConfig.isPOS;
  bool get enableRetailMode => FlavorConfig.isPOS;
  bool get enableCafeMode => FlavorConfig.isPOS;
  bool get enableRestaurantMode => FlavorConfig.isPOS;
  bool get enableTableManagement => FlavorConfig.isPOS;
  bool get enableCheckout => FlavorConfig.isPOS;
  bool get enablePrinterSettings => FlavorConfig.isPOS;
  bool get enablePaymentMethods => FlavorConfig.isPOS;
  bool get enableCustomerManagement => FlavorConfig.isPOS;
  bool get enableRefunds => FlavorConfig.isPOS;
  bool get enableReports => FlavorConfig.isPOS;
  bool get enableAnalytics => FlavorConfig.isPOS;
  bool get enableEmployeePerformance => FlavorConfig.isPOS;

  // KDS-specific features
  bool get enableKitchenDisplay => FlavorConfig.isKDS;
  bool get enableOrderQueue => FlavorConfig.isKDS;
  bool get enableOrderStatusUpdate => FlavorConfig.isKDS;
  bool get enableKitchenTimer => FlavorConfig.isKDS;
  bool get enableMultiKitchenSupport => FlavorConfig.isKDS;

  // Shared features
  bool get enableSettings => true;
  bool get enableUsers => true;
  bool get enableBusinessInfo => true;
}

/// Flavor-specific configuration values
class FlavorValues {
  static String get apiEndpoint {
    switch (FlavorConfig.currentFlavor) {
      case AppFlavor.pos:
        // POS flavor should talk to the self-hosted backend sync API
        // Hosted under your public domain and routed via Traefik/Cloudflare
        return 'https://backend.extropos.org/api/v1';
      case AppFlavor.kds:
        // KDS flavor can use the same backend API base path (or a separate path if needed)
        return 'https://backend.extropos.org/api/v1';
    }
  }

  static String get databaseName {
    switch (FlavorConfig.currentFlavor) {
      case AppFlavor.pos:
        return 'flutterpos_db.sqlite';
      case AppFlavor.kds:
        return 'flutterpos_kds_db.sqlite';
    }
  }

  static bool get enableDebugMode {
    const isProduction = bool.fromEnvironment('dart.vm.product');
    return !isProduction;
  }
}
