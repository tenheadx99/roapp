import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:roapp/core/database/dummy_data.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const String dbName = 'roapp_private_v2.db';
  static const int dbVersion = 12;
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
CREATE TABLE app_settings (
  key $idType,
  value $textType
)
''');

    await db.execute('''
CREATE TABLE schema_migrations (
  version INTEGER PRIMARY KEY,
  appliedAt $textType,
  notes $textNullType
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
  upcomingServiceDate $textNullType,
  updatedAt $textNullType
)
''');

    await db.execute('''
CREATE TABLE inventory (
  id $idType,
  name $textType,
  mrp $doubleType,
  supplier $textType,
  price $doubleType,
  supplierPrice $doubleType,
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
  customerId $textNullType,
  customerName $textType,
  address $textType,
  type $textType,
  model $textType,
  time $textType,
  status $textType,
  scheduledFor $textNullType,
  completedAt $textNullType,
  technicianId $textNullType,
  technicianName $textNullType,
  notes $textNullType,
  inventoryItems $textNullType,
  totalAmount REAL NOT NULL DEFAULT 0
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
  serviceRequestId $textNullType,
  date $textType,
  type $textType,
  technicianName $textType,
  notes $textType,
  cost $doubleType,
  partsReplaced $textType,
  FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE invoices (
  id $idType,
  customerId $textType,
  invoiceNumber $textType,
  issueDate $textType,
  dueDate $textType,
  totalAmount $doubleType,
  paidAmount $doubleType,
  supplierPrice $doubleType,
  status $textType,
  notes $textNullType,
  FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE amc_contracts (
  id $idType,
  customerId $textType,
  contractName $textType,
  startDate $textType,
  endDate $textType,
  visitsIncluded $intType,
  visitsUsed $intType,
  amount $doubleType,
  status $textType,
  renewalReminderDate $textType,
  FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE communication_logs (
  id $idType,
  customerId $textType,
  channel $textType,
  note $textType,
  createdAt $textType,
  createdBy $textType,
  FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE purchase_orders (
  id $idType,
  supplierId $textType,
  poNumber $textType,
  createdAt $textType,
  expectedDate $textType,
  receivedDate $textNullType,
  status $textType,
  totalAmount $doubleType,
  leadDays $intType,
  notes $textNullType,
  FOREIGN KEY (supplierId) REFERENCES suppliers (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE technician_schedules (
  id $idType,
  technicianId $textType,
  scheduleDate $textType,
  routeArea $textType,
  plannedStops $textType,
  checklist $textType,
  leaveStatus $textType,
  FOREIGN KEY (technicianId) REFERENCES technicians (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE service_attachments (
  id $idType,
  customerId $textType,
  serviceRequestId $textNullType,
  type $textType,
  title $textType,
  filePath $textType,
  createdAt $textType,
  FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
)
''');

    await _recordMigration(
      db,
      version,
      'Initial schema with operations and settings tables.',
    );
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
          'id':
              'cat-${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}',
          'name': name,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE users ADD COLUMN name TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN role TEXT');
    }

    if (oldVersion < 5) {
      await db.execute('''
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''');
    }

    if (oldVersion < 6) {
      await db.delete('customers');
      await db.delete('inventory');
      await db.delete('service_requests');
      await db.delete('suppliers');
      await db.delete('technicians');
      await db.delete('service_history');
      await db.delete('product_categories');
    }

    if (oldVersion < 7) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS schema_migrations (
  version INTEGER PRIMARY KEY,
  appliedAt TEXT NOT NULL,
  notes TEXT
)
''');

      await db.execute('''
CREATE TABLE IF NOT EXISTS invoices (
  id TEXT PRIMARY KEY,
  customerId TEXT NOT NULL,
  invoiceNumber TEXT NOT NULL,
  issueDate TEXT NOT NULL,
  dueDate TEXT NOT NULL,
  totalAmount REAL NOT NULL,
  paidAmount REAL NOT NULL,
  status TEXT NOT NULL,
  notes TEXT,
  FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
)
''');

      await db.execute('''
CREATE TABLE IF NOT EXISTS amc_contracts (
  id TEXT PRIMARY KEY,
  customerId TEXT NOT NULL,
  contractName TEXT NOT NULL,
  startDate TEXT NOT NULL,
  endDate TEXT NOT NULL,
  visitsIncluded INTEGER NOT NULL,
  visitsUsed INTEGER NOT NULL,
  amount REAL NOT NULL,
  status TEXT NOT NULL,
  renewalReminderDate TEXT NOT NULL,
  FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
)
''');

      await db.execute('''
CREATE TABLE IF NOT EXISTS communication_logs (
  id TEXT PRIMARY KEY,
  customerId TEXT NOT NULL,
  channel TEXT NOT NULL,
  note TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  createdBy TEXT NOT NULL,
  FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
)
''');

      await db.execute('''
CREATE TABLE IF NOT EXISTS purchase_orders (
  id TEXT PRIMARY KEY,
  supplierId TEXT NOT NULL,
  poNumber TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  expectedDate TEXT NOT NULL,
  receivedDate TEXT,
  status TEXT NOT NULL,
  totalAmount REAL NOT NULL,
  leadDays INTEGER NOT NULL,
  notes TEXT,
  FOREIGN KEY (supplierId) REFERENCES suppliers (id) ON DELETE CASCADE
)
''');

      await db.execute('''
CREATE TABLE IF NOT EXISTS technician_schedules (
  id TEXT PRIMARY KEY,
  technicianId TEXT NOT NULL,
  scheduleDate TEXT NOT NULL,
  routeArea TEXT NOT NULL,
  plannedStops TEXT NOT NULL,
  checklist TEXT NOT NULL,
  leaveStatus TEXT NOT NULL,
  FOREIGN KEY (technicianId) REFERENCES technicians (id) ON DELETE CASCADE
)
''');

      await db.execute('''
CREATE TABLE IF NOT EXISTS service_attachments (
  id TEXT PRIMARY KEY,
  customerId TEXT NOT NULL,
  serviceRequestId TEXT,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  filePath TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
)
''');

      await _recordMigration(
        db,
        7,
        'Added operations workflows, attachments, and migration audit tracking.',
      );
    }

    if (oldVersion < 8) {
      await db.execute(
        'ALTER TABLE service_requests ADD COLUMN customerId TEXT',
      );
      await db.execute(
        'ALTER TABLE service_requests ADD COLUMN technicianId TEXT',
      );
      await db.execute(
        'ALTER TABLE service_requests ADD COLUMN inventoryItems TEXT',
      );
      await db.execute(
        'ALTER TABLE service_requests ADD COLUMN totalAmount REAL NOT NULL DEFAULT 0',
      );

      await _recordMigration(
        db,
        8,
        'Linked service requests to customers and added priced inventory line items.',
      );
    }

    if (oldVersion < 9) {
      await db.execute(
        'ALTER TABLE service_requests ADD COLUMN completedAt TEXT',
      );
      await db.execute(
        'ALTER TABLE service_history ADD COLUMN serviceRequestId TEXT',
      );

      await _recordMigration(
        db,
        9,
        'Tracked service completion timestamps and linked service history to service requests.',
      );
    }

    if (oldVersion < 10) {
      await db.execute(
        'ALTER TABLE invoices ADD COLUMN supplierPrice REAL NOT NULL DEFAULT 0.0',
      );
      await _recordMigration(
        db,
        10,
        'Added supplierPrice column to invoices.',
      );
    }

    if (oldVersion < 11) {
      await db.execute(
        'ALTER TABLE inventory ADD COLUMN supplierPrice REAL NOT NULL DEFAULT 0.0',
      );
      await _recordMigration(
        db,
        11,
        'Added supplierPrice column to inventory.',
      );
    }

    if (oldVersion < 12) {
      await db.execute(
        'ALTER TABLE customers ADD COLUMN updatedAt TEXT',
      );
      await _recordMigration(
        db,
        12,
        'Added updatedAt column to customers.',
      );
    }

    await _ensureDefaultAdmin(db);
  }

  Future<void> seedData() async {
    final db = await database;
    await _ensureDefaultAdmin(db);
  }

  Future<void> loadDemoData({bool replaceExisting = true}) async {
    final db = await database;
    if (replaceExisting) {
      await clearAllData();
    }
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
      where:
          'id = ? AND (name IS NULL OR TRIM(name) = \'\' OR phone IS NULL OR TRIM(phone) = \'\' OR role IS NULL OR TRIM(role) = \'\')',
      whereArgs: ['default-admin'],
    );
  }

  Future<void> _recordMigration(Database db, int version, String notes) async {
    await db.insert('schema_migrations', {
      'version': version,
      'appliedAt': DateTime.now().toIso8601String(),
      'notes': notes,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
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
        await txn.delete(
          'app_settings',
          where: 'key = ?',
          whereArgs: ['current_user_id'],
        );
      }
      await txn.delete('customers');
      await txn.delete('inventory');
      await txn.delete('product_categories');
      await txn.delete('service_requests');
      await txn.delete('suppliers');
      await txn.delete('technicians');
      await txn.delete('service_history');
      await txn.delete('invoices');
      await txn.delete('amc_contracts');
      await txn.delete('communication_logs');
      await txn.delete('purchase_orders');
      await txn.delete('technician_schedules');
      await txn.delete('service_attachments');
    });

    if (!includeUsers) {
      await _ensureDefaultAdmin(db);
    }
  }
}
