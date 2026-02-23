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
