import 'package:extropos/services/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';

/// Unified backup service that handles local backups only
/// Cloud backup functionality removed - using Appwrite for data sync instead
class BackupService {
  static final BackupService instance = BackupService._init();
  BackupService._init();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Initialize backup services
  Future<void> initialize() async {
    // Local backup only - no cloud initialization needed
  }

  /// Create a local backup
  Future<String?> createLocalBackup() async {
    try {
      return await _dbHelper.backupDatabase();
    } catch (e) {
      debugPrint('Local backup failed: $e');
      return null;
    }
  }

  /// Create backups on all available platforms (local only)
  Future<Map<String, String?>> createAllBackups({String? customName}) async {
    final results = <String, String?>{};

    // Always try local backup
    results['local'] = await createLocalBackup();

    return results;
  }

  /// Get list of local backup files
  Future<List<String>> getLocalBackupFiles() async {
    return await _dbHelper.getBackupFiles();
  }

  /// Restore from local backup
  Future<bool> restoreFromLocalBackup(String backupPath) async {
    try {
      await _dbHelper.restoreFromBackup(backupPath);
      return true;
    } catch (e) {
      debugPrint('Local restore failed: $e');
      return false;
    }
  }

  /// Delete local backup file
  Future<bool> deleteLocalBackup(String backupPath) async {
    try {
      await File(backupPath).delete();
      return true;
    } catch (e) {
      debugPrint('Failed to delete local backup: $e');
      return false;
    }
  }

  /// Get backup statistics
  Future<Map<String, dynamic>> getBackupStats() async {
    final stats = await _dbHelper.getDatabaseStats();

    // Cloud functionality removed - only local backups supported
    return stats;
  }

  /// Clean up old backups (local only)
  Future<void> cleanupOldBackups({int keepLocal = 5}) async {
    // Cleanup local backups only
    await _dbHelper.cleanupOldBackups(keepCount: keepLocal);
  }
}
