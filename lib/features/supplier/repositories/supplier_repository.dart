import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/features/supplier/models/supplier.dart';
import 'package:uuid/uuid.dart';

class SupplierRepository {
  final dbHelper = DatabaseHelper.instance;
  final uuid = const Uuid();

  Future<List<Supplier>> getSuppliers() async {
    final db = await dbHelper.database;
    final maps = await db.query('suppliers');
    return maps.map((e) => Supplier.fromMap(e)).toList();
  }

  Future<Supplier?> getSupplierById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query('suppliers', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Supplier.fromMap(maps.first);
    }
    return null;
  }

  Future<void> addSupplier(Supplier supplier) async {
    final db = await dbHelper.database;
    await db.insert('suppliers', supplier.toMap());
  }

  Future<void> updateSupplier(Supplier supplier) async {
    final db = await dbHelper.database;
    await db.update(
      'suppliers',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<void> deleteSupplier(String id) async {
    final db = await dbHelper.database;
    await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }
}
