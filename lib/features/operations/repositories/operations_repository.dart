import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/core/utils/currency_formatter.dart';
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

  Future<String> exportServiceInvoice(ServiceRequest request) async {
    final customer = await _resolveCustomerForRequest(request);
    final completedAt =
        DateTime.tryParse(request.completedAt ?? '') ??
        DateTime.tryParse(request.scheduledFor ?? '') ??
        DateTime.now();
    final invoiceNumber = _serviceInvoiceNumber(request, completedAt);
    final invoiceDir = await _invoiceDirectory();
    final filePath = p.join(invoiceDir.path, '$invoiceNumber.html');
    final file = File(filePath);

    await file.writeAsString(
      _buildServiceInvoiceHtml(
        request: request,
        customer: customer,
        invoiceNumber: invoiceNumber,
        completedAt: completedAt,
      ),
    );

    return file.path;
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

  String _buildServiceInvoiceHtml({
    required ServiceRequest request,
    required Customer? customer,
    required String invoiceNumber,
    required DateTime completedAt,
  }) {
    final customerName = customer?.name ?? request.customerName;
    final customerPhone = customer?.phone ?? 'N/A';
    final customerAddress = customer?.area ?? request.address;
    final model = customer?.model ?? request.model;
    final technician = (request.technicianName ?? '').trim().isEmpty
        ? 'Unassigned'
        : request.technicianName!.trim();
    final lineItems = request.inventoryItems;
    final rows = lineItems.isEmpty
        ? '''
            <tr>
              <td colspan="4" style="padding:12px;border-bottom:1px solid #e2e8f0;color:#64748b;text-align:center;">
                No inventory items were added to this service.
              </td>
            </tr>
          '''
        : lineItems
              .map(
                (item) =>
                    '''
                  <tr>
                    <td style="padding:12px;border-bottom:1px solid #e2e8f0;">${_escapeHtml(item.name)}</td>
                    <td style="padding:12px;border-bottom:1px solid #e2e8f0;text-align:center;">${item.quantity}</td>
                    <td style="padding:12px;border-bottom:1px solid #e2e8f0;text-align:right;">${formatRupee(item.unitPrice, decimalDigits: 2)}</td>
                    <td style="padding:12px;border-bottom:1px solid #e2e8f0;text-align:right;">${formatRupee(item.lineTotal, decimalDigits: 2)}</td>
                  </tr>
                ''',
              )
              .join();

    final notes = (request.notes ?? '').trim().isEmpty
        ? 'Service completed successfully.'
        : request.notes!.trim();

    return '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>$invoiceNumber</title>
  </head>
  <body style="font-family: Arial, sans-serif; margin: 32px; color: #0f172a;">
    <div style="max-width: 900px; margin: 0 auto;">
      <div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:32px;">
        <div>
          <h1 style="margin:0; font-size:28px;">Service Invoice</h1>
          <p style="margin:8px 0 0; color:#64748b;">$invoiceNumber</p>
        </div>
        <div style="text-align:right;">
          <p style="margin:0; font-weight:700;">RO Manager</p>
          <p style="margin:6px 0 0; color:#64748b;">Generated on ${_formatDate(completedAt)}</p>
        </div>
      </div>

      <div style="display:grid; grid-template-columns:1fr 1fr; gap:20px; margin-bottom:28px;">
        <div style="padding:18px; background:#f8fafc; border-radius:16px;">
          <p style="margin:0 0 8px; font-size:12px; letter-spacing:1px; color:#64748b;">BILLED TO</p>
          <p style="margin:0; font-weight:700;">${_escapeHtml(customerName)}</p>
          <p style="margin:6px 0 0;">Phone: ${_escapeHtml(customerPhone)}</p>
          <p style="margin:6px 0 0;">Address: ${_escapeHtml(customerAddress)}</p>
        </div>
        <div style="padding:18px; background:#f8fafc; border-radius:16px;">
          <p style="margin:0 0 8px; font-size:12px; letter-spacing:1px; color:#64748b;">SERVICE DETAILS</p>
          <p style="margin:0;">Type: ${_escapeHtml(request.type)}</p>
          <p style="margin:6px 0 0;">Model: ${_escapeHtml(model)}</p>
          <p style="margin:6px 0 0;">Technician: ${_escapeHtml(technician)}</p>
          <p style="margin:6px 0 0;">Completed: ${_escapeHtml(request.time)}</p>
        </div>
      </div>

      <table style="width:100%; border-collapse:collapse; margin-bottom:20px;">
        <thead>
          <tr style="background:#eff6ff;">
            <th style="padding:12px; text-align:left;">Item</th>
            <th style="padding:12px; text-align:center;">Qty</th>
            <th style="padding:12px; text-align:right;">Unit Price</th>
            <th style="padding:12px; text-align:right;">Line Total</th>
          </tr>
        </thead>
        <tbody>
          $rows
        </tbody>
      </table>

      <div style="display:flex; justify-content:space-between; gap:20px;">
        <div style="flex:1; padding:18px; background:#f8fafc; border-radius:16px;">
          <p style="margin:0 0 8px; font-size:12px; letter-spacing:1px; color:#64748b;">NOTES</p>
          <p style="margin:0; white-space:pre-wrap;">${_escapeHtml(notes)}</p>
        </div>
        <div style="width:280px; padding:18px; background:#0f172a; color:white; border-radius:16px;">
          <div style="display:flex; justify-content:space-between; margin-bottom:10px;">
            <span>Subtotal</span>
            <strong>${formatRupee(request.totalAmount, decimalDigits: 2)}</strong>
          </div>
          <div style="display:flex; justify-content:space-between; margin-bottom:10px;">
            <span>Tax</span>
            <strong>${formatRupee(0, decimalDigits: 2)}</strong>
          </div>
          <div style="display:flex; justify-content:space-between; padding-top:10px; border-top:1px solid rgba(255,255,255,0.2); font-size:18px;">
            <span>Total</span>
            <strong>${formatRupee(request.totalAmount, decimalDigits: 2)}</strong>
          </div>
        </div>
      </div>
    </div>
  </body>
</html>
''';
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  String _formatDate(DateTime value) {
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day.toString().padLeft(2, '0')} ${labels[value.month - 1]} ${value.year}';
  }
}
