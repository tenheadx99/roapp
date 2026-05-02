import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'package:roapp/core/database/dummy_data.dart';

class DatabaseHelper {
  static const String dbName = 'roapp_private_v2.db';
  static const int dbVersion = 4;
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    await _initializeDatabaseFactory();
    _database = await _initDB(dbName);
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

    return await openDatabase(
      path,
      version: dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
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
  email $textType UNIQUE,
  passkey $textType,
  name $textNullType,
  phone $textNullType,
  role $textNullType
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
CREATE TABLE product_categories (
  id $idType,
  name $textType UNIQUE
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
  status $textType,
  scheduledFor $textNullType,
  technicianName $textNullType,
  notes $textNullType
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
  status $textType,
  phone $textNullType,
  email $textNullType
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

    await DummyData.seed(db);
    await _ensureDefaultAdmin(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE service_requests ADD COLUMN scheduledFor TEXT',
      );
      await db.execute(
        'ALTER TABLE service_requests ADD COLUMN technicianName TEXT',
      );
      await db.execute('ALTER TABLE service_requests ADD COLUMN notes TEXT');
      await db.execute('ALTER TABLE suppliers ADD COLUMN phone TEXT');
      await db.execute('ALTER TABLE suppliers ADD COLUMN email TEXT');
    }

    if (oldVersion < 3) {
      await db.execute('''
CREATE TABLE product_categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
)
''');

      final inventoryCategories = await db.rawQuery(
        "SELECT DISTINCT category FROM inventory WHERE category IS NOT NULL AND TRIM(category) != ''",
      );

      const defaultCategories = [
        'Filters',
        'Membranes',
        'Pumps',
        'UV Lamps',
        'Other',
        'Tubes & Fittings',
        'Adapters',
        'Miscellaneous',
      ];

      final categories = {
        ...defaultCategories,
        ...inventoryCategories
            .map((row) => row['category'] as String? ?? '')
            .where((name) => name.trim().isNotEmpty),
      };

      for (final name in categories) {
        await db.insert('product_categories', {
          'id': 'cat-${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}',
          'name': name,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE users ADD COLUMN name TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN role TEXT');
    }

    await _ensureDefaultAdmin(db);
  }

  Future<void> seedData() async {
    final db = await database;
    await DummyData.seed(db);
    await _ensureDefaultAdmin(db);
  }

  Future<void> _ensureDefaultAdmin(Database db) async {
    final existing = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM users'),
    );

    if ((existing ?? 0) == 0) {
      await db.insert('users', {
        'id': 'default-admin',
        'email': 'admin@roservice.com',
        'passkey': 'password123',
        'name': 'Ramesh Admin',
        'phone': '+91 9876543210',
        'role': 'Operations Admin',
      });
      return;
    }

    await db.update(
      'users',
      {
        'name': 'Ramesh Admin',
        'phone': '+91 9876543210',
        'role': 'Operations Admin',
      },
      where: 'id = ? AND (name IS NULL OR TRIM(name) = \'\' OR phone IS NULL OR TRIM(phone) = \'\' OR role IS NULL OR TRIM(role) = \'\')',
      whereArgs: ['default-admin'],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }

  Future<void> clearAllData({bool includeUsers = false}) async {
    final db = await database;
    await db.transaction((txn) async {
      if (includeUsers) {
        await txn.delete('users');
      }
      await txn.delete('customers');
      await txn.delete('inventory');
      await txn.delete('service_requests');
      await txn.delete('suppliers');
      await txn.delete('technicians');
      await txn.delete('service_history');
    });

    if (!includeUsers) {
      await _ensureDefaultAdmin(db);
    }
  }
}
