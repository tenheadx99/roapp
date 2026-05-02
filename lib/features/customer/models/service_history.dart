import 'package:equatable/equatable.dart';

class ServiceHistory extends Equatable {
  final String id;
  final String customerId;
  final String date;
  final String type;
  final String technicianName;
  final String notes;
  final double cost;
  final String partsReplaced;

  const ServiceHistory({
    required this.id,
    required this.customerId,
    required this.date,
    required this.type,
    required this.technicianName,
    required this.notes,
    required this.cost,
    required this.partsReplaced,
  });

  factory ServiceHistory.fromMap(Map<String, dynamic> map) {
    return ServiceHistory(
      id: map['id'] as String,
      customerId: map['customerId'] as String,
      date: map['date'] as String,
      type: map['type'] as String,
      technicianName: map['technicianName'] as String,
      notes: map['notes'] as String,
      cost: (map['cost'] as num).toDouble(),
      partsReplaced: map['partsReplaced'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'date': date,
      'type': type,
      'technicianName': technicianName,
      'notes': notes,
      'cost': cost,
      'partsReplaced': partsReplaced,
    };
  }

  @override
  List<Object?> get props => [
    id,
    customerId,
    date,
    type,
    technicianName,
    notes,
    cost,
    partsReplaced,
  ];
}
