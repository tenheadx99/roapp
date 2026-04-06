import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/features/inventory/models/inventory_item.dart';
import 'package:roapp/features/inventory/repositories/inventory_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('InventoryRepository Tests', () {
    final inventoryRepo = InventoryRepository();
    final uuid = const Uuid();

    test('Add, Get, Update, and Delete InventoryItem works', () async {
      final db = await DatabaseHelper.instance.database;
      await db.delete('inventory'); // Start clean

      // Add item
      final item = InventoryItem(
        id: uuid.v4(),
        name: 'Test Filter',
        mrp: 15.0,
        supplier: 'AquaPure Solutions',
        price: 10.0,
        stock: 50,
        lowStockThreshold: 10,
        category: 'Filters',
      );
      
      await inventoryRepo.addInventoryItem(item);

      // Get inventory
      final inventory = await inventoryRepo.getInventory();
      expect(inventory.length, 1);
      expect(inventory.first.name, 'Test Filter');

      // Update item
      final updatedItem = item.copyWith(stock: 100);
      await inventoryRepo.updateInventoryItem(updatedItem);
      
      final updatedInventory = await inventoryRepo.getInventory();
      expect(updatedInventory.first.stock, 100);

      // Delete item
      await inventoryRepo.deleteInventoryItem(item.id);
      final finalInventory = await inventoryRepo.getInventory();
      expect(finalInventory, isEmpty);
    });
  });
}
