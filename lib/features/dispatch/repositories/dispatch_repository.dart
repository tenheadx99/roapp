import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/features/customer/models/customer.dart';
import 'package:roapp/features/customer/models/service_history.dart';
import 'package:roapp/features/dispatch/models/service_request.dart';
import 'package:roapp/features/dispatch/models/service_request_inventory_item.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

class DispatchRepository {
  final dbHelper = DatabaseHelper.instance;
  final uuid = const Uuid();

  Future<List<ServiceRequest>> getServiceRequests() async {
    final db = await dbHelper.database;
    await _synchronizeCompletedRequests(db);
    final maps = await db.query(
      'service_requests',
      orderBy: 'scheduledFor ASC, time ASC',
    );
    return maps.map((e) => ServiceRequest.fromMap(e)).toList();
  }

  Future<ServiceRequest?> getServiceRequestById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'service_requests',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ServiceRequest.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ServiceRequest>> getServiceRequestsByCustomerName(
    String name,
  ) async {
    return getServiceRequestsByCustomer(customerName: name);
  }

  Future<List<ServiceRequest>> getServiceRequestsByCustomer({
    String? customerId,
    String? customerName,
  }) async {
    final db = await dbHelper.database;
    await _synchronizeCompletedRequests(db);
    late final List<Map<String, Object?>> maps;

    final hasCustomerId = (customerId ?? '').trim().isNotEmpty;
    final hasCustomerName = (customerName ?? '').trim().isNotEmpty;

    if (hasCustomerId && hasCustomerName) {
      maps = await db.query(
        'service_requests',
        where:
            '(customerId = ?) OR ((customerId IS NULL OR TRIM(customerId) = \'\') AND customerName = ?)',
        whereArgs: [customerId, customerName],
        orderBy: 'scheduledFor ASC, time ASC',
      );
    } else if (hasCustomerId) {
      maps = await db.query(
        'service_requests',
        where: 'customerId = ?',
        whereArgs: [customerId],
        orderBy: 'scheduledFor ASC, time ASC',
      );
    } else if (hasCustomerName) {
      maps = await db.query(
        'service_requests',
        where: 'customerName = ?',
        whereArgs: [customerName],
        orderBy: 'scheduledFor ASC, time ASC',
      );
    } else {
      maps = const [];
    }

    return maps.map((e) => ServiceRequest.fromMap(e)).toList();
  }

  Future<void> addServiceRequest(ServiceRequest request) async {
    final db = await dbHelper.database;
    await db.insert('service_requests', request.toMap());
    if (request.status == 'completed') {
      await _synchronizeCompletedRequests(db);
    }
  }

  Future<void> updateServiceRequest(ServiceRequest request) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final existingMaps = await txn.query(
        'service_requests',
        where: 'id = ?',
        whereArgs: [request.id],
        limit: 1,
      );

      final existingRequest = existingMaps.isEmpty
          ? null
          : ServiceRequest.fromMap(existingMaps.first);
      final isCompletingNow =
          existingRequest?.status != 'completed' &&
          request.status == 'completed';

      final requestToStore = isCompletingNow
          ? request.copyWith(completedAt: DateTime.now().toIso8601String())
          : request.copyWith(
              completedAt:
                  request.completedAt ??
                  existingRequest?.completedAt ??
                  (request.status == 'completed'
                      ? DateTime.now().toIso8601String()
                      : null),
            );

      await txn.update(
        'service_requests',
        requestToStore.toMap(),
        where: 'id = ?',
        whereArgs: [request.id],
      );

