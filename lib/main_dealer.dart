import 'dart:developer' as developer;

import 'package:extropos/config/app_flavor.dart';
import 'package:extropos/screens/dealer_home_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:universal_io/io.dart' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set app flavor to Dealer
  AppFlavor.setFlavor(AppFlavorType.dealer);

  // Initialize SQLite FFI for Web
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
    developer.log('🌐 Dealer Portal: Initialized SQLite FFI for Web');
  }
  // Initialize SQLite FFI for desktop platforms (Windows/Linux)
  else if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    developer.log('🖥️ Dealer Portal: Initialized SQLite FFI for desktop');
  }

  // DEALER PORTAL FLAVOR: WEB ONLY
  // Disable Android and Windows - Dealer Portal only runs on web
  if (!kIsWeb &&
      !Platform.isWindows &&
      !Platform.isLinux &&
      !Platform.isMacOS) {
    developer.log(
      '🚫 Dealer Portal Flavor: Disabled for native mobile platforms',
    );
    developer.log(
      '🌐 Dealer Portal Flavor: Only available on web/desktop platform',
    );
    developer.log('💡 To run Dealer Portal: Use web build or browser');

    // Exit the app for non-web platforms
    // This prevents the dealer portal from running on Android/Windows
    return;
  }

  // WEB ONLY: Initialize and run web dealer portal
  developer.log('🌐 Dealer Portal Web: Initializing web-only dealer portal');

  runApp(const DealerWebApp());
}

// ==========================================
// WEB-ONLY DEALER PORTAL APP
// ==========================================
class DealerWebApp extends StatelessWidget {
  const DealerWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExtroPOS Dealer Portal (Web)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2563EB),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const DealerHomeScreen(),
    );
  }
}
