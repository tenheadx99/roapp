import 'package:equatable/equatable.dart';

class InventoryItem extends Equatable {
  final String id;
  final String name;
  final String sku;
  final String supplier;
  final double price;
  final int stock;
  final int lowStockThreshold;
  final String category;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.supplier,
    required this.price,
    required this.stock,
    required this.lowStockThreshold,
    required this.category,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    sku,
    supplier,
    price,
    stock,
    lowStockThreshold,
    category,
  ];
}
