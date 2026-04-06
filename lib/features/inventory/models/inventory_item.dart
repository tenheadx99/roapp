import 'package:equatable/equatable.dart';

class InventoryItem extends Equatable {
  final String id;
  final String name;
  final double mrp;
  final String supplier;
  final double price;
  final int stock;
  final int lowStockThreshold;
  final String category;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.mrp,
    required this.supplier,
    required this.price,
    required this.stock,
    required this.lowStockThreshold,
    required this.category,
  });

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as String,
      name: map['name'] as String,
      mrp: (map['mrp'] as num).toDouble(),
      supplier: map['supplier'] as String,
      price: (map['price'] as num).toDouble(),
      stock: map['stock'] as int,
      lowStockThreshold: map['lowStockThreshold'] as int,
      category: map['category'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mrp': mrp,
      'supplier': supplier,
      'price': price,
      'stock': stock,
      'lowStockThreshold': lowStockThreshold,
      'category': category,
    };
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    double? mrp,
    String? supplier,
    double? price,
    int? stock,
    int? lowStockThreshold,
    String? category,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      mrp: mrp ?? this.mrp,
      supplier: supplier ?? this.supplier,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    mrp,
    supplier,
    price,
    stock,
    lowStockThreshold,
    category,
  ];
}
