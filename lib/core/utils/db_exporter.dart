import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

class DbExporter {
  static Future<String> exportDatabase() async {
    final dbFolder = await getDatabasesPath();
    final dbPath = join(dbFolder, DatabaseHelper.dbName);
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception('Database file not found. Please try again.');
    }

    final backupDir = await _backupDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = join(backupDir.path, 'roapp-backup-$timestamp.db');
    final latestPath = join(backupDir.path, 'roapp-backup-latest.db');

    await dbFile.copy(backupPath);
    await dbFile.copy(latestPath);

    await Share.shareXFiles([
      XFile(backupPath),
    ], subject: 'RO App Database Backup');

    return 'Database backup saved to $backupPath and is ready to share.';
  }

  static Future<String> restoreLatestBackup() async {
    final backupFile = await latestBackupFile();
    if (backupFile == null || !await backupFile.exists()) {
      throw Exception('No local backup was found to restore.');
    }

    await DatabaseHelper.instance.close();
    final dbFolder = await getDatabasesPath();
    final dbPath = join(dbFolder, DatabaseHelper.dbName);
    await backupFile.copy(dbPath);

    return 'Latest backup restored successfully.';
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
}
