import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/features/inventory/models/inventory_item.dart';
import 'package:uuid/uuid.dart';

class InventoryRepository {
  final dbHelper = DatabaseHelper.instance;
  final uuid = const Uuid();

  Future<List<InventoryItem>> getInventory() async {
    final db = await dbHelper.database;
    final maps = await db.query('inventory');
    return maps.map((e) => InventoryItem.fromMap(e)).toList();
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    final db = await dbHelper.database;
    await db.insert('inventory', item.toMap());
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    final db = await dbHelper.database;
    await db.update(
      'inventory',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteInventoryItem(String id) async {
    final db = await dbHelper.database;
    await db.delete('inventory', where: 'id = ?', whereArgs: [id]);
  }
}