      if (requestToStore.status == 'completed') {
        await _syncCompletedRequestArtifacts(txn, requestToStore);
      }
    });
  }

  Future<void> deleteServiceRequest(String id) async {
    final db = await dbHelper.database;
    await db.delete('service_requests', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _synchronizeCompletedRequests(Database db) async {
    await db.transaction((txn) async {
      final completedMaps = await txn.query(
        'service_requests',
        where: 'status = ?',
        whereArgs: ['completed'],
      );

      for (final map in completedMaps) {
        final request = ServiceRequest.fromMap(map);
        if ((request.completedAt ?? '').trim().isEmpty) {
          final completedAt =
              request.scheduledFor ?? DateTime.now().toIso8601String();
          final updated = request.copyWith(completedAt: completedAt);
          await txn.update(
            'service_requests',
            updated.toMap(),
            where: 'id = ?',
            whereArgs: [request.id],
          );
          await _syncCompletedRequestArtifacts(txn, updated);
        } else {
          await _syncCompletedRequestArtifacts(txn, request);
        }
      }
    });
  }

  Future<void> _syncCompletedRequestArtifacts(
    DatabaseExecutor db,
    ServiceRequest request,
  ) async {
    final customer = await _resolveCustomer(db, request);
    final completionTime = _completionDateTime(request);
    final formattedHistoryDate = _formatDateAndTime(completionTime);
    final formattedShortDate = _formatDate(completionTime);
    final nextServiceDate = _formatDate(
      completionTime.add(const Duration(days: 90)),
    );
    final partsSummary = _buildPartsSummary(request.inventoryItems);
    final technicianName = (request.technicianName ?? '').trim().isEmpty
        ? 'Unassigned'
        : request.technicianName!.trim();
    if (customer == null) {
      return;
    }

    final existingHistory = await db.query(
      'service_history',
      where: 'serviceRequestId = ?',
      whereArgs: [request.id],
      limit: 1,
    );

    final history = ServiceHistory(
      id: existingHistory.isNotEmpty
          ? existingHistory.first['id'] as String
          : 'sh-${uuid.v4()}',
      customerId: customer.id,
      serviceRequestId: request.id,
      date: formattedHistoryDate,
      type: request.type,
      technicianName: technicianName,
      notes: request.notes?.trim().isNotEmpty == true
          ? request.notes!.trim()
          : 'Service completed.',
      cost: request.totalAmount,
      partsReplaced: partsSummary,
    );

    if (existingHistory.isEmpty) {
      await db.insert('service_history', history.toMap());
    } else {
      await db.update(
        'service_history',
        history.toMap(),
        where: 'id = ?',
        whereArgs: [history.id],
      );
    }

    final updatedCustomer = customer.copyWith(
      status: 'Operational',
      lastService: formattedShortDate,
      upcomingServiceDate: nextServiceDate,
      installationDate:
          customer.installationDate ??
          (request.type == 'New Installation' ? formattedShortDate : null),
    );
    await db.update(
      'customers',
      updatedCustomer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );

    await db.update(
      'service_requests',
      {'customerId': customer.id},
      where: 'id = ?',
      whereArgs: [request.id],
    );

    // Fetch total supplier price for request's items
    double supplierPrice = 0.0;
    final itemIds = request.inventoryItems
        .map((e) => e.inventoryItemId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
    if (itemIds.isNotEmpty) {
      final placeholders = List.filled(itemIds.length, '?').join(', ');
      final results = await db.rawQuery(
        'SELECT id, supplierPrice FROM inventory WHERE id IN ($placeholders)',
        itemIds,
      );
      final priceMap = {
        for (final row in results)
          row['id'] as String: (row['supplierPrice'] as num?)?.toDouble() ?? 0.0
      };
      for (final item in request.inventoryItems) {
        final pCost = priceMap[item.inventoryItemId] ?? 0.0;
        supplierPrice += pCost * item.quantity;
      }
    }

    final existingInvoice = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: ['inv-${request.id}'],
      limit: 1,
    );

    final datePart =
        '${completionTime.year}${completionTime.month.toString().padLeft(2, '0')}${completionTime.day.toString().padLeft(2, '0')}';
    final suffix = request.id.length >= 6
        ? request.id.substring(request.id.length - 6).toUpperCase()
        : request.id.toUpperCase();
    final invoiceNumber = 'SVC-$datePart-$suffix';

    final invoiceData = {
      'id': 'inv-${request.id}',
      'customerId': customer.id,
      'invoiceNumber': invoiceNumber,
      'issueDate': completionTime.toIso8601String(),
      'dueDate': completionTime.toIso8601String(),
      'totalAmount': request.totalAmount,
      'paidAmount': request.totalAmount,
      'supplierPrice': supplierPrice,
      'status': 'paid',
      'notes':
          'Auto-generated invoice from completed service request: ${request.type}.',
    };

    if (existingInvoice.isEmpty) {
      await db.insert('invoices', invoiceData);
    } else {
      await db.update(
        'invoices',
        invoiceData,
        where: 'id = ?',
        whereArgs: ['inv-${request.id}'],
      );
    }

    if (existingHistory.isNotEmpty) {
      return;
    }

    for (final item in request.inventoryItems) {
      final inventoryId = (item.inventoryItemId ?? '').trim();
      if (inventoryId.isEmpty) continue;

      final inventoryMaps = await db.query(
        'inventory',
        where: 'id = ?',
        whereArgs: [inventoryId],
        limit: 1,
      );
      if (inventoryMaps.isEmpty) continue;

      final currentStock = (inventoryMaps.first['stock'] as int?) ?? 0;
      final nextStock = currentStock - item.quantity;
      await db.update(
        'inventory',
        {'stock': nextStock < 0 ? 0 : nextStock},
        where: 'id = ?',
        whereArgs: [inventoryId],
      );
    }
  }

  Future<Customer?> _resolveCustomer(
    DatabaseExecutor db,
    ServiceRequest request,
  ) async {
    final customerId = (request.customerId ?? '').trim();
    if (customerId.isNotEmpty) {
      final byId = await db.query(
        'customers',
        where: 'id = ?',
        whereArgs: [customerId],
        limit: 1,
      );
      if (byId.isNotEmpty) {
        return Customer.fromMap(Map<String, dynamic>.from(byId.first));
      }
    }

    final byName = await db.query(
      'customers',
      where: 'name = ?',
      whereArgs: [request.customerName],
      limit: 1,
    );
    if (byName.isNotEmpty) {
      return Customer.fromMap(Map<String, dynamic>.from(byName.first));
    }
    return null;
  }

  DateTime _completionDateTime(ServiceRequest request) {
    return DateTime.tryParse(request.completedAt ?? '') ??
        DateTime.tryParse(request.scheduledFor ?? '') ??
        DateTime.now();
  }

  String _buildPartsSummary(List<ServiceRequestInventoryItem> items) {
    if (items.isEmpty) {
      return 'None';
    }
    return items
        .map(
          (item) =>
              item.quantity > 1 ? '${item.name} x${item.quantity}' : item.name,
        )
        .join(', ');
  }

  String _formatDate(DateTime date) {
    const months = [
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
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateAndTime(DateTime date) {
    const months = [
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
    var hour = date.hour;
    var period = 'AM';
    if (hour >= 12) {
      period = 'PM';
      if (hour > 12) {
        hour -= 12;
      }
    }
    if (hour == 0) {
      hour = 12;
    }
    return '${months[date.month - 1]} ${date.day}, ${date.year} • $hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}
