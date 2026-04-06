import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/features/customer/repositories/customer_repository.dart';
import 'package:roapp/features/inventory/repositories/inventory_repository.dart';
import 'package:roapp/features/supplier/repositories/supplier_repository.dart';
import 'package:roapp/features/technician/repositories/technician_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Sanity Tests - Database & Repositories', () {
    test('Database initializes and seeds correctly', () async {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.clearAllData();
      await dbHelper.seedData();
      final db = await dbHelper.database;
      
      final customers = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) as count FROM customers')) ?? 0;
      final suppliers = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) as count FROM suppliers')) ?? 0;
      final inventory = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) as count FROM inventory')) ?? 0;
      final technicians = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) as count FROM technicians')) ?? 0;

      print('Actual Counts: Customers: $customers, Suppliers: $suppliers, Inventory: $inventory, Technicians: $technicians');

      expect(customers, 50);
      expect(suppliers, 10);
      expect(inventory, greaterThanOrEqualTo(100));
      expect(technicians, 10);
      
      await dbHelper.close();
    });

    // Add more granular repo tests if needed.
  });
}
