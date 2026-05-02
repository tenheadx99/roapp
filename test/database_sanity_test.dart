import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:roapp/core/database/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
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
  });
}
