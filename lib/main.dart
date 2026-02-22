import 'dart:developer' as developer;

import 'package:extropos/migrations/pos_products_migration.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/repositories/product_repository.dart';
import 'package:extropos/screens/activation_screen.dart';
import 'package:extropos/screens/einvoice_config_screen.dart';
import 'package:extropos/screens/einvoice_submission_screen.dart';
import 'package:extropos/screens/lock_screen.dart';
import 'package:extropos/screens/maintenance_screen.dart';
import 'package:extropos/screens/my_invois_queue_screen.dart';
import 'package:extropos/screens/my_invois_settings_screen.dart';
import 'package:extropos/screens/setup_screen.dart';
import 'package:extropos/screens/unified_pos_screen.dart';
import 'package:extropos/screens/vice_customer_display_screen.dart';
import 'package:extropos/seeders/pos_product_seeder.dart';
import 'package:extropos/services/appwrite_phase1_service.dart';
import 'package:extropos/services/appwrite_service.dart';
// services/printer_service_clean.dart already imported above
import 'package:extropos/services/backup_service.dart';
import 'package:extropos/services/business_session_service.dart';
import 'package:extropos/services/config_service.dart';
import 'package:extropos/services/dual_display_service.dart';
import 'package:extropos/services/einvoice_service.dart';
import 'package:extropos/services/guide_service.dart';
import 'package:extropos/services/iap_service.dart';
import 'package:extropos/services/image_optimization_service.dart';
import 'package:extropos/services/lazy_loading_service.dart';
import 'package:extropos/services/license_service.dart';
import 'package:extropos/services/memory_manager.dart';
import 'package:extropos/services/performance_monitor.dart';
import 'package:extropos/services/pin_store.dart';
import 'package:extropos/services/pos_seed_service.dart';
import 'package:extropos/services/printer_service_clean.dart';
import 'package:extropos/services/secure_storage_service.dart';
import 'package:extropos/services/tenant_service.dart';
import 'package:extropos/services/theme_service.dart';
import 'package:extropos/services/training_mode_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
// Google services removed - Nextcloud is used for cloud storage
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:universal_io/io.dart' show Platform;
import 'package:window_manager/window_manager.dart';

/// Seed POS products for all modes
Future<String> _seedPOSProducts(ProductRepository repository) async {
  // Check if products already exist
  final existingProducts = await repository.getProducts();
  if (existingProducts.isNotEmpty) {
    return 'Already seeded (${existingProducts.length} products)';
  }
  
  // Seed all modes
  final seeder = POSProductSeeder(repository);
  await seeder.seedAll();
  
  final retailCount = (await repository.getProducts(mode: 'retail')).length;
  final cafeCount = (await repository.getProducts(mode: 'cafe')).length;
  final restaurantCount = (await repository.getProducts(mode: 'restaurant')).length;
  
  return 'Retail: $retailCount, Cafe: $cafeCount, Restaurant: $restaurantCount';
}

