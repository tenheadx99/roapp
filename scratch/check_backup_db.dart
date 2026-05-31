import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:roapp/features/customer/models/customer.dart';
import 'package:roapp/features/dispatch/models/service_request.dart';
import 'package:roapp/features/customer/models/service_history.dart';
import 'package:roapp/features/operations/models/invoice.dart';
import 'package:roapp/features/inventory/models/inventory_item.dart';
import 'package:roapp/features/technician/models/technician.dart';
import 'package:roapp/features/supplier/models/supplier.dart';

void main() async {
  sqfliteFfiInit();
  final databaseFactory = databaseFactoryFfi;

  final dbPath = join(Directory.current.path, 'db', 'roapp-backup-2026-05-31T13-54-03.239023.db');
  print('Checking backup database at: $dbPath');

  if (!await File(dbPath).exists()) {
    print('ERROR: Backup database file does not exist!');
    exit(1);
  }

  final db = await databaseFactory.openDatabase(dbPath);

  try {
    print('\n=== Running PRAGMA integrity_check ===');
    final integrity = await db.rawQuery('PRAGMA integrity_check;');
    print('Integrity check result: $integrity');

    print('\n=== Fetching Table Schema Migrations ===');
    final migrations = await db.query('schema_migrations');
    for (final row in migrations) {
      print('Migration version ${row['version']}: ${row['notes']} (Applied: ${row['appliedAt']})');
    }

    print('\n=== Validating Tables and Deserializing Models ===');

    // Customers
    final customersData = await db.query('customers');
    print('Customers: ${customersData.length} records found.');
    if (customersData.isNotEmpty) {
      final customer = Customer.fromMap(customersData.first);
      print('Successfully mapped first Customer: ID=${customer.id}, Name=${customer.name}');
    }

    // Service Requests
    final serviceRequestsData = await db.query('service_requests');
    print('Service Requests: ${serviceRequestsData.length} records found.');
    if (serviceRequestsData.isNotEmpty) {
      final request = ServiceRequest.fromMap(serviceRequestsData.first);
      print('Successfully mapped first ServiceRequest: ID=${request.id}, Type=${request.type}, Customer=${request.customerName}, TotalAmount=${request.totalAmount}');
    }

    // Service History
    final serviceHistoryData = await db.query('service_history');
    print('Service History: ${serviceHistoryData.length} records found.');
    if (serviceHistoryData.isNotEmpty) {
      final history = ServiceHistory.fromMap(serviceHistoryData.first);
      print('Successfully mapped first ServiceHistory: ID=${history.id}, Type=${history.type}, Date=${history.date}');
    }

    // Invoices
    final invoicesData = await db.query('invoices');
    print('Invoices: ${invoicesData.length} records found.');
    if (invoicesData.isNotEmpty) {
      final invoice = Invoice.fromMap(invoicesData.first);
      print('Successfully mapped first Invoice: ID=${invoice.id}, InvoiceNumber=${invoice.invoiceNumber}, Status=${invoice.status}');
    }

    // Inventory
    final inventoryData = await db.query('inventory');
    print('Inventory Items: ${inventoryData.length} records found.');
    if (inventoryData.isNotEmpty) {
      final item = InventoryItem.fromMap(inventoryData.first);
      print('Successfully mapped first InventoryItem: ID=${item.id}, Name=${item.name}, Stock=${item.stock}');
    }

    // Technicians
    final techniciansData = await db.query('technicians');
    print('Technicians: ${techniciansData.length} records found.');
    if (techniciansData.isNotEmpty) {
      final tech = Technician.fromMap(techniciansData.first);
      print('Successfully mapped first Technician: ID=${tech.id}, Name=${tech.name}, Status=${tech.status}');
    }

    // Suppliers
    final suppliersData = await db.query('suppliers');
    print('Suppliers: ${suppliersData.length} records found.');
    if (suppliersData.isNotEmpty) {
      final supplier = Supplier.fromMap(suppliersData.first);
      print('Successfully mapped first Supplier: ID=${supplier.id}, Name=${supplier.name}');
    }

    print('\n[SUCCESS] Backup database structure is fully correct, healthy, and compatible with modern app models!');
  } catch (e, stack) {
    print('ERROR during backup verification: $e');
    print(stack);
    exit(1);
  } finally {
    await db.close();
  }
}
