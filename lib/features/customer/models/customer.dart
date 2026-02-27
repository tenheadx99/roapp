import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String model;
  final String
  status; // 'Service Due' | 'Operational' | 'AMC Plan' | 'Pending Install'
  final String lastService;
  final String area;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.model,
    required this.status,
    required this.lastService,
    required this.area,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      model: map['model'] as String,
      status: map['status'] as String,
      lastService: map['lastService'] as String,
      area: map['area'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'model': model,
      'status': status,
      'lastService': lastService,
      'area': area,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    model,
    status,
    lastService,
    area,
  ];
}
