import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

class DbExporter {
  /// Flushes any WAL pages into the main database file so a plain file copy
  /// captures every committed transaction. Safe no-op when WAL is not in use.
  static Future<void> _checkpointWal() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
    } catch (e) {
      debugPrint('WAL checkpoint before backup failed: $e');
    }
  }

  /// Rejects files that are not a readable SQLite database before they can
  /// overwrite the live one.
  static Future<void> _validateBackupFile(File candidate) async {
    final raf = await candidate.open();
    try {
      final header = await raf.read(16);
      const magic = 'SQLite format 3\u0000';
      if (String.fromCharCodes(header) != magic) {
        throw Exception('That file is not a valid SQLite database backup.');
      }
    } finally {
      await raf.close();
    }

    final db = await databaseFactory.openDatabase(
      candidate.path,
      options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
    );
    try {
      final result = await db.rawQuery('PRAGMA integrity_check');
      final status = result.isEmpty
          ? 'missing'
          : result.first.values.first?.toString().toLowerCase();
      if (status != 'ok') {
        throw Exception('The backup file failed the integrity check.');
      }
      final hasUsers = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'customers'",
      );
      if (hasUsers.isEmpty) {
        throw Exception('The backup file is not an RO Manager database.');
      }
    } finally {
      await db.close();
    }
  }

  /// Replaces the live database with [source], keeping a safety copy of the
  /// current database next to the backups so a bad restore can be undone.
  static Future<void> _replaceLiveDatabase(File source) async {
    await _validateBackupFile(source);

    await _checkpointWal();
    await DatabaseHelper.instance.close();

    final dbFolder = await getDatabasesPath();
    final dbPath = join(dbFolder, DatabaseHelper.dbName);
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      final backupDir = await _backupDirectory();
      await dbFile.copy(join(backupDir.path, 'roapp-pre-restore.db'));
    }

    await source.copy(dbPath);
  }

  static Future<String> exportDatabase() async {
    final dbFolder = await getDatabasesPath();
    final dbPath = join(dbFolder, DatabaseHelper.dbName);
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception('Database file not found. Please try again.');
    }

    await _checkpointWal();

    final backupDir = await _backupDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = join(backupDir.path, 'roapp-backup-$timestamp.db');
    final latestPath = join(backupDir.path, 'roapp-backup-latest.db');

    await dbFile.copy(backupPath);
    await dbFile.copy(latestPath);

    String? downloadsMsg;
    try {
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getDownloadsDirectory();
        }
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir != null && await downloadsDir.exists()) {
        final publicBackupPath = join(downloadsDir.path, 'roapp-backup-$timestamp.db');
        await dbFile.copy(publicBackupPath);
        downloadsMsg = 'Saved to your Downloads folder: roapp-backup-$timestamp.db';
      }
    } catch (_) {
      // Ignore downloads folder write errors if restricted
    }

    await Share.shareXFiles([
      XFile(backupPath),
    ], subject: 'RO App Database Backup');

    return downloadsMsg ?? 'Database backup saved to $backupPath and is ready to share.';
  }

  static Future<String> restoreLatestBackup() async {
    final backupFile = await latestBackupFile();
    if (backupFile == null || !await backupFile.exists()) {
      throw Exception('No local backup was found to restore.');
    }

    await _replaceLiveDatabase(backupFile);

    return 'Latest backup restored successfully.';
  }

  static Future<String> restoreFromFile(File selectedFile) async {
    if (!await selectedFile.exists()) {
      throw Exception('Selected database file does not exist.');
    }

    await _replaceLiveDatabase(selectedFile);

    return 'Database restored successfully from ${basename(selectedFile.path)}.';
  }

  /// Produces a fresh on-disk copy of the live database and returns it, for
  /// uploading to a remote destination (e.g. Google Drive). Reuses the same
  /// `backups/` folder as the local backup flow.
  static Future<File> dbFileForUpload() async {
    final dbFolder = await getDatabasesPath();
    final dbPath = join(dbFolder, DatabaseHelper.dbName);
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception('Database file not found. Please try again.');
    }

    await _checkpointWal();

    final backupDir = await _backupDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final uploadPath = join(backupDir.path, 'roapp-upload-$timestamp.db');
    return dbFile.copy(uploadPath);
  }

  static Future<File?> latestBackupFile() async {
    final backupDir = await _backupDirectory();
    if (!await backupDir.exists()) {
      return null;
    }

    final files =
        backupDir
            .listSync()
            .whereType<File>()
            .where((file) => basename(file.path).endsWith('.db'))
            .toList()
          ..sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          );
    if (files.isEmpty) return null;
    return files.first;
  }

  static Future<Directory> _backupDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(join(root.path, 'backups'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<void> silentAutoBackup() async {
    try {
      final latest = await latestBackupFile();
      if (latest != null && await latest.exists()) {
        final lastModified = await latest.lastModified();
        final now = DateTime.now();
        if (lastModified.year == now.year &&
            lastModified.month == now.month &&
            lastModified.day == now.day) {
          // Backup was already created today
          return;
        }
      }

      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, DatabaseHelper.dbName);
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        return;
      }

      await _checkpointWal();

      final backupDir = await _backupDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath = join(backupDir.path, 'roapp-backup-$timestamp.db');
      final latestPath = join(backupDir.path, 'roapp-backup-latest.db');

      await dbFile.copy(backupPath);
      await dbFile.copy(latestPath);
    } catch (e) {
      // Fail silently to prevent app launch crashing due to filesystem issues
      debugPrint('Silent auto backup failed: $e');
    }
  }
}
