import 'package:equatable/equatable.dart';

class ServiceRequest extends Equatable {
  final String id;
  final String customerName;
  final String address;
  final String type;
  final String model;
  final String time;
  final String status; // 'new' | 'assigned' | 'in-progress'

  const ServiceRequest({
    required this.id,
    required this.customerName,
    required this.address,
    required this.type,
    required this.model,
    required this.time,
    required this.status,
  });

  @override
  List<Object?> get props => [
    id,
    customerName,
    address,
    type,
    model,
    time,
    status,
  ];
}
