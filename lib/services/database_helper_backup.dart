/// Database backup and restore operations
/// Part of database_helper.dart
part of 'database_helper.dart';

/// Create a timestamped backup copy of the on-disk database file and
/// return the absolute path to the backup file. Throws on failure.
extension DatabaseBackupExtension on DatabaseHelper {
  Future<String> backupDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('Database backup not supported on Web');
    }

    final dbPath =
        DatabaseHelper._overrideDatabaseFilePath ??
        join(await getDatabasesPath(), 'extropos.db');
    final file = File(dbPath);

    if (!await file.exists()) {
      throw StateError('Database file does not exist: $dbPath');
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath =
        join(dirname(dbPath), 'extropos_backup_$timestamp.db');

    await file.copy(backupPath);
    return backupPath;
  }

  /// Restore database from a specific backup file
  Future<void> restoreFromBackup(String backupPath) async {
    if (kIsWeb) {
      throw UnsupportedError('Database restore not supported on Web');
    }

    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      throw StateError('Backup file does not exist: $backupPath');
    }

    // Close current database connection
    if (DatabaseHelper._database != null) {
      await DatabaseHelper._database!.close();
      DatabaseHelper._database = null;
    }

    final dbPath =
        DatabaseHelper._overrideDatabaseFilePath ??
        join(await getDatabasesPath(), 'extropos.db');

    // Copy backup file to database location
    await backupFile.copy(dbPath);

    // Reopen database
    DatabaseHelper._database = await _initDB('extropos.db');
  }

  /// Try to restore from the most recent backup if database is corrupted
  Future<bool> _restoreFromBackupIfAvailable(String dbPath) async {
    if (kIsWeb) return false;

    final backups = await getBackupFiles();
    if (backups.isEmpty) return false;

    // Sort backups by name (which includes timestamp) and get most recent
    backups.sort((a, b) => b.compareTo(a));
    final mostRecentBackup = backups.first;

    try {
      await restoreFromBackup(mostRecentBackup);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> cleanupOldBackups({int keepCount = 5}) async {
    if (kIsWeb) return;

    final backups = await getBackupFiles();
    if (backups.length <= keepCount) return;

    backups.sort((a, b) => b.compareTo(a));
    final toDelete = backups.skip(keepCount);
    for (final path in toDelete) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // ignore cleanup errors
      }
    }
  }
}
