import 'dart:io';
import 'package:path/path.dart';
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

    await Share.shareXFiles(
      [XFile(dbPath)],
      subject: 'RO App Database Backup',
    );

    return 'Database backup is ready to share.';
  }
}
