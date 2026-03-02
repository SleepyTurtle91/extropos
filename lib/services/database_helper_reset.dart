part of 'database_helper.dart';

extension DatabaseHelperReset on DatabaseHelper {
  Future<void> resetDatabase() async {
    String path;
    if (kIsWeb) {
      path = 'extropos.db';
    } else {
      path =
          DatabaseHelper._overrideDatabaseFilePath ??
          join(await getDatabasesPath(), 'extropos.db');
    }

    try {
      await deleteDatabase(path);
    } catch (_) {
      // ignore
    }
    DatabaseHelper._database = null;
    await database; // Reinitialize
  }

  Future<String> safeResetDatabase({bool createBackup = true}) async {
    String path;
    if (kIsWeb) {
      path = 'extropos.db';
    } else {
      path =
          DatabaseHelper._overrideDatabaseFilePath ??
          join(await getDatabasesPath(), 'extropos.db');
    }

    String? backupPath;
    if (createBackup && !kIsWeb) {
      try {
        backupPath = await backupDatabase();
        // Database backed up before reset: $backupPath
      } catch (e) {
        // Warning: Could not create backup before reset: $e
      }
    }

    // Close current connection
    if (DatabaseHelper._database != null) {
      await DatabaseHelper._database!.close();
      DatabaseHelper._database = null;
    }

    // Delete and recreate
    try {
      await deleteDatabase(path);
    } catch (_) {
      // ignore
    }

    // Reinitialize
    await database;

    return backupPath ?? 'No backup created';
  }

  Future<void> _checkDatabaseIntegrity(String dbPath) async {
    if (kIsWeb) return; // Skip integrity check on Web

    final file = File(dbPath);
    if (!await file.exists()) return; // New database, no integrity check needed

    try {
      // Try to open database for a quick integrity check
      final testDb = await openDatabase(dbPath, readOnly: true);
      await testDb.close();
    } catch (e) {
      // Database integrity check failed: $e
      // Try to restore from backup
      await _restoreFromBackupIfAvailable(dbPath);
    }
  }

  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    // Warning: Database downgrade detected from v$oldVersion to v$newVersion
    // In production, we should not allow downgrades as they can cause data loss
    // For now, we'll allow it but create a backup first
    if (!kIsWeb) {
      try {
        await backupDatabase();
      } catch (e) {
        // Could not create backup before downgrade: $e
      }
    }
  }

}
