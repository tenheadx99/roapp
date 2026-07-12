import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/core/services/invoice_pdf_service.dart';
import 'package:roapp/features/customer/models/customer.dart';
import 'package:roapp/features/customer/repositories/customer_repository.dart';
import 'package:roapp/features/dispatch/models/service_request.dart';
import 'package:roapp/features/inventory/repositories/inventory_repository.dart';
import 'package:roapp/features/operations/models/amc_contract.dart';
import 'package:roapp/features/operations/models/communication_log.dart';
import 'package:roapp/features/operations/models/invoice.dart';
import 'package:roapp/features/operations/models/purchase_order.dart';
import 'package:roapp/features/operations/models/service_attachment.dart';
import 'package:roapp/features/operations/models/technician_schedule.dart';
import 'package:roapp/features/settings/repositories/settings_repository.dart';
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

  /// Adds [amount] to the invoice's paid total (capped at the invoice total)
  /// and recomputes its status. Returns the updated invoice, or null if the
  /// invoice does not exist.
  Future<Invoice?> recordInvoicePayment(String invoiceId, double amount) async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final invoice = Invoice.fromMap(rows.first);
    final newPaid = (invoice.paidAmount + amount)
        .clamp(0.0, invoice.totalAmount)
        .toDouble();
    final settled = invoice.totalAmount - newPaid <= 0.01;
    final due = DateTime.tryParse(invoice.dueDate);
    final status = settled
        ? 'paid'
        : (due != null && due.isBefore(DateTime.now()) ? 'overdue' : 'due');

    await db.update(
      'invoices',
      {'paidAmount': newPaid, 'status': status},
      where: 'id = ?',
      whereArgs: [invoiceId],
    );

    final updated = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );
    return updated.isEmpty ? null : Invoice.fromMap(updated.first);
  }

  /// Contract status is only computed when a contract is saved, so mark any
  /// active contract whose end date has passed as expired before reading.
  Future<void> _expireStaleContracts(Database db) async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await db.update(
      'amc_contracts',
      {'status': 'expired'},
      where: "LOWER(status) = 'active' AND substr(endDate, 1, 10) < ?",
      whereArgs: [todayStr],
    );
  }

  Future<List<AmcContract>> getContracts({String? customerId}) async {
    final db = await dbHelper.database;
    await _expireStaleContracts(db);
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

  /// Creates the follow-on contract for [contract]: same terms, dates shifted
  /// so the new period starts when the old one ends (or today if it already
  /// ended), and the visit counter reset. Returns the new contract.
  Future<AmcContract> renewContract(AmcContract contract) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final oldStart = DateTime.tryParse(contract.startDate);
    final oldEnd = DateTime.tryParse(contract.endDate);
    final duration = (oldStart != null && oldEnd != null)
        ? oldEnd.difference(oldStart)
        : const Duration(days: 365);

    var newStart = oldEnd ?? today;
    if (newStart.isBefore(today)) newStart = today;
    final newEnd = newStart.add(duration);

    final renewed = AmcContract(
      id: 'amc-${DateTime.now().microsecondsSinceEpoch}',
      customerId: contract.customerId,
      contractName: contract.contractName,
      startDate: newStart.toIso8601String(),
      endDate: newEnd.toIso8601String(),
      visitsIncluded: contract.visitsIncluded,
      visitsUsed: 0,
      amount: contract.amount,
      status: 'active',
      renewalReminderDate: newEnd
          .subtract(const Duration(days: 30))
          .toIso8601String(),
    );
    await upsertContract(renewed);
    return renewed;
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

  /// Marks the purchase order as received and stocks in its line items.
  /// Idempotent: a PO that is already received is left untouched, so stock
  /// can never be incremented twice for the same order. Returns true when
  /// the transition happened.
  Future<bool> markPurchaseOrderReceived(String id) async {
    final db = await dbHelper.database;
    var transitioned = false;

    await db.transaction((txn) async {
      final rows = await txn.query(
        'purchase_orders',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return;

      final order = PurchaseOrder.fromMap(rows.first);
      if (order.status.toLowerCase() == 'received') return;

      await txn.update(
        'purchase_orders',
        {
          'status': 'received',
          'receivedDate': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      for (final item in order.items) {
        final itemId = item.inventoryItemId;
        if (itemId == null || itemId.isEmpty || item.quantity <= 0) continue;
        await txn.rawUpdate(
          'UPDATE inventory SET stock = stock + ? WHERE id = ?',
          [item.quantity, itemId],
        );
      }

      await _syncSupplierActivePoCount(txn, order.supplierId);
      transitioned = true;
    });

    return transitioned;
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
    final list = maps.map(TechnicianSchedule.fromMap).toList();
    return sortSchedulesByRoute(list);
  }

  static List<TechnicianSchedule> sortSchedulesByRoute(List<TechnicianSchedule> schedules) {
    final sorted = List<TechnicianSchedule>.from(schedules);
    sorted.sort((a, b) {
      final dateComp = a.scheduleDate.compareTo(b.scheduleDate);
      if (dateComp != 0) return dateComp;
      
      final techComp = a.technicianId.compareTo(b.technicianId);
      if (techComp != 0) return techComp;
      
      return a.routeArea.toLowerCase().compareTo(b.routeArea.toLowerCase());
    });
    return sorted;
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
    final db = await dbHelper.database;
    await _expireStaleContracts(db);

    final nowIso = DateTime.now().toIso8601String();
    final todayStr = nowIso.substring(0, 10);

    final rows = await db.rawQuery(
      '''
SELECT
  (SELECT COALESCE(SUM(totalAmount - paidAmount), 0) FROM invoices) AS outstandingBalance,
  (SELECT COUNT(*) FROM invoices
     WHERE (totalAmount - paidAmount) > 0.01 AND dueDate < ?) AS overdueInvoices,
  (SELECT COUNT(*) FROM amc_contracts WHERE renewalReminderDate <= ?) AS expiringContracts,
  (SELECT COUNT(*) FROM purchase_orders WHERE LOWER(status) != 'received') AS openPurchaseOrders,
  (SELECT COUNT(*) FROM technician_schedules WHERE substr(scheduleDate, 1, 10) = ?) AS plannedToday,
  (SELECT COUNT(*) FROM communication_logs) AS communicationLogs,
  (SELECT COUNT(*) FROM service_attachments) AS attachments,
  (SELECT COUNT(*) FROM invoices) AS activeInvoices,
  (SELECT COUNT(*) FROM amc_contracts) AS activeContracts
''',
      [nowIso, nowIso, todayStr],
    );

    final row = rows.first;
    return {
      'outstandingBalance':
          (row['outstandingBalance'] as num?)?.toDouble() ?? 0.0,
      'overdueInvoices': row['overdueInvoices'] as int? ?? 0,
      'expiringContracts': row['expiringContracts'] as int? ?? 0,
      'openPurchaseOrders': row['openPurchaseOrders'] as int? ?? 0,
      'plannedToday': row['plannedToday'] as int? ?? 0,
      'communicationLogs': row['communicationLogs'] as int? ?? 0,
      'attachments': row['attachments'] as int? ?? 0,
      'activeInvoices': row['activeInvoices'] as int? ?? 0,
      'activeContracts': row['activeContracts'] as int? ?? 0,
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

  Future<String> exportServiceInvoice(ServiceRequest request) async {
    final customer = await _resolveCustomerForRequest(request);
    final completedAt =
        DateTime.tryParse(request.completedAt ?? '') ??
        DateTime.tryParse(request.scheduledFor ?? '') ??
        DateTime.now();
    final invoiceNumber = _serviceInvoiceNumber(request, completedAt);
    final invoiceDir = await _invoiceDirectory();
    final filePath = p.join(invoiceDir.path, '$invoiceNumber.pdf');
    final file = File(filePath);

    final settingsRepository = SettingsRepository();
    final appSettings = await settingsRepository.loadSettings();

    // Look up the MRP and Supplier Price values for each item in the service request
    final db = await dbHelper.database;
    final itemIds = request.inventoryItems
        .map((e) => e.inventoryItemId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
    
    final mrpMap = <String, double>{};
    final priceMap = <String, double>{};
    if (itemIds.isNotEmpty) {
      final placeholders = List.filled(itemIds.length, '?').join(', ');
      final results = await db.rawQuery(
        'SELECT id, mrp, supplierPrice FROM inventory WHERE id IN ($placeholders)',
        itemIds,
      );
      for (final row in results) {
        final id = row['id'] as String;
        final mrp = (row['mrp'] as num).toDouble();
        final price = (row['supplierPrice'] as num?)?.toDouble() ?? 0.0;
        mrpMap[id] = mrp;
        priceMap[id] = price;
      }
    }

    final pdfBytes = await InvoicePdfService().buildServiceInvoicePdf(
      request: request,
      customer: customer,
      invoiceNumber: invoiceNumber,
      completedAt: completedAt,
      businessName: appSettings.businessName,
      businessPhone: appSettings.businessPhone,
      businessAddress: appSettings.businessAddress,
      mrpMap: mrpMap,
    );
    await file.writeAsBytes(pdfBytes, flush: true);

    // Sync invoice to database so already completed services get added immediately upon downloading/viewing!
    if (customer != null) {
      double supplierPriceSum = 0.0;
      for (final item in request.inventoryItems) {
        final itemPrice = priceMap[item.inventoryItemId] ?? 0.0;
        supplierPriceSum += itemPrice * item.quantity;
      }

      final invoice = Invoice(
        id: 'inv-${request.id}',
        customerId: customer.id,
        invoiceNumber: invoiceNumber,
        issueDate: completedAt.toIso8601String(),
        dueDate: completedAt.toIso8601String(),
        totalAmount: request.totalAmount,
        paidAmount: request.totalAmount,
        supplierPrice: supplierPriceSum,
        status: 'paid',
        notes:
            'Auto-generated invoice from completed service request: ${request.type}.',
      );
      await upsertInvoice(invoice);
    }

    return file.path;
  }

  Future<void> _syncSupplierActivePoCount(
    DatabaseExecutor db,
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

  Future<Customer?> _resolveCustomerForRequest(ServiceRequest request) async {
    final customerRepository = CustomerRepository();
    final customerId = (request.customerId ?? '').trim();
    if (customerId.isNotEmpty) {
      final customer = await customerRepository.getCustomerById(customerId);
      if (customer != null) {
        return customer;
      }
    }

    final customers = await customerRepository.getCustomers();
    for (final customer in customers) {
      if (customer.name == request.customerName) {
        return customer;
      }
    }
    return null;
  }

  Future<Directory> _invoiceDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'invoices'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _serviceInvoiceNumber(ServiceRequest request, DateTime completedAt) {
    final datePart =
        '${completedAt.year}${completedAt.month.toString().padLeft(2, '0')}${completedAt.day.toString().padLeft(2, '0')}';
    final suffix = request.id.length >= 6
        ? request.id.substring(request.id.length - 6).toUpperCase()
        : request.id.toUpperCase();
    return 'SVC-$datePart-$suffix';
  }

  Future<List<ServiceRequest>>
  getCompletedServiceRequestsWithoutInvoice() async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT sr.* FROM service_requests sr
      LEFT JOIN invoices inv ON inv.id = 'inv-' || sr.id
      WHERE sr.status = 'completed' AND inv.id IS NULL
    ''');
    return maps.map((e) => ServiceRequest.fromMap(e)).toList();
  }
}
