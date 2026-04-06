import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'package:roapp/core/database/dummy_data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    await _initializeDatabaseFactory();
    _database = await _initDB('roapp_private_v2.db');
    return _database!;
  }

  Future<void> _initializeDatabaseFactory() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullType = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';

    // Users (Passkey support)
    await db.execute('''
CREATE TABLE users (
  id $idType,
  email $textType,
  passkey $textType
)
''');

    await db.execute('''
CREATE TABLE customers (
  id $idType,
  name $textType,
  phone $textType,
  model $textType,
  status $textType,
  lastService $textType,
  area $textType,
  installationDate $textNullType,
  upcomingServiceDate $textNullType
)
''');

    await db.execute('''
CREATE TABLE inventory (
  id $idType,
  name $textType,
  mrp $doubleType,
  supplier $textType,
  price $doubleType,
  stock $intType,
  lowStockThreshold $intType,
  category $textType
)
''');

    await db.execute('''
CREATE TABLE service_requests (
  id $idType,
  customerName $textType,
  address $textType,
  type $textType,
  model $textType,
  time $textType,
  status $textType
)
''');

    await db.execute('''
CREATE TABLE suppliers (
  id $idType,
  name $textType,
  contactPerson $textType,
  city $textType,
  specialties $textType,
  activePOs $intType,
  status $textType
)
''');

    await db.execute('''
CREATE TABLE technicians (
  id $idType,
  name $textType,
  phone $textType,
  region $textType,
  hubs $textType,
  tasksToday $intType,
  status $textType,
  avatar $textNullType
)
''');

    await db.execute('''
CREATE TABLE service_history (
  id $idType,
  customerId $textType,
  date $textType,
  type $textType,
  technicianName $textType,
  notes $textType,
  cost $doubleType,
  partsReplaced $textType,
  FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
)
''');

    await seedData();
  }

  Future<void> seedData() async {
    final db = await database;
    await DummyData.seed(db);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('users');
      await txn.delete('customers');
      await txn.delete('inventory');
      await txn.delete('service_requests');
      await txn.delete('suppliers');
      await txn.delete('technicians');
      await txn.delete('service_history');
    });
  }
}
