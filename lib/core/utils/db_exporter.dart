import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

class DbExporter {
  static Future<void> exportDatabase() async {
    try {
      // 1. Get the path to the internal database
      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, DatabaseHelper.dbName);
      final dbFile = File(dbPath);

      if (await dbFile.exists()) {
        // 2. Share the file using the native share sheet
        // This allows the user to "Save to Files" or "Download"
        await Share.shareXFiles(
          [XFile(dbPath)],
          subject: 'RO App Database Backup',
        );
      } else {
        print("Database file not found at $dbPath");
      }
    } catch (e) {
      print("Error exporting database: $e");
    }
  }
}
