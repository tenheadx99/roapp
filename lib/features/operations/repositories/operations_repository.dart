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
    final filePath = p.join(invoiceDir.path, '$invoiceNumber.html');
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

    await file.writeAsString(
      _buildServiceInvoiceHtml(
        request: request,
        customer: customer,
        invoiceNumber: invoiceNumber,
        completedAt: completedAt,
        businessName: appSettings.businessName,
        businessPhone: appSettings.businessPhone,
        businessAddress: appSettings.businessAddress,
        mrpMap: mrpMap,
      ),
    );

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
    required String businessName,
    required String businessPhone,
    required String businessAddress,
    Map<String, double> mrpMap = const {},
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
              <td colspan="5" style="padding:16px; border-bottom:1px solid #E2E8F0; color:#64748B; text-align:center; font-style:italic;">
                No inventory items were added to this service.
              </td>
            </tr>
          '''
        : lineItems
              .map(
                (item) {
                  final mrp = mrpMap[item.inventoryItemId] ?? item.unitPrice;
                  return '''
                  <tr>
                    <td style="padding:16px; border-bottom:1px solid #E2E8F0; font-weight:600; color:#1E293B;">${_escapeHtml(item.name)}</td>
                    <td data-label="Qty" style="padding:16px; border-bottom:1px solid #E2E8F0; text-align:center; color:#334155;">${item.quantity}</td>
                    <td data-label="MRP" style="padding:16px; border-bottom:1px solid #E2E8F0; text-align:right; color:#64748B; font-weight:500;">${formatRupee(mrp, decimalDigits: 2)}</td>
                    <td data-label="Price" style="padding:16px; border-bottom:1px solid #E2E8F0; text-align:right; color:#334155;">${formatRupee(item.unitPrice, decimalDigits: 2)}</td>
                    <td data-label="Total" style="padding:16px; border-bottom:1px solid #E2E8F0; text-align:right; font-weight:700; color:#0F172A;">${formatRupee(item.lineTotal, decimalDigits: 2)}</td>
                  </tr>
                ''';
                },
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
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>$invoiceNumber</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
      body {
        font-family: 'Outfit', sans-serif;
        margin: 0;
        padding: 40px 24px;
        background-color: #F8FAFC;
        color: #0F172A;
        -webkit-print-color-adjust: exact;
      }
      .container {
        max-width: 850px;
        margin: 0 auto;
        background: #FFFFFF;
        padding: 48px;
        border-radius: 24px;
        box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.02), 0 8px 10px -6px rgba(0, 0, 0, 0.02);
        border: 1px solid #E2E8F0;
      }
      .header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        border-bottom: 2px solid #F1F5F9;
        padding-bottom: 32px;
        margin-bottom: 32px;
      }
      .header-title h1 {
        margin: 0;
        font-size: 32px;
        font-weight: 800;
        color: #007FFF;
        letter-spacing: -0.5px;
      }
      .invoice-badge {
        display: inline-block;
        padding: 6px 14px;
        background: #DCFCE7;
        color: #15803D;
        font-weight: 700;
        font-size: 12px;
        border-radius: 9999px;
        text-transform: uppercase;
        letter-spacing: 1px;
        margin-top: 8px;
      }
      .details-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 24px;
        margin-bottom: 36px;
      }
      .details-card {
        padding: 24px;
        background: #F8FAFC;
        border-radius: 20px;
        border: 1px solid #E2E8F0;
      }
      .details-card h3 {
        margin: 0 0 12px;
        font-size: 12px;
        font-weight: 700;
        letter-spacing: 1.5px;
        color: #64748B;
        text-transform: uppercase;
      }
      .details-card p {
        margin: 6px 0;
        font-size: 14px;
        color: #334155;
        line-height: 1.5;
      }
      .details-card strong {
        color: #0F172A;
      }
      .table-container {
        border: 1px solid #E2E8F0;
        border-radius: 16px;
        overflow: hidden;
        margin-bottom: 32px;
      }
      table {
        width: 100%;
        border-collapse: collapse;
      }
      th {
        background: #F1F5F9;
        padding: 14px 16px;
        text-align: left;
        font-size: 12px;
        font-weight: 700;
        text-transform: uppercase;
        color: #475569;
        letter-spacing: 0.5px;
      }
      .footer-grid {
        display: grid;
        grid-template-columns: 1fr 280px;
        gap: 24px;
      }
      .notes-card {
        padding: 24px;
        background: #F8FAFC;
        border-radius: 20px;
        border: 1px solid #E2E8F0;
        align-self: start;
      }
      .notes-card h3 {
        margin: 0 0 10px;
        font-size: 12px;
        font-weight: 700;
        letter-spacing: 1.5px;
        color: #64748B;
        text-transform: uppercase;
      }
      .notes-card p {
        margin: 0;
        font-size: 14px;
        line-height: 1.6;
        color: #475569;
        white-space: pre-wrap;
      }
      .summary-card {
        padding: 24px;
        background: #0F172A;
        color: #FFFFFF;
        border-radius: 20px;
      }
      .summary-row {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 12px;
        font-size: 14px;
        color: #94A3B8;
      }
      .summary-row.total {
        margin-top: 16px;
        padding-top: 16px;
        border-top: 1px solid rgba(255, 255, 255, 0.15);
        font-size: 20px;
        font-weight: 700;
        color: #FFFFFF;
      }
      .summary-row strong {
        color: #FFFFFF;
      }
      .footer-thankyou {
        text-align: center;
        margin-top: 48px;
        padding-top: 24px;
        border-top: 1px solid #F1F5F9;
        font-size: 14px;
        color: #94A3B8;
        font-weight: 500;
      }
      @media (max-width: 600px) {
        body {
          padding: 16px 8px;
          background-color: #FFFFFF;
        }
        .container {
          padding: 16px;
          border-radius: 16px;
          box-shadow: none;
          border: none;
        }
        .header {
          flex-direction: column;
          align-items: stretch;
          gap: 16px;
          padding-bottom: 24px;
          margin-bottom: 24px;
        }
        .header-business {
          text-align: left !important;
        }
        .details-grid {
          grid-template-columns: 1fr;
          gap: 16px;
          margin-bottom: 24px;
        }
        .details-card {
          padding: 16px;
          border-radius: 16px;
        }
        .footer-grid {
          grid-template-columns: 1fr;
          gap: 16px;
        }
        table, thead, tbody, th, td, tr {
          display: block;
        }
        thead {
          display: none;
        }
        tr {
          background: #F8FAFC;
          border: 1px solid #E2E8F0;
          border-radius: 16px;
          padding: 16px;
          margin-bottom: 12px;
        }
        td {
          border-bottom: none !important;
          padding: 6px 0 !important;
          display: flex;
          justify-content: space-between;
          font-size: 14px;
          text-align: right;
        }
        td::before {
          content: attr(data-label) ": ";
          font-weight: 700;
          color: #64748B;
          text-transform: uppercase;
          font-size: 11px;
          letter-spacing: 0.5px;
          margin-right: 8px;
        }
        td:first-child {
          font-size: 16px;
          font-weight: 700;
          color: #0F172A;
          border-bottom: 1px solid #E2E8F0 !important;
          padding-bottom: 10px !important;
          margin-bottom: 6px;
          display: block;
          text-align: left;
        }
        td:first-child::before {
          display: none;
        }
      }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="header">
        <div class="header-title">
          <h1>Service Invoice</h1>
          <p style="margin:4px 0 0; color:#64748B; font-weight:600; font-size:15px;">$invoiceNumber</p>
          <span class="invoice-badge">Paid</span>
        </div>
        <div class="header-business" style="text-align:right;">
          <p style="margin:0; font-weight:800; font-size:18px; color:#0F172A;">${_escapeHtml(businessName)}</p>
          ${businessPhone.trim().isNotEmpty ? '<p style="margin:4px 0 0; color:#475569; font-size:14px;">📞 ${_escapeHtml(businessPhone)}</p>' : ''}
          ${businessAddress.trim().isNotEmpty ? '<p style="margin:4px 0 0; color:#475569; font-size:14px; max-width:250px; display:inline-block; word-break:break-word;">📍 ${_escapeHtml(businessAddress)}</p>' : ''}
          <p style="margin:8px 0 0; color:#94A3B8; font-size:12px; font-weight:600; text-transform:uppercase; letter-spacing:0.5px;">Issued: ${_formatDate(completedAt)}</p>
        </div>
      </div>

      <div class="details-grid">
        <div class="details-card">
          <h3>Billed To</h3>
          <p><strong>${_escapeHtml(customerName)}</strong></p>
          <p>Phone: ${_escapeHtml(customerPhone)}</p>
          <p>Address: ${_escapeHtml(customerAddress)}</p>
        </div>
        <div class="details-card">
          <h3>Service Details</h3>
          <p>Type: <strong>${_escapeHtml(request.type)}</strong></p>
          <p>Model: ${_escapeHtml(model)}</p>
          <p>Technician: ${_escapeHtml(technician)}</p>
          <p>Completed: ${_escapeHtml(request.time)}</p>
        </div>
      </div>

      <div class="table-container">
        <table>
          <thead>
            <tr>
              <th style="padding:14px 16px;">Item / Spare Part</th>
              <th style="padding:14px 16px; text-align:center;">Qty</th>
              <th style="padding:14px 16px; text-align:right;">MRP</th>
              <th style="padding:14px 16px; text-align:right;">Price</th>
              <th style="padding:14px 16px; text-align:right;">Total</th>
            </tr>
          </thead>
          <tbody>
            $rows
          </tbody>
        </table>
      </div>

      <div class="footer-grid">
        <div class="notes-card">
          <h3>Service Notes</h3>
          <p>${_escapeHtml(notes)}</p>
        </div>
        <div class="summary-card">
          <div class="summary-row">
            <span>Subtotal</span>
            <strong>${formatRupee(request.totalAmount, decimalDigits: 2)}</strong>
          </div>
          <div class="summary-row">
            <span>Tax (GST 0%)</span>
            <strong>${formatRupee(0, decimalDigits: 2)}</strong>
          </div>
          <div class="summary-row total">
            <span>Total</span>
            <span>${formatRupee(request.totalAmount, decimalDigits: 2)}</span>
          </div>
        </div>
      </div>

      <div class="footer-thankyou">
        Thank you for choosing ${_escapeHtml(businessName)}!
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
