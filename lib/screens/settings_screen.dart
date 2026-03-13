import 'package:extropos/config/settings_categories.dart';
import 'package:extropos/dialogs/settings_dialogs.dart';
import 'package:extropos/dialogs/update_dialogs.dart';
import 'package:extropos/screens/setup_screen.dart';
import 'package:extropos/services/app_settings.dart';
import 'package:extropos/services/config_service.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/lock_manager.dart';
import 'package:extropos/services/reset_service.dart';
import 'package:extropos/services/training_data_generator.dart';
import 'package:extropos/services/training_mode_service.dart';
import 'package:extropos/services/update_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

part 'settings_screen_ui.dart';

typedef UpdateServiceFactory = UpdateService Function();
typedef OpenFileFunction = Future<void> Function(String path);

class SettingsScreen extends StatefulWidget {
  final UpdateServiceFactory? updateServiceFactory;
  final OpenFileFunction? openFileFn;

  const SettingsScreen({super.key, this.updateServiceFactory, this.openFileFn});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _activeCategoryId;

  @override
  Widget build(BuildContext context) {
    return _buildSettingsScreen(context);
  }

  Future<Map<String, String>> _getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return {
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'appName': packageInfo.appName,
    };
  }

  Future<void> _handleResetPos(BuildContext context) async {
    final currentContext = context;
    final currentUser = LockManager.instance.currentUser;
    if (currentUser?.id != 'first-admin-system') {
      if (currentContext.mounted) {
        ToastHelper.showToast(
          currentContext,
          'Only the system administrator can reset the POS',
        );
      }
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: currentContext,
      builder: (context) {
        bool backup = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Reset POS State'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This will delete ALL persisted database data (categories, items, users, tables, orders, transactions) and clear in-memory POS state. This action is destructive and cannot be undone.',
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: backup,
                  onChanged: (v) => setState(() => backup = v ?? false),
                  title: const Text('Create backup before resetting'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, {
                  'confirmed': false,
                  'backup': false,
                }),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, {
                  'confirmed': true,
                  'backup': backup,
                }),
                child: const Text('Reset'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;

    final confirmed = result['confirmed'] == true;
    final doBackup = result['backup'] == true;

    if (!confirmed) return;

    if (doBackup) {
      try {
        final backupPath = await DatabaseHelper.instance.backupDatabase();
        if (currentContext.mounted) {
          ToastHelper.showToast(
            currentContext,
            'Database backed up to $backupPath',
          );
        }
      } catch (e) {
        if (currentContext.mounted) {
          ToastHelper.showToast(currentContext, 'Backup failed: $e');
        }
        return;
      }
    }

    try {
      final backupResult = await DatabaseHelper.instance.safeResetDatabase();
      if (currentContext.mounted) {
        ToastHelper.showToast(
          currentContext,
          'Database reset complete. Backup: $backupResult',
        );
      }
    } catch (e) {
      if (currentContext.mounted) {
        ToastHelper.showToast(currentContext, 'Error resetting database: $e');
      }
      return;
    }

    ResetService.instance.triggerReset();
    if (currentContext.mounted) {
      ToastHelper.showToast(
        currentContext,
        'POS database and in-memory state cleared.',
      );
    }
  }

  Future<void> _handleClearTrainingData(BuildContext context) async {
    TrainingModeService.instance.clearTrainingData();
    try {
      await TrainingDataGenerator.instance.clearTrainingData();
      ToastHelper.showToast(context, 'Training data cleared');
    } catch (e) {
      ToastHelper.showToast(context, 'Failed to clear training DB data: $e');
    }
  }

  Future<void> _handleResetSetup(BuildContext context) async {
    final currentContext = context;
    final currentUser = LockManager.instance.currentUser;
    if (currentUser?.id != 'first-admin-system') {
      if (currentContext.mounted) {
        ToastHelper.showToast(
          currentContext,
          'Only the system administrator can reset the setup',
        );
      }
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: currentContext,
      builder: (context) {
        bool resetDb = false;
        bool backup = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Reset Setup'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This will clear the initial setup flag and store name so the app will show the setup screen on next start. Optionally you can reset the database to factory defaults (this will recreate seeded data).',
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: backup,
                  onChanged: (v) => setState(() => backup = v ?? false),
                  title: const Text('Create backup before resetting'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  value: resetDb,
                  onChanged: (v) => setState(() => resetDb = v ?? false),
                  title: const Text('Also reset database to factory defaults'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, {
                  'confirmed': false,
                  'resetDb': false,
                  'backup': false,
                }),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, {
                  'confirmed': true,
                  'resetDb': resetDb,
                  'backup': backup,
                }),
                child: const Text('Reset Setup'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;
    final confirmed = result['confirmed'] == true;
    final doResetDb = result['resetDb'] == true;
    final doBackup = result['backup'] == true;
    if (!confirmed) return;

    try {
      await ConfigService.instance.setSetupDone(false);
      await ConfigService.instance.setStoreName('');
    } catch (e) {
      if (currentContext.mounted) {
        ToastHelper.showToast(currentContext, 'Error clearing setup flag: $e');
      }
      return;
    }

    if (doBackup) {
      try {
        final backupPath = await DatabaseHelper.instance.backupDatabase();
        if (currentContext.mounted) {
          ToastHelper.showToast(
            currentContext,
            'Database backed up to $backupPath',
          );
        }
      } catch (e) {
        if (currentContext.mounted) {
          ToastHelper.showToast(currentContext, 'Backup failed: $e');
        }
        return;
      }
    }

    if (doResetDb) {
      try {
        await DatabaseHelper.instance.resetDatabase();
      } catch (e) {
        if (currentContext.mounted) {
          ToastHelper.showToast(currentContext, 'Error resetting database: $e');
        }
        return;
      }
    }

    ResetService.instance.triggerReset();
    if (context.mounted) {
      ToastHelper.showToast(
        context,
        'Setup cleared — showing Setup screen now',
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (c) => const SetupScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _showTutorial(BuildContext context) async {
    await AppSettings.instance.resetTutorial();
    if (context.mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
      ToastHelper.showToast(context, 'Tutorial will show on next app start');
    }
  }
}
