import 'dart:developer' as developer;

import 'package:extropos/config/app_flavor.dart';
import 'package:extropos/screens/tenant_login_screen.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:universal_io/io.dart' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set app flavor to Backend
  AppFlavor.setFlavor(AppFlavorType.backend);

  // Initialize SQLite FFI for Web
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
    developer.log('🌐 Backend Portal: Initialized SQLite FFI for Web');
  }
  // Initialize SQLite FFI for desktop platforms (Windows/Linux)
  else if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    developer.log('🖥️ Backend Portal: Initialized SQLite FFI for desktop');
  }

  // BACKEND FLAVOR: WEB ONLY
  // Disable Android and Windows - Backend only runs on web
  if (!kIsWeb &&
      !Platform.isWindows &&
      !Platform.isLinux &&
      !Platform.isMacOS) {
    developer.log('🚫 Backend Flavor: Disabled for native mobile platforms');
    developer.log('🌐 Backend Flavor: Only available on web/desktop platform');
    developer.log('💡 To run Backend: Use web build or browser');

    // Exit the app for non-web platforms
    // This prevents the backend from running on Android/Windows
    return;
  }

  // WEB ONLY: Initialize database and run web backend
  developer.log('🌐 Backend Web: Initializing web-only backend');

  // Initialize database for tenant management
  try {
    await DatabaseHelper.instance.database;
    developer.log('✅ Database initialized successfully');
  } catch (e) {
    developer.log('⚠️ Database initialization error: $e');
  }

  runApp(const BackendWebApp());
}

// ==========================================
// WEB-ONLY TENANT BACKEND APP
// ==========================================
class BackendWebApp extends StatelessWidget {
  const BackendWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExtroPOS Tenant Backend',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2563EB),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const TenantLoginScreen(),
    );
  }
}
