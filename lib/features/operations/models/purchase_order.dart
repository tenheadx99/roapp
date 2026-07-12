import 'dart:convert';

import 'package:equatable/equatable.dart';

class PurchaseOrderItem extends Equatable {
  final String? inventoryItemId;
  final String name;
  final int quantity;
  final double unitCost;

  const PurchaseOrderItem({
    this.inventoryItemId,
    required this.name,
    required this.quantity,
    required this.unitCost,
  });

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      inventoryItemId: map['inventoryItemId'] as String?,
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitCost: (map['unitCost'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inventoryItemId': inventoryItemId,
      'name': name,
      'quantity': quantity,
      'unitCost': unitCost,
    };
  }

  double get lineTotal => quantity * unitCost;

  PurchaseOrderItem copyWith({
    String? inventoryItemId,
    String? name,
    int? quantity,
    double? unitCost,
  }) {
    return PurchaseOrderItem(
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
    );
  }

  @override
  List<Object?> get props => [inventoryItemId, name, quantity, unitCost];
}

class PurchaseOrder extends Equatable {
  final String id;
  final String supplierId;
  final String poNumber;
  final String createdAt;
  final String expectedDate;
  final String? receivedDate;
  final String status;
  final double totalAmount;
  final int leadDays;
  final String notes;
  final List<PurchaseOrderItem> items;

  const PurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.poNumber,
    required this.createdAt,
    required this.expectedDate,
    required this.receivedDate,
    required this.status,
    required this.totalAmount,
    required this.leadDays,
    required this.notes,
    this.items = const [],
  });

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    final rawItems = map['lineItems'] as String?;
    final items = rawItems == null || rawItems.isEmpty
        ? const <PurchaseOrderItem>[]
        : (jsonDecode(rawItems) as List<dynamic>)
              .map(
                (item) => PurchaseOrderItem.fromMap(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();

    return PurchaseOrder(
      id: map['id'] as String,
      supplierId: map['supplierId'] as String,
      poNumber: map['poNumber'] as String,
      createdAt: map['createdAt'] as String,
      expectedDate: map['expectedDate'] as String,
      receivedDate: map['receivedDate'] as String?,
      status: map['status'] as String,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      leadDays: map['leadDays'] as int,
      notes: map['notes'] as String? ?? '',
      items: items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierId': supplierId,
      'poNumber': poNumber,
      'createdAt': createdAt,
      'expectedDate': expectedDate,
      'receivedDate': receivedDate,
      'status': status,
      'totalAmount': totalAmount,
      'leadDays': leadDays,
      'notes': notes,
      'lineItems': items.isEmpty
          ? null
          : jsonEncode(items.map((item) => item.toMap()).toList()),
    };
  }

  PurchaseOrder copyWith({
    String? id,
    String? supplierId,
    String? poNumber,
    String? createdAt,
    String? expectedDate,
    String? receivedDate,
    String? status,
    double? totalAmount,
    int? leadDays,
    String? notes,
    List<PurchaseOrderItem>? items,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      poNumber: poNumber ?? this.poNumber,
      createdAt: createdAt ?? this.createdAt,
      expectedDate: expectedDate ?? this.expectedDate,
      receivedDate: receivedDate ?? this.receivedDate,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      leadDays: leadDays ?? this.leadDays,
      notes: notes ?? this.notes,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
    id,
    supplierId,
    poNumber,
    createdAt,
    expectedDate,
    receivedDate,
    status,
    totalAmount,
    leadDays,
    notes,
    items,
  ];
}
