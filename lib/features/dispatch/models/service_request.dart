import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'service_request_inventory_item.dart';

class ServiceRequest extends Equatable {
  final String id;
  final String? customerId;
  final String customerName;
  final String address;
  final String type;
  final String model;
  final String time;
  final String status; // 'new' | 'assigned' | 'in_progress' | 'completed'
  final String? scheduledFor;
  final String? completedAt;
  final String? technicianId;
  final String? technicianName;
  final String? notes;
  final List<ServiceRequestInventoryItem> inventoryItems;
  final double totalAmount;

  const ServiceRequest({
    required this.id,
    this.customerId,
    required this.customerName,
    required this.address,
    required this.type,
    required this.model,
    required this.time,
    required this.status,
    this.scheduledFor,
    this.completedAt,
    this.technicianId,
    this.technicianName,
    this.notes,
    this.inventoryItems = const [],
    this.totalAmount = 0,
  });

  factory ServiceRequest.fromMap(Map<String, dynamic> map) {
    final rawInventoryItems = map['inventoryItems'] as String?;
    final inventoryItems =
        rawInventoryItems == null || rawInventoryItems.isEmpty
        ? const <ServiceRequestInventoryItem>[]
        : (jsonDecode(rawInventoryItems) as List<dynamic>)
              .map(
                (item) => ServiceRequestInventoryItem.fromMap(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();

    return ServiceRequest(
      id: map['id'] as String,
      customerId: map['customerId'] as String?,
      customerName: map['customerName'] as String,
      address: map['address'] as String,
      type: map['type'] as String,
      model: map['model'] as String,
      time: map['time'] as String,
      status: map['status'] as String,
      scheduledFor: map['scheduledFor'] as String?,
      completedAt: map['completedAt'] as String?,
      technicianId: map['technicianId'] as String?,
      technicianName: map['technicianName'] as String?,
      notes: map['notes'] as String?,
      inventoryItems: inventoryItems,
      totalAmount:
          (map['totalAmount'] as num?)?.toDouble() ??
          inventoryItems.fold<double>(0, (sum, item) => sum + item.lineTotal),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'address': address,
      'type': type,
      'model': model,
      'time': time,
      'status': status,
      'scheduledFor': scheduledFor,
      'completedAt': completedAt,
      'technicianId': technicianId,
      'technicianName': technicianName,
      'notes': notes,
      'inventoryItems': jsonEncode(
        inventoryItems.map((item) => item.toMap()).toList(),
      ),
      'totalAmount': totalAmount,
    };
  }

  @override
  List<Object?> get props => [
    id,
    customerId,
    customerName,
    address,
    type,
    model,
    time,
    status,
    scheduledFor,
    completedAt,
    technicianId,
    technicianName,
    notes,
    inventoryItems,
    totalAmount,
  ];

  ServiceRequest copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? address,
    String? type,
    String? model,
    String? time,
    String? status,
    String? scheduledFor,
    String? completedAt,
    String? technicianId,
    String? technicianName,
    String? notes,
    List<ServiceRequestInventoryItem>? inventoryItems,
    double? totalAmount,
  }) {
    return ServiceRequest(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      type: type ?? this.type,
      model: model ?? this.model,
      time: time ?? this.time,
      status: status ?? this.status,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      completedAt: completedAt ?? this.completedAt,
      technicianId: technicianId ?? this.technicianId,
      technicianName: technicianName ?? this.technicianName,
      notes: notes ?? this.notes,
      inventoryItems: inventoryItems ?? this.inventoryItems,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  bool get hasAssignedTechnician =>
      (technicianName ?? '').trim().isNotEmpty ||
      (technicianId ?? '').isNotEmpty;

  int get inventoryLineCount => inventoryItems.length;

  String get statusLabel {
    switch (status) {
      case 'new':
        return 'NEW';
      case 'assigned':
        return 'ASSIGNED';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      default:
        return status.toUpperCase();
    }
  }
}
