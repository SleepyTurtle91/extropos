import 'package:extropos/design_system/horizon_theme.dart';
import 'package:extropos/screens/horizon_inventory_grid_screen.dart';
import 'package:extropos/screens/horizon_pulse_dashboard_screen.dart';
import 'package:extropos/screens/horizon_reports_screen.dart';
import 'package:extropos/services/appwrite_service.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BackendWebApp());
}

/// Web-specific Backend App with Horizon Admin Design System
class BackendWebApp extends StatelessWidget {
  const BackendWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Horizon Admin - ExtroPOS Backend',
      debugShowCheckedModeBanner: false,
      theme: HorizonTheme.lightTheme(),
      home: const WebBackendHomeScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/dashboard':
          case '/pulse':
            return MaterialPageRoute(
              builder: (_) => const HorizonPulseDashboardScreen(),
            );
          case '/inventory':
            return MaterialPageRoute(
              builder: (_) => const HorizonInventoryGridScreen(),
            );
          case '/reports':
            return MaterialPageRoute(
              builder: (_) => const HorizonReportsScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const WebBackendHomeScreen(),
            );
        }
      },
    );
  }
}

/// Web-compatible Backend Home Screen
class WebBackendHomeScreen extends StatefulWidget {
  const WebBackendHomeScreen({super.key});

  @override
  State<WebBackendHomeScreen> createState() => _WebBackendHomeScreenState();
}

class _WebBackendHomeScreenState extends State<WebBackendHomeScreen> {
  bool _isAppwriteConfigured = false;
  bool _isCheckingConfig = true;

  @override
  void initState() {
    super.initState();
    _checkAppwriteConfiguration();
  }

  Future<void> _checkAppwriteConfiguration() async {
    try {
      final appwriteService = AppwriteService.instance;
      await appwriteService.initialize();
      _isAppwriteConfigured = appwriteService.isInitialized;
    } catch (e) {
      _isAppwriteConfigured = false;
    } finally {
      setState(() {
        _isCheckingConfig = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingConfig) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAppwriteConfigured) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          title: const Text('ExtroPOS - Backend'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storage, size: 80, color: Color(0xFF2563EB)),
              const SizedBox(height: 24),
              const Text(
                'Backend Database Required',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'To use the backend management features, you need to configure the Appwrite database first.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _showAppwriteSetupDialog(context),
                icon: const Icon(Icons.settings),
                label: const Text('Configure Appwrite'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If Appwrite is configured, show the Horizon Admin Pulse Dashboard
    return const HorizonPulseDashboardScreen();
  }

  void _showAppwriteSetupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appwrite Configuration'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please configure your Appwrite instance in the backend settings.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'You can access the Appwrite settings from the backend management app on your device.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
