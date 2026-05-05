import 'package:equatable/equatable.dart';

class ServiceRequestInventoryItem extends Equatable {
  final String? inventoryItemId;
  final String name;
  final int quantity;
  final double unitPrice;

  const ServiceRequestInventoryItem({
    this.inventoryItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  factory ServiceRequestInventoryItem.fromMap(Map<String, dynamic> map) {
    return ServiceRequestInventoryItem(
      inventoryItemId: map['inventoryItemId'] as String?,
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inventoryItemId': inventoryItemId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  double get lineTotal => quantity * unitPrice;

  ServiceRequestInventoryItem copyWith({
    String? inventoryItemId,
    String? name,
    int? quantity,
    double? unitPrice,
  }) {
    return ServiceRequestInventoryItem(
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  List<Object?> get props => [inventoryItemId, name, quantity, unitPrice];
}
