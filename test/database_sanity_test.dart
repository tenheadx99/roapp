import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:roapp/core/database/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.dbName = 'roapp_test_database_sanity.db';
  });

  group('Sanity Tests - Database & Repositories', () {
    test(
      'Database initializes without dummy data and keeps default admin',
      () async {
        final dbHelper = DatabaseHelper.instance;
        await dbHelper.clearAllData();
        await dbHelper.seedData();
        final db = await dbHelper.database;

        final customers =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM customers'),
            ) ??
            0;
        final suppliers =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM suppliers'),
            ) ??
            0;
        final inventory =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM inventory'),
            ) ??
            0;
        final technicians =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM technicians'),
            ) ??
            0;
        final users =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM users'),
            ) ??
            0;
        final migrations =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM schema_migrations'),
            ) ??
            0;

        expect(customers, 0);
        expect(suppliers, 0);
        expect(inventory, 0);
        expect(technicians, 0);
        expect(users, greaterThanOrEqualTo(1));
        expect(migrations, greaterThanOrEqualTo(1));

        await dbHelper.close();
      },
    );

    test(
      'loadDemoData seeds customers, inventory, technicians, and dispatch',
      () async {
        final dbHelper = DatabaseHelper.instance;
        await dbHelper.clearAllData();
        await dbHelper.loadDemoData();
        final db = await dbHelper.database;

        final customers =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM customers'),
            ) ??
            0;
        final inventory =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM inventory'),
            ) ??
            0;
        final technicians =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM technicians'),
            ) ??
            0;
        final requests =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM service_requests'),
            ) ??
            0;
        final history =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM service_history'),
            ) ??
            0;

        expect(customers, greaterThan(0));
        expect(inventory, greaterThan(0));
        expect(technicians, greaterThan(0));
        expect(requests, greaterThan(0));
        expect(history, greaterThan(0));

        await dbHelper.close();
      },
    );
  });
}
