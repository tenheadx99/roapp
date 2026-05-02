import 'package:equatable/equatable.dart';

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
  });

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
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
    };
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
  ];
}
