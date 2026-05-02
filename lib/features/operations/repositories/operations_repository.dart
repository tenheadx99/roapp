import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/features/customer/repositories/customer_repository.dart';
import 'package:roapp/features/inventory/repositories/inventory_repository.dart';
import 'package:roapp/features/operations/models/amc_contract.dart';
import 'package:roapp/features/operations/models/communication_log.dart';
import 'package:roapp/features/operations/models/invoice.dart';
import 'package:roapp/features/operations/models/purchase_order.dart';
import 'package:roapp/features/operations/models/service_attachment.dart';
import 'package:roapp/features/operations/models/technician_schedule.dart';
import 'package:sqflite/sqflite.dart';

class OperationsRepository {
  final DatabaseHelper dbHelper;

  OperationsRepository({DatabaseHelper? dbHelper})
    : dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Invoice>> getInvoices({String? customerId}) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'invoices',
      where: customerId == null ? null : 'customerId = ?',
      whereArgs: customerId == null ? null : [customerId],
      orderBy: 'dueDate ASC',
    );
    return maps.map(Invoice.fromMap).toList();
  }

  Future<void> upsertInvoice(Invoice invoice) async {
    final db = await dbHelper.database;
    await db.insert(
      'invoices',
      invoice.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteInvoice(String id) async {
    final db = await dbHelper.database;
    await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<AmcContract>> getContracts({String? customerId}) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'amc_contracts',
      where: customerId == null ? null : 'customerId = ?',
      whereArgs: customerId == null ? null : [customerId],
      orderBy: 'endDate ASC',
    );
    return maps.map(AmcContract.fromMap).toList();
  }

  Future<void> upsertContract(AmcContract contract) async {
    final db = await dbHelper.database;
    await db.insert(
      'amc_contracts',
      contract.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteContract(String id) async {
    final db = await dbHelper.database;
    await db.delete('amc_contracts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CommunicationLog>> getCommunicationLogs({
    String? customerId,
  }) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'communication_logs',
      where: customerId == null ? null : 'customerId = ?',
      whereArgs: customerId == null ? null : [customerId],
      orderBy: 'createdAt DESC',
    );
    return maps.map(CommunicationLog.fromMap).toList();
  }

  Future<void> addCommunicationLog(CommunicationLog log) async {
    final db = await dbHelper.database;
    await db.insert('communication_logs', log.toMap());
  }

  Future<List<PurchaseOrder>> getPurchaseOrders({String? supplierId}) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'purchase_orders',
      where: supplierId == null ? null : 'supplierId = ?',
      whereArgs: supplierId == null ? null : [supplierId],
      orderBy: 'createdAt DESC',
    );
    return maps.map(PurchaseOrder.fromMap).toList();
  }

  Future<void> upsertPurchaseOrder(PurchaseOrder order) async {
    final db = await dbHelper.database;
    await db.insert(
      'purchase_orders',
      order.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _syncSupplierActivePoCount(db, order.supplierId);
  }

  Future<void> deletePurchaseOrder(String id) async {
    final db = await dbHelper.database;
    final order = await db.query(
      'purchase_orders',
      columns: ['supplierId'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    await db.delete('purchase_orders', where: 'id = ?', whereArgs: [id]);
    if (order.isNotEmpty) {
      await _syncSupplierActivePoCount(db, order.first['supplierId'] as String);
    }
  }

  Future<List<TechnicianSchedule>> getTechnicianSchedules({
    String? technicianId,
  }) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'technician_schedules',
      where: technicianId == null ? null : 'technicianId = ?',
      whereArgs: technicianId == null ? null : [technicianId],
      orderBy: 'scheduleDate ASC',
    );
    return maps.map(TechnicianSchedule.fromMap).toList();
  }

  Future<void> upsertTechnicianSchedule(TechnicianSchedule schedule) async {
    final db = await dbHelper.database;
    await db.insert(
      'technician_schedules',
      schedule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ServiceAttachment>> getAttachments({String? customerId}) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'service_attachments',
      where: customerId == null ? null : 'customerId = ?',
      whereArgs: customerId == null ? null : [customerId],
      orderBy: 'createdAt DESC',
    );
    return maps.map(ServiceAttachment.fromMap).toList();
  }

  Future<void> upsertAttachment(ServiceAttachment attachment) async {
    final db = await dbHelper.database;
    await db.insert(
      'service_attachments',
      attachment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAttachment(String id) async {
    final db = await dbHelper.database;
    await db.delete('service_attachments', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> getOperationsOverview() async {
    final invoices = await getInvoices();
    final contracts = await getContracts();
    final purchaseOrders = await getPurchaseOrders();
    final schedules = await getTechnicianSchedules();
    final logs = await getCommunicationLogs();
    final attachments = await getAttachments();

    final outstandingBalance = invoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.balanceDue,
    );
    final overdueInvoices = invoices
        .where((invoice) => invoice.isOverdue)
        .length;
    final expiringContracts = contracts
        .where((contract) => contract.isRenewalDue)
        .length;
    final openPurchaseOrders = purchaseOrders
        .where((order) => order.status.toLowerCase() != 'received')
        .length;
    final today = DateTime.now();
    final plannedToday = schedules.where((schedule) {
      final date = DateTime.tryParse(schedule.scheduleDate);
      if (date == null) return false;
      return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    }).length;

    return {
      'outstandingBalance': outstandingBalance,
      'overdueInvoices': overdueInvoices,
      'expiringContracts': expiringContracts,
      'openPurchaseOrders': openPurchaseOrders,
      'plannedToday': plannedToday,
      'communicationLogs': logs.length,
      'attachments': attachments.length,
      'activeInvoices': invoices.length,
      'activeContracts': contracts.length,
    };
  }

  Future<String> buildOperationsReport() async {
    final invoices = await getInvoices();
    final contracts = await getContracts();
    final orders = await getPurchaseOrders();
    final schedules = await getTechnicianSchedules();
    final overview = await getOperationsOverview();
    final inventory = await InventoryRepository().getInventory();
    final serviceHistory = await CustomerRepository().getAllServiceHistory();

    final buffer = StringBuffer()
      ..writeln('RO Manager Operations Report')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln()
      ..writeln('Invoices: ${invoices.length}')
      ..writeln('Outstanding Due: ${overview['outstandingBalance']}')
      ..writeln('Overdue Invoices: ${overview['overdueInvoices']}')
      ..writeln('AMC Contracts: ${contracts.length}')
      ..writeln('Renewals Due: ${overview['expiringContracts']}')
      ..writeln('Purchase Orders: ${orders.length}')
      ..writeln('Open Purchase Orders: ${overview['openPurchaseOrders']}')
      ..writeln('Technician Schedules: ${schedules.length}')
      ..writeln('Monthly Service Volume: ${serviceHistory.length}');

    if (orders.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Supplier Lead Times');
      for (final order in orders.take(10)) {
        buffer.writeln(
          '- ${order.poNumber}: ${order.leadDays} days, status ${order.status}',
        );
      }
    }

    if (inventory.isNotEmpty) {
      final grouped = <String, int>{};
      for (final item in inventory) {
        grouped[item.category] = (grouped[item.category] ?? 0) + item.stock;
      }

      buffer
        ..writeln()
        ..writeln('Stock Movement Snapshot');
      grouped.forEach((category, units) {
        buffer.writeln('- $category: $units units on hand');
      });
    }

    return buffer.toString();
  }

  Future<void> _syncSupplierActivePoCount(
    Database db,
    String supplierId,
  ) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM purchase_orders WHERE supplierId = ? AND LOWER(status) != 'received'",
        [supplierId],
      ),
    );
    await db.update(
      'suppliers',
      {'activePOs': count ?? 0},
      where: 'id = ?',
      whereArgs: [supplierId],
    );
  }
}