/// Entry point for the vice (back) customer display screen
/// This is called by the iMin SDK when launching the app on the secondary screen
@pragma('vm:entry-point')
void viceMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ViceDisplayApp());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize SQLite FFI for Web
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  // Initialize SQLite FFI for desktop platforms (Windows/Linux)
  else if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await GuideService.instance.init();
  await ConfigService.instance.init();
  // POS offline mode toggle (set via --dart-define=POS_OFFLINE=true for POS flavor builds)
  final bool posOffline = const bool.fromEnvironment('POS_OFFLINE', defaultValue: false);
  if (posOffline) {
    AppwritePhase1Service.setEnabled(false);
    AppwriteService.setEnabled(false);
    developer.log('🔧 Main: POS_OFFLINE=true -> Appwrite disabled for offline POS flavor');
    // Seed local DB with starter products for offline POS
    try {
      await PosSeedService.seedIfNeeded();
      developer.log('🔧 Main: POS seed applied (if DB was empty)');
    } catch (e) {
      developer.log('⚠️ Main: POS seeding failed: $e');
    }
    
    // Initialize POS Products database table and seed sample data
    try {
      final tableExists = await POSProductsMigration.isTableExists();
      if (!tableExists) {
        developer.log('🔧 Main: Creating pos_products table...');
        await POSProductsMigration.migrate();
        
        // Seed sample products for all modes
        developer.log('🔧 Main: Seeding POS products...');
        final repository = DatabaseProductRepository();
        final seedData = await _seedPOSProducts(repository);
        developer.log('✅ Main: POS products seeded - $seedData');
      } else {
        developer.log('✅ Main: pos_products table already exists');
      }
    } catch (e) {
      developer.log('⚠️ Main: POS products setup failed: $e');
    }
  } else {
    // Default to offline-only for now per release focus
    AppwritePhase1Service.setEnabled(false);
    AppwriteService.setEnabled(false);
    developer.log('🔧 Main: Appwrite disabled for offline-only POS focus');
  }
  await LicenseService.instance.init();
  await LicenseService.instance.initializeIfNeeded();
  // Initialize IAP service (Google Play Billing)
  await IAPService.instance.initialize();

  // Initialize tenant service if tenant mode is activated
  if (LicenseService.instance.isTenantActivated) {
    try {
      await TenantService.instance.initialize();
      developer.log('🔧 Main: Tenant service initialized');
    } catch (e) {
      developer.log('⚠️ Main: Failed to initialize tenant service: $e');
    }
  }

  // TEMPORARY FIX: Disable encryption on ALL Android devices
  // This bypasses the iMin detection issue entirely
  bool useEncryption = !Platform.isAndroid;
  debugPrint(
    '🔧 Platform: ${Platform.operatingSystem}, useEncryption: $useEncryption',
  );

  // Initialize secure storage and Hive for encrypted PIN storage
  // On Android devices, disable encryption due to compatibility issues
  await SecureStorageService.instance.init();
  await Hive.initFlutter();
  await PinStore.instance.init(useEncryption: useEncryption);
  debugPrint('🔧 PinStore initialized with encryption: $useEncryption');

  // Perform a one-time migration of user PINs from the DB to the encrypted PinStore
  await PinStore.instance.migrateFromDatabase();

  // Initialize DualDisplayService in the background to prevent ANR
  // Do NOT await this as it involves hardware initialization which can block the main thread
  developer.log(
    '🔧 Main: Starting DualDisplayService initialization (background)',
  );
  DualDisplayService()
      .initialize()
      .then((_) {
        developer.log('🔧 Main: DualDisplayService initialized successfully');
        // Show welcome message after successful initialization
        DualDisplayService().showWelcome();
      })
      .catchError((e) {
        developer.log('⚠️ Main: DualDisplayService initialization failed: $e');
      });

  developer.log('🔧 Main: About to initialize BusinessInfo');
  await BusinessInfo.initialize();
  developer.log('🔧 Main: BusinessInfo initialized');
  // Initialize theme service
  developer.log('🔧 Main: About to initialize ThemeService');
  await ThemeService().initialize();
  developer.log('🔧 Main: ThemeService initialized');
  // Initialize backup service
  developer.log('🔧 Main: About to initialize BackupService');
  await BackupService.instance.initialize();
  developer.log('🔧 Main: BackupService initialized');
  // Initialize business session service
  developer.log('🔧 Main: About to initialize BusinessSessionService');
  await BusinessSessionService().initialize();
  developer.log('🔧 Main: BusinessSessionService initialized');
  // Initialize e-Invoice service
  developer.log('🔧 Main: About to initialize EInvoiceService');
  await EInvoiceService.instance.init();
  developer.log('🔧 Main: EInvoiceService initialized');
  // Initialize performance services
  developer.log('🔧 Main: About to initialize PerformanceMonitor');
  await PerformanceMonitor.instance.initialize();
  developer.log('🔧 Main: PerformanceMonitor initialized');
  developer.log('🔧 Main: About to initialize LazyLoadingService');
  await LazyLoadingService.instance.initialize();
  developer.log('🔧 Main: LazyLoadingService initialized');
  developer.log('🔧 Main: About to initialize ImageOptimizationService');
  await ImageOptimizationService.instance.initialize();
  developer.log('🔧 Main: ImageOptimizationService initialized');
  developer.log('🔧 Main: About to initialize MemoryManager');
  await MemoryManager.instance.initialize();
  developer.log('🔧 Main: MemoryManager initialized');
  // Initialize dual display service for customer-facing displays
  developer.log('🔧 Main: About to initialize DualDisplayService');
  await DualDisplayService().initialize();
  developer.log('🔧 Main: DualDisplayService initialized');
  // Initialize window manager for desktop platforms
  developer.log('🔧 Main: Completed all service initializations');
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      fullScreen: true,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setFullScreen(true);
    });
  }

  developer.log('🔧 Main: About to runApp');
  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  runApp(
    ChangeNotifierProvider<TrainingModeService>.value(
      value: TrainingModeService.instance,
      child: ExtroPOSApp(scaffoldMessengerKey: scaffoldMessengerKey),
    ),
  );
  // Attempt to initialize platform printer service on Windows after first frame
  if (Platform.isWindows) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        developer.log('Main after frame: Calling PrinterService.initialize');
        await PrinterService().initialize();
        developer.log('Main after frame: PrinterService.initialize returned');
        developer.log('Main after frame: PrinterService.initialize succeeded');
        // For diagnostics: attempt to discover printers and print a brief summary
        try {
          final printers = await PrinterService().discoverPrinters();
          developer.log(
            'Main after frame: discoverPrinters -> found ${printers.length} printers',
          );
          for (final p in printers) {
            developer.log(
              'Main after frame: printer ${p.name} ${p.id} ${p.modelName}',
            );
          }
        } catch (pe) {
          developer.log('Main after frame: discoverPrinters failed: $pe');
          developer.log('Main after frame: discoverPrinters failed: $pe');
        }
      } catch (e) {
        developer.log('Main after frame: PrinterService.initialize threw: $e');
        developer.log('Main after frame: PrinterService.initialize threw: $e');
      }
    });
  }
  // Subscribe to printer logs and show snackbars on critical messages for all platforms
  try {
    PrinterService().printerLogStream.listen((msg) {
      final lower = msg.toLowerCase();
      if (lower.contains('error') ||
          lower.contains('failed') ||
          lower.contains('timeout')) {
        // Display a short snackbar centrally
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Printer: $msg'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    });
  } catch (_) {}
}

/// Dedicated app for the vice (customer) display
class ViceDisplayApp extends StatelessWidget {
  const ViceDisplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExtroPOS Customer Display',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ViceCustomerDisplayScreen(),
    );
  }
}

