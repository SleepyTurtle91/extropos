import 'dart:developer' as developer;

import 'package:extropos/config/app_flavor.dart';
import 'package:extropos/features/auth/services/business_session_service.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/screens/start_screen.dart';
import 'package:extropos/services/backup_service.dart';
import 'package:extropos/services/dual_display_service.dart';
import 'package:extropos/services/license_service.dart';
import 'package:extropos/services/pin_store.dart';
import 'package:extropos/services/secure_storage_service.dart';
import 'package:extropos/services/tenant_service.dart';
import 'package:extropos/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:universal_io/io.dart' show Platform;

/// Frontend (Customer) app - Android-focused entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set app flavor to Frontend
  AppFlavor.setFlavor(AppFlavorType.frontend);

  // Initialize services required on Android
  developer.log('🔧 Frontend: Initializing services');

  await LicenseService.instance.init();
  await LicenseService.instance.initializeIfNeeded();

  // Initialize tenant service if tenant mode is activated
  if (LicenseService.instance.isTenantActivated) {
    try {
      await TenantService.instance.initialize();
      developer.log('🔧 Frontend: Tenant service initialized');
    } catch (e) {
      developer.log('⚠️ Frontend: Failed to initialize tenant service: $e');
    }
  }

  // TEMP: Disable encryption on Android devices when necessary (keeps parity with main)
  bool useEncryption = !Platform.isAndroid;
  debugPrint('🔧 Platform: ${Platform.operatingSystem}, useEncryption: $useEncryption');

  // Secure storage, Hive and PinStore initialization
  await SecureStorageService.instance.init();
  await Hive.initFlutter();
  await PinStore.instance.init(useEncryption: useEncryption);
  debugPrint('🔧 Frontend: PinStore initialized with encryption: $useEncryption');

  // Migrate PINs if present
  await PinStore.instance.migrateFromDatabase();

  // Initialize optional services used by frontend
  await DualDisplayService().initialize();
  await BusinessInfo.initialize();
  await ThemeService().initialize();
  await BackupService.instance.initialize();
  await BusinessSessionService().initialize();

  // Show welcome on dual display if supported
  await DualDisplayService().showWelcome();

  developer.log('🔧 Frontend: Initialization complete, running app');

  runApp(const FrontendApp());
}

class FrontendApp extends StatelessWidget {
  const FrontendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterPOS Customer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // Customer-friendly theme with larger touch targets
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        cardTheme: const CardThemeData(elevation: 4, margin: EdgeInsets.all(8)),
      ),
      home: const StartScreen(),
    );
  }
}
