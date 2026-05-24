import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/features/inventory/models/inventory_item.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

class InventoryRepository {
  final dbHelper = DatabaseHelper.instance;
  final uuid = const Uuid();

  Future<List<InventoryItem>> getInventory() async {
    final db = await dbHelper.database;
    final maps = await db.query('inventory');
    return maps.map((e) => InventoryItem.fromMap(e)).toList();
  }

  Future<List<String>> getCategories() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'product_categories',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    final categories = maps
        .map((row) => row['name'] as String)
        .where((name) => name.trim().isNotEmpty)
        .toList();
    return ['All', ...categories];
  }

  Future<void> addCategory(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    final db = await dbHelper.database;
    final existing = await db.query(
      'product_categories',
      where: 'LOWER(name) = ?',
      whereArgs: [trimmedName.toLowerCase()],
      limit: 1,
    );

    if (existing.isNotEmpty) return;

    await db.insert('product_categories', {
      'id': 'cat-${uuid.v4()}',
      'name': trimmedName,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
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