class ExtroPOSApp extends StatelessWidget {
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
  const ExtroPOSApp({super.key, this.scaffoldMessengerKey});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService(),
      builder: (context, child) {
        return MaterialApp(
          scaffoldMessengerKey: scaffoldMessengerKey,
          title: 'ExtroPOS',
          debugShowCheckedModeBanner: false,
          theme: ThemeService().themeData,
          // Use ConfigService to decide whether first-run setup is required.
          routes: {
            '/setup': (_) => const SetupScreen(),
            '/maintenance': (_) => const MaintenanceScreen(),
            '/lock': (_) => const LockScreen(),
            '/activation': (_) => const ActivationScreen(),
            '/pos': (_) => const UnifiedPOSScreen(),
            '/vice': (_) =>
                const ViceCustomerDisplayScreen(), // Vice display route
            '/einvoice-config': (_) => const EInvoiceConfigScreen(),
            '/einvoice-submission': (_) => const EInvoiceSubmissionScreen(),
            '/myinvois-settings': (_) => const MyInvoisSettingsScreen(),
            '/myinvois-queue': (_) => const MyInvoisQueueScreen(),
          },
          onGenerateRoute: (settings) {
            // Handle vice screen launch (if SDK passes special route)
            if (settings.name == '/vice' ||
                settings.name == 'viceMain' ||
                settings.name == '/presentation') {
              return MaterialPageRoute(
                builder: (_) => const ViceCustomerDisplayScreen(),
              );
            }
            return null; // Let default routing handle other cases
          },
          home: Builder(
            builder: (context) {
              // ConfigService is initialized in main(); read the flag directly.
              final showSetup = !ConfigService.instance.isSetupDone;
              if (showSetup) {
                return const SetupScreen();
              }

              // Check license state: if expired and not activated, show activation screen
              if (LicenseService.instance.isExpired) {
                return const ActivationScreen();
              }

              // If setup is complete and license is valid or in trial, require unlocking first.
              return const LockScreen();
            },
          ),
        );
      },
    );
  }
}
